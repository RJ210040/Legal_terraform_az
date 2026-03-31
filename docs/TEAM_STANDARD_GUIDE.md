# Team Infrastructure Standard Guide
## Azure AI Platform — Deployment Playbook

> **Purpose:** This is the single source of truth for provisioning a new AI project on Azure. Follow the 5-step process in order. No architectural decisions required — the codebase is already production-ready.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Component Reference](#2-component-reference)
3. [The 5-Step Process for Every New Project](#3-the-5-step-process-for-every-new-project)
4. [The Control Sheet — Complete Reference](#4-the-control-sheet--complete-reference)
5. [AI Gateway (APIM)](#5-ai-gateway-apim)
6. [Private Network vs Local Access](#6-private-network-vs-local-access)
7. [Local Development Setup](#7-local-development-setup)
8. [Optional Components](#8-optional-components)
9. [Dev vs Production Standards](#9-dev-vs-production-standards)
10. [Naming Convention](#10-naming-convention)
11. [Team Conventions & Rules](#11-team-conventions--rules)
12. [Cost Reference](#12-cost-reference)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Architecture Overview

Every project deploys the same architecture. Optional components are shown as `[optional]`.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          Azure Virtual Network                               │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐     │
│  │               Application Layer (Container Apps)                    │     │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │     │
│  │   │  FastAPI     │  │  React /     │  │  Any other container     │ │     │
│  │   │  Backend     │  │  Frontend    │  │  (worker, scheduler)     │ │     │
│  │   └──────┬───────┘  └──────────────┘  └──────────────────────────┘ │     │
│  └──────────┼───────────────────────────────────────────────────────────┘    │
│             │ IP allowlist (allowed_source_ips) controls who reaches apps    │
│  ┌──────────▼──────────────────────────────────────────────────────────┐     │
│  │                  AI Gateway — Azure APIM                            │     │
│  │   Single endpoint · API keys in Key Vault · Rate limiting           │     │
│  │  ┌────────────────┐  ┌───────────────┐  ┌───────────────────────┐  │     │
│  │  │  Azure OpenAI  │  │  OpenAI API   │  │  Claude (Anthropic)   │  │     │
│  │  └────────────────┘  └───────────────┘  └───────────────────────┘  │     │
│  └─────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                          Data Layer                                  │    │
│  │  ┌────────────────┐  ┌──────────────────┐  ┌─────────────────────┐ │    │
│  │  │  PostgreSQL    │  │  Qdrant (ACA)    │  │  Neo4j (ACA) ······ │ │    │
│  │  │  Flexible Srv  │  │  Vector DB       │  │  Graph DB [optional] │ │    │
│  │  └────────────────┘  └──────────────────┘  └─────────────────────┘ │    │
│  │  ┌────────────────┐  ┌──────────────────┐                           │    │
│  │  │  Blob Storage  │  │  Service Bus     │                           │    │
│  │  │  (files/docs)  │  │  (async queues)  │                           │    │
│  │  └────────────────┘  └──────────────────┘                           │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                    Security & Operations                             │    │
│  │  ┌────────────┐  ┌─────────────────┐  ┌──────────────────────────┐ │    │
│  │  │  Key Vault │  │  ACR (images)   │  │  Log Analytics +         │ │    │
│  │  │  (secrets) │  │                 │  │  App Insights            │ │    │
│  │  └────────────┘  └─────────────────┘  └──────────────────────────┘ │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Stack deployment order** (each reads state from the previous ones):
```
foundation → network → security → registry → monitor → data → compute-aca → qdrant → apim
```

---

## 2. Component Reference

| Component | Azure Service | Purpose | Feature flag |
|---|---|---|---|
| Resource Group + Naming | Azure Resource Group | Shared container; CAF-compliant naming | Always on |
| Virtual Network | Azure VNet | Network isolation for all components | Always on |
| Key Vault | Azure Key Vault | All secrets: DB passwords, API keys | Always on |
| Managed Identity | User-Assigned Identity | Passwordless auth for containers | Always on |
| Container Registry | Azure ACR | Private Docker image registry | Always on |
| Monitoring | Log Analytics + App Insights | Logs, metrics, traces | Always on |
| **PostgreSQL** | Azure PostgreSQL Flex | Structured/relational data | `enable_postgres` |
| **Blob Storage** | Azure Storage Account | File storage, Azure Files for Qdrant/Neo4j | `enable_storage` |
| **Service Bus** | Azure Service Bus | Async message queues | `enable_service_bus` |
| Container Apps | Azure Container Apps | Runs backend, frontend, Qdrant, Neo4j | Always on |
| **Qdrant** | Qdrant on ACA/AKS | Vector database for RAG/embeddings | `enable_qdrant` |
| **Neo4j** | Neo4j on ACA | Graph database (entity relationships) | `enable_neo4j` |
| **APIM** | Azure API Management | AI provider gateway | `enable_apim` |
| AKS *(prod only)* | Azure Kubernetes Service | Production compute for Qdrant | `enable_qdrant` + prod env |

---

## 3. The 5-Step Process for Every New Project

### Step 1: Create the Repository

This repo is a **GitHub Template Repository**. Do not clone it directly.

1. Go to the template repo on GitHub
2. Click **"Use this template"** → **"Create a new repository"**
3. Name it `{project-name}_terraform_az` (e.g., `billing_terraform_az`)
4. Set to **Private**
5. Click **"Create repository"**

---

### Step 2: Update the Control Sheet (2 lines)

Open `envs/dev/terraform.tfvars`. Change lines 1–2:

```hcl
org_short   = "tv"        # Always "tv"
project     = "billing"   # ← Your project name, lowercase, no spaces
```

Open `envs/prod/terraform.tfvars`. Change the same two lines identically.

That's it. Every resource name, state backend name, and configuration key derives from these two values automatically. You do not touch `backend.hcl` — it is generated for you.

**Also review the Feature Flags section** in the control sheet and set which components you need.

---

### Step 3: Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions**.

#### Azure credentials (required for all deployments):

| Secret | How to get it |
|---|---|
| `ARM_CLIENT_ID` | From Service Principal creation (see below) |
| `ARM_CLIENT_SECRET` | From Service Principal creation |
| `ARM_SUBSCRIPTION_ID` | Azure Portal → Subscriptions |
| `ARM_TENANT_ID` | Azure Portal → Azure Active Directory |

**Creating the Service Principal** (one-time, reuse across all projects):
```bash
az ad sp create-for-rbac \
  --name "github-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

#### AI provider keys (add only what you use):

| Secret | When required |
|---|---|
| `TF_VAR_azure_openai_api_key` | Azure OpenAI |
| `TF_VAR_openai_api_key` | Direct OpenAI API |
| `TF_VAR_anthropic_api_key` | Claude (Anthropic) |

Keys are stored in Key Vault during deployment. Apps never hold keys directly.

---

### Step 4: Bootstrap + Deploy Infrastructure

#### 4a. Bootstrap (creates Terraform state storage — once per environment)

1. GitHub repo → **Actions** → **"Bootstrap Terraform State"**
2. Click **"Run workflow"**
3. Fill in: Environment=`dev`, Region=`eastus2`, Org short=`tv`, Project=`billing`
4. Click **"Run workflow"**

Repeat with `prod` when you're ready for production. The bootstrap creates the Azure Storage Account that holds Terraform state. It auto-writes the values needed for CI/CD — you do not need to update `backend.hcl` manually.

#### 4b. Deploy everything

1. GitHub repo → **Actions** → **"Terraform"**
2. Click **"Run workflow"**
3. Fill in: Environment=`dev`, Stack=`all`, Action=`apply`
4. Click **"Run workflow"**

**Runtime: 15–30 minutes** (APIM takes ~10 min on first creation). Stacks run in this order:
```
foundation → network → security → registry → monitor → data → compute-aca → qdrant → apim
```

Stacks with their feature flag set to `false` in the control sheet complete in ~5 seconds with zero resources created. No manual stack selection needed.

---

### Step 5: Set Up Local Development & Deploy Application

#### 5a. Generate your local .env file

Run the `fetch-dev-env.ps1` script **from your application repository** (see the "Local App Development" section at the end of this guide for the full script). It reads all connection strings and endpoints from Key Vault and Container Apps and writes them to `.env.local`. This file is gitignored. Re-run it after infrastructure changes or secret rotations.

#### 5b. Push your application images

```bash
# ACR name is auto-derived from your project identity
az acr login --name tvbillingdeveus2acr001

docker tag your-backend:latest  tvbillingdeveus2acr001.azurecr.io/backend:latest
docker push tvbillingdeveus2acr001.azurecr.io/backend:latest
```

#### 5c. Update container apps with your images

In `envs/dev/terraform.tfvars`, update the `image` field in `container_apps`:
```hcl
{
  name  = "fastapi-backend"
  image = "tvbillingdeveus2acr001.azurecr.io/backend:latest"
  ...
}
```

Re-run the Terraform workflow: Stack=`compute-aca`, Action=`apply`.

---

## 4. The Control Sheet — Complete Reference

`envs/dev/terraform.tfvars` is your project control sheet. The same file feeds all 10 stacks — the GitHub Actions workflow passes it to every stack automatically.

### Section 1: Project Identity ← The only required change per project

```hcl
org_short   = "tv"       # Always "tv"
project     = "billing"  # ← Change this
environment = "dev"      # Do not change
region      = "eastus2"  # Change only for data residency requirements
```

### Section 2: Feature Flags ← Turn components on/off

```hcl
enable_postgres    = true   # PostgreSQL structured database
enable_storage     = true   # Blob + Azure Files (auto-enabled when enable_qdrant or enable_neo4j = true)
enable_service_bus = false  # Async queues — disable if no background processing
enable_qdrant      = true   # Vector database — container app + Azure Files share provisioned automatically
enable_neo4j       = false  # Graph database  — container app + Azure Files share provisioned automatically
enable_apim        = true   # AI gateway — required if using any AI model
```

**How it works:** Setting a flag to `false` means the stack for that component runs but creates zero resources. The deploy-all workflow runs all stacks regardless — no manual selection needed.

**Qdrant and Neo4j are fully automatic.** Setting `enable_qdrant = true` or `enable_neo4j = true` is the only action required — the infrastructure code automatically adds the Container App, Azure Files share, and persistent storage. You do not need to edit `container_apps`, `storage_file_shares`, or `azure_file_shares`.

### Section 3: Access Control ← Controls who can reach what

```hcl
# false (dev default): databases, Key Vault, Storage have public endpoints
#                      → you can connect from your laptop with az login
# true  (prod default): all backend resources are VNet-only
#                      → only containers inside the VNet can connect
enable_private_endpoints = false

# IP allowlist for the Container Apps themselves (the web application endpoints).
# Empty = allow all traffic (typical for dev and public-facing apps).
# Add IP CIDRs to restrict which machines/offices can reach the app over HTTPS.
# Note: this is independent of enable_private_endpoints.
allowed_source_ips = []
# Example: ["203.0.113.0/24", "198.51.100.42/32"]
```

### Section 4: Networking ← Rarely changed

```hcl
address_space = ["10.0.0.0/16"]  # Change only if this CIDR conflicts with your VPN
subnet_cidrs  = { ... }           # Usually unchanged
```

### Section 5: Databases, Storage, Messaging ← Rename to your domain

```hcl
databases         = ["app"]              # Your database name(s)
storage_containers = ["uploads", "exports"]  # Your blob container names
servicebus_queues  = ["task-queue"]      # Your queue names (only if enable_service_bus = true)
```

### Section 6: Container Apps ← Define only your application containers

```hcl
container_apps = [
  { name = "fastapi-backend", min_replicas = 0, max_replicas = 2, ... },
  { name = "react-frontend",  min_replicas = 0, max_replicas = 2, ... }
  # Do NOT add Qdrant or Neo4j here — they are managed by the feature flags
]
```

**Qdrant and Neo4j are not in this list.** Setting `enable_qdrant = true` or `enable_neo4j = true` in the Feature Flags section is the only action required. The infrastructure code automatically adds the correct Container App, Azure Files share, and persistent storage configuration. Nothing else changes.

**Why separate?** Stateless app containers (frontend, backend) can scale to zero when idle — no traffic, no cost. Database containers (Qdrant, Neo4j) must stay at `min_replicas = 1` because they need to be running to serve data requests. Neo4j takes 60–90 seconds to initialise — letting it cold-start on every query would make the app unusable.

### Section 7: AI Gateway ← Configure your AI providers

```hcl
publisher_email = "you@yourcompany.com"   # Update this

apis = [
  { name = "azure-openai", path = "ai/azure-openai", backend_url = "..." },
  { name = "openai-direct", path = "ai/openai",      backend_url = "https://api.openai.com/v1" },
  { name = "claude",         path = "ai/claude",      backend_url = "https://api.anthropic.com/v1" }
]
```

### What you NEVER change

| Setting | Value | Reason |
|---|---|---|
| `org_short` | `"tv"` | Org-level constant |
| `enable_private_endpoints` in dev | `false` | Team standard for dev access |
| `enable_private_endpoints` in prod | `true` | Security standard |
| Terraform version | `1.6.0` | Pinned for stability |
| Provider version | `~> 4.66` | Pinned for stability |

---

## 5. AI Gateway (APIM)

**Rule: All AI model calls go through APIM. Applications never call AI providers directly.**

### Why

- API keys live in Key Vault. APIM reads them — the app never sees a key.
- Switching providers (Azure OpenAI → Claude) is a one-line config change, not a code change.
- Centralized rate limiting prevents runaway costs.
- All AI calls are logged to App Insights for cost tracking.
- Single endpoint per environment: `https://tv-{project}-{env}-eus2-apim-001.azure-api.net`

### How the app calls it

```python
import os, httpx

APIM_BASE = os.environ["APIM_ENDPOINT"]          # from .env.local or Key Vault reference
APIM_KEY  = os.environ["APIM_SUBSCRIPTION_KEY"]  # from .env.local or Key Vault reference

# Call Azure OpenAI via APIM
async def chat(prompt: str) -> str:
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{APIM_BASE}/ai/azure-openai/chat/completions",
            headers={"Ocp-Apim-Subscription-Key": APIM_KEY},
            json={"model": "gpt-4o", "messages": [{"role": "user", "content": prompt}]}
        )
        return r.json()["choices"][0]["message"]["content"]

# Switch to Claude — just change the path, same key, same base URL
async def chat_claude(prompt: str) -> str:
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{APIM_BASE}/ai/claude/messages",
            headers={"Ocp-Apim-Subscription-Key": APIM_KEY},
            json={"model": "claude-3-5-sonnet-20241022", "max_tokens": 1024,
                  "messages": [{"role": "user", "content": prompt}]}
        )
        return r.json()["content"][0]["text"]
```

### Adding a new AI provider

Add one entry to `apis` in `terraform.tfvars` and one entry to `api_product_links`:
```hcl
# Example: add Mistral
{ name = "mistral", display_name = "Mistral AI", path = "ai/mistral", backend_url = "https://api.mistral.ai/v1" }
```

Add the API key to GitHub Secrets as `TF_VAR_mistral_api_key`, then add it to the security stack to store in Key Vault. Re-run the `apim` stack.

---

## 6. Private Network vs Local Access

The `enable_private_endpoints` flag controls network isolation of **backend resources** (Postgres, Key Vault, Storage, Service Bus).

| Setting | Backend resources | Container Apps (your app) | Your laptop |
|---|---|---|---|
| `false` (dev default) | Public endpoints — accessible from anywhere | Public HTTPS endpoint | Can connect to Postgres, Key Vault, Storage directly |
| `true` (prod default) | VNet-only — no public endpoint | Still has public HTTPS endpoint | Cannot connect to Postgres etc. directly — only containers inside VNet can |

**Key insight:** `enable_private_endpoints` does NOT affect whether users can reach your web application. Container Apps always have a public HTTPS ingress regardless of this setting. The private endpoint setting only affects the databases and infrastructure behind the app.

### The IP allowlist (separate concern)

`allowed_source_ips` controls who can reach the **Container Apps themselves** over HTTPS:

```hcl
# Allow all traffic (typical for public-facing or dev environments)
allowed_source_ips = []

# Restrict to office IP only (useful for internal tools)
allowed_source_ips = ["YOUR_OFFICE_IP/32"]

# Allow multiple offices/team members
allowed_source_ips = ["203.0.113.0/24", "198.51.100.42/32"]
```

### Recommended configurations

| Scenario | `enable_private_endpoints` | `allowed_source_ips` |
|---|---|---|
| Dev — full local access | `false` | `[]` |
| Dev — slightly locked down | `false` | `["OFFICE_IP/32"]` |
| Internal tool (prod) | `true` | `["OFFICE_IP/32"]` |
| Public customer app (prod) | `true` | `[]` |

---

## 7. About backend.hcl and Local Terraform

**If you only use GitHub Actions (the standard workflow), you never need to touch `backend.hcl` or run Terraform locally.**

GitHub Actions computes the state storage names automatically from `org_short` and `project` in `terraform.tfvars`. The `backend.hcl` files exist in the repo but are not used by CI/CD.

The only people who would need `backend.hcl` are developers who want to run Terraform CLI commands locally (e.g., `terraform plan` from their terminal). For that use case, `backend.hcl` needs to contain the correct storage account names. If you ever need this, generate it by hand from the naming pattern:

```
resource_group_name  = "{org_short}-{project}-{env}-tfstate-rg"
storage_account_name = "{org_short}{project}{env}tfstate"
container_name       = "tfstate"
```

For the `legal` project dev environment this would be:
```
resource_group_name  = "tv-legal-dev-tfstate-rg"
storage_account_name = "tvlegaldevtfstate"
container_name       = "tfstate"
```

**Standard team workflow:** edit `terraform.tfvars` → push to GitHub → run the Terraform workflow in Actions. That's it.

---

## 8. Optional Components

### Neo4j Graph Database

Enable Neo4j with a single change in `terraform.tfvars`:

```hcl
enable_neo4j = true   # ← this is the only change required
```

The infrastructure code takes care of everything else automatically:
- Deploys a `neo4j:5` Container App in the existing ACA environment
- Creates an Azure Files share (`neo4j-data`) and mounts it at `/data` for persistence
- Data survives container restarts and redeployments (same persistence model as Qdrant)
- Neo4j stays at `min_replicas = 1` (never scales to zero — 60–90s startup makes cold-starts unacceptable)

**Connection strings from your application:**
```python
# Bolt protocol (for queries) — internal within the ACA environment
NEO4J_URI  = "bolt://neo4j:7687"
NEO4J_USER = "neo4j"
NEO4J_AUTH = "none"   # dev setting — no password

from neo4j import GraphDatabase
driver = GraphDatabase.driver(NEO4J_URI)
```

**Neo4j Browser (exploration UI):** accessible at the Container App's public HTTPS URL (port 7474). Get it from Azure Portal → Container Apps → neo4j → Application URL.

**Port behaviour:**
- Port 7474 (HTTP) — exposed externally via Container Apps ingress, for the browser UI
- Port 7687 (Bolt) — available internally within the ACA environment for your backend app

**When to use it:** Knowledge graphs, entity relationships, multi-hop traversals — use cases where the connections between data points matter as much as the data itself. Examples: user-document-entity relationship graphs, regulatory citation networks, supply chain graphs.

**Prod note:** Currently the neo4j Container App runs in dev the same way as Qdrant. For production-scale deployments, a dedicated AKS StatefulSet with a Premium persistent disk would be the right pattern — but for MVP/prototyping work, the Container App is sufficient.

---

## 9. Dev vs Production Standards

These settings are already configured correctly. Do not override them without a documented reason.

| Concern | Dev | Prod | Reason |
|---|---|---|---|
| Compute | Container Apps | AKS | ACA scales to zero (saves cost); AKS gives guaranteed uptime |
| Database size | `B_Standard_B1ms` | `GP_Standard_D4s_v3` | Dev is for testing, not load |
| Database HA | Off | Zone-Redundant | Downtime acceptable in dev |
| Storage replication | LRS | ZRS | Tolerate zone failure in prod |
| ACR SKU | Basic | Premium + geo-replication | VNet integration + replication needed in prod |
| Private endpoints | Off | On | Dev convenience vs prod security |
| Log retention | 30 days | 90 days | Compliance requirements |
| Qdrant | 1 replica (ACA) | 3 replicas HPA 3–6 (AKS) | Availability in prod |
| APIM SKU | Consumption (per-call, no fixed cost) | Developer_1 | Fixed SLA needed in prod |
| Container min_replicas | 0 (scale to zero) | 2 | Cost savings in dev |

---

## 10. Naming Convention

All resource names are auto-generated by the `naming` module. You never name resources manually.

### Pattern
```
{org_short}-{project}-{env}-{region_short}-{resource_type}-{sequence}
```

### Examples (project = "billing", env = "dev")

| Resource | Name |
|---|---|
| Resource Group | `tv-billing-dev-eus2-rg-001` |
| PostgreSQL | `tv-billing-dev-eus2-psql-001` |
| Key Vault | `tv-billing-dev-eus2-kv-001` |
| Container Apps Env | `tv-billing-dev-eus2-cae-001` |
| APIM | `tv-billing-dev-eus2-apim-001` |
| Log Analytics | `tv-billing-dev-eus2-law-001` |
| Storage Account | `tvbillingdeveus2sa001` *(no hyphens — Azure constraint)* |
| ACR | `tvbillingdeveus2acr001` *(no hyphens — Azure constraint)* |
| State RG | `tv-billing-dev-tfstate-rg` *(auto-derived by CI/CD)* |
| State SA | `tvbillingdevtfstate` *(auto-derived by CI/CD)* |

### Region short codes

| Region | Code |
|---|---|
| East US 2 | `eus2` |
| East US | `eus` |
| West US 2 | `wus2` |
| West Europe | `weu` |
| UK South | `uks` |

---

## 11. Team Conventions & Rules

### Git workflow

1. **Main branch is always deployable.** Do not commit broken Terraform.
2. **PRs to main trigger validation-only CI** — Terraform validate runs on all modules automatically.
3. **Manual deploy only** — all deployments require manual workflow dispatch. Nothing auto-deploys.
4. **Plan before apply.** Always run `Action: plan` first, review output, then re-run with `Action: apply`.

### Secrets management

1. **No secrets in code.** All keys and connection strings go in Key Vault.
2. **No secrets in GitHub env vars.** Only `ARM_*` credentials and `TF_VAR_*` API keys go in GitHub Secrets.
3. **Apps use Key Vault references.** Container Apps pull secrets at runtime via managed identity — no raw values in env vars.
4. **Local dev uses `.env.local`**, generated by `scripts/fetch-dev-env.ps1`. This file is gitignored.

### backend.hcl

`backend.hcl` is not used by GitHub Actions. CI/CD computes state storage names automatically from `terraform.tfvars`. You can ignore this file for the standard GitHub Actions workflow.

### Cost management

1. **Scale to zero in dev.** All Container Apps in dev have `min_replicas = 0`. Do not change this.
2. **Destroy dev when idle.** Run the Terraform workflow with `Action: destroy` to tear down and `Action: apply` to restore.
3. **APIM Consumption SKU in dev** has no fixed cost — you pay only per API call.

---

## 12. Cost Reference

### Dev environment (~$5–20/day depending on usage)

| Resource | Approximate cost |
|---|---|
| PostgreSQL B1ms | ~$0.50/day |
| Container Apps (scales to 0) | ~$0.10–0.40/day |
| Qdrant ACA (1 replica) | ~$0.10/day |
| Key Vault | Negligible |
| Storage LRS | Negligible |
| Log Analytics (30 days, 5 GB/day cap) | ~$0.10/day |
| ACR Basic | ~$0.17/day |
| APIM Consumption | $0 fixed + ~$3.50 per million calls |
| **Total dev** | **~$5–20/day** |

### Production environment (~$60–250/day)

| Resource | Approximate cost |
|---|---|
| PostgreSQL D4s_v3 HA | ~$18/day |
| AKS (system + user node pools) | ~$29/day |
| ACR Premium | ~$0.67/day |
| Storage ZRS | ~$0.25/day |
| APIM Developer_1 | ~$9.60/day |
| Log Analytics (90 days, unlimited) | ~$1/day |
| **Total prod** | **~$60–250/day** |

> Tear down dev when not actively in use — saves ~$5–20/day per project.

---

## 13. Local App Development — Connecting to Cloud Resources

This section is for **application developers** (in the app repo, not this infrastructure repo) who want to run the application locally on their laptop while connecting to the cloud-deployed databases and APIs.

### How it works

Your Entra ID must be in `developer_object_ids` in `terraform.tfvars`. The security stack grants that identity `Key Vault Secrets User` access automatically. Once deployed, you can read any secret with your own `az login` — no shared credentials or service accounts needed.

### PowerShell script: generate .env.local for your app

Add this script to your **application repo** as `scripts/fetch-dev-env.ps1`:

```powershell
# scripts/fetch-dev-env.ps1
# Reads connection strings from Key Vault and writes .env.local for local development.
# Run this once after infrastructure is deployed, and again after any secret rotation.
#
# Prerequisites:
#   - Azure CLI installed (az)
#   - Your Entra ID in developer_object_ids in the infra repo terraform.tfvars

param(
    [string]$OrgShort   = "tv",
    [string]$Project    = "legal",     # change to your project name
    [string]$Env        = "dev",
    [string]$Region     = "eastus2",
    [string]$OutputFile = ".env.local"
)

# Ensure logged in
$account = az account show -o json 2>$null | ConvertFrom-Json
if (-not $account) { az login | Out-Null; $account = az account show -o json | ConvertFrom-Json }

$regionMap = @{ "eastus2"="eus2"; "eastus"="eus"; "westus2"="wus2"; "westeurope"="weu"; "uksouth"="uks" }
$rs = $regionMap[$Region] ?? $Region.Replace("-","").Substring(0,4)

$kv = "${OrgShort}-${Project}-${Env}-${rs}-kv-001"
$rg = "${OrgShort}-${Project}-${Env}-rg-001"

function Get-Secret($name) {
    $v = az keyvault secret show --vault-name $kv --name $name --query "value" -o tsv 2>$null
    return ($LASTEXITCODE -eq 0) ? $v : $null
}
function Get-AppFqdn($name) {
    return az containerapp show --name $name --resource-group $rg `
        --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
}

$pgConn    = Get-Secret "postgresql-connection-string"
$sbConn    = Get-Secret "servicebus-connection-string"
$openaiKey = Get-Secret "azure-openai-api-key"
$claudeKey = Get-Secret "anthropic-api-key"
$qdrantUrl = (Get-AppFqdn "qdrant") ? "https://$(Get-AppFqdn 'qdrant')" : "http://localhost:6333"
$neo4jBolt = (Get-AppFqdn "neo4j")  ? "bolt://$(Get-AppFqdn 'neo4j'):7687"  : "bolt://localhost:7687"

@(
  "# Auto-generated — DO NOT commit. Re-run after infra changes.",
  "DATABASE_URL=$pgConn",
  "QDRANT_URL=$qdrantUrl",
  "NEO4J_URI=$neo4jBolt",
  "NEO4J_USER=neo4j",
  "SERVICEBUS_CONNECTION=$sbConn",
  "APIM_ENDPOINT=https://${OrgShort}-${Project}-${Env}-${rs}-apim-001.azure-api.net",
  "APIM_SUBSCRIPTION_KEY=  # get from Azure Portal → APIM → Subscriptions",
  "AZURE_OPENAI_API_KEY=$openaiKey",
  "ANTHROPIC_API_KEY=$claudeKey"
) | Set-Content $OutputFile

Write-Host "✅ Written to $OutputFile — add this file to .gitignore"
```

Add `.env.local` to your app repo's `.gitignore`. Your FastAPI/Python app reads these as standard environment variables:

```python
# In your app — reads from .env.local locally, from Key Vault references in Container Apps
import os
from dotenv import load_dotenv
load_dotenv(".env.local", override=False)  # no-op in Container Apps where env vars come from Key Vault

DATABASE_URL = os.environ["DATABASE_URL"]
QDRANT_URL   = os.environ["QDRANT_URL"]
NEO4J_URI    = os.environ["NEO4J_URI"]
APIM_ENDPOINT = os.environ["APIM_ENDPOINT"]
```

### Running databases locally (without cloud)

If the cloud environment isn't deployed yet, run the databases locally in Docker:

```bash
# Qdrant
docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant:v1.13.2

# Neo4j (no auth, dev-only)
docker run -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=none neo4j:5
```

Set `QDRANT_URL=http://localhost:6333` and `NEO4J_URI=bolt://localhost:7687` in `.env.local`.

## 14. Troubleshooting

### "Backend configuration required" or init fails
The state storage doesn't exist yet. Run the **Bootstrap** workflow first (Step 4a above).

### Stack fails because it can't read state from another stack
The dependency stack wasn't deployed yet. Deploy in order: `foundation → network → security → registry → monitor → data → compute-aca → qdrant → apim`.

### "Resource already exists" during apply
A resource with the generated name already exists (possibly from a prior deploy). Either import it:
```bash
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/tv-billing-dev-rg-001
```
Or delete it from Azure Portal, then re-run apply.

### APIM deployment takes 30–45 minutes
This is normal for first creation. The Developer and Consumption SKUs take up to 45 minutes to provision. Let it run.

### Container App shows placeholder image after deploy
Push your image to ACR first (Step 5b), then update `container_apps.image` in tfvars and re-run the `compute-aca` stack. The Container App was deployed with a placeholder image by design — it allows infrastructure to be ready before the app is built.

### fetch-dev-env.ps1 says "Secret not found"
The stack for that component wasn't deployed, or its feature flag is `false`. If the stack is deployed, check that your Entra ID object ID is in `developer_object_ids` in the control sheet.

### Qdrant container restarts but data is preserved
This is working as intended. Qdrant mounts an Azure Files share at `/qdrant/storage`. Data persists across restarts and redeployments. If data is missing, verify that `enable_qdrant = true` in the feature flags — the share and volume mount are managed automatically when the flag is set.

### PostgreSQL connection refused from laptop (prod)
Prod has `enable_private_endpoints = true` — Postgres is VNet-only. You cannot connect directly from a laptop. Options:
- Use Azure Cloud Shell (runs inside Azure, can reach VNet resources via private DNS)
- Add a Jump Box VM to the VNet (not in this template)
- Use the FastAPI backend as a proxy for data operations

---

## Appendix: Files Changed Per New Project

When you create a new project from this template, these are the **only** files you touch:

| File | What to change |
|---|---|
| `envs/dev/terraform.tfvars` | `project` value, feature flags, APIM email |
| `envs/prod/terraform.tfvars` | Same two things |

Everything else is template code that does not change. `backend.hcl` does not need to be touched for the GitHub Actions workflow.

---

*Last updated: 2026-03-31 | Maintainer: TV Engineering | Template repo: this repository*
