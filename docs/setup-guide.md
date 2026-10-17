# Google Cloud (GCP) 環境 初期セットアップ & Workload Identity 構築ガイド

本ドキュメントは、Terraform を使用して Google Cloud 上に **Cloud Run** および **Cloud Monitoring 監視基盤** をデプロイするための事前準備手順書です。

サービスアカウントキー（JSON秘密鍵ファイル）を一切発行せず、GitHub Actions の一時的な ID トークンを信頼する **Workload Identity 連携 (OIDC認証)** を設定します。

---

## 1. 前提条件

- **Google Cloud SDK (`gcloud`)** がインストールされ、管理者権限で認証されていること。
  ```bash
  gcloud auth login
  ```
- 作業対象の **プロジェクトID** を設定します。
  ```bash
  PROJECT_ID="<YOUR_GCP_PROJECT_ID>"
  gcloud config set project $PROJECT_ID
  ```

---

## 2. 必要な Google Cloud API の有効化

インフラ自動化および監視に必要な API を一括で有効化します。

```bash
gcloud services enable \
  run.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  storage.googleapis.com
```

---

## 3. Terraform State 管理用 GCS バケットの作成

Terraform の状態（State）を安全に保管するための Cloud Storage バケットを作成し、履歴保護のためにバージョニングを有効化します。

```bash
BUCKET_NAME="<YOUR_UNIQUE_GCS_BUCKET_NAME>"
REGION="asia-northeast1"

# バケットの作成 (東京リージョン)
gcloud storage buckets create gs://$BUCKET_NAME \
  --location=$REGION \
  --uniform-bucket-level-access

# バージョニングの有効化
gcloud storage buckets update gs://$BUCKET_NAME --versioning
```

> [!NOTE]
> 作成後、[terraform/environments/prod/backend.tf](../terraform/environments/prod/backend.tf) 内の `bucket` を作成したバケット名に置き換えてください。

---

## 4. GitHub Actions 用 Workload Identity 連携 (OIDC) の設定

### 4-1. デプロイ用サービスアカウントの作成と権限付与
```bash
SA_NAME="terraform-deployer"
gcloud iam service-accounts create $SA_NAME \
  --display-name="Terraform Deployer for GitHub Actions"

SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# 必要なロールの付与
for ROLE in \
  roles/run.admin \
  roles/monitoring.admin \
  roles/storage.admin \
  roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE"
done
```

### 4-2. Workload Identity プールおよびプロバイダの作成
```bash
# プールの作成
POOL_NAME="github-actions-pool"
gcloud iam workload-identity-pools create $POOL_NAME \
  --location="global" \
  --display-name="GitHub Actions Pool"

# プロバイダの作成 (GitHub OIDC連携)
PROVIDER_NAME="github-actions-provider"
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
  --location="global" \
  --workload-identity-pool=$POOL_NAME \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository == '<YOUR_GITHUB_USER>/<YOUR_GITHUB_REPO>'"
```

### 4-3. サービスアカウントの権限借用（Impersonation）の許可
対象の GitHub リポジトリからのアクセスのみに、サービスアカウントの借用を許可します。

```bash
REPO="<YOUR_GITHUB_USER>/<YOUR_GITHUB_REPO>"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$REPO"
```

---

## 5. GitHub Secrets の登録

GitHub リポジトリの **Settings** > **Secrets and variables** > **Actions** にて、以下の2つのシークレットを登録します。

| Secret 名 | 設定する値 |
| :--- | :--- |
| **`GCP_WORKLOAD_IDENTITY_PROVIDER`** | `projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider` |
| **`GCP_SERVICE_ACCOUNT`** | `terraform-deployer@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com` |

---

## 6. デプロイの流れ

1. `terraform/environments/prod/` 配下のコードを変更します。
2. ブランチを切って Pull Request を作成すると、[terraform.yml](../.github/workflows/terraform.yml) が起動し、`terraform plan` が自動実行されます。
3. PR を `main` ブランチへマージすると、`terraform apply` が自動実行され、Cloud Run（外部公開HTTPS URL付き）および Cloud Monitoring アラート基盤がデプロイされます。
