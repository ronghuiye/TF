output "resources" {
    value = {
        "SBX" = module.sbx.resources
        "DEV" = module.dev.resources
        # "qae" = module.qae.resources
        # "pte" = module.pte.resources
    }
}