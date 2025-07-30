#!/bin/bash

# Ensure we're in the right directory
cd "$(dirname "$0")" || exit

if [[ "$1" == "--list" ]]; then
  IP=$(terraform -chdir=../infra output -raw instance_public_ip 2>/dev/null)
  if [ -z "$IP" ]; then
    echo "Error: Could not get IP from Terraform" >&2
    exit 1
  fi

  cat <<EOF
{
  "web": {
    "hosts": ["$IP"],
    "vars": {
      "ansible_user": "ubuntu",
      "ansible_ssh_private_key_file": "~/.ssh/gitops-key",
      "ansible_become": "yes",
      "ansible_become_method": "sudo",
      "ansible_become_user": "ubuntu",
      "ansible_ssh_common_args": "-o StrictHostKeyChecking=no -o PubkeyAuthentication=yes -o PasswordAuthentication=no -o PreferredAuthentications=publickey -o IdentitiesOnly=yes -o KbdInteractiveAuthentication=no -o GSSAPIAuthentication=no -o ConnectTimeout=60 -o ServerAliveInterval=60 -o ServerAliveCountMax=3"
    }
  },
  "_meta": {
    "hostvars": {}
  }
}
EOF
else
  echo "{}"
fi