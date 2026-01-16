# output "eks_cluster_role_arn" {
#   value = aws_iam_role.Task17-EKS-Cluster-Role-Zaeem.arn
# }

# output "eks_cluster_policy" {
#   value = aws_iam_role_policy_attachment.Task17-EKS-Cluster-Policy-Zaeem
# }

# output "node_cni_policy" {
#   value = aws_iam_role_policy_attachment.node_cni_policy
# }

# output "node_ecr_policy" {
#   value = aws_iam_role_policy_attachment.node_ecr_policy
# }

# output "node_worker_policy" {
#   value = aws_iam_role_policy_attachment.node_worker_policy
# }

# output "eks_node_role_arn" {
#   value = aws_iam_role.Task17-EKS-Node-Role-Zaeem.arn
# }

# output "alb_controller_role_arn" {
#   value = aws_iam_role.alb_controller_role.arn
# }

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}
