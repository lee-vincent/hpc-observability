data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.name_prefix}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "bcm" {
  name               = "${var.name_prefix}-bcm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "controller" {
  name               = "${var.name_prefix}-controller-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "db" {
  name               = "${var.name_prefix}-db-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "observability" {
  name               = "${var.name_prefix}-observability-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "compute" {
  name               = "${var.name_prefix}-compute-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = var.use_ssm ? 1 : 0
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bcm_ssm" {
  count      = var.use_ssm ? 1 : 0
  role       = aws_iam_role.bcm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "controller_ssm" {
  count      = var.use_ssm ? 1 : 0
  role       = aws_iam_role.controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "db_ssm" {
  count      = var.use_ssm ? 1 : 0
  role       = aws_iam_role.db.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "observability_ssm" {
  count      = var.use_ssm ? 1 : 0
  role       = aws_iam_role.observability.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "compute_ssm" {
  count      = var.use_ssm ? 1 : 0
  role       = aws_iam_role.compute.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ssm_parameters_read" {
  statement {
    sid = "ReadSSMParameters"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/hpc-obs/${var.environment}/*"
    ]
  }

  statement {
    sid = "DecryptSSMParameters"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ssm_parameters_read" {
  name        = "${var.name_prefix}-ssm-params-read"
  description = "Allow reading SSM parameters for HPC cluster"
  policy      = data.aws_iam_policy_document.ssm_parameters_read.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "bcm_ssm_params" {
  role       = aws_iam_role.bcm.name
  policy_arn = aws_iam_policy.ssm_parameters_read.arn
}

resource "aws_iam_role_policy_attachment" "controller_ssm_params" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.ssm_parameters_read.arn
}

resource "aws_iam_role_policy_attachment" "db_ssm_params" {
  role       = aws_iam_role.db.name
  policy_arn = aws_iam_policy.ssm_parameters_read.arn
}

resource "aws_iam_role_policy_attachment" "compute_ssm_params" {
  role       = aws_iam_role.compute.name
  policy_arn = aws_iam_policy.ssm_parameters_read.arn
}

resource "aws_iam_role_policy_attachment" "observability_ssm_params" {
  role       = aws_iam_role.observability.name
  policy_arn = aws_iam_policy.ssm_parameters_read.arn
}

data "aws_iam_policy_document" "ec2_describe" {
  statement {
    sid = "DescribeEC2"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_describe" {
  name        = "${var.name_prefix}-ec2-describe"
  description = "Allow describing EC2 instances for service discovery"
  policy      = data.aws_iam_policy_document.ec2_describe.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "controller_ec2_describe" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.ec2_describe.arn
}

resource "aws_iam_role_policy_attachment" "observability_ec2_describe" {
  role       = aws_iam_role.observability.name
  policy_arn = aws_iam_policy.ec2_describe.arn
}

resource "aws_iam_role_policy_attachment" "bcm_ec2_describe" {
  role       = aws_iam_role.bcm.name
  policy_arn = aws_iam_policy.ec2_describe.arn
}

data "aws_iam_policy_document" "bcm_s3_read" {
  statement {
    sid = "ReadBCMBucket"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::bcm10",
      "arn:aws:s3:::bcm10/*"
    ]
  }
}

resource "aws_iam_policy" "bcm_s3_read" {
  name        = "${var.name_prefix}-bcm-s3-read"
  description = "Allow BCM instance to read BCM ISO from S3"
  policy      = data.aws_iam_policy_document.bcm_s3_read.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "bcm_s3_read" {
  role       = aws_iam_role.bcm.name
  policy_arn = aws_iam_policy.bcm_s3_read.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = var.tags
}

resource "aws_iam_instance_profile" "bcm" {
  name = "${var.name_prefix}-bcm-profile"
  role = aws_iam_role.bcm.name

  tags = var.tags
}

resource "aws_iam_instance_profile" "controller" {
  name = "${var.name_prefix}-controller-profile"
  role = aws_iam_role.controller.name

  tags = var.tags
}

resource "aws_iam_instance_profile" "db" {
  name = "${var.name_prefix}-db-profile"
  role = aws_iam_role.db.name

  tags = var.tags
}

resource "aws_iam_instance_profile" "observability" {
  name = "${var.name_prefix}-observability-profile"
  role = aws_iam_role.observability.name

  tags = var.tags
}

resource "aws_iam_instance_profile" "compute" {
  name = "${var.name_prefix}-compute-profile"
  role = aws_iam_role.compute.name

  tags = var.tags
}
