#!/bin/bash

RESOURCE_GROUP_NAME=Demo-Project
DEV_SA_ACCOUNT=tfstatesademoproject
CONTAINER_NAME=tfstate


# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location westeurope

# Create storage account for dev environment
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $DEV_SA_ACCOUNT --sku Standard_LRS --encryption-services blob

# Create blob container for dev environment
az storage container create --name $CONTAINER_NAME --account-name $DEV_SA_ACCOUNT