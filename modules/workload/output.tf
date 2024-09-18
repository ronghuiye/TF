output "resources" {
    value = {
        vpc_id = aws_vpc.vpc.id
        vpc_cidr = aws_vpc.vpc.cidr_block
        vpc_name = aws_vpc.vpc.tags_all.Name
        subnets = {
            db = { for s in aws_subnet.db_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
                zone_id = s.availability_zone_id
            }}
            app = { for s in aws_subnet.app_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
                zone_id = s.availability_zone_id
            }}
            core = { for s in aws_subnet.core_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
                zone_id = s.availability_zone_id
            }}
            tgw = { for s in aws_subnet.tgw_subnets: s.id => {
                name = s.tags_all.Name 
                cidr = s.cidr_block
                zone_id = s.availability_zone_id
            }}
        }
        route_tables = {
            db = {
                id = aws_route_table.db_route_table.id
                name = aws_route_table.db_route_table.tags_all.Name
            }
            app = {
                id = aws_route_table.app_route_table.id
                name = aws_route_table.app_route_table.tags_all.Name
            }
            core = {
                id = aws_route_table.core_route_table.id
                name = aws_route_table.core_route_table.tags_all.Name
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
        subnet_share = {
            id = aws_ram_resource_share.subnet_share.id
            name = aws_ram_resource_share.subnet_share.tags_all.Name
        }
    }
}