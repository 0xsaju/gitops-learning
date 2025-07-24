#!/bin/bash
IP=$(terraform -chdir=../infra output -raw vm_public_ip)
echo "[web]"
echo "$IP ansible_user=azureuser" 