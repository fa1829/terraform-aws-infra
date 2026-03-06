# terraform-aws-infra

> Provision a complete AWS environment — VPC, EC2, and S3 — in a single command. Destroy and recreate it identically, proving 100% reproducible Infrastructure as Code.

![Terraform](https://img.shields.io/badge/Terraform-v1.14-7B42BC?style=flat-square&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Free%20Tier-FF9900?style=flat-square&logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## What This Provisions
```
terraform apply
        │
        ▼
┌─────────────────────────────────────────┐
│  AWS Infrastructure                     │
│                                         │
│  VPC (10.0.0.0/16)                      │
│  ├── Public Subnet (10.0.1.0/24)        │
│  ├── Internet Gateway                   │
│  └── Route Table                        │
│                                         │
│  EC2 t2.micro                           │
│  ├── Amazon Linux 2023                  │
│  ├── Docker pre-installed               │
│  ├── Security Group (SSH/HTTP/HTTPS)    │
│  └── SSH Key Pair (auto-generated)      │
│                                         │
│  S3 Bucket                              │
│  ├── Versioning enabled                 │
│  ├── AES256 encryption                  │
│  └── Public access blocked             │
└─────────────────────────────────────────┘
```

**14 resources. One command. Fully reproducible.**

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.0 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | >= 2.0 | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| AWS Account | Free tier | [aws.amazon.com](https://aws.amazon.com/free/) |

Configure AWS credentials:
```bash
aws configure
# AWS Access Key ID:     AKIA...
# AWS Secret Access Key: xxxxxxxx
# Default region:        us-east-1
# Output format:         json
```

Verify connection:
```bash
aws sts get-caller-identity
```

---

## Quick Start
```bash
git clone https://github.com/fa1829/terraform-aws-infra.git
cd terraform-aws-infra

terraform init      # download providers
terraform plan      # preview changes (nothing created yet)
terraform apply     # create all 14 resources (~60 seconds)
```

After apply you'll see:
```
Outputs:
ec2_public_ip  = "54.x.x.x"
s3_bucket_name = "devops-demo-dev-148761656757"
ssh_command    = "ssh -i devops-demo-key.pem ec2-user@54.x.x.x"
vpc_id         = "vpc-xxxxxxxxx"
```

SSH into your server:
```bash
ssh -i devops-demo-key.pem ec2-user@$(terraform output -raw ec2_public_ip)
```

---

## Project Structure
```
terraform-aws-infra/
├── main.tf              ← root module — wires VPC, EC2, S3 together
├── variables.tf         ← all input variables with descriptions
├── outputs.tf           ← what prints after terraform apply
├── versions.tf          ← provider versions pinned
├── terraform.tfvars     ← your actual values (gitignored)
└── modules/
    ├── vpc/             ← VPC, subnet, IGW, route table
    ├── ec2/             ← instance, security group, SSH key
    └── s3/              ← bucket, versioning, encryption
```

---

## Configuration

All settings live in `terraform.tfvars`. Change any value before running `terraform apply`.

### Change the AWS region
```hcl
# terraform.tfvars
aws_region = "us-west-2"   # default: us-east-1
```

Available regions: `us-east-1`, `us-west-2`, `eu-west-1`, `ap-southeast-1`

### Change the EC2 instance type
```hcl
# terraform.tfvars
ec2_instance_type = "t3.small"   # default: t2.micro (free tier)
```

Common options:

| Type | vCPU | RAM | Free Tier | Use Case |
|------|------|-----|-----------|----------|
| t2.micro | 1 | 1GB | ✅ Yes | Dev/learning |
| t3.small | 2 | 2GB | ❌ No | Light workloads |
| t3.medium | 2 | 4GB | ❌ No | Medium workloads |
| t3.large | 2 | 8GB | ❌ No | Production |

> ⚠️ Only `t2.micro` is free tier. Any other type will incur charges.

### Change the project name
```hcl
# terraform.tfvars
project_name = "my-project"   # default: devops-demo
```

All AWS resources are tagged and named using this prefix automatically.

### Change the environment
```hcl
# terraform.tfvars
environment = "staging"   # default: dev
```

### Restrict SSH access to your IP only
```hcl
# terraform.tfvars
my_ip = "203.x.x.x/32"   # replace with your actual IP
```

Find your IP:
```bash
curl -s ifconfig.me
```

---

## What Each Resource Does

### VPC (Virtual Private Cloud)
Your isolated private network inside AWS. Nothing outside can access resources inside unless you explicitly allow it. Think of it as your own data centre section — you define the IP ranges, subnets, and traffic rules.

### Public Subnet
A subdivision of the VPC where resources receive public IP addresses. EC2 instances in a public subnet are reachable from the internet (subject to security group rules).

### Internet Gateway
The door between your VPC and the internet. Without it, nothing inside the VPC can reach out or be reached from outside — even with a public IP.

### Route Table
Traffic rules for the subnet. Our public route table says: all internet-bound traffic (`0.0.0.0/0`) goes through the Internet Gateway.

### Security Group
A stateful firewall attached to the EC2 instance. Inbound rules allow SSH (port 22), HTTP (port 80), and HTTPS (port 443). Outbound allows everything. Only explicitly allowed traffic passes.

### EC2 Instance (t2.micro)
A virtual server running Amazon Linux 2023. On first boot, a `user_data` script automatically installs Docker and starts the service — ready to run containers immediately.

### SSH Key Pair
Terraform generates a 4096-bit RSA key pair. The public key is uploaded to AWS. The private key is saved locally as `devops-demo-key.pem` (gitignored). Used to SSH into the EC2 instance.

### S3 Bucket
Object storage — like a hard drive in the cloud. Configured with:
- **Versioning** — every file change is preserved, enabling rollback to any previous version
- **AES256 encryption** — all files encrypted at rest automatically
- **Public access blocked** — no accidental public exposure of data

---

## How This Automation Helps Organizations

### Before IaC (manual console setup)
```
Engineer clicks through AWS console
        ↓
No record of what was configured
        ↓
Second engineer can't replicate it
        ↓
Staging ≠ Production (subtle differences)
        ↓
"Works in staging, broken in prod"
        ↓
Nobody knows what to fix
```

### After IaC (this project)
```
git clone → terraform apply
        ↓
Identical environment every time
        ↓
Staging = Production = DR environment
        ↓
Every change tracked in Git with author + reason
        ↓
Disaster recovery = terraform apply in new region
        ↓
New team member onboards in 5 minutes
```

### Concrete benefits

| Benefit | Impact |
|---------|--------|
| Reproducibility | Identical environments every time — no snowflakes |
| Version control | Every infra change has a commit, author, and message |
| Peer review | Infrastructure changes go through pull requests |
| Disaster recovery | Redeploy in a new region in under 5 minutes |
| Cost control | `terraform destroy` tears everything down instantly |
| Onboarding | New engineer runs 3 commands and has a working environment |
| Auditability | Full history of who changed what and when |

---

## Common Operations

### See what will change before applying
```bash
terraform plan
```

### Apply only a specific module
```bash
terraform apply -target=module.ec2
terraform apply -target=module.s3
```

### See all current outputs
```bash
terraform output
```

### Get a single output value
```bash
terraform output -raw ec2_public_ip
terraform output -raw ssh_command
```

### See what's currently deployed
```bash
terraform show
```

### Destroy everything (always do this when done)
```bash
terraform destroy
```

### Destroy only a specific resource
```bash
terraform destroy -target=module.ec2.aws_instance.main
```

---

## Adding a New Resource

To add a new resource, follow the module pattern:

1. Create `modules/rds/main.tf`, `variables.tf`, `outputs.tf`
2. Define the resource in `main.tf`
3. Add variables to `variables.tf`
4. Expose outputs in `outputs.tf`
5. Wire it into the root `main.tf`
6. Run `terraform plan` to preview
7. Run `terraform apply` to create

---

## Security Notes

- **Never commit** `terraform.tfvars`, `*.tfstate`, or `*.pem` files — all gitignored
- **SSH access** — change `my_ip` in `terraform.tfvars` to your IP (`x.x.x.x/32`) for production use
- **Root account** — create an IAM user with least-privilege permissions for team use
- **State file** — for team use, configure an S3 remote backend with DynamoDB locking
- **Secrets** — never hardcode AWS keys; use IAM roles or environment variables

---

## Free Tier Warning

This project is designed to stay within AWS Free Tier:

- EC2 t2.micro: **750 hrs/month free** for 12 months
- S3: **5GB storage free**, 20K GET requests, 2K PUT requests
- VPC/IGW/Security Groups: **always free**

> ⚠️ Always run `terraform destroy` when done. EC2 charges by the hour.
> Check your usage at: AWS Console → Billing → Free Tier

---

## License

MIT
