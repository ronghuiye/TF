terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~>5.0"
      }
  }
}

locals {
    purpose = "EGR"
}

resource "aws_vpc" "vpc" {
    cidr_block = var.environment.vpc.cidr
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    enable_network_address_usage_metrics = true

    tags = {
      "Name" = format("%s_%s_%s_VPC_%s", var.common_vars.deployment, var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      "Name" = format("%s_%s_%s_IGW_%s", var.common_vars.deployment, var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_subnet" "pub_subnets" {
    for_each = tomap(var.environment.vpc.subnets.PUB)
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    availability_zone_id = join("-", [var.common_vars.region_id, each.key])

    tags = {
      "Name" = format("%s_%s_SBNT_%s_%s_PUB", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_subnet" "tgw_subnets" {
    for_each = tomap(var.environment.vpc.subnets.TGW)
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    availability_zone_id = join("-", [var.common_vars.region_id, each.key])

    tags = {
      "Name" = format("%s_%s_SBNT_%s_%s_TGW", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_eip" "nat_eip" {
    for_each = var.environment.vpc.subnets.PUB
    
    tags = {
      "Name" = format("%s_%s_EIP_NAT_%s", var.common_vars.organization, var.environment.name, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_nat_gateway" "nat_gateway" {
    for_each = var.environment.vpc.subnets.PUB
    allocation_id = aws_eip.nat_eip[each.key].id
    subnet_id = aws_subnet.pub_subnets[each.key].id
    
    tags = {
      "Name" = format("%s_%s_NAT_PUB_%s", var.common_vars.organization, var.environment.name, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway_attachment" {
    subnet_ids = [for v in aws_subnet.tgw_subnets: v.id]
    transit_gateway_id = var.transit_gateway_id
    vpc_id = aws_vpc.vpc.id
    dns_support = "enable"
    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false

    tags = {
        "Name" = format("%s_%s_TAGS_%s", var.common_vars.organization, upper(var.common_vars.region_id), local.purpose)
        environment = var.environment.name
    }
}

resource "aws_route_table" "pub_route_table" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }
    route {
        cidr_block = var.common_vars.depllyment_cidr
        tranat_gateway_id = var.transit_gateway_id
    }
    
    tags = {
      "Name" = format("%s_%s_RTBL_%s_PUB", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_route_table" "tgw_route_table" {
    for_each = var.environment.vpc.subnets.TGW
    vpc_id = aws_vpc.vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
    }

    tags = {
      "Name" = format("%s_%s_RTBL_%s_%s_TGW", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_route_table_association" "pub_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.PUB)
    subnet_id = aws_subnet.pub_subnets[each.key].id
    route_table_id = aws_route_table.pub_route_table.id
}

resource "aws_route_table_association" "tgw_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.TGW)
    subnet_id = aws_subnet.tgw_subnets[each.key].id
    route_table_id = aws_route_table.tgw_route_table.id
}

resource "aws_route53_resolver_rule_association" "dns_outbound_rule_association" {
    for_each = var.dns_forward_rules
    resolver_rule_id = each.value
    vpc_id = aws_vpc.vpc.id
    name = format("%s_%s_$s_RULE_ASO_%s_%s", var.common_vars.deployment, var.common_vars.organization, var.environment.name, local.purpose, each.key)
}