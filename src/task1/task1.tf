# Task 1 : Hybrid Multi Cloud Training led by Mr. Vimal Daga

# Have to create/launch Application using Terraform

# 1. Create the key and security group which allow the port 80.

# 2. Launch EC2 instance.

# 3. In this Ec2 instance use the key and security group which we have created in step 1.

# 4. Launch one Volume (EBS) and mount that volume into /var/www/html

# 5. Developer have uploaded the code into github repo also the repo has some images.

# 6. Copy the github repo code into /var/www/html

# 7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.

# 8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to update in code in /var/www/html #ec2 #ebs #cloudfront


provider "aws" {
  region     = "ap-south-1"
  profile = "hybrid"
}

# Creating KeyPair
resource "tls_private_key" "privateKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "MyKey" {
  key_name = "MyKey"
  public_key = tls_private_key.privateKey.public_key_openssh
}



#Creating Security Group
#With only HTTP and SSH Ingress Traffic
resource "aws_security_group" "MyGroup" {
  name        = "MySecurityGroup"
  description = "Allow HTTP inbound traffic"
  
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }
}

resource "aws_security_group_rule" "Rule1" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.MyGroup.id
}

resource "aws_security_group_rule" "Rule2" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.MyGroup.id
}



# Creating Instance
# Amazon Linux 2 AMI & t2.micro
resource "aws_instance" "MyInstance" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.MyKey.key_name
  security_groups = ["MySecurityGroup"] 

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.privateKey.private_key_pem
    host     = aws_instance.MyInstance.public_ip
  }
  # Remotely executing and configuring the server with webserver, php and git
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "HybridOS-Terraform"
  }
}

# Output the public ip
output "Public_IP"{
  value=aws_instance.MyInstance.public_ip
}

resource "null_resource" "local1" {
  #Save the Public IP to a local text file
  provisioner "local-exec" {
    command = "echo ${aws_instance.MyInstance.public_ip} > publicip.txt"
  }
}


#Open Chrome after Cloudfront setup [Last Step]
resource "null_resource" "local2" {
  depends_on = [
    null_resource.remote1,aws_cloudfront_distribution.MyS3Distribution
  ]
  provisioner "local-exec" {
    command = "start chrome ${aws_instance.MyInstance.public_ip}"
  }
}

#Output the availability_zone
output "AZ"{
  value=aws_instance.MyInstance.availability_zone
}

#Create 1Gb EBS Volume in the same region as the previouslyc created EC2 Instance
resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = aws_instance.MyInstance.availability_zone
  size              = 1

  tags = {
    Name = "MyVol"
  }
}

#Attach the EBS Volume to the instance once it has been created
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.MyInstance.id
  force_detach = true
}

#After Attaching SSH into the instance and create partition, 
#format it and  mount the new 1GB EBS volume at the /var/www/html folder
#Clear the contents of /var/www/html/ and Clone the github repo to the same folder
resource "null_resource" "remote1" {
  depends_on = [
    aws_volume_attachment.ebs_att,
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.privateKey.private_key_pem
    host     = aws_instance.MyInstance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html/",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/HybridShivam/aws-terraform.git /var/www/html/",
    ]
  }
}


#Create a S3 Bucket
#With Read access for all users
resource "aws_s3_bucket" "buck" {
  bucket = "my-bucket-hybrid"
  force_destroy = true

  versioning {
    enabled = true
  }
  grant {
    type        = "Group"
    permissions = ["READ"]
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
  }
  tags = {
    Name        = "my-bucket-hybrid"
    Environment = "Dev"
  }
}


#Add one image to the Bucket with public-read ACL
resource "aws_s3_bucket_object" "buck_obj" {
  depends_on=[aws_s3_bucket.buck]
  bucket = "my-bucket-hybrid"
  key    = "terraform.png"
  source = "img/terraform.png"
  etag = filemd5("img/terraform.png")
  acl = "public-read"
 
}

locals {
  s3_origin_id = "myS3Origin"
}


# After adding the image, create Cloudfront Distribution with the previously created S3 as the origin.
resource "aws_cloudfront_distribution" "MyS3Distribution" {
  depends_on = [
    null_resource.remote1
  ]
  origin {
    domain_name = aws_s3_bucket.buck.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terraform Image Distribution"
  default_root_object = "terraform.png"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.privateKey.private_key_pem
    host     = aws_instance.MyInstance.public_ip
  }


  // Generate Cloudfront URL for image and append to the HTML Page
  provisioner "remote-exec" {
    inline = [
      "sudo su << EOF",
      "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.buck_obj.key}' height='200px' width='200px'>\" >> /var/www/html/index.php",
      "EOF",
    ]
  }
}