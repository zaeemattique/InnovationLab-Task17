# resource "aws_iam_role" "Task17-EKS-Cluster-Role-Zaeem" {
#   name = "Task17-${var.cluster_name}-Cluster-Role-Zaeem"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "Task17-EKS-Cluster-Policy-Zaeem" {
#   role       = aws_iam_role.Task17-EKS-Cluster-Role-Zaeem.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role" "Task17-EKS-Node-Role-Zaeem" {
#   name = "Task17-${var.cluster_name}-Node-Role-Zaeem"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "node_worker_policy" {
#   role       = aws_iam_role.Task17-EKS-Node-Role-Zaeem.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# resource "aws_iam_role_policy_attachment" "node_cni_policy" {
#   role       = aws_iam_role.Task17-EKS-Node-Role-Zaeem.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
#   role       = aws_iam_role.Task17-EKS-Node-Role-Zaeem.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_policy" "alb_controller_policy" {
#   name   = "Task17AWSLoadBalancerControllerIAMPolicy"
#   policy = file("${path.module}/iam_policy.json")
# }

# data "aws_eks_cluster" "eks" {
#   name = var.cluster_name
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = var.cluster_name
# }

# data "tls_certificate" "oidc" {
#   url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer

#   client_id_list = ["sts.amazonaws.com"]

#   thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
# }

# data "aws_iam_openid_connect_provider" "eks" {
#   url = var.oidc_provider_url
# }

# resource "aws_iam_role" "alb_controller_role" {
#   name = "Task17-ALB-Controller-Role-Zaeem"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = data.aws_iam_openid_connect_provider.eks.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_policy" "alb_policy" {
#   name   = "Task17-ALB-Controller-Policy-Zaeem"
#   policy = file("${path.module}/iam_policy.json")
# }

# resource "aws_iam_role_policy_attachment" "alb_attach" {
#   role       = aws_iam_role.alb_controller_role.name
#   policy_arn = aws_iam_policy.alb_policy.arn
# }

resource "aws_iam_role" "eks_cluster_role" {
  name = "Task17-EKS-Cluster-Role-Zaeem"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "Task17-EKS-Node-Role-Zaeem"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
