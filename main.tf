terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 5.0"
      }
  }
  backend "s3" {

  }
}

data "terraform_remote_state" "gateway" {
    backend = var.gateway_state.backend
    workspace = var.gateway_state.workspace
    config = var.gateway_state.config
}

locals {
    gateway_data = data.terraform_remote_state.gateway.outputs
}

module "dns" {
    source = "./modules/dns"
    providers = { aws = aws.SHARED }
    common_vars = var.common_vars
    environment = var.dns_environment
    transit_gateway_id = local.gateway_data.transit_gateway.id
    resolver_ip = var.resolver_ip
    dns_forward_rules = var.dns_forward_rules
    wl_leg_vpc = var.wl_leg_vpc
}

module "egress" {
    depends_on = [ module.dns ]
    source = "./modules/egress"
    providers = { aws = aws.SHARED }
    common_vars = var.common_vars
    environment = var.egress_environment
    transit_gateway_id = local.gateway_data.transit_gateway.id
    dns_forward_rules = {
        for k, v in var.dns_forward_rules: k => module.dns.resources.outbound_resolver_ep_fwd_rule[k].id
    }
}

module "egress_legacy" {
    depends_on = [ module.dns ]
    source = "./modules/egress_legacy"
    providers = { aws = aws.SHARED }
    common_vars = var.common_vars
    environment = var.egress_legacy_environment
    transit_gateway_id = local.gateway_data.transit_gateway.id
    dns_forward_rules = {
        for k, v in var.dns_forward_rules: k => module.dns.resources.outbound_resolver_ep_fwd_rule[k].id
    }
}

module "workload" {
    depends_on = [ module.dns ]
    source = "./modules/workload"
    for_each = var.workload_environments
    providers = { aws = aws.SHARED }
    common_vars = var.common_vars
    environment = each.value
    transit_gateway_id = local.gateway_data.transit_gateway.id
    dns_forward_rules = {
        for k, v in var.dns_forward_rules: k => module.dns.resources.outbound_resolver_ep_fwd_rule[k].id
    }
}

resource "aws_route53_zone" "services_zone" {
    depends_on = [ module.dns ]
    for_each = var.workload_environments
    name = format("aro-%s.aws-fin.com", lower(each.value.name))
    provider = aws.SHARED
    vpc {
        vpc_id = module.dns.resources.vpc_id
    }
    dynamic "vpc" {
        for_each = module.workload
        content {
            vpc_id = vpc.value.resources.vpc_id
        }
    }
    tags = {
      owner = var.common_vars.owner
      owner_account = var.common_vars.owner_account
      environment = each.value.name
      deployment = var.common_vars.deployment
      category = "Network"
    }
}

resource "aws_ssm_parameter" "services_zone_param" {
    depends_on = [ module.dns ]
    for_each = var.workload_environments
    provider = aws.SHARED
    name = format("/param/%s/%s/%s/service_zone_id", 
        var.common_vars.deployment,
        var.common_vars.organization,
        each.value.name
        )
    description = format("%s zone id for service",
        each.value.name
        )
    type = "String"
    value = aws_route53_zone.services_zone[each.key].zone_id

    tags = {
      owner = var.common_vars.owner
      owner_account = var.common_vars.owner_account
      environment = each.value.name
      deployment = var.common_vars.deployment
      category = "Network"
      name = aws_route53_zone.services_zone[each.key].name
    }
}

module "workload_legacy" {
    depends_on = [ module.dns ]
    source = "./modules/workload_legacy"
    providers = { aws.leg = aws.leg }
    common_vars = var.common_vars
    transit_gateway_id = local.gateway_data.transit_gateway.id
    vpc_id = var.wl_leg_vpc.vpc_id
    subnet_ids = var.wl_leg_vpc.subnet_ids
    dns_forward_rules = {
        for k, v in var.dns_forward_rules: k => module.dns.resources.outbound_resolver_ep_fwd_rule[k].id
    }
}

module "gateway_association" {
    depends_on = [ module.dns, module.egress, module.egress_legacy, module.workload, module.workload_legacy ]
    source = "./modules/gateway_association"
    providers = { aws = aws.SHARED }
    common_vars = var.common_vars
    vpn_destinations_from_leg_vpc = var.vpn_destinations_from_leg_vpc
    transit_gateway_attachments = {
        transit_gateway_id = local.gateway_data.transit_gateway.id
        vpn_transit_gateway_attachment_id_1 = local.gateway_data.vpn_connection_1.transit_gateway_attachment_id
        vpn_transit_gateway_attachment_id_2 = local.gateway_data.vpn_connection_2.transit_gateway_attachment_id
        egr_transit_gateway_attachment_id = module.egress.resources.transit_gateway_attachment.id
        wl_transit_gateway_attachment_ids = merge({
            "DNS": module.dns.resources.transit_gateway_attachment.id
        }, {
            for k, v in var.workload_environments: k => module.workload[k].resources.transit_gateway_attachment.id
        })
        egr_leg_transit_gateway_attachment_id = module.egress_legacy.resources.transit_gateway_attachment.id
        wl_leg_transit_gateway_attachment_id = module.workload_legacy.resources.transit_gateway_attachment.id
        vpn_destinations_from_leg_vpc = var.vpn_destinations_from_leg_vpc
    }
}


