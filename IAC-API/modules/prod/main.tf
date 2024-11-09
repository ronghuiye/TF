terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 5.0"
          configuration_aliases = [
              aws.stg,
              aws.prod
          ]
      }
  }
}

module "stg" {
    source = "../resources"
    providers = {
        aws = aws.stg
    }
    common = var.common
    environments = var.environments["stg"]
}