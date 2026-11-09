# Secure GCP Infrastructure as Code Lab

A hands-on cloud security engineering portfolio project using **Terraform, Google Cloud Platform, Python FastAPI, Docker and GitHub Actions**. The goal is to provision a small authenticated API, verify that it works, and shift security checks into CI.

## Architecture

```text
Developer -> GitHub -> GitHub Actions
                         |-- Terraform format / init / validate
                         |-- Python unit tests
                         |-- Checkov Terraform policy scan
                         |
Terraform -> GCP APIs + service account + Artifact Registry + Cloud Run
                                         ^                    |
Docker build -> private Artifact Registry image --------------+
                                                              |
Authenticated caller -- identity token --> Cloud Run /health
Unauthenticated caller ------------------> 403 Forbidden
```

The API runs in **Cloud Run** in `australia-southeast1`. Its Docker image is stored in a **private Artifact Registry** repository. Terraform provisions the infrastructure; image build, push and deployment changes are currently performed manually. GitHub Actions validates changes but does **not** deploy automatically.

## Implemented

- **Infrastructure as Code:** Terraform configures required GCP APIs, a dedicated Cloud Run runtime service account, the Cloud Run service and a private Docker Artifact Registry repository.
- **Application:** FastAPI exposes `GET /health`, returning `{"status":"ok"}`.
- **Container:** Python 3.12-based Docker image runs as a non-root user on port 8080.
- **Access control:** Cloud Run has no `allUsers` invoker binding. An unauthenticated request was verified to return HTTP 403; an identity-token-authenticated request can invoke the API. Note that Cloud Run ingress is currently set to `INGRESS_TRAFFIC_ALL`: the endpoint is network-reachable but protected by IAM authentication.
- **CI:** GitHub Actions runs Terraform formatting/validation, Python tests and a Checkov scan on pushes and pull requests.
- **Policy exception:** Checkov `CKV_GCP_84` is explicitly skipped for the lab's Artifact Registry repository because it uses Google-managed encryption rather than customer-managed Cloud KMS keys. This is a documented risk decision, **not** a claim that CMEK is enabled. Other applicable Checkov findings are configured to fail the security job.

**Status:** The deployed FastAPI container has been tested locally and the authenticated Cloud Run `/health` endpoint has been verified. Trivy container scanning is the **next planned addition**; it is not yet part of the committed workflow.

## Repository layout

```text
application/                 FastAPI app, Dockerfile, tests, requirements
terraform/                   GCP infrastructure and outputs
.github/workflows/validate.yml
docs/security-controls.md    Security decisions and controls
pytest.ini                   Python test discovery
```

## Run tests locally

From the repository root:

```bash
python -m pip install -r application/requirements.txt
python -m pytest -q
uvicorn main:app --app-dir application --reload
# In another terminal:
curl http://127.0.0.1:8000/health
```

## Build and test the container

```bash
docker build -t secure-api:local ./application
docker run --rm -p 8080:8080 secure-api:local
# In another terminal:
curl http://127.0.0.1:8080/health
```

## Terraform workflow

Prerequisites: Terraform >= 1.6, Google Cloud CLI with appropriate permissions, a GCP project with billing enabled, and a budget alert. Cloud resources may incur charges.

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars for your project and region.
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan
# Review changes and costs before:
terraform -chdir=terraform apply
```

**Before reusing this project:** `terraform/main.tf` currently refers to a project-specific Artifact Registry image path. Change it to your own image URI and push that image before applying. Keep `terraform.tfvars`, Terraform state, credentials and secrets out of Git.

## Verify Cloud Run authentication

From an authenticated Google Cloud Shell session with Cloud Run invoker permission:

```bash
URL=$(terraform -chdir=terraform output -raw cloud_run_uri)
curl -i "$URL/health"  # Expected: HTTP 403 (without authentication)
TOKEN=$(gcloud auth print-identity-token --audiences="$URL")
curl -i -H "Authorization: Bearer $TOKEN" "$URL/health"
# Expected: HTTP 200 and {"status":"ok"}
```

Do not paste identity tokens into public logs or screenshots.

## Two-minute demo

1. **0:00–0:20 — Goal:** Show this README and explain the authenticated API and automated validation.
2. **0:20–0:50 — Infrastructure:** Open `terraform/main.tf`; highlight the runtime service account, Cloud Run service, Artifact Registry and absence of a public invoker binding.
3. **0:50–1:20 — Security checks:** Show a green GitHub Actions run and the Checkov job. Explain the explicit encryption policy exception.
4. **1:20–2:00 — Live proof:** Show an unauthenticated `/health` request returning 403, followed by an authenticated request returning 200 and `{"status":"ok"}`. Close with the next improvements.

## Next improvements

- Add **Trivy** container vulnerability scanning in GitHub Actions; review findings before enforcing a blocking threshold.
- Pin CI actions and container deployments to immutable commit SHAs/image digests.
- Use remote Terraform state with appropriate access controls.
- Add GitHub OIDC Workload Identity Federation for keyless deployment.
- Evaluate Cloud KMS customer-managed encryption keys and tighter Cloud Run ingress where appropriate.
- Improve policy coverage and security reporting.
