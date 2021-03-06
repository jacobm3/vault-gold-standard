# CREATE NAMESPACES
vault namespace create geo-us
vault namespace create -namespace=geo-us ops
vault namespace create -namespace=geo-us dev

vault namespace create geo-eu
vault namespace create -namespace=geo-eu ops
vault namespace create -namespace=geo-eu dev

vault namespace create geo-apac
vault namespace create -namespace=geo-apac ops
vault namespace create -namespace=geo-apac dev


# CREATE NAMESPACE POLICIES
vault policy write -namespace=geo-us/ops ops-space-admin space-admin.hcl

vault policy write -namespace=geo-us/ops ops-pki-admin pki-admin.hcl

vault token create -namespace=geo-us/ops -policy=ops-space-admin -policy=ops-pki-admin



# SETUP PKI SECRETS ENGINE

export VAULT_NAMESPACE=geo-us/ops
vault secrets enable pki

vault secrets tune -max-lease-ttl=87600h pki

vault write pki/root/generate/internal common_name=hashicorp.com ttl=87600h

vault write pki/config/urls \
    issuing_certificates="http://vault.hashicorp.com:8200/v1/pki/ca" \
    crl_distribution_points="http://vault.hashicorp.com:8200/v1/pki/crl"

# Create roles
vault write -namespace=geo-us/ops \
    pki/roles/hashicorp-test-dot-com \
    allowed_domains=hashicorp-test.com \
    allow_bare_domains=true \
    allow_subdomains=true max_ttl=72h

vault write -namespace=geo-us/ops \
    pki/roles/apache-jacobm-azure-hashidemos-io \
    allowed_domains=apache.jacobm.azure.hashidemos.io \
    allow_bare_domains=true \
    allow_subdomains=true max_ttl=72h

# Policy for Hashicorp Test cert user
vault policy write -namespace=geo-us/ops \
  pki-generator-hashicorp-test-dot-com \
  pki-generator-hashicorp-test-dot-com.hcl

vault token create -namespace=geo-us/ops \
  -policy=pki-generator-hashicorp-test-dot-com

# Policy for apache-jacobm cert user
vault policy write -namespace=geo-us/ops \
  pki-issuer-apache-jacobm-azure-hashidemos-io \
  pki-issuer-apache-jacobm-azure-hashidemos-io.hcl

vault token create -namespace=geo-us/ops -policy=pki-issuer-apache-jacobm-azure-hashidemos-io

vault write -namespace=geo-us/ops pki/issue/hashicorp-test-dot-com \
    common_name=app1.hashicorp-test.com


# MSI
export VAULT_NAMESPACE=geo-us/ops

vault auth enable azure

# https://www.vaultproject.io/api/auth/azure/index.html#parameters-1
vault write auth/azure/config \
   tenant_id=$ARM_TENANT_ID \
   resource=https://management.azure.com/ \
   client_id=$ARM_CLIENT_ID \
   client_secret=$ARM_CLIENT_SECRET

vault write auth/azure/role/apache-jacobm-azure-hashidemos-io \
   policies="pki-issuer-apache-jacobm-azure-hashidemos-io" \
   bound_subscription_ids=$ARM_SUBSCRIPTION_ID \
   bound_resource_groups=jmartinson-rg \
   token_ttl=24h \
   token_max_ttl=168h

vault secrets enable -version=2 kv
vault kv put kv/my-secret my-value=s3cr3t

