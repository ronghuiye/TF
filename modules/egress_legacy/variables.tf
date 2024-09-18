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

variable "environment" {
    description = "Egress resource provisioning variables"
    type = object({
        account = string
        name = string
        account_name = string
        vpc = object({
            cidr = string
            subnets = object({
                VPN = object({
                    az1 = string
                    az2 = string
                    az3 = string
                })
                TGW = object({
                    az1 = string
                    az2 = string
                    az3 = string
                })
            })
        })
    })
}

variable "transit_gateway_id" {
    description = "A transit gateway id that's connecting VPCs"
    type = string
}

variable "dns_forward_rules" {
    type = map(string)
    description = "DNS query forward rules"
}