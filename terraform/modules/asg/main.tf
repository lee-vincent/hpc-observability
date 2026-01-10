resource "aws_launch_template" "compute" {
  name_prefix   = "${var.name_prefix}-compute-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.keypair_name != "" ? var.keypair_name : null

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  user_data = base64encode(templatefile("${var.scripts_path}/cloud-init/compute.yaml", {
    hostname         = "compute"
    environment      = var.environment
    project_name     = var.project_name
    cluster_name     = var.slurm_cluster_name
    controller_ip    = var.controller_ip
    bcm_ip           = var.bcm_ip
    observability_ip = var.observability_ip
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-compute"
      Role = "compute"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-compute-volume"
    })
  }

  dynamic "instance_market_options" {
    for_each = var.enable_spot ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price          = var.spot_max_price != "" ? var.spot_max_price : null
        spot_instance_type = "one-time"
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "compute" {
  name                = "${var.name_prefix}-compute-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = [var.private_subnet_id]

  launch_template {
    id      = aws_launch_template.compute.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${var.name_prefix}-compute"
      Role = "compute"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
