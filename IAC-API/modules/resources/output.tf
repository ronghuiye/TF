output "resources" {
    value = {
        vpc_id = local.vpc_id
        app_subnets = local.app_subnets
        internal_alb = aws_lb.internal_alb
        resource_label = local.resource_label
    }
}