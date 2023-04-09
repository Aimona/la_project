#!/bin/bash
#replace vpc_id with actual vpc_id
eks_sg=$(aws ec2 describe-security-groups --filters Name=group-name,\
Values=eks-cluster-sg-eks-project* --query 'SecurityGroups[*].[GroupId]' Name=vpc-id,\
Values=vpc-0301c778593ec7860 --output text)

aws efs modify-mount-target-security-groups \
--mount-target-id fsmt-0785930748b0940b1 \
--security-groups $eks_sg

aws efs modify-mount-target-security-groups \
--mount-target-id fsmt-0dc0722157de51bed  \
--security-groups $eks_sg