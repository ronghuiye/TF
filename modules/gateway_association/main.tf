terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~>5.0"
      }
  }
}

resource "aws_ec2_transit_gateway_route_table" "tgw_vpn_route_table" {
    transit_gateway_id = var.transit_gateway_attachment.tranat_gateway_id

    tags = {
      "Name" = format("%s_%s_TGWRTL_VPN", var.common_vars.organization, upper(var.common_vars.region_id))
      environment = var.environment.name
    }
  
}

resource "aws_ec2_transit_gateway_route_table" "tgw_wl_route_table" {
    transit_gateway_id = var.transit_gateway_attachment.tranat_gateway_id

    tags = {
      "Name" = format("%s_%s_TGWRTL_WL", var.common_vars.organization, upper(var.common_vars.region_id))
      environment = var.environment.name
    }
  
}

resource "aws_ec2_transit_gateway_route_table" "tgw_egr_route_table" {
    transit_gateway_id = var.transit_gateway_attachment.tranat_gateway_id

    tags = {
      "Name" = format("%s_%s_TGWRTL_EGR", var.common_vars.organization, upper(var.common_vars.region_id))
      environment = var.environment.name
    }
  
}

resource "aws_ec2_transit_gateway_route_table" "tgw_wl_leg_route_table" {
    transit_gateway_id = var.transit_gateway_attachment.tranat_gateway_id

    tags = {
      "Name" = format("%s_%s_TGWRTL_WL_LEG", var.common_vars.organization, upper(var.common_vars.region_id))
      environment = var.environment.name
    }
  
}

resource "aws_ec2_transit_gateway_route_table" "tgw_egr_leg_route_table" {
    transit_gateway_id = var.transit_gateway_attachment.tranat_gateway_id

    tags = {
      "Name" = format("%s_%s_TGWRTL_EGR_LEG", var.common_vars.organization, upper(var.common_vars.region_id))
      environment = var.environment.name
    }
  
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_vpn_route_table_association_1" {
    transit_gateway_attachment_id = var.transit_gateway_attachment.vpn_transit_gateway_attachment_id_1
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_vpn_route_table.id
    replace_existing_association = true  
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_vpn_route_table_association_2" {
    transit_gateway_attachment_id = var.transit_gateway_attachment.vpn_transit_gateway_attachment_id_2
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_vpn_route_table.id
    replace_existing_association = true  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_vpn_route_table_propagation_wl" {
    for_each = var.transit_gateway_attachments.wl_transit_gateway_attachment_ids
    transit_gateway_attachment_id = each.value
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_vpn_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_vpn_route_table_propagation_egr_leg" {
    transit_gateway_attachment_id = each.value
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_vpn_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_egr_route_table_association" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.egr_transit_gateway_attachment_id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_egr_route_table.id
    replace_existing_association = true  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_egr_route_table_propagation_wl" {
    for_each = var.transit_gateway_attachments.wl_transit_gateway_attachment_ids
    transit_gateway_attachment_id = each.value
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_egr_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_egr_leg_route_table_association" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.egr_leg_transit_gateway_attachment_id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_egr_leg_route_table.id
    replace_existing_association = true  
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "tgw_wl_leg_rvpc_attachment_accepter" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.wl_leg_transit_gateway_attachment_id
    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false

    tags = {
      "Name" = format("%s_%s_TAGS_%s_%s", var.common_vars.organization, var.common_vars.region_id, "WL", "LEG")
    }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_egr_leg_route_table_propagation_wl" {
    depends_on = [
      aws_ec2_transit_gateway_vpc_attachment_accepter.tgw_wl_leg_rvpc_attachment_accepter
    ]
    transit_gateway_attachment_id = var.transit_gateway_attachments.wl_leg_transit_gateway_attachment_id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_egr_leg_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_egr_leg_route_table_propagation_vpn_1" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.vpn_transit_gateway_attachment_id_1
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_egr_leg_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_egr_leg_route_table_propagation_vpn_2" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.vpn_transit_gateway_attachment_id_2
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_egr_leg_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_wl_route_table_association" {
    for_each = var.transit_gateway_attachments.wl_transit_gateway_attachment_ids
    transit_gateway_attachment_id = each.value
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id
    replace_existing_association = true  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_wl_route_table_propagation_vpn_1" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.vpn_transit_gateway_attachment_id_1
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_wl_route_table_propagation_vpn_2" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.vpn_transit_gateway_attachment_id_2
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_wl_route_table_propagation_wl_leg" {
    transit_gateway_attachment_id = var.transit_gateway_attachments.wl_leg_transit_gateway_attachment_id_1
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_wl_route_table_propagation_wl" {
    for_each = var.transit_gateway_attachments.wl_transit_gateway_attachment_ids
    transit_gateway_attachment_id = each.value
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id 
}

resource "aws_ec2_transit_gateway_route" "tgw_wl_route_table_route" {
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_attachment_id = var.transit_gateway_attachments.egr_transit_gateway_attachment_id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_wl_leg_route_table_association" {
    depends_on = [
      aws_ec2_transit_gateway_vpc_attachment_accepter.tgw_wl_leg_rvpc_attachment_accepter
    ]
    transit_gateway_attachment_id = var.transit_gateway_attachments.wl_leg_transit_gateway_attachment_id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_leg_route_table.id
    replace_existing_association = true  
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_wl_leg_route_table_propagation_wl" {
    for_each = var.transit_gateway_attachments.wl_transit_gateway_attachment_ids
    transit_gateway_attachment_id = each.value
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_leg_route_table.id  
}

resource "aws_ec2_managed_prefix_list" "vpn_destinations_prefix_list" {
    Name = format("%s_%s_prefix_list", var.common_vars.organization, var.common_vars.region_id)
    address_family = "IPv4"
    max_entries = 100

    dynamic "entry" {
        for_each = var.vpn_destinations_from_leg_vpc
        content {
            cidr = entry.value
            description = entry.key
        }
    }
    tags = {
      "Name" = format("%s_%s_s_prefix_list", var.common_vars.organization, upper(var.common_vars.region_id))
      environment = var.environment.name
    }
}

resource "aws_ec2_transit_gateway_prefix_list_reference" "tgw_wl_leg_route_table_prefix_list" {
    prefix_list_id = aws_ec2_managed_prefix_list.vpn_destinations_prefix_list.id
    transit_gateway_attachment_id = var.transit_gateway_attachments.egr_leg_transit_gateway_attachment_id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_wl_leg_route_table
  
}