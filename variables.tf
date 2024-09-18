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

variable "gateway_state" {
    type = object({
        backend = string
        workspace = string
        config = object({
            bucket = string
            key = string
            region = string
            encrypt = bool
            dynamodb_table = string
        })
    })
}

variable "dns_environment" {
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

variable "egress_environment" {
    description = "Egress resource provisioning variables"
    type = object({
        account = string
        name = string
        account_name = string
        vpc = object({
            cidr = string
            subnets = object({
                PUB = object({
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

variable "egress_legacy_environment" {
    description = "Legacy egress resource provisioning variables"
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

variable "workload_environments" {
    description = "Workload resource provisioning variables"
    type = map(object({
        account = string
        name = string
        account_name = string
        assume_role_name = string
        vpc = object({
            cidr = string
            subnets = object({
                DB = object({
                    az1 = string
                    az2 = string
                    az3 = string
                })
                APP = object({
                    az1 = string
                    az2 = string
                    az3 = string
                })
                CORE = object({
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
    }))
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

variable "vpn_destinations_from_leg_vpc" {
    type = map(string)
    description = "List of destinations in VPN from legacy vpc"
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