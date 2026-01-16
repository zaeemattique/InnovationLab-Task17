module "networking" {
  source = "./modules/networking"
  vpc_cidr          = var.vpc_cidr
  private_sna_cidr  = var.private_sna_cidr
  private_snb_cidr  = var.private_snb_cidr
  public_sna_cidr   = var.public_sna_cidr
  public_snb_cidr   = var.public_snb_cidr
  cluster_name      = var.cluster_name
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source = "./modules/eks"
  depends_on = [
    module.networking,
    module.iam
  ]
  
  cluster_name          = var.cluster_name
  eks_cluster_role_arn  = module.iam.eks_cluster_role_arn
  public_sn_A_id        = module.networking.public_sn_A_id
  public_sn_B_id        = module.networking.public_sn_B_id
  private_sn_A_id       = module.networking.private_sn_A_id
  private_sn_B_id       = module.networking.private_sn_B_id
  eks_node_role_arn     = module.iam.eks_node_role_arn
}

# Configure providers AFTER EKS is created
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

module "iam_alb" {
  source = "./modules/iam_alb"
  depends_on = [module.eks]

  oidc_provider_url                    = module.eks.oidc_provider_url
  aws_iam_openid_connect_provider_arn  = module.eks.oidc_provider_arn
}

# ALB Controller removed - will install manually via Helm

# Add output for IAM role ARN to use with manual Helm installation
output "alb_controller_iam_role_arn" {
  value = module.iam_alb.alb_controller_role_arn
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}