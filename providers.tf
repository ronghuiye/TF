provider "aws" {
    region = var.common_vars.region
}

provider "aws" {
    alias = "SHARED"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.common_vars.owner_account, var.common_vars.owner_account_assume_role)
    }
    default_tags {
        tags = {
            "category" = "Network"
            "deployment" = var.common_vars.deployment
        }
    }
}

provider "aws" {
    alias = "leg"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.wl_leg_vpc.account, var.wl_leg_vpc.assume_role_name)
    }
}