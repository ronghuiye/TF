variable "common_vars" {
    description = "Common variable across accounts"
    type = object({
        region = string
        region_id = string
        deployment = string
        organization = string
        depllyment_cidr = string
        owner = string
        owner_account = string
    })
}

variable "transit_gateway_attachments" {
    type = object({
        transit_gateway_id = string
        vpn_transit_gateway_attachment_id_1 = string
        vpn_transit_gateway_attachment_id_2 = string
        egr_transit_gateway_attachment_id = string
        wl_transit_gateway_attachment_ids = map(string)
        egr_leg_transit_gateway_attachment_id = string
        wl_leg_transit_gateway_attachment_id = string
    })
    description = "Ids of transit gateway"
}

variable "vpn_destinations_from_leg_vpc" {
    type = map(string)
    description = "List of destinations in VPN from legacy vpc"
}