output "resources" {
    value = {
        transit_gateway_attachment = {
            id = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
            name = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.tags_all.Name
        }
    }
}