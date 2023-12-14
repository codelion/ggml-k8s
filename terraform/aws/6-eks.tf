resource "aws_eks_cluster" "LlamaCppEKSCluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.llamacpp-eks-cluster-role.arn

  enabled_cluster_log_types = ["api", "audit"] // Enable API server and audit logs

  vpc_config {
    endpoint_private_access = true  // Enable private access
    endpoint_public_access  = false // Disable public access

    // If you need to enable public access but restrict it to certain IP ranges, you can specify them here
    // public_access_cidrs     = ["<your-ip-range>"]

    subnet_ids = [
      aws_subnet.llamacpp-private-subnet-01.id,
      aws_subnet.llamacpp-private-subnet-02.id,
      aws_subnet.llamacpp-public-subnet-01.id,
      aws_subnet.llamacpp-public-subnet-02.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.llamacpp-eks-cluster-policy]
}