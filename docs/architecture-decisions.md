# システムアーキテクチャ設計判断書 (Google Cloud Edition)

本ドキュメントは、Google Cloud (GCP) 上に構築するコンテナ基盤および監視システムの**技術選定理由、トレードオフ、および設計思想**を記録したものです。

---

## 1. 全体アーキテクチャ概要

```mermaid
flowchart TD
    subgraph CI_CD ["GitHub Actions CI/CD"]
        GHA["GitHub Actions Runner"]
        WIP["Workload Identity プール / プロバイダ (OIDC)"]
        GHA -->|1. OIDC認証 / 短期トークン交換| WIP
    end

    subgraph GCP_Cloud ["Google Cloud (asia-northeast1: 東京リージョン)"]
        SA["デプロイ用 サービスアカウント"]
        WIP -->|2. 権限借用 (Impersonation)| SA
        
        subgraph Compute ["コンテナ実行基盤"]
            Cloud_Run["Cloud Run v2 サービス"]
            HTTPS_URL["組み込み HTTPS URL (外部公開)"]
            Cloud_Run --- HTTPS_URL
        end

        subgraph Monitoring ["統合監視基盤 (Cloud Operations)"]
            Logging["Cloud Logging (構造化ログ)"]
            Alert_Policy["Cloud Monitoring アラートポリシー (CPU >= 80%)"]
            Notification_Channel["通知チャネル (メール通知)"]
            
            Cloud_Run -.->|コンテナログ| Logging
            Cloud_Run -.->|CPU使用率メトリクス| Alert_Policy
            Alert_Policy -->|インシデント発報| Notification_Channel
        end

        subgraph Storage ["State管理"]
            GCS_Bucket["Cloud Storage (GCS) バケット"]
            GCS_Bucket -->|Terraform State & バージョニング| State_File["default.tfstate"]
        end
    end

    SA -->|3. Terraform Apply| Cloud_Run
    SA -->|3. Terraform Apply| Alert_Policy
```

---

## 2. 主要な設計判断 (Design Decisions)

### 判断 1: なぜ GKE ではなく Cloud Run なのか？

| 比較項目 | Google Kubernetes Engine (GKE) | Cloud Run (本構成) |
| :--- | :--- | :--- |
| **クラスター管理費** | 月額 約 $74 (ゾーン/リージョン固定費) | **$0 (無料)** |
| **ロードバランサー** | Cloud Load Balancing の構築・維持費が必要 (月約$20〜) | **無料の組み込み HTTPS URL が自動発行** |
| **ゼロスケール (0台待機)** | 不可 (ノードインスタンスが常時稼働) | **標準対応 (リクエストのない時間は完全0円)** |
| **運用保守コスト** | 高 (K8sバージョン追従、ノードプール管理) | **極めて低い (OS・ノード・ランタイム管理不要の完全サーバーレス)** |

#### 【選定理由】
- **圧倒的なコスト効率とゼロ運用負荷**: Cloud Run は Google Cloud が誇る最高峰のサーバーレスコンテナサービスです。アイドル時はコンテナインスタンスがゼロになり CPU 課金が完全に停止するため、個人・検証環境では月額ほぼ 0 円で運用可能です。さらに、ロードバランサーを個別に構築せずともセキュアな HTTPS エンドポイントが即座に利用できるため、TCO（総保有コスト）の観点から最も優れた選択肢となります。

---

### 判断 2: Cloud Operations (Monitoring & Logging) の設計思想

1. **Cloud Logging とのネイティブ統合**:
   - コンテナの標準出力・標準エラー出力は自動的に Cloud Logging にストリーミングされ、JSON 構造化ログとして取り込まれます。Log Explorer を使用した柔軟なフィルタリングやログベースのメトリクス抽出が容易です。
2. **CPU使用率 80%（2分間継続）のアラート設計**:
   - 一時的なトラフィックのスパイクやコンテナ起動時の CPU バーストによる誤検知を排除するため、集約ウィンドウ（120秒継続）を設定した上で Alert Policy を発報します。
3. **Notification Channels による通知先の一元管理**:
   - アラートルールと通知チャネルを分離して定義することで、通知先メールアドレスの変更や将来的な Slack / PagerDuty / Pub/Sub との連携に柔軟に対応できます。

---

### 判断 3: Workload Identity 連携によるセキュリティ強化

- **サービスアカウントキー（JSON秘密鍵）の完全排除**:
  - 従来の CI/CD パイプラインで頻発していた「サービスアカウントの JSON キー漏洩事故」を根本から防止するため、Google Cloud の **Workload Identity 連携** を採用しました。
  - GitHub Actions から発行される OIDC トークン（JWT）を Google STS で検証し、一時的なアクセストークンのみをメモリ上で利用することで、鍵管理のリスクをゼロ化しています。

---

### 判断 4: なぜ Terraform なのか？（Config Connector ではなく）

1. **3大クラウド共通のアーキテクチャ記述力**:
   - Google Cloud ネイティブの Config Connector は Kubernetes クラスターが必要ですが、Terraform であれば軽量かつ AWS や Azure と全く同じ思想・モジュール構造で管理できます。
2. **GCS バケットによるシンプルな State 管理**:
   - Google Cloud Storage は強力な整合性とオブジェクトバージョニングを備えているため、追加の分散ロックサービスを用意することなく安全なチーム運用が可能です。
