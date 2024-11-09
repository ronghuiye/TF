terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

data "aws_ssm_parameter" "vpc_id_param" {
    name = format("/param/%s/%s/%s/vpc/wl/%s",
        var.common.deployment,
        var.common.organization,
        var.environment.name,
        var.common.region_id
    )
}

data "aws_ssm_parameters_by_path" "app_subnets" {
    path = format("/param/%s/%s/%s/subnets/%s/%s",
        var.common.deployment,
        var.common.organization,
        var.environment.name,
        data.aws_ssm_parameter.vpc_id_param.insecure_value,
        "app"
    )
    recursive = true
}

locals {
    vpc_id = data.aws_ssm_parameter.vpc_id_param.insecure_value
    app_subnets = nonsensitive(data.aws_ssm_parameters_by_path.app_subnets.value)
}

resource "aws_s3_bucket" "alb_logs_bucket" {
    bucket = lower(format("%s-/%s-/%s-S3-/%s-LOGS",
        var.common.deployment,
        var.common.organization,
        var.environment.name,
        var.common.region_id
    ))
    tags = {
        Name = lower(format("%s-/%s-/%s-S3-/%s-LOGS",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id))
        environment = var.environment.name
    }
}

resource "aws_s3_bucket_policy" "alb_logs_bucket_policy" {
    bucket = aws_s3_bucket.alb_logs_bucket.id
    policy = data.aws_iam_policy_document.alb_logs_bucket_policy_doc.json
}

data "aws_iam_policy_document" "alb_logs_bucket_policy_doc" {
    statement {
        principals {
            type = "AWS"
            identifiers = [data.aws_elb_service_account.aws_lb.arn]
        }
        actions = ["s3:PutObject"]
        resources = ["${aws_s3_bucket.alb_logs_bucket.arn}/*"]
    }
}

data "aws_elb_service_account" "aws_lb" {

}

resource "aws_security_group" "alb_sg" {
    name = format("%s-/%s-/%s-SG-/%s-ALB",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    description = format("%s-/%s-/%s-SG-/%s-ALB",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    vpc_id = local.vpc_id

    ingress {
        cidr_blocks = [var.common.deployment_cidr]
        from_port = 80
        to_port = 80
        protocol = "TCP"
        description = "Allow TCP traffic at port 80"
    }

    ingress {
        cidr_blocks = ["10.0.0.0/8"]
        from_port = 80
        to_port = 80
        protocol = "TCP"
        description = "Allow UDP traffic from 10.0.0.0/8 at port 80"
    }

    egress {
        cidr_blocks = ["0.0.0.0/8"]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }

    tags = {
        Name = format("%s-/%s-/%s-SG-/%s-ALB",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
        environment = var.environment.name
    }
}

resource "aws_lb" "internal_alb" {
    depends_on = [aws_s3_bucket_policy.alb_logs_bucket_policy, aws_security_group.alb_sg]
    name = format("%s-/%s-/%s-ALB-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    load_balancer_type = "application"
    internal = true
    subnets = local.app_subnets
    security_group = [aws_security_group.alb_sg.id]
    ip_address_type = "ipv4"

    access_logs {
        bucket = aws_s3_bucket.alb_logs_bucket.id
        enabled = true
        prefix = format("%s-/%s-/%s-ALB-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    }
    connection_logs {
        bucket = aws_s3_bucket.alb_logs_bucket.id
        enabled = true
        prefix = format("%s-/%s-/%s-ALB-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    }
    client_keep_alive = 60
    enable_tls_version_and_cipher_suite_headers = true
    idle_timeout = 60
    preserve_host_header = true

    tags = {
        Name = format("%s-/%s-/%s-ALB-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
        environment = var.environment.name
    }
}

resource "aws_lb_listener" "internal_alb_listener" {
    load_bancer_arn = aws_lb.internal_alb.id
    port = "80"
    protocal = "HTTP"

    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/html"
            message_body = format("<html></html>")
            status_code = "200"
        }
    }

    tags = {
        Name = format("%s-/%s-/%s-LIS-/%s-ALB",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
        environment = var.environment.name
    }
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name = format("%s-/%s-/%s-ECS-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)

    setting {
        nmae = "containerInsights"
        value = "enabled"
    }
    
    tags = {
        Name = format("%s-/%s-/%s-ECS-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
        environment = var.environment.name
    }
}