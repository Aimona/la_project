#S3 backend
terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region  = "us-east-1"
    #profile = "terraform"
    key     = "terraformstatefile"
    bucket  = "aimona-chelek"
  }
}


#Providers
provider "aws" {
  #profile = "terraform"
  region  = "us-east-1"
}

#Create VPC
module "vpc" {
  source    = "./modules/aws_vpc"
  vpc_block = "10.0.0.0/16"
}


#Create IGW
module "internet-gateway" {
  source = "./modules/aws_igw"
  vpc_id = module.vpc.id
}


#Create subnets
module "public-subnet" {
  source         = "./modules/aws_subnet"
  vpc_id         = module.vpc.id
  cidr_block     = ["10.0.0.0/18", "10.0.64.0/18"]
  az             = "us-east-1a,us-east-1b"
  route_table_id = module.route-table.id
}

module "private-subnet" {
  source     = "./modules/aws_private_subnet"
  vpc_id     = module.vpc.id
  cidr_block = ["10.0.128.0/18", "10.0.192.0/18"]
  az         = "us-east-1a,us-east-1b"
}


#Create route table
module "route-table" {
  source = "./modules/aws_route_table"
  vpc_id = module.vpc.id
}

#Create routes
module "route" {
  source         = "./modules/aws_route"
  route_table_id = module.route-table.id
  gateway_id     = module.internet-gateway.id
}


#Create security groups and rules
#--------------------------------------------------------------------
#Security group RDS
module "sg-rds" {
  source         = "./modules/aws_sg"
  vpc_id         = module.vpc.id
  sg_name        = "rds_sg"
  sg_description = "RDS security group"
}

#Ingress rules
module "sg-rds-ingress-rules" {
  source            = "./modules/aws_sg_rule"
  type              = "ingress"
  security_group_id = module.sg-rds.security_group_id
  rules = {
    "0" = ["10.0.0.0/18", "3306", "3306", "TCP", "RDS access"]
    "1" = ["10.0.64.0/18", "3306", "3306", "TCP", "RDS access"]
  }
}

#Egress rule (terraform does not do this by default)
module "sg-rds-egress-rules" {
  source            = "./modules/aws_sg_rule"
  type              = "egress"
  security_group_id = module.sg-rds.security_group_id
  rules = {
    "0" = ["0.0.0.0/0", "0", "65535", "TCP", "allow all outbound"]
  }
}


#Create RDS
module "rds" {
  source                 = "./modules/aws_rds"
  private_subnets        = [module.private-subnet.id[0], module.private-subnet.id[1]]
  vpc_security_group_ids = [module.sg-rds.security_group_id]
}


#Create EFS
resource "aws_efs_file_system" "eks-efs" {
  creation_token   = "eks-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"
  tags = {
    Name = "efs-eks"
  }
}


#Create EFS mount targets 
resource "aws_efs_mount_target" "efs-mount1a" {
  file_system_id  = aws_efs_file_system.eks-efs.id
  subnet_id       = module.public-subnet.id[0]
}

resource "aws_efs_mount_target" "efs-mount1b" {
  file_system_id  = aws_efs_file_system.eks-efs.id
  subnet_id       = module.public-subnet.id[1]
}
