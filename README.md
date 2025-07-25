# GitOps Learning: AWS Terraform + Ansible Deployment

## System Architecture

```mermaid
flowchart TD
  User["User Browser"]
  FE["Frontend (React)\n:3000"]
  BE["Backend (Node.js/Express)\n:4000"]
  SQL["MySQL (Container)\n:3306"]
  WT["Watchtower (Auto-update)"]
  GH["GitHub Actions"]
  DH["Docker Hub"]
  VM["AWS EC2 (Ubuntu 22.04)\nDocker + Docker Compose"]

  User -- "HTTP" --> FE
  FE -- "REST API" --> BE
  BE -- "SQL" --> SQL

  GH -- "Build & Push" --> DH
  DH -- "docker pull" --> VM
  VM -. "docker-compose up" .-> FE
  VM -. "docker-compose up" .-> BE
  VM -. "docker-compose up" .-> SQL
  VM -. "docker-compose up" .-> WT
  WT -- "Auto-pull new images" --> FE
  WT -- "Auto-pull new images" --> BE
```

---

## Prerequisites
- AWS account with access keys configured
- Terraform installed (`brew install terraform` or from terraform.io)
- Ansible installed (`brew install ansible`)
- sshpass installed (`brew install hudochenkov/sshpass/sshpass`)
- Python 3.10+ on your local machine
- Docker Hub account (for pulling images)

---

## Deployment Steps

### 1. **Provision Infrastructure with Terraform**

```sh
cd infra
terraform init
terraform apply
```
- This will create a VPC, subnet, security group, and an EC2 instance (Ubuntu 22.04 LTS, t3.micro, public IP).
- The instance will be initialized with password login (`ubuntu:Ubuntu2024!`) and your public SSH key.

### 2. **Deploy and Configure with Ansible**

```sh
cd ../ansible
ansible-playbook -i inventory.sh playbook.yml
```
- Installs Docker, Docker Compose, MySQL client, and other dependencies
- Downloads DigiCert CA cert
- Templates and deploys the Docker Compose file
- Starts backend, frontend, MySQL, and watchtower containers

---

## SSH Access

- **Username:** `ubuntu`
- **Password:** `Ubuntu2024!`
- **Or use your SSH key (added via Terraform user_data)**
- Example:
  ```sh
  ssh ubuntu@<EC2_PUBLIC_IP>
  # or, if using password:
  sshpass -p 'Ubuntu2024!' ssh ubuntu@<EC2_PUBLIC_IP>
  ```

---

## Application Access
- **Frontend:** http://<EC2_PUBLIC_IP>:3000
- **Backend API:** http://<EC2_PUBLIC_IP>:4000

---

## Notes
- The static `ansible/files/docker-compose.yml` is for Azure; AWS uses the Jinja2 template.
- All infrastructure and app setup is fully automated—no manual steps required on the VM.
- To destroy everything:
  ```sh
  cd infra
  terraform destroy
  ```

---

## Troubleshooting
- Ensure your AWS security group allows inbound ports 22 (SSH), 3000 (frontend), 4000 (backend), and 3306 (MySQL, if needed).
- If Ansible cannot connect, check the public IP and ensure the instance is running and accessible.
- For any issues, check the Terraform and Ansible logs for error messages.
