terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~>5.0"
      }
  }
}

locals {
    purpose = "WL"
}

resource "aws_route53_resolver_rule_association" "dns_outbound_rule_association" {
    provider = aws.leg
    for_each = var.dns_forward_rules
    resolver_rule_id = each.value
    vpc_id = aws_vpc.vpc.id
    name = format("%s_%s_%s_RULE_ASO", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
}

resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway_attachment" {
    provider = aws.leg
    subnet_ids = var.subnet_ids
    transit_gateway_id = var.tranat_gateway_id
    vpc_id = var.vpc_id
    dns_support = "enable"
    tags = {
        name = format("%s_%s_%s_TAGS", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
    }
  
}