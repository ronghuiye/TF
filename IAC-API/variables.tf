variable "common" {
    description = "Common variable across accounts"
    type = object({
        region = string
        region_id = string
        deployment = string
        organization = string
        depllyment_cidr = string
        purpose = string
        shared_account_number = string
        shared_account_name = string
        shared_account_assume_role = string
    })
}

variable "environments" {
    description = "Workload resource provisioning variables"
    type = map(object({
        name = string
        account_name = string
        account_number = string
        assume_role_name = string
    }))
}

variable "services" {
    type = map(object({
        context_path = string
        image_name = string
        protocol = string
        port = number
        desired_count = number
        priority = number
        health_check = object({
            port = number
            path = string
            healthy_threshold = number
            unhealthy_threshold = number
            timeout = number
            interval = number
            health_check_grace_period_seconds = number
        })
        scaling = object({
            desired_capacity = number
            min_capacity = number
            max_capacity = number
            request_per_target = number
            scale_in_cooldown = number
            scale_out_cooldown = number
        })
    }))
}
