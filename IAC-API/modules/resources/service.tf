resource "aws_iam_role" "ecs_task_role" {
    name = format("%s-/%s-/%s-ROLE_TASK-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    description = "A generic and param store & secret manager access role for ecs service tasks" 
    tags = {
        Name = format("%s-/%s-/%s-ROLE_TASK-/%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
        environment = var.environment.name
    }

    assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ecs-tasks.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "ecs_task_policy" {
    name = format("%s-/%s-/%s-POLICY_TASK-/%s_ECR",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id)
    role = aws_iam_role.ecs_task_role.id
    policy = file("${path.module}/docs/ecs-task-policy.json")
}

resource "aws_cloudwatch_log_group" "ecs_task_log" {
    for_each = var.services
    name = format("%s-/%s-/%s-LOG-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    tags = {
        Name = format("%s-/%s-/%s-LOG-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
    for_each = var.services
    family = format("%s-/%s-/%s-TASK-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = 512
    memory = 1024
    task_role_arn = aws_iam_role.ecs_task_role.arn
    execution_role_arn = aws_iam_role.ecs_task_role.arn
    container_definitions = templatefile("${path.module}/docs/task-def.json.tpl",
    {
        name = format("%s-/%s-/%s-CONT-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        image = format("%s.dkr.ecr.us-west-2.amazonaws.com/%s", var.environment.account_number, each.value.image_name)
        port = each.value.port
        awslogs-group = aws_cloudwatch_log_group.ecs_task_log[each.key].name
        awslogs-region = var.common.region
        awslogs-stream-prefix = each.key
        var1Name = "service"
        var1Value = each.value.context_path
        var2Name = "ENV"
        var2Value = var.environment.name
    })

    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture = "ARM64"
    }
    tags = {
        Name = format("%s-/%s-/%s-TASK-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        environment = var.environment.name
    }
}

resource "aws_lb_target_group" "target_group" {
    for_each = var.services
    name = format("%s-/%s-/%s-TG-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    port = each.value.port
    protocol = each.value.protocol
    target_type = "ip"
    vpc_id = local.vpc_id
    health_check {
        port = each.value.health_check.port
        path = each.value.health_check.path
        healthy_threshold = each.value.health_check.healthy_threshold
        unhealthy_threshold = each.value.health_check.unhealthy_threshold
        timeout = each.value.health_check.timeout
        interval = each.value.health_check.interval
    }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
    depends_on = [aws_lb_target_group.target_group]
    for_each = var.services
    listener_arn = aws_lb_listener.internal_alb_listener.arn
    priority = each.value.priority

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_group[each.key].arn
    }

    condition {
        path_pattern {
            values = [format(/"%s", each.value.context_path),format("/%s/", each.value.context_path),format("/%s/*", each.value.context_path)]
        }
    }
    tags = {
        Name = format("%s-/%s-/%s-LIS_RULE-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        environment = var.environment.name
    }
}

resource "aws_security_group" "ecs_svc_sg" {
    depends_on = [aws_security_group.alb_sg]
    for_each = var.services
    name = format("%s-/%s-/%s-SG-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    description = format("%s-/%s-/%s-SG-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    vpc_id = local.vpc_id

    ingress {
        cidr_blocks = [var.common.deployment_cidr]
        from_port = each.value.port
        to_port = each.value.port
        protocol = "TCP"
        description = "Allow TCP traffic at port"
    }

    ingress {
        from_port = each.value.port
        to_port = each.value.port
        protocol = "TCP"
        security_group = [aws_security_group.alb_sg.id]
        description = "Allow TCP"
    }

    egress {
        cidr_blocks = ["0.0.0.0/8"]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }

    tags = {
        Name = format("%s-/%s-/%s-SG-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        environment = var.environment.name
    }
    
}

resource "aws_ecs_service" "ecs_service" {
    depends_on = [aws_ecs_task_definition.ecs_task_definition, aws_lb_listener_rule.alb_listener_rule]
    for_each = var.services
    launch_type = "FARGATE"
    name = format("%s-/%s-/%s-SVC-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.ecs_task_definition[each.key].arn
    desired_count = each.value.scaling.desired_capacity
    health_check_grace_period_seconds = each.value.health_check.health_check_grace_period_seconds
    deployment_minimum_healthy_percent = 50
    deployment_maximum_percent = 200
    network_configuration {
        assign_public_ip = false
        subnets = local.app_subnets
        security_groups = [aws_security_group.ecs_svc_sg[each.key].id]
    }
    load_balancer {
        target_group_arn = aws_lb_target_group.target_group[each.key].arn
        container_name = format("%s-/%s-/%s-CONT-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        container_port = each.value.port
    }
    tags = {
        Name = format("%s-/%s-/%s-SVC-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        environment = var.environment.name
    }
}

resource "aws_appautoscaling_target" "ecs_service_autoscaling_target" {
    depends_on = [aws_ecs_service.ecs_service]
    for_each = var.services
    scalable_dimension = "ecs:service:DesiredCount"
    min_capacity = each.value.scaling.min_capacity
    max_capacity = each.value.scaling.max_capacity
    resource_id = format("%s-/%s-/%s-target-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    service_namespace = "ecs"
    tags = {
        Name = format("%s-/%s-/%s-SVC_SCAL_TAR-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        environment = var.environment
    }
}

resource "aws_appautoscaling_policy" "ecs_service_autoscaling_policy" {
    depends_on = [aws_ecs_service.ecs_service]
    for_each = var.services
    name = format("%s-/%s-/%s-XXX-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
    policy_type = "TargetTrackingScaling"
    resource_id = aws_appautoscaling_target.ecs_service_autoscaling_target[each.key].resource_id
    scalable_dimension = aws_appautoscaling_target.ecs_service_autoscaling_target[each.key].scalable_dimension
    service_namespace = aws_appautoscaling_target.ecs_service_autoscaling_target[each.key].service_namespace

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ALBRequestCountPerTarget"
            resource_label = format("%s-/%s-/%s-label-/%s-%s",var.common.deployment,var.common.organization,var.environment.name,var.common.region_id, each.key)
        }
        target_value = each.value.scaling.request_per_target
        scale_in_cooldown = each.value.scaling.scale_in_cooldown
        scale_out_cooldown = each.value.scaling.scale_out_cooldown
    }
}

locals {
    resource_label = {
        for k,v in var.services: k => format("app/%s/%s/targetgroup/%s/%s",aws_lb.internal_alb.name, basename(aws_lb.internal_alb.id),
        aws_lb_target_group.target_group[k].name, basename(aws_lb_target_group.target_group[k].id))
    }
}