from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.client import Users
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.container import Docker
from diagrams.azure.database import DatabaseForMysqlServers
try:
    from diagrams.azure.compute import LinuxVirtualMachine
    vm_node = LinuxVirtualMachine
except ImportError:
    from diagrams.generic.os import Ubuntu
    vm_node = Ubuntu

with Diagram("Full Application Workflow & System Architecture", show=False, direction="LR"):
    user = Users("User Browser")
    gh = GithubActions("GitHub Actions")
    dh = Docker("Docker Hub")
    db_az = DatabaseForMysqlServers("Azure MySQL Flexible Server")
    vm = vm_node("Azure VM (Ubuntu)\nDocker + Docker Compose")

    with Cluster("Docker Compose Stack on VM"):
        fe = Docker("Frontend (React):3000")
        be = Docker("Backend (Node.js/Express):4000")
        sql = Docker("MySQL (Container):3306")
        wt = Docker("Watchtower (Auto-update)")

    # User flow
    user >> Edge(label="HTTP") >> fe
    fe >> Edge(label="REST API") >> be
    be >> Edge(label="SQL") >> sql
    vm >> Edge(label="connects") >> db_az

    # CI/CD flow
    gh >> Edge(label="Build & Push") >> dh
    dh >> Edge(label="docker pull") >> vm

    # Docker Compose up flows
    vm >> Edge(style="dotted", label="docker-compose up") >> fe
    vm >> Edge(style="dotted", label="docker-compose up") >> be
    vm >> Edge(style="dotted", label="docker-compose up") >> sql
    vm >> Edge(style="dotted", label="docker-compose up") >> wt

    # Watchtower auto-update
    wt >> Edge(label="Auto-pull new images") >> fe
    wt >> Edge(label="Auto-pull new images") >> be 