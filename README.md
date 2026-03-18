# Agentic AI Platform - Azure Infrastructure

This project sets up all the cloud infrastructure needed to run an AI-powered application on Microsoft Azure. **No local tools required** - everything runs through GitHub Actions.

## What Does This Create?

When you deploy this, you'll get:

- **Database** - PostgreSQL for storing application data
- **Storage** - Azure Storage for files and documents
- **Container Registry** - A place to store your application's Docker images
- **Container Apps** - Runs your application containers (dev environment)
- **Kubernetes (AKS)** - Runs containers at scale (production only)
- **Qdrant** - Vector database for AI/ML features
- **API Management** - Gateway to manage and secure your APIs
- **Key Vault** - Secure storage for passwords and API keys
- **Monitoring** - Logs and metrics to track application health

## Prerequisites

1. **Azure Account** - An active Azure subscription
2. **GitHub Account** - To run the automation workflows
3. **Azure Service Principal** - For GitHub to access Azure (see setup below)

**No local installation needed!** Everything runs in GitHub Actions.

---

## Quick Start (5 Steps)

### Step 1: Create Azure Service Principal

Go to [Azure Cloud Shell](https://shell.azure.com) (runs in your browser) and run:

```bash
# Create a Service Principal with Contributor access
az ad sp create-for-rbac \
  --name "github-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

**Save the output** - you'll need these values:
- `clientId` → ARM_CLIENT_ID
- `clientSecret` → ARM_CLIENT_SECRET
- `subscriptionId` → ARM_SUBSCRIPTION_ID
- `tenantId` → ARM_TENANT_ID

### Step 2: Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these 4 secrets:

| Secret Name | Value |
|-------------|-------|
| `ARM_CLIENT_ID` | clientId from Step 1 |
| `ARM_CLIENT_SECRET` | clientSecret from Step 1 |
| `ARM_SUBSCRIPTION_ID` | subscriptionId from Step 1 |
| `ARM_TENANT_ID` | tenantId from Step 1 |

### Step 3: Bootstrap State Storage

1. Go to your repo → **Actions** tab
2. Click **"Bootstrap Terraform State"** workflow
3. Click **"Run workflow"**
4. Fill in the inputs:
   - Environment: `dev`
   - Region: `eastus`
   - Org short: `tv` (or your organization)
   - Project: `agentic` (or your project name)
5. Click **"Run workflow"**

This creates the storage account that tracks your infrastructure state.

### Step 4: Deploy Infrastructure

1. Go to **Actions** → **"Terraform"** workflow
2. Click **"Run workflow"**
3. Select:
   - Environment: `dev`
   - Stack: `all` (deploys everything in order)
   - Action: `apply`
4. Click **"Run workflow"**

Wait ~15-20 minutes for all resources to be created.

### Step 5: Deploy Your Application

After infrastructure is ready, use the **"Docker Build & Push"** workflow (or your own CI) to deploy your application containers.

---

## How It Works

### Deployment Flow

```
GitHub Actions
     │
     ├── 1. Bootstrap (one-time)
     │      └── Creates storage for Terraform state
     │
     ├── 2. Terraform Workflow
     │      └── Creates all Azure resources
     │
     └── 3. Application Deployment
            └── Pushes Docker images to Container Registry
```

### What Gets Created (in order)

```
1. foundation   → Resource group and naming conventions
2. network      → Virtual network and subnets
3. security     → Key Vault for secrets
4. registry     → Container registry for Docker images
5. monitor      → Logging and monitoring
6. data         → PostgreSQL database and storage
7. compute-aca  → Container Apps (runs your application)
8. qdrant       → Vector database for AI features
9. apim         → API Management gateway
```

Each stack depends on the previous ones, so they deploy in order.

---

## Folder Structure

```
pos_terraform_az/
├── .github/
│   └── workflows/
│       ├── bootstrap.yml    # Creates state storage (run once)
│       └── terraform.yml    # Main deployment workflow
├── modules/                 # Reusable building blocks
├── stacks/                  # Deployable infrastructure units
├── envs/
│   ├── dev/                 # Dev environment config
│   └── prod/                # Production config
└── scripts/                 # Optional local scripts
```

---

## Configuration

### Environment Settings

Edit `envs/dev/terraform.tfvars` to customize:

```hcl
org_short   = "tv"          # Your organization abbreviation
project     = "agentic"     # Project name
environment = "dev"         # Environment name
region      = "eastus"      # Azure region

# Database
postgresql_sku = "B_Standard_B1ms"   # Small for dev

# Container Apps
container_apps = [
  {
    name         = "fastapi-backend"
    cpu          = 0.5
    memory       = "1Gi"
    min_replicas = 0        # Scale to zero when idle
    max_replicas = 2
    target_port  = 8000
  }
]
```

### Resource Naming

All resources are automatically named using this pattern:

```
{org}-{project}-{env}-{region}-{resource-type}-{sequence}

Example: tv-agentic-dev-eus-psql-001
```

---

## Dev vs Production

| What | Dev (cheaper) | Prod (scalable) |
|------|---------------|-----------------|
| Database | Small, no backup | Large, high availability |
| Containers | Scales 0-2 | Scales 2-10 |
| Qdrant | Single container | Kubernetes cluster |
| Compute | Container Apps | AKS (Kubernetes) |
| Estimated Cost | ~$5-20/day | ~$60-250/day |

To deploy production, run the Terraform workflow with `environment: prod`.

---

## Manual Deployment (Optional)

If you prefer to run Terraform locally instead of GitHub Actions:

### Prerequisites for Local Development

1. Install [Terraform](https://www.terraform.io/downloads) (v1.6.0+)
2. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Local Commands

```powershell
# Login to Azure
az login

# Bootstrap state storage (one-time)
.\scripts\bootstrap.ps1 -Environment dev -Region eastus

# Deploy a stack
cd stacks\foundation
terraform init -backend-config=..\..\envs\dev\backend.hcl -backend-config="key=foundation.tfstate"
terraform apply -var-file=..\..\envs\dev\terraform.tfvars
```

---

## Setting Secrets

For API keys (OpenAI, etc.), add them as GitHub Secrets:

| Secret Name | Description |
|-------------|-------------|
| `TF_VAR_azure_openai_api_key` | Azure OpenAI API key |
| `TF_VAR_perplexity_api_key` | Perplexity API key |

These get stored in Key Vault during deployment.

---

## Cleaning Up

To delete all resources and stop charges:

1. Go to **Actions** → **"Terraform"** workflow
2. Click **"Run workflow"**
3. Select:
   - Environment: `dev`
   - Stack: `all`
   - Action: `destroy`
4. Click **"Run workflow"**

Or delete the resource group directly in Azure Portal.

---

## Troubleshooting

### "Backend configuration required"

Run the Bootstrap workflow first to create state storage.

### "Permission denied"

Check that your Service Principal has Contributor access to the subscription.

### "Resource already exists"

Either:
- Import it: `terraform import <resource> <id>`
- Or delete it from Azure Portal and re-run

---

## Need Help?

- **Terraform Docs**: https://www.terraform.io/docs
- **Azure Docs**: https://docs.microsoft.com/en-us/azure
- **AzureRM Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
