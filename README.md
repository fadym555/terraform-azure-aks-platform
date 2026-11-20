# terraform-azure-aks-platform

[![CI](https://github.com/fadym555/terraform-azure-aks-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/fadym555/terraform-azure-aks-platform/actions/workflows/ci.yml)

Modular Terraform for an Azure Kubernetes platform: networking, AKS, a container registry and monitoring, wired together per environment. It's the layout I use for client infrastructure: small focused modules, guard rails in the variables, and a pipeline that catches mistakes before anyone runs `apply`.

## Layout

```
modules/
  network/      VNet, subnets, one NSG per subnet (internet inbound denied)
  aks/          AKS cluster, system + user node pools, identities, ACR pull
  acr/          Container registry (no admin user, private on Premium)
  monitoring/   Log Analytics workspace for Container Insights
platform/       Composes the modules for one environment
  environments/ dev.tfvars, prod.tfvars
```

## Security and reliability defaults

- **No static credentials:** AKS local accounts disabled, Entra ID + Azure RBAC only, workload identity and OIDC issuer on
- **Locked-down API server:** `authorized_ip_ranges` is required, and `0.0.0.0/0` is rejected by validation
- **User-assigned identities** for the control plane and kubelet, so role assignments survive a cluster rebuild
- **Network policy** (Calico) on Azure CNI Overlay, NSG on every subnet
- **Separate system and user pools**, both autoscaling across 3 availability zones, surge upgrades
- **Automatic patch upgrades** for Kubernetes and node images
- **Container Insights** wired to Log Analytics, Azure Policy add-on on, Key Vault CSI driver with secret rotation

## What CI checks

| Job | What it does |
|---|---|
| Format & validate | `terraform fmt -check`, then `init` + `validate` for every module and the platform stack |
| TFLint | Recommended preset plus the azurerm ruleset (catches invalid VM sizes, SKUs, etc.), documented variables and outputs, naming |
| Trivy | Misconfiguration scan of all the Terraform, fails on any high or critical finding |
| terraform test | Plan-time test suites with a mocked provider: secure defaults hold, bad input is rejected (open API server, inverted autoscaling bounds, invalid CIDRs, bad names) |

No cloud credentials are needed for any of it, so it runs on every pull request.

## Deploy an environment

```bash
cd platform
terraform init -backend-config=environments/prod.backend.hcl
terraform plan -var-file=environments/prod.tfvars -out=prod.tfplan
terraform apply prod.tfplan
```

`prod.backend.hcl` holds the state storage account details and is kept out of git.
