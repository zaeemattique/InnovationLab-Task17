resource "aws_eks_cluster" "Task17-EKS-Cluster-Zaeem" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = [
      var.private_sn_A_id,
      var.private_sn_B_id,
      var.public_sn_A_id,
      var.public_sn_B_id
    ]
  }
}

resource "aws_eks_node_group" "Task17-EKS-NodeGroup-Zaeem" {
  cluster_name    = aws_eks_cluster.Task17-EKS-Cluster-Zaeem.name
  node_group_name = "Task17-EKS-NodeGroup-Zaeem"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = [
    var.private_sn_A_id,
    var.private_sn_B_id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]
  disk_size      = 20
}

# Wait for cluster to be active
resource "null_resource" "cluster_wait" {
  triggers = {
    cluster_name = aws_eks_cluster.Task17-EKS-Cluster-Zaeem.name
  }

  provisioner "local-exec" {
    command = "echo 'Waiting for EKS cluster to be active...'"
  }

  depends_on = [aws_eks_cluster.Task17-EKS-Cluster-Zaeem]
}

# Create OIDC provider for the EKS cluster
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.Task17-EKS-Cluster-Zaeem.identity[0].oidc[0].issuer
  
  depends_on = [
    aws_eks_cluster.Task17-EKS-Cluster-Zaeem,
    null_resource.cluster_wait
  ]
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.Task17-EKS-Cluster-Zaeem.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]

  depends_on = [data.tls_certificate.eks_oidc]
}