#!/bin/bash
if [[ "$1" == "--list" ]]; then
  IP=$(terraform -chdir=../infra output -raw vm_public_ip)
  cat <<EOF
{
  "web": {
    "hosts": ["$IP"],
    "vars": {
      "ansible_user": "ubuntu",
      "ansible_ssh_pass": "Ubuntu2024!",
      "ansible_ssh_common_args": "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    }
  }
}
EOF
else
  exit 0
fi 