# Google Cloud CI/CD & マイクロサービス監視基盤

本リポジトリは、Terraformを使用して **Google Cloud (GCP)** 上にコンテナ実行環境（**Cloud Run**）と統合監視基盤（**Cloud Monitoring / Notification Channels**）を構築し、**GitHub Actions（Workload Identity 連携 / OIDC認証）** から安全に自動デプロイを行うための構成管理リポジトリです。

> [!TIP]
> **アーキテクチャ設計判断書（ADR）**
> 「なぜ GKE ではなく Cloud Run なのか」「Cloud Monitoring の閾値設計と構造化ログ」「Workload Identity 連携による鍵漏洩リスクゼロ化」などの詳細な設計思想は、[docs/architecture-decisions.md](docs/architecture-decisions.md) をご覧ください。

---

## 主な特徴

- **完全サーバーレスコンテナ (Cloud Run v2)**:
  - OS・ノード・Kubernetes管理が完全不要。
  - **無料の組み込みHTTPS URLが自動プロビジョニング**（Cloud Load Balancing の構築・維持費をゼロ化）。
  - **ゼロスケール（0台待機）** に標準対応し、アイドル時はCPU課金が完全停止（月額数十円〜ほぼ無料での運用が可能）。
- **シークレットレス CI/CD (GitHub Actions OIDC)**:
  - 漏洩リスクの高いサービスアカウント JSON キーを一切発行せず、**Workload Identity 連携** による短期トークン認証を採用。
- **統合監視 & ログ分析 (Cloud Operations)**:
  - **Cloud Logging** による構造化ログ集約。
  - **Cloud Monitoring アラートポリシー**（CPU使用率80%超えで発報）＋ **Notification Channel** によるメール通知。

---

## ディレクトリ構成

```text
.
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitHub Actions OIDC CI/CDパイプライン
├── docs/
│   ├── architecture-decisions.md  # アーキテクチャ設計判断書
│   └── setup-guide.md             # Workload Identity 連携初期設定手順書
└── terraform/
    ├── environments/
    │   └── prod/                  # 本番環境定義 (main.tf, variables.tf, outputs.tf)
    └── modules/
        ├── cloud-run/             # Cloud Run サービスモジュール
        └── monitoring/            # Alert Policy & Notification Channel モジュール
```

---

## クイックスタート

詳細な初期設定コマンドやWorkload Identity連携の作成手順は、[docs/setup-guide.md](docs/setup-guide.md) をご覧ください。

### 1. 初期リソースの準備
1. `gcloud` CLI でログインし、Terraform State 管理用の GCS バケットを作成します。
2. GitHub Actions 用の Workload Identity プールおよびプロバイダを作成し、サービスアカウントの権限借用を設定します。
3. GitHub Secrets に以下を登録します：
   - `GCP_WORKLOAD_IDENTITY_PROVIDER`
   - `GCP_SERVICE_ACCOUNT`

### 2. デプロイ
1. `terraform/environments/prod/` 配下のコードを変更して Pull Request を作成すると、自動的に `terraform plan` が実行されます。
2. PR を `main` ブランチへマージすると、自動的に `terraform apply` が実行され、Cloud Run（外部公開HTTPS URL付き）および Cloud Monitoring アラート基盤がデプロイされます。
