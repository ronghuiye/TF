output "resources" {
    value = {
        vpc_id = aws_vpc.vpc.id
        vpc_cidr = aws_vpc.vpc.cidr_block
        vpc_name = aws_vpc.vpc.tags_all.Name
        subnets = {
            pub = { for s in aws_subnet.pub_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
            }}
            tgw = { for s in aws_subnet.tgw_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
            }}
        }
        nat = {
            for z in ["az1", "az2", "az3"]: z => {
                id = aws_nat_gateway.aws_nat_gateway[z].id
                ip = aws_eip.nat_eip[z].public_ip
            }
        }
        route_tables = {
            pub = {
                id = aws_route_table.pub_route_table.id
                name = aws_route_table.pub_route_table.tags_all.Name
            }
            tgw = {
                for z in ["az1", "az2", "az3"]: z => {
                    id = aws_route_table.tgw_route_table[z].id
                    ip = aws_route_table.tgw_route_table[z].tags_all.Name
                }
            }
        }
        transit_gateway_attachment = {
            id = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
            name = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.tags_all.Name
        }
    }
}