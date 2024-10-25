terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 5.0"
      }
  }
  backend "s3" {
      bucket = "nprod-aro-shared-terraform-state"
      key = "state/terraform.tfstate"
      region = "us-west-2"
      encript = true
      dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
    region = var.region
    profile = var.profile
    default_tags {
        tags = {
            "category" = "Network"
            "deployment" = var.deployment
            "environment" = var.environment
            "owner" = var.owner
        }
    }
}

locals {
}

resource "aws_ec2_transit_gateway" "transit_gateway_resource" {
    description = format("Transit Gateway")
    dns_support = "enable"
    vpn_ecmp_support = "enable"
    auto_accept_shared_attachments = "disable"
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    multicast_support = "disable"
    amazon_side_asn = var.amazon_side_asn
    tags = {
        Name = format("%s_%s_TGW", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_ram_resource_share" "transit_gateway_share" {
    name = format("%s_%s_RAM_SHARE", var.common_vars.organization, var.environment.name)
    allow_external_principals = false
    tags = {
        name = format("%s_%s_RAM_SHARE", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_ram_resource_association" "transit_gateway_share_association" {
    resource_arn = aws_ec2_transit_gateway.transit_gateway_resource.arn
    resource_share_arn = aws_ram_resource_share.transit_gateway_share.arn
}

resource "aws_ram_principal_association" "transit_gateway_association_principal" {
    principal = var.legacy_account
    resource_share_arn = aws_ram_resource_share.transit_gateway_share.arn
}

resource "aws_customer_gateway" "customer_gateway_resource_1" {
    bgp_asn = var.customer_side_asn
    ip_address = var.cutomer_side_public_ip_1
    device_name = format("%s_%s_CGW", var.common_vars.organization, var.environment.name)
    type = "ipsec.1"
    tags = {
        Name = format("%s_%s_CGW", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_cloudwatch_log_group" "connection1_tunnel1_log" {
    name = format("%s_%s_LOG", var.common_vars.organization, var.environment.name)
    tags = {
        Name = format("%s_%s_LOG", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_cloudwatch_log_group" "connection1_tunnel2_log" {
    name = format("%s_%s_LOG2", var.common_vars.organization, var.environment.name)
    tags = {
        Name = format("%s_%s_LOG2", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_vpn_connection" "vpn_connection_1" {
    lifecycle {
        prevent_destroy = true
        ignore_changes = all
    }
    depends_on = [
        aws_ec2_transit_gateway.transit_gateway_resource,
        aws_customer_gateway.customer_gateway_resource_1,
        aws_cloudwatch_log_group.connection1_tunnel1_log,
        aws_cloudwatch_log_group.connection1_tunnel2_log
    ]
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway_resource.id
    customer_gateway_id = aws_customer_gateway.customer_gateway_resource_1.id
    type = "ipsec.1"
    static_routes_only = false
    enable_acceleration = false
    local_ipv4_network_cidr = "0.0.0.0/0"
    outside_ip_address_type = "PublicIpv4"
    remote_ipv4_network_cidr = "0.0.0.0/0"
    tunnel1_preshared_key = var.pre_shared_key
    tunnel2_preshared_key = var.pre_shared_key
    tunnel1_inside_cidr = var.inside_vpn_cidr_1_tunnel_1
    tunnel2_inside_cidr = var.inside_vpn_cidr_1_tunnel_2
    tunnel1_log_options {
        cloudwatch_log_options {
            log_enabled = true
            log_group_arn = aws_cloudwatch_log_group.connection1_tunnel1_log
            log_output_format = "json"
        }
    }
    tunnel2_log_options {
        cloudwatch_log_options {
            log_enabled = true
            log_group_arn = aws_cloudwatch_log_group.connection1_tunnel2_log
            log_output_format = "json"
        }
    }
    tags = {
        Name = format("%s_%s_VPN1", var.common_vars.organization, var.environment.name)
    }

} 

resource "aws_customer_gateway" "customer_gateway_resource_2" {
    bgp_asn = var.customer_side_asn
    ip_address = var.cutomer_side_public_ip_2
    device_name = format("%s_%s_CGW", var.common_vars.organization, var.environment.name)
    type = "ipsec.1"
    tags = {
        Name = format("%s_%s_CGW", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_cloudwatch_log_group" "connection2_tunnel1_log" {
    name = format("%s_%s_LOG", var.common_vars.organization, var.environment.name)
    tags = {
        Name = format("%s_%s_LOG", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_cloudwatch_log_group" "connection2_tunnel2_log" {
    name = format("%s_%s_LOG2", var.common_vars.organization, var.environment.name)
    tags = {
        Name = format("%s_%s_LOG2", var.common_vars.organization, var.environment.name)
    }
}

resource "aws_vpn_connection" "vpn_connection_2" {
    lifecycle {
        prevent_destroy = true
        ignore_changes = all
    }
    depends_on = [
        aws_ec2_transit_gateway.transit_gateway_resource,
        aws_customer_gateway.customer_gateway_resource_2,
        aws_cloudwatch_log_group.connection2_tunnel1_log,
        aws_cloudwatch_log_group.connection2_tunnel2_log
    ]
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway_resource.id
    customer_gateway_id = aws_customer_gateway.customer_gateway_resource_2.id
    type = "ipsec.1"
    static_routes_only = false
    enable_acceleration = false
    local_ipv4_network_cidr = "0.0.0.0/0"
    outside_ip_address_type = "PublicIpv4"
    remote_ipv4_network_cidr = "0.0.0.0/0"
    tunnel1_preshared_key = var.pre_shared_key
    tunnel2_preshared_key = var.pre_shared_key
    tunnel1_inside_cidr = var.inside_vpn_cidr_2_tunnel_1
    tunnel2_inside_cidr = var.inside_vpn_cidr_2_tunnel_2
    tunnel1_log_options {
        cloudwatch_log_options {
            log_enabled = true
            log_group_arn = aws_cloudwatch_log_group.connection2_tunnel1_log
            log_output_format = "json"
        }
    }
    tunnel2_log_options {
        cloudwatch_log_options {
            log_enabled = true
            log_group_arn = aws_cloudwatch_log_group.connection2_tunnel2_log
            log_output_format = "json"
        }
    }
    tags = {
        Name = format("%s_%s_VPN2", var.common_vars.organization, var.environment.name)
    }

} 



