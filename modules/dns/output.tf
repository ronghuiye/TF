output "resources" {
    value = {
        vpc_id = aws_vpc.vpc.id
        vpc_cidr = aws_vpc.vpc.cidr_block
        vpc_name = aws_vpc.vpc.tags_all.Name
        subnets = {
            rsol = { for s in aws_subnet.rsol_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
            }}
            tgw = { for s in aws_subnet.tgw_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
            }}
        }
        route_tables = {
            rsol = {
                id = aws_route_table.rsol_route_table.id
                name = aws_route_table.rsol_route_table.tags_all.Name
            }
            tgw = {
                id = aws_route_table.rsol_route_table.id
                name = aws_route_table.tgw_route_table.tags_all.Name
            }
        }
        transit_gateway_attachment = {
            id = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
            name = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.tags_all.Name
        }
        dns_inbound_resolver_sg = {
            id = aws_security_group.dns_inbound_resolver_sg.id
            name = aws_security_group.dns_inbound_resolver_sg.tags_all.Name
        }
        dns_outbound_resolver_sg = {
            id = aws_security_group.dns_outbound_resolver_sg.id
            name = aws_security_group.dns_outbound_resolver_sg.tags_all.Name
        }
        inbound_resolver_ep = {
            id = aws_route53_resolver_endpoint.inbound_resolver_ep.id
            name = aws_route53_resolver_endpoint.inbound_resolver_ep.tags_all.Name
        }
        outbound_resolver_ep = {
            id = aws_route53_resolver_endpoint.outbound_resolver_ep.id
            name = aws_route53_resolver_endpoint.outbound_resolver_ep.tags_all.Name
        }
        outbound_resolver_ep_fwd_rule = {
            for k, v in aws_route53_resolver_rule.outbound_resolver_ep_fwd_rule:
                k => { name = v.tags_all.Name, id = v.id }
        }
    }
}