output "vpc" {
  value = module.vpc.id
}

output "public_subnet1a" {
  value = module.public-subnet.id[0]
}

output "public_subnet1b" {
  value = module.public-subnet.id[1]
}


output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_password" {
  value = module.rds.password.result
}

output "efs_id" {
  value = aws_efs_file_system.eks-efs.id
}

output "fsmt_id_1a" {
  value = aws_efs_mount_target.efs-mount1a.id 
}

output "fsmt_id_1b" {
  value = aws_efs_mount_target.efs-mount1b.id 
}
