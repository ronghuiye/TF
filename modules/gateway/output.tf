output "transit_gateway" {
    value = {
        id = aws_ec2_transit_gateway.transit_gateway_resource.id
        name = aws_ec2_transit_gateway.transit_gateway_resource.tags.name
        aws_side_asn = aws_ec2_transit_gateway.transit_gateway_resource.amazon_side_asn
    }
}

output "aws_customer_gateway_1" {
    value = {
        id = aws_customer_gateway.customer_gateway_resource_1.id
        azure_side_asn = aws_customer_gateway.customer_gateway_resource_1.bgp_asn
        azure_public_ip = aws_customer_gateway.customer_gateway_resource_1.ip_address
        name = aws_customer_gateway.customer_gateway_resource_1.tags.Name
    }
}

output "aws_customer_gateway_2" {
    value = {
        id = aws_customer_gateway.customer_gateway_resource_2.id
        azure_side_asn = aws_customer_gateway.customer_gateway_resource_2.bgp_asn
        azure_public_ip = aws_customer_gateway.customer_gateway_resource_2.ip_address
        name = aws_customer_gateway.customer_gateway_resource_2.tags.Name
    }
}

output "vpn_connection_1" {
    value = {
        id = aws_vpn_connection.vpn_connection_1.id
        arn = aws_vpn_connection.vpn_connection_1.arn
        customer_gateway_id = aws_vpn_connection.vpn_connection_1.customer_gateway_id
        name = aws_vpn_connection.vpn_connection_1.tags.Name
        transit_gateway_attachment_id = aws_vpn_connection.vpn_connection_1.transit_gateway_attachment_id
    }
}

output "vpn_connection_2" {
    value = {
        id = aws_vpn_connection.vpn_connection_2.id
        arn = aws_vpn_connection.vpn_connection_2.arn
        customer_gateway_id = aws_vpn_connection.vpn_connection_2.customer_gateway_id
        name = aws_vpn_connection.vpn_connection_2.tags.Name
        transit_gateway_attachment_id = aws_vpn_connection.vpn_connection_2.transit_gateway_attachment_id
    }
}