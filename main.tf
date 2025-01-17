# Create a default VPC
resource "aws_vpc" "default" {
  provider = aws.us-east-1

  tags       = merge(var.tags, {})
  cidr_block = var.vpc_cidr
}

# Create the first public subnet
resource "aws_subnet" "snet1" {
  provider = aws.us-east-1

  vpc_id                  = aws_vpc.default.id
  tags                    = merge(var.tags, {})
  map_public_ip_on_launch = true
  cidr_block              = var.subnets[0]
  availability_zone       = "us-east-1a"
}

# Create the second public subnet
resource "aws_subnet" "snet2" {
  provider = aws.us-east-1

  vpc_id                  = aws_vpc.default.id
  tags                    = merge(var.tags, {})
  map_public_ip_on_launch = true
  cidr_block              = var.subnets[1]
  availability_zone       = "us-east-1b"
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "gtw" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.default.id

  tags = {
    Name = "Brainboard k8s"
    Env  = "Development"
  }
}

# Create a default route table and associate it with the second subnet
resource "aws_route_table" "default" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.default.id
  tags   = merge(var.tags, {})

  route {
    gateway_id = aws_internet_gateway.gtw.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "route-association-2" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.snet2.id
  route_table_id = aws_route_table.default.id
}

# Create a default IAM role for the EKS worker nodes
resource "aws_iam_role" "default-iam" {
  provider = aws.us-east-1

  tags               = merge(var.tags, {})
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach the necessary IAM policies to the default IAM role
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  provider = aws.us-east-1

  role       = aws_iam_role.default-iam.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create an EKS node group using the default IAM role
resource "aws_eks_node_group" "default" {
  provider = aws.us-east-1

  tags            = merge(var.tags, {})
  node_role_arn   = aws_iam_role.default-iam.arn
  node_group_name = "brainboard_k8s"
  cluster_name    = aws_eks_cluster.default.name

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  scaling_config {
    min_size     = var.scaling.min
    max_size     = var.scaling.max
    desired_size = var.scaling.desired
  }

  subnet_ids = [
    aws_subnet.snet1.id,
    aws_subnet.snet2.id,
  ]
}

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "iam-cluster" {
  provider = aws.us-east-1

  tags               = merge(var.tags, {})
  name               = "brainboard-k8s-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach the necessary IAM policies to the EKS cluster IAM role
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  provider = aws.us-east-1

  role       = aws_iam_role.iam-cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create a security group for the EKS cluster
resource "aws_security_group" "cluster-sg" {
  provider = aws.us-east-1

  vpc_id      = aws_vpc.default.id
  tags        = merge(var.tags, {})
  name        = var.sg_name
  description = "Cluster communication with worker nodes"

  egress {
    to_port   = 0
    protocol  = "-1"
    from_port = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

# Create a security group rule to allow HTTPS access to the EKS cluster
resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
  provider = aws.us-east-1

  type              = "ingress"
  to_port           = 443
  security_group_id = aws_security_group.cluster-sg.id
  protocol          = "tcp"
  from_port         = 443
  description       = "Allow workstation to communicate with the cluster API Server"

  cidr_blocks = [
    var.workstation-external-cidr,
  ]
}

# Create the EKS cluster
resource "aws_eks_cluster" "default" {
  provider = aws.us-east-1

  role_arn = aws_iam_role.iam-cluster.arn
  name     = var.cluster-name

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
  ]

  tags = {
    env      = "Staging"
    archUUID = "db83bcc0-696a-4f64-a6d5-fcc143caf3e2"
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.cluster-sg.id,
    ]
    subnet_ids = [
      aws_subnet.snet1.id,
      aws_subnet.snet2.id,
    ]
  }
}
