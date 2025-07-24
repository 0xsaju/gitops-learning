#!/bin/bash
if [[ "$1" == "--list" ]]; then
  IP=$(terraform -chdir=../infra output -raw vm_public_ip)
  cat <<EOF
{
  "web": {
    "hosts": ["$IP"],
    "vars": {
      "ansible_user": "azureuser"
    }
  }
}
EOF
else
  exit 0
fi 