# AWS Terraform and Ansible Web Server

## Project Overview

This project demonstrates infrastructure provisioning and configuration management using **Terraform** and **Ansible** on AWS.

Terraform is used to provision the AWS infrastructure, including:

- EC2 instance
- S3 bucket
- IAM role and instance profile
- Security group

Ansible is then used to connect to the EC2 instance, install and configure **Nginx**, and deploy a simple web page displaying **Hello, World!**

The project infrastructure is deployed in the AWS **us-east-2** region.

---

## Architecture

```text
Local Mac
   |
   |-- Terraform
   |      |
   |      +-- AWS EC2 Instance
   |      +-- S3 Bucket
   |      +-- IAM Role
   |      +-- IAM Instance Profile
   |      +-- Security Group
   |
   |-- Ansible
          |
          +-- SSH to EC2
                 |
                 +-- Install Nginx
                 +-- Start and enable Nginx
                 +-- Deploy index.html
                        |
                        +-- Hello, World!
```

Terraform handles the infrastructure provisioning, while Ansible handles the operating system and web server configuration.

---

## Technologies Used

- AWS
- Terraform
- Ansible
- Amazon EC2
- Amazon S3
- AWS IAM
- AWS Security Groups
- Nginx
- Ubuntu Linux
- AWS CLI
- Git
- GitHub

---

## Project Structure

```text
aws-terraform-ansible-webserver/
|
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── security.tf
│   ├── iam.tf
│   ├── s3.tf
│   ├── ec2.tf
│   └── outputs.tf
|
├── ansible/
│   ├── inventory.ini
│   └── webserver.yml
|
├── screenshots/
│   ├── 01-terraform-init.png
│   ├── 02-terraform-validate.png
│   ├── 03-terraform-plan.png
│   ├── 04-terraform-apply.png
│   ├── 05-terraform-outputs.png
│   ├── 06-aws-ec2-running.png
│   ├── 07-aws-s3-bucket.png
│   ├── 08-aws-iam-role.png
│   ├── 09-security-group.png
│   ├── 10-ansible-ping.png
│   ├── 11-ansible-playbook-success.png
│   ├── 12-hello-world-website.png
│   └── 13-terraform-state.png
|
├── .gitignore
└── README.md
```

Sensitive and local Terraform files such as `terraform.tfvars`, Terraform state files, `.terraform/`, and private key files are excluded from Git using `.gitignore`.

---

# Prerequisites

The following tools are required:

- AWS account
- AWS CLI
- Terraform
- Ansible
- Git
- An existing EC2 SSH key pair

Verify AWS CLI access:

```bash
aws sts get-caller-identity
```

Verify the configured AWS region:

```bash
aws configure get region
```

For this project:

```text
us-east-2
```

Verify Terraform:

```bash
terraform --version
```

Verify Ansible:

```bash
ansible --version
```

---

# Terraform Infrastructure

## AWS Provider

Terraform uses the AWS provider with the region configured through a variable.

Example:

```hcl
provider "aws" {
  region = var.aws_region
}
```

The project uses:

```text
us-east-2
```

---

## Variables

The Terraform configuration defines variables for:

- AWS region
- EC2 instance type
- EC2 key pair

