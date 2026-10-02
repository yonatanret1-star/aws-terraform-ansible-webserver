resource "aws_s3_bucket" "project_bucket" {
  bucket_prefix = "terraform-ansible-project-"

  tags = {
    Name        = "Terraform Ansible Project"
    Environment = "Lab"
  }
}