terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 5.0"
          configuration_aliases = [
              aws.shared,
              aws.sbx,
              aws.dev,
              aws.qae,
              aws.pte
          ]
      }
  }
  backend "s3" {

  }
}

module "sbx" {
    source = "../resources"
    providers = {
        aws = aws.sbx
    }
    common = var.common
    environments = var.environments["SBX"]
    services = var.services
}

data "aws_ssm_parameter" "sbx_record_param" {
    provider = aws.shared
    name = format("/param/%s/%s/%s/service_zone_id", 
        var.common.deployment,
        var.common.organization,
        "SBX"
    )
}

resource "aws_route53_record" "sbx_record" {
    provider = aws.shared
    zone_id = data.aws_ssm_parameter.sbx_record_param.insecure_value
    name = var.common.purpose
    type = "A"
    alias {
        name = module.sbx.resources.internal_alb.dns_name
        zone_id = module.sbx.resources.internal_alb.zone_id
        evaluate_target_health = true
    }
}

module "dev" {
    source = "../resources"
    providers = {
        aws = aws.dev
    }
    common = var.common
    environments = var.environments["DEV"]
    services = var.services
}

data "aws_ssm_parameter" "dev_record_param" {
    provider = aws.shared
    name = format("/param/%s/%s/%s/service_zone_id", 
        var.common.deployment,
        var.common.organization,
        "DEV"
    )
}

resource "aws_route53_record" "dev_record" {
    provider = aws.shared
    zone_id = data.aws_ssm_parameter.dev_record_param.insecure_value
    name = var.common.purpose
    type = "A"
    alias {
        name = module.dev.resources.internal_alb.dns_name
        zone_id = module.dev.resources.internal_alb.zone_id
        evaluate_target_health = true
    }
}