#!/bin/bash

CERT_FILE=/etc/pki/tls/certs/localhost.crt
KEY_FILE=/etc/pki/tls/private/localhost.key

VAULT_ADDR=https://vault.jacobm.azure.hashidemos.io:8200/
export VAULT_ADDR

echo
echo -n "NEW RUN: "
date


export VAULT_NAMESPACE=geo-us/ops
json=$(/usr/local/bin/vault write auth/azure/login -format=json role="apache-jacobm-azure-hashidemos-io" \
     jwt=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' \
                -H Metadata:true | jq -r .access_token) \
     subscription_id=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | \
         jq -r '.compute | .subscriptionId')  \
     resource_group_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | \
         jq -r '.compute | .resourceGroupName') \
     vm_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | \
         jq -r '.compute | .name') )

export VAULT_TOKEN=$(echo $json | jq -r .auth.client_token)


echo "Retrieving new certificate and private key from Vault"
json=$( /usr/local/bin/vault write -format=json \
          -namespace=geo-us/ops \
          pki/issue/apache-jacobm-azure-hashidemos-io \
          common_name=apache.jacobm.azure.hashidemos.io \
          format=pem)

echo $json
