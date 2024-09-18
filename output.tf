output "gateway_data" {
    value = local.gateway_data
}

output "dns" {
    value = module.dns.resources
}

output "services_zone" {
    value = {
        for k, v in aws_route53_zone.services_zone: k => {
            name = v.name
            zone_id = v.zone_id
        }
    }
}

output "egress" {
    value = module.egress.resources
}
output "egress_legacy" {
    value = module.egress_legacy.resources
}
output "workload" {
    value = {
        for k, v in var.workload_environments: k => module.workload[k].resources
    }
}
output "workload_legacy" {
    value = module.workload_legacy.resources
}
output "gateway_association" {
    value = module.gateway_association.resources
}