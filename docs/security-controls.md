# Security controls

| ID | Control | Implementation | Status |
|---|---|---|---|
| SEC-001 | Authenticated service invocation | No public Cloud Run invoker binding | Scaffolded |
| SEC-002 | Dedicated runtime identity | Service account without broad project roles | Scaffolded |
| SEC-003 | Non-root application | Docker UID 10001 | Scaffolded |
| SEC-004 | Infrastructure validation | Terraform fmt and validate in CI | Scaffolded |
| SEC-005 | Keyless CI deployment | GitHub OIDC federation | Planned |

Learning environment only. Validate effective IAM policies, ingress settings, image provenance and logging before production use.
