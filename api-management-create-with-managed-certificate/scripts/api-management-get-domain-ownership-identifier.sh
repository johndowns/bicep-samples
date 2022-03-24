domainOwnershipIdentifier=$(az rest --method post --uri "/subscriptions/$subscriptionId/providers/Microsoft.ApiManagement/getDomainOwnershipIdentifier?api-version=2021-04-01-preview" | jq -r .domainOwnershipIdentifier)
echo "{\"domainOwnershipIdentifier\": \"$domainOwnershipIdentifier\"}" > $AZ_SCRIPTS_OUTPUT_PATH
