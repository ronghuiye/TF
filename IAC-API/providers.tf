provider "aws" {
    region = var.common.region
}

provider "aws" {
    alias = "shared"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.common.shared_account_number, var.common.shared_account_assume_role)
    }
    default_tags {
        tags = {
            "category" = var.common.purpose
            "deployment" = var.common.deployment
        }
    }
}

provider "aws" {
    alias = "sbx"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.environments["SBX"].account_number, var.environments["SBX"].assume_role_name)
    }
    default_tags {
        tags = {
            "category" = var.common.purpose
            "deployment" = var.common.deployment
        }
    }
}

provider "aws" {
    alias = "dev"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.environments["DEV"].account_number, var.environments["DEV"].assume_role_name)
    }
    default_tags {
        tags = {
            "category" = var.common.purpose
            "deployment" = var.common.deployment
        }
    }
}

provider "aws" {
    alias = "qae"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.environments["QAE"].account_number, var.environments["QAE"].assume_role_name)
    }
    default_tags {
        tags = {
            "category" = var.common.purpose
            "deployment" = var.common.deployment
        }
    }
}

provider "aws" {
    alias = "pte"
    assume_role {
        role_arn = format("arn:aws:iam::%s:role/%s", var.environments["PTE"].account_number, var.environments["PTE"].assume_role_name)
    }
    default_tags {
        tags = {
            "category" = var.common.purpose
            "deployment" = var.common.deployment
        }
    }
}