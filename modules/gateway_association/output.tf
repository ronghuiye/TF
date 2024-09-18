output "resources" {
    value = {
        tgw_route_tables = {
            vpn = {
                name = aws_ec2_transit_gateway_route_table.tgw_vpn_route_table.tags_all.Name
                id = aws_ec2_transit_gateway_route_table.tgw_vpn_route_table.id
            }
            egr = {
                name = aws_ec2_transit_gateway_route_table.tgw_egr_route_table.tags_all.Name
                id = aws_ec2_transit_gateway_route_table.tgw_egr_route_table.id
            }
            wl = {
                name = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.tags_all.Name
                id = aws_ec2_transit_gateway_route_table.tgw_wl_route_table.id
            }
            egr_leg = {
                name = aws_ec2_transit_gateway_route_table.tgw_egr_leg_route_table.tags_all.Name
                id = aws_ec2_transit_gateway_route_table.tgw_egr_leg_route_table.id
            }
            wl_leg = {
                name = aws_ec2_transit_gateway_route_table.tgw_wl_leg_route_table.tags_all.Name
                id = aws_ec2_transit_gateway_route_table.tgw_wl_leg_route_table.id
            }
        }
        vpn_destinations_prefix_list = {
            id = aws_ec2_managed_prefix_list.vpn_destinations_prefix_list.id
            name = aws_ec2_managed_prefix_list.vpn_destinations_prefix_list.tags_all.Name
        }
    }
}