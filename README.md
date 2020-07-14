# hybrid-multi-cloud-training
 @LinuxWorldIndia
 Tasks completed during Summer Training @LinuxWorldIndia
 
# task-1
 AWS Infrastructure As Code Using Terraform
 
1. Create the key and security group which allow the port `80`.
1. Launch EC2 instance.
1. In this Ec2 instance use the key and security group which we have created in step 1.
1. Launch one Volume (EBS) and mount that volume into `/var/www/html`
1. Developer have uploaded the code into github repo also the repo has some images.
1. Copy the github repo code into /var/www/html
1. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
1. Create a Cloudfront Distribution using S3 bucket(which contains images) and use the Cloudfront URL to update in code in `/var/www/html`
 
# task-2
 AWS Infrastructure As Code Using Terraform

1. Create Security group which allow the port `80`.
1. Launch EC2 instance.
1. In this Ec2 instance use the existing key or provided key and security group which we have created in step 1.
1. Launch one Volume using the EFS service and attach it in your vpc, then mount that volume into `/var/www/html`
1. Developer have uploaded the code into github repo also the repo has some images.
1. Copy the github repo code into `/var/www/html`
1. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
1. Create a Cloudfront Distribution using S3 bucket(which contains images) and use the Cloudfront URL to update in code in `/var/www/html`

# Getting Started:
1. Clone this repo.
1. Download and install [aws-cli-v2](https://awscli.amazonaws.com/AWSCLIV2.msi) place it somewhere and add the exact path to the `PATH` environment variable.
1. For working with AWS create an `aws cli profile` using `aws configure --profile <newProfileName>` and configure it with `access` and `secret keys`. Terraform will use the profile specified by us in the `.tf` code.
1. I have a profile named `hybrid` created on my system. (The profiles are located in `$HOME/.aws/` by default.)
1. Download and install [`terraform`](https://www.terraform.io/downloads.html) binary extract it somewhere and add the exact path to the `PATH` environment variable.
1. `terraform init` : This will cause terraform to check through your code and download the plugins required for the used providers eg. `terraform-provider-aws` or even `terraform-provider-aws`.
1. `terraform apply --auto-approve` : This starts the infrastructure building process.
1. After done use `terraform destroy --auto-approve` : This starts the infrastructure destroying process.