Example:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}
```

The EC2 key pair value is provided locally using `terraform.tfvars`.

The `terraform.tfvars` file is not committed to GitHub.

---

## EC2 Instance

Terraform provisions an Ubuntu EC2 instance.

The Ubuntu AMI is dynamically retrieved through AWS Systems Manager Parameter Store instead of hardcoding an AMI ID.

```hcl
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}
```

The EC2 instance uses:

```text
Instance Type: t3.micro
Region: us-east-2
Operating System: Ubuntu
```

---

## Security Group

Terraform creates a security group allowing:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |

Port `22` allows Ansible and SSH access to the EC2 instance.

Port `80` allows users to access the Nginx web server.

---

## IAM

Terraform creates:

```text
terraform-ansible-ec2-role
```

and an EC2 instance profile:

```text
terraform-ansible-ec2-profile
```

The instance profile attaches the IAM role to the EC2 instance.

---

## S3

Terraform provisions an Amazon S3 bucket using a generated bucket prefix:

```text
terraform-ansible-project-
```

Example deployed bucket:

```text
terraform-ansible-project-f56bf6503474feb227193cab63
```

---

# Deploying the Infrastructure

Change to the Terraform directory:

```bash
cd terraform
```

## Initialize Terraform

```bash
terraform init
```

Expected result:

```text
Terraform has been successfully initialized!
```

![Terraform Init](screenshots/01-terraform-init.png)

---

## Format Terraform

```bash
terraform fmt
```

---

## Validate Terraform

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

![Terraform Validate](screenshots/02-terraform-validate.png)

---

## Review the Terraform Plan

```bash
terraform plan
```

This displays the AWS resources Terraform will create before making any changes.

![Terraform Plan](screenshots/03-terraform-plan.png)

---

## Apply the Terraform Configuration

```bash
terraform apply
```

Enter:

```text
yes
```

when prompted.

Terraform provisions the AWS resources and displays the resulting outputs.

![Terraform Apply](screenshots/04-terraform-apply.png)

---

## Terraform Outputs

Run:

```bash
terraform output
```

Terraform returns information such as:

- EC2 public IP
- Web server URL
- S3 bucket name

![Terraform Outputs](screenshots/05-terraform-outputs.png)

---

# AWS Resource Verification

## EC2 Instance

The EC2 instance was successfully provisioned and entered the `Running` state.

Instance name:

```text
terraform-ansible-webserver
```

Instance type:

```text
t3.micro
```

Availability Zone:

```text
us-east-2a
```

![EC2 Running](screenshots/06-aws-ec2-running.png)

---

## S3 Bucket

Terraform successfully created the project S3 bucket.

![S3 Bucket](screenshots/07-aws-s3-bucket.png)

---

## IAM Role

Terraform created the IAM role used by the EC2 instance.

![IAM Role](screenshots/08-aws-iam-role.png)

---

## Security Group

The security group allows SSH and HTTP access required for Ansible administration and website access.

![Security Group](screenshots/09-security-group.png)

---

# Ansible Configuration

After Terraform creates the infrastructure, Ansible configures the EC2 instance.

The Ansible playbook performs the following tasks:

1. Connects to the EC2 instance using SSH.
2. Updates the Ubuntu package cache.
3. Installs Nginx.
4. Starts the Nginx service.
5. Enables Nginx to start automatically at boot.
6. Deploys a custom `index.html` file.

---

## Ansible Inventory

The EC2 instance is defined inside:

```text
ansible/inventory.ini
```

Example:

```ini
[webservers]
EC2_PUBLIC_DNS ansible_user=ubuntu ansible_ssh_private_key_file="/path/to/private-key.pem"
```

The private SSH key itself is not stored in the GitHub repository.

---

## Test Ansible Connectivity

Change to the Ansible directory:

```bash
cd ansible
```

Test communication with the EC2 instance:

```bash
ansible all -i inventory.ini -m ping
```

Successful output includes:

```text
SUCCESS
"ping": "pong"
```

![Ansible Ping](screenshots/10-ansible-ping.png)

---

# Ansible Playbook

The playbook is located at:

```text
ansible/webserver.yml
```

The playbook installs and configures Nginx and deploys the web page.

Run:

```bash
ansible-playbook -i inventory.ini webserver.yml
```

A successful deployment shows:

```text
unreachable=0
failed=0
```

![Ansible Playbook](screenshots/11-ansible-playbook-success.png)

---

# Web Application

After Ansible completes, the website can be accessed using the EC2 public IP address.

Current deployment:

```text
http://3.14.144.109
```

The page displays:

```text
Hello, World!

Deployed with Terraform and Ansible on AWS.
```

![Hello World Website](screenshots/12-hello-world-website.png)

> Note: The public IP may change if the EC2 instance is stopped or recreated unless an Elastic IP is assigned.

---

# Terraform State Verification

Terraform tracks the deployed AWS resources in its local state.

To display the managed resources:

```bash
terraform state list
```

The state includes resources such as:

```text
data.aws_ssm_parameter.ubuntu_ami
aws_iam_instance_profile.ec2_profile
aws_iam_role.ec2_role
aws_instance.web_server
aws_s3_bucket.project_bucket
aws_security_group.web_sg
```

![Terraform State](screenshots/13-terraform-state.png)

---

# Testing the Website

The web server can also be tested from the command line.

Using the public IP:

```bash
curl http://3.14.144.109
```

Or using the EC2 public DNS name:

```bash
curl http://EC2-PUBLIC-DNS
```

A successful response returns the HTML generated by the Ansible playbook.

---

# How Terraform and Ansible Work Together

Terraform and Ansible perform different roles in this project.

### Terraform

Terraform provisions the AWS infrastructure:

```text
Terraform
   |
   +-- EC2
   +-- S3
   +-- IAM
   +-- Security Group
```

Terraform answers the question:

> What infrastructure should exist?

### Ansible

Ansible configures the EC2 server after Terraform creates it:

```text
Ansible
   |
   +-- Connect to EC2
   +-- Install Nginx
   +-- Start Nginx
   +-- Deploy webpage
```

Ansible answers the question:

> How should the server be configured?

Together, they provide automated infrastructure provisioning and server configuration.

---

# Security Considerations

Sensitive files are excluded from the Git repository.

The `.gitignore` file prevents files such as the following from being committed:

```text
.terraform/
*.tfstate
*.tfstate.*
*.pem
terraform.tfvars
.DS_Store
```

Private SSH keys and Terraform state should never be committed to a public or private source control repository.

For a production environment, SSH access should also be restricted to trusted IP addresses instead of allowing unrestricted access to port `22`.

---

# Cleanup

After the project has been reviewed, the AWS infrastructure can be removed using Terraform.

Change to the Terraform directory:

```bash
cd terraform
```

Run:

```bash
terraform destroy
```

Review the destruction plan and enter:

```text
yes
```

Terraform will delete the AWS resources managed by this project.

---

# Results

This project successfully demonstrates:

- Infrastructure as Code using Terraform
- Automated AWS resource provisioning
- EC2 deployment
- S3 provisioning
- IAM configuration
- Security group configuration
- Configuration management using Ansible
- Automated Nginx installation
- Automated web page deployment
- SSH-based remote server management
- Git and GitHub version control

The final result is a working Nginx web server running on an AWS EC2 instance and displaying a **Hello, World!** web page.