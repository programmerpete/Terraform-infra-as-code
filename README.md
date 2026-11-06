# Terraform Infrastructure as Code — Secure GCP Lab

Project 1: Learn Terraform, Google Cloud security, Docker, Python and GitHub Actions.

## Goals
- Provision a Cloud Run service using Terraform
- Use a dedicated least-privilege runtime identity
- Run a Python FastAPI health endpoint in a non-root container
- Validate infrastructure and application changes in GitHub Actions

## Prerequisites
Terraform >=1.6, Google Cloud CLI, Python 3.12, Docker, a personal GCP project with billing enabled and a budget alert.

## Run locally
```sh
pip install -r application/requirements.txt
PYTHONPATH=application pytest application/tests -q
uvicorn main:app --app-dir application --reload
```

## Terraform
Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`, replace the placeholder project ID, then run:
```sh
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```
Review costs and access before running `apply`. This initial configuration uses a public sample container image but **does not grant public invocation**. Deployment of our own app and GitHub OIDC are upcoming milestones.
