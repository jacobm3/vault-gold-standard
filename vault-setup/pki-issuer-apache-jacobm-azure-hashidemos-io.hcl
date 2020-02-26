# Issue certs
path "pki/issue/apache-jacobm-azure-hashidemos-io" {
   capabilities = ["create","read","update"]
}

# List paths
path "pki/*" {
   capabilities = ["list"]
}
