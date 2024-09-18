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
        owner_account_assume_role = string
    })
}

variable "environment" {
    description = "DNS resource provisioning variables"
    type = object({
        account = string
        name = string
        account_name = string
        vpc = object({
            cidr = string
            subnets = object({
                RSOL = object({
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

variable "resolver_ip" {
    description = "Resolver IPs in each zone"
    type = object({
        inbound = object({
            az1 = string
            az2 = string
            az3 = string
        })
        outbound = object({
            az1 = string
            az2 = string
            az3 = string
        })
        external = object({
            ip1 = string
            ip2 = string
        })
    })
}

variable "dns_forward_rules" {
    type = map(string)
    description = "DNS query forward rules"
}

variable "wl_leg_vpc" {
    type = object({
        vpc_id = string
        subnet_ids = list(string)
        account = string
        account_name = string
        assume_role_name = string
    })
}