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

variable "transit_gateway_id" {
    type = string
}

variable "subnet_ids" {
    type = list(string)
}

variable "vpc_id" {
    type = string
}

variable "dns_forward_rules" {
    type = map(string)
    description = "DNS query forward rules"
}