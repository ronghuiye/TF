terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 5.0"
      }
  }
  backend "s3" {

  }
}

module "nprod" {
    count = var.common.deployment == "NPROD" ? 1 : 0
    source = "./modules/nprod"
    providers = { 
        aws.shared = aws.shared
        aws.sbx = aws.sbx
        aws.shared = aws.shared
        aws.shared = aws.shared
        aws.shared = aws.shared
    }
    common = var.common
    environments = var.environments
    services = var.services
}

