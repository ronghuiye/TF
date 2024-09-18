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

resource "aws_subnet" "db_subnets" {
    for_each = tomap(var.environment.vpc.subnets.DB)
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    availability_zone_id = join("-", [var.common_vars.region_id, each.key])

    tags = {
      "Name" = format("%s_%s_SBNT_%s_%s_DB", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_subnet" "app_subnets" {
    for_each = tomap(var.environment.vpc.subnets.APP)
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    availability_zone_id = join("-", [var.common_vars.region_id, each.key])

    tags = {
      "Name" = format("%s_%s_SBNT_%s_%s_APP", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
      environment = var.environment.name
    }
}

resource "aws_subnet" "core_subnets" {
    for_each = tomap(var.environment.vpc.subnets.CORE)
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    availability_zone_id = join("-", [var.common_vars.region_id, each.key])

    tags = {
      "Name" = format("%s_%s_SBNT_%s_%s_CORE", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
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

resource "aws_route_table" "db_route_table" {
    vpc_id = aws_vpc.vpc.id
    
    tags = {
      "Name" = format("%s_%s_RTBL_%s_DB", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_route_table" "app_route_table" {
    vpc_id = aws_vpc.vpc.id
    
    tags = {
      "Name" = format("%s_%s_RTBL_%s_APP", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_route_table" "core_route_table" {
    vpc_id = aws_vpc.vpc.id
    
    tags = {
      "Name" = format("%s_%s_RTBL_%s_CORE", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_route_table" "tgw_route_table" {
    vpc_id = aws_vpc.vpc.id
    
    tags = {
      "Name" = format("%s_%s_RTBL_%s_TGW", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_route_table_association" "db_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.DB)
    subnet_id = aws_subnet.db_subnets[each.key].id
    route_table_id = aws_route_table.db_route_table.id
}

resource "aws_route_table_association" "app_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.APP)
    subnet_id = aws_subnet.app_subnets[each.key].id
    route_table_id = aws_route_table.app_route_table.id
}

resource "aws_route_table_association" "core_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.CORE)
    subnet_id = aws_subnet.core_subnets[each.key].id
    route_table_id = aws_route_table.core_route_table.id
}

resource "aws_route_table_association" "tgw_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.TGW)
    subnet_id = aws_subnet.tgw_subnets[each.key].id
    route_table_id = aws_route_table.tgw_route_table.id
}

resource "aws_route" "transit_gateway_routes_app" {
    depends_on = [
      aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment
    ]
    route_table_id = aws_route_table.app_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
}

resource "aws_route" "transit_gateway_routes_core" {
    depends_on = [
      aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment
    ]
    route_table_id = aws_route_table.core_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
}

resource "aws_ram_resource_share" "subnet_share" {
    name = format("%s_%s_RSHR_SBNT", var.common_vars.deployment, var.common_vars.organization)
    allow_external_principals = false

    tags = {
        Name = format("%s_%s_RSHR_SBNT", var.common_vars.deployment, var.common_vars.organization)
        environment = var.environment.name
    }
}

resource "aws_ram_resource_association" "subnet_share_association_db" {
    for_each = tomap(var.environment.vpc.subnets.DB)
    resource_arn = aws_subnet.db_subnets[each.key].arn
    resource_share_arn = aws_ram_resource_share.subnet_share.arn  
}

resource "aws_ram_resource_association" "subnet_share_association_app" {
    for_each = tomap(var.environment.vpc.subnets.APP)
    resource_arn = aws_subnet.app_subnets[each.key].arn
    resource_share_arn = aws_ram_resource_share.subnet_share.arn  
}

resource "aws_ram_resource_association" "subnet_share_association_core" {
    for_each = tomap(var.environment.vpc.subnets.CORE)
    resource_arn = aws_subnet.core_subnets[each.key].arn
    resource_share_arn = aws_ram_resource_share.subnet_share.arn  
}

resource "aws_ram_principal_association" "subnet_share_association_principal" {
    principal = var.dns_forward_rules
    resource_share_arn = aws_ram_resource_share.subnet_share.arn  
}

resource "aws_route53_resolver_rule_association" "dns_outbound_rule_association" {
    for_each = var.dns_forward_rules
    resolver_rule_id = each.value
    vpc_id = aws_vpc.vpc.id
    name = format("%s_%s_%s_RULE_ASO", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
}