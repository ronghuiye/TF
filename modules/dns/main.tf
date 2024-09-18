terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~>5.0"
      }
  }
}

locals {
    purpose = "DNS"
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

resource "aws_subnet" "rsol_subnets" {
    for_each = tomap(var.environment.vpc.subnets.RSOL)
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    availability_zone_id = join("-", [var.common_vars.region_id, each.key])

    tags = {
      "Name" = format("%s_%s_SBNT_%s_%s_RSOL", var.common_vars.organization, var.environment.name, local.purpose, upper(each.key))
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

resource "aws_route_table" "rsol_route_table" {
    vpc_id = aws_vpc.vpc.id
    
    tags = {
      "Name" = format("%s_%s_RTBL_%s_RSOL", var.common_vars.organization, var.environment.name, local.purpose)
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

resource "aws_route_table_association" "rsol_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.RSOL)
    subnet_id = aws_subnet.rsol_subnets[each.key].id
    route_table_id = aws_route_table.rsol_route_table.id
}

resource "aws_route_table_association" "tgw_route_table_associations" {
    for_each = tomap(var.environment.vpc.subnets.TGW)
    subnet_id = aws_subnet.tgw_subnets[each.key].id
    route_table_id = aws_route_table.tgw_route_table.id
}

resource "aws_route" "transit_gateway_routes_rsol" {
    route_table_id = aws_route_table.rsol_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
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

resource "aws_security_group" "dns_inbound_resolver_sg" {
    name = format("%s_%s_SG_%s_INB_RSOL", var.common_vars.organization, var.environment.name, local.purpose)
    description = "Allow DNS inbound traffic at port 53 for TCP and UDP and all outbound traffic"
    vpc_id = aws_vpc.vpc.id

    ingress {
        cidr_blocks = ["10.0.0.0/8"]
        from_port = 53
        to_port = 53
        protocol = "TCP"
        description = "Allow TCP traffic from 10.0.0.0/8 at port 53"
    }

    ingress {
        cidr_blocks = ["10.0.0.0/8"]
        from_port = 53
        to_port = 53
        protocol = "UDP"
        description = "Allow UDP traffic from 10.0.0.0/8 at port 53"
    }

    egress {
        cidr_blocks = ["0.0.0.0/8"]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }

    tags = {
      Name = format("%s_%s_SG_%s_INB_RSOL", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_security_group" "dns_outbound_resolver_sg" {
    name = format("%s_%s_SG_%s_OUB_RSOL", var.common_vars.organization, var.environment.name, local.purpose)
    description = "Allow DNS inbound traffic at port 53 for TCP and UDP and all outbound traffic"
    vpc_id = aws_vpc.vpc.id

    egress {
        cidr_blocks = ["0.0.0.0/8"]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }

    tags = {
      Name = format("%s_%s_SG_%s_OUB_RSOL", var.common_vars.organization, var.environment.name, local.purpose)
      environment = var.environment.name
    }
}

resource "aws_route53_resolver_endpoint" "inbound_resolver_ep" {
    name = format("%s_%s_%s_RSOL_INB", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
    direction = "INBOUND"
    resolver_enpoint_type = "IPV4"
    protocols = ["Do53"]
    security_group_ids = [ aws_security_group.dns_inbound_resolver_sg.id ]
    
    ip_address {
        subnet_id = aws_subnet.rsol_subnets["az1"].id
        ip = var.resolver_ip.inbound.az1
    } 

    ip_address {
        subnet_id = aws_subnet.rsol_subnets["az2"].id
        ip = var.resolver_ip.inbound.az2
    } 

    ip_address {
        subnet_id = aws_subnet.rsol_subnets["az3"].id
        ip = var.resolver_ip.inbound.az3
    }   
    

    tags = {
      Name = format("%s_%s_SG_%s_RSOL_INB", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
      environment = var.environment.name
    }
}

resource "aws_route53_resolver_endpoint" "outbound_resolver_ep" {
    name = format("%s_%s_%s_RSOL_OUB", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
    direction = "OUTBOUND"
    resolver_enpoint_type = "IPV4"
    protocols = ["Do53"]
    security_group_ids = [ aws_security_group.dns_outbound_resolver_sg.id ]
    
    ip_address {
        subnet_id = aws_subnet.rsol_subnets["az1"].id
        ip = var.resolver_ip.outbound.az1
    } 

    ip_address {
        subnet_id = aws_subnet.rsol_subnets["az2"].id
        ip = var.resolver_ip.outbound.az2
    } 

    ip_address {
        subnet_id = aws_subnet.rsol_subnets["az3"].id
        ip = var.resolver_ip.outbound.az3
    }   
    

    tags = {
      Name = format("%s_%s_SG_%s_RSOL_OUB", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
      environment = var.environment.name
    }
}

resource "aws_route53_resolver_rule" "outbound_resolver_ep_fwd_rule" {
    for_each = var.dns_forward_rules
    domain_name = each.value
    name = format("%s_%s_%s_RSOL_OUB_RULE", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
    rule_type = "FORWARD"
    resolver_enpoint_id = aws_route53_resolver_endpoint.outbound_resolver_ep.id
    
    target_ip {
        ip = var.resolver_ip.external.ip1
        port = 53
        protocol = "Do53"
    } 

    target_ip {
        ip = var.resolver_ip.external.ip2
        port = 53
        protocol = "Do53"
    }  
    

    tags = {
      Name = format("%s_%s_SG_%s_RSOL_OUB_RULE", var.common_vars.deployment, var.common_vars.organization, var.environment.name)
      environment = var.environment.name
    }
}

resource "aws_route53_resolver_rule_association" "outbound_resolver_ep_fwd_rule_association" {
    for_each = var.dns_forward_rules
    resolver_rule_id = aws_route53_resolver_rule.outbound_resolver_ep_fwd_rule[each.value].id
    vpc_id = aws_vpc.vpc.id
    name = format("%s_%s_$s_RULE_ASO_%s_%s", var.common_vars.deployment, var.common_vars.organization, var.environment.name, local.purpose, each.key)
}

resource "aws_ram_resource_share" "outbound_rule_share" {
    name = format("%s_%s_RSHR_OUBRULE", var.common_vars.deployment, var.common_vars.organization)
    allow_external_principals = false

    tags = {
        Name = format("%s_%s_RSHR_OUBRULE", var.common_vars.deployment, var.common_vars.organization)
    }
}

resource "aws_ram_resource_association" "outbound_rule_share_association" {
    for_each = var.dns_forward_rules
    resource_arn = aws_route53_resolver_rule.outbound_resolver_ep_fwd_rule[each.key].arn
    resource_share_arn = aws_ram_resource_share.outbound_rule_share.arn  
}

resource "aws_ram_principal_association" "outbound_rule_share_association_principal" {
    principal = var.wl_leg_vpc.account
    resource_share_arn = aws_ram_resource_share.outbound_rule_share.arn  
}