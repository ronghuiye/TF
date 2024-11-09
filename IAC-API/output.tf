output "resources" {
    value = {
        nprod = module.nprod[0].resources
    }
}