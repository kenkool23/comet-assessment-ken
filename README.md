# EKS Infrastructure & Helm Deployment Project for Comet takehome

A simple, automated infrastructure project that deploys an EKS cluster on AWS and manages application deployments using Helm charts with GitHub Actions.

## Project Structure

```
├── .github/workflows/
│   ├── terraform.yml      # Infrastructure deployment
│   └── deploy-chart.yml   # Helm chart deployment
├── infra/
│   ├── main.tf           # EKS cluster configuration
│   ├── variables.tf      # Terraform variables
│   ├── outputs.tf        # Terraform outputs
│   └── versions.tf       # Provider requirements
├── helm/
│   ├── templates/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── Chart.yaml        # Helm chart metadata
│   ├── values.yaml       # Default values
│   └── .helmignore
└── README.md
```

## What This Project Does

**Infrastructure Layer (Terraform)**
- Creates an EKS cluster in your AWS default VPC
- Sets up managed node groups with auto-scaling
- Configures necessary IAM roles and security groups
- Installs essential cluster addons (CoreDNS, VPC CNI, kube-proxy)

**Application Layer (Helm)**
- Deploys a simple Nginx application
- Creates Kubernetes deployments and services
- Manages application configuration through Helm values

**Automation Layer (GitHub Actions)**
- Automatically deploys infrastructure changes
- Deploys application updates when Helm charts change
- Uses secure OIDC authentication with AWS

## Quick Start

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** with this code
3. **AWS CLI** configured locally (for initial setup)

### 1. Configure GitHub Secrets

Add these secrets to your GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

```
AWS_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=simple-eks-cluster
HELM_RELEASE_NAME=my-nginx
HELM_NAMESPACE=default
```

### 2. Set Up AWS OIDC Authentication

Create an IAM role that GitHub Actions can assume:

```bash
# Create trust policy for GitHub OIDC
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role --role-name GitHubActionsRole --assume-role-policy-document file://trust-policy.json

# Attach necessary policies
aws iam attach-role-policy --role-name GitHubActionsRole --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### 3. Deploy Infrastructure

Push changes to the `infra/` directory to trigger the Terraform workflow:

```bash
git add infra/
git commit -m "Add EKS infrastructure"
git push origin main
```

### 4. Deploy Application

Push changes to the `helm/` directory to trigger the Helm deployment:

```bash
git add helm/
git commit -m "Add Nginx helm chart"
git push origin main
```

## Configuration

### Infrastructure Configuration

Modify `infra/variables.tf` to customize:

- **Cluster Name**: Change `cluster_name` default value
- **AWS Region**: Change `aws_region` default value  
- **Kubernetes Version**: Change `cluster_version` default value
- **Instance Types**: Modify in `infra/main.tf` under `eks_managed_node_groups`

### Application Configuration

Modify `helm/values.yaml` to customize:

- **Image**: Change `image.repository` and `image.tag`
- **Replicas**: Change `replicaCount`
- **Service Type**: Change `service.type` (ClusterIP, NodePort, LoadBalancer)

## Workflow Automation

### Terraform Workflow
- **Triggers**: Changes to `infra/` directory
- **Actions**: `terraform fmt`, `terraform plan`, `terraform apply`
- **Security**: Runs only on main branch for apply operations

### Helm Deployment Workflow  
- **Triggers**: Changes to `helm/` directory
- **Actions**: Helm lint, template validation, deployment
- **Verification**: Checks pod and service status after deployment

##  Local Development

### Test Terraform Locally
```bash
cd infra
terraform init
terraform plan
terraform apply
```

### Test Helm Chart Locally
```bash
cd helm
helm lint .
helm template my-nginx . --namespace default
helm install my-nginx . --namespace default --create-namespace
```

### Connect to EKS Cluster
```bash
aws eks update-kubeconfig --region us-east-1 --name simple-eks-cluster
kubectl get nodes
kubectl get pods -A
```

## Monitoring & Troubleshooting

### Check GitHub Actions
- Go to `Actions` tab in your GitHub repository
- Monitor workflow runs for both Terraform and Helm deployments

### Check EKS Cluster
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -n default
kubectl describe deployment my-nginx
```

### Common Issues
- **OIDC Authentication**: Ensure trust policy matches your repo exactly
- **AWS Permissions**: Role needs sufficient permissions for EKS operations
- **Cluster Access**: May take 10-15 minutes for new cluster to be fully ready

## Cleanup

To destroy all resources:

```bash
# Remove Helm deployment
helm uninstall my-nginx -n default

# Destroy infrastructure
cd infra
terraform destroy
```
