# GitOps Learning - Flask Microservices

This project demonstrates a complete GitOps workflow with Python Flask microservices, featuring:

## Application Architecture

The application is built using Python Flask microservices architecture with the following components:

- **Frontend Service** (Port 8080): Flask web application for user interface
- **User Service** (Port 5001): User management and authentication
- **Product Service** (Port 5002): Product catalog management
- **Order Service** (Port 5003): Order processing and management

Each service has its own MySQL database:
- User DB (Port 32000)
- Product DB (Port 32001) 
- Order DB (Port 32002)

## System Architecture

```mermaid
flowchart TD
    User["User Browser"]
    FE["Frontend (Flask)\n:8080"]
    US["User Service (Flask)\n:5001"]
    PS["Product Service (Flask)\n:5002"]
    OS["Order Service (Flask)\n:5003"]
    UDB["User DB (MySQL)\n:32000"]
    PDB["Product DB (MySQL)\n:32001"]
    ODB["Order DB (MySQL)\n:32002"]
    WT["Watchtower (Auto-update)"]
    GH["GitHub Actions"]
    DH["Docker Hub"]
    VM["AWS EC2 (Ubuntu 22.04)\nDocker + Docker Compose"]

    User -- "HTTP" --> FE
    FE -- "REST API" --> US
    FE -- "REST API" --> PS
    FE -- "REST API" --> OS
    US -- "SQL" --> UDB
    PS -- "SQL" --> PDB
    OS -- "SQL" --> ODB

    GH -- "Build & Push" --> DH
    DH -- "docker pull" --> VM
    VM -. "docker-compose up" .-> FE
    VM -. "docker-compose up" .-> US
    VM -. "docker-compose up" .-> PS
    VM -. "docker-compose up" .-> OS
    VM -. "docker-compose up" .-> UDB
    VM -. "docker-compose up" .-> PDB
    VM -. "docker-compose up" .-> ODB
    VM -. "docker-compose up" .-> WT
    WT -- "Auto-pull new images" --> FE
    WT -- "Auto-pull new images" --> US
    WT -- "Auto-pull new images" --> PS
    WT -- "Auto-pull new images" --> OS
```

### Microservices Design Pattern

The application follows a **Microservices Architecture** pattern where each service is:
- **Independently deployable**: Each service can be deployed, updated, and scaled independently
- **Loosely coupled**: Services communicate through well-defined APIs
- **Single responsibility**: Each service handles a specific business domain
- **Database per service**: Each service owns its data and database

### Service Communication

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Frontend Service                               │
│                              (Port 8080)                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │   User Module   │  │  Product Module │  │   Order Module  │              │
│  │                 │  │                 │  │                 │              │
│  │ • Registration  │  │ • Browse Catalog│  │ • Shopping Cart │              │
│  │ • Authentication│  │ • Product Search│  │ • Checkout      │              │
│  │ • Profile Mgmt  │  │ • Product Details│  │ • Order History │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │User Service │ │Product Svc  │ │Order Service│
            │  (5001)     │ │  (5002)     │ │  (5003)     │
            └─────────────┘ └─────────────┘ └─────────────┘
                    │               │               │
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │  User DB    │ │ Product DB  │ │  Order DB   │
            │  (32000)    │ │  (32001)    │ │  (32002)    │
            └─────────────┘ └─────────────┘ └─────────────┘
```

### Data Flow Architecture

#### 1. User Registration Flow
```
Frontend → User Service → User Database
    ↓           ↓              ↓
HTTP POST → Flask Route → MySQL Insert
```

#### 2. Product Browsing Flow
```
Frontend → Product Service → Product Database
    ↓           ↓              ↓
HTTP GET → Flask Route → MySQL Select
```

#### 3. Order Processing Flow
```
Frontend → Order Service → Order Database
    ↓           ↓              ↓
HTTP POST → Flask Route → MySQL Insert
```

### Service Responsibilities

#### Frontend Service (Port 8080)
- **Purpose**: Single-page application serving the user interface
- **Technologies**: Flask, Jinja2 templates, Bootstrap
- **Features**:
  - User registration and login forms
  - Product catalog display
  - Shopping cart management
  - Order checkout process
  - User profile management

#### User Service (Port 5001)
- **Purpose**: User management and authentication
- **API Endpoints**:
  - `POST /api/user/register` - User registration
  - `POST /api/user/login` - User authentication
  - `GET /api/user/profile` - Get user profile
  - `PUT /api/user/profile` - Update user profile
- **Database Schema**:
  - Users table (id, username, email, password_hash, created_at, updated_at)

#### Product Service (Port 5002)
- **Purpose**: Product catalog management
- **API Endpoints**:
  - `GET /api/product/list` - List all products
  - `GET /api/product/<id>` - Get product details
  - `POST /api/product/create` - Create new product
  - `PUT /api/product/<id>` - Update product
  - `DELETE /api/product/<id>` - Delete product
- **Database Schema**:
  - Products table (id, name, slug, image, price, created_at, updated_at)

#### Order Service (Port 5003)
- **Purpose**: Order processing and management
- **API Endpoints**:
  - `POST /api/order/create` - Create new order
  - `GET /api/order/list` - List user orders
  - `GET /api/order/<id>` - Get order details
  - `PUT /api/order/<id>/status` - Update order status
- **Database Schema**:
  - Orders table (id, user_id, total_amount, status, created_at, updated_at)
  - Order_items table (id, order_id, product_id, quantity, price)

### Infrastructure Architecture

#### Development Environment
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Docker Compose Network                            │
│                              (micro_network)                                │
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Frontend  │  │ User Service│  │Product Svc  │  │Order Service│        │
│  │   (8080)    │  │   (5001)    │  │   (5002)    │  │   (5003)    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                 │                 │                 │            │
│         └─────────────────┼─────────────────┼─────────────────┘            │
│                           │                 │                 │            │
│                    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│                    │  User DB    │  │ Product DB  │  │  Order DB   │        │
│                    │  (32000)    │  │  (32001)    │  │  (32002)    │        │
│                    └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Production Environment
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Load Balancer                                  │
│                              (Nginx/AWS ALB)                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │Frontend Pod │ │User Svc Pod │ │Product Pod  │
            │  (K8s)      │ │  (K8s)      │ │  (K8s)      │
            └─────────────┘ └─────────────┘ └─────────────┘
                    │               │               │
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │  User DB    │ │ Product DB  │ │  Order DB   │
            │  (RDS)      │ │  (RDS)      │ │  (RDS)      │
            └─────────────┘ └─────────────┘ └─────────────┘
```

### Security Architecture

#### Authentication & Authorization
- **JWT Tokens**: Stateless authentication using JSON Web Tokens
- **Password Hashing**: bcrypt for secure password storage
- **CORS**: Cross-Origin Resource Sharing configuration
- **Input Validation**: Request validation and sanitization

#### Network Security
- **Docker Networks**: Isolated network communication between services
- **Port Mapping**: Controlled exposure of service ports
- **Environment Variables**: Secure configuration management

### Scalability Considerations

#### Horizontal Scaling
- **Stateless Services**: Frontend, User, Product, and Order services can be scaled horizontally
- **Load Balancing**: Multiple instances can be deployed behind a load balancer
- **Database Scaling**: Each service database can be scaled independently

#### Vertical Scaling
- **Resource Allocation**: Docker containers can be configured with specific CPU/memory limits
- **Database Optimization**: Indexing, query optimization, and connection pooling

### Monitoring & Observability

#### Logging
- **Structured Logging**: JSON-formatted logs for easy parsing
- **Centralized Logging**: All service logs can be aggregated
- **Log Levels**: DEBUG, INFO, WARNING, ERROR levels

#### Health Checks
- **Service Health**: `/health` endpoints for each service
- **Database Connectivity**: Connection health monitoring
- **Dependency Checks**: Service dependency validation

### Data Architecture

#### Database Design
- **Database per Service**: Each microservice owns its data
- **ACID Compliance**: Transactional integrity within each service
- **Data Consistency**: Eventual consistency across services

#### Data Flow Patterns
- **Synchronous Communication**: HTTP REST APIs for immediate responses
- **Asynchronous Communication**: Message queues for event-driven communication (future enhancement)
- **Data Replication**: Read replicas for improved performance (production)

## DevOps Infrastructure

### Infrastructure as Code (Terraform)
- **Location**: `infra/`
- **Purpose**: Provision cloud infrastructure (AWS/Azure/GCP)
- **Components**: VMs, networking, security groups, load balancers

### Configuration Management (Ansible)
- **Location**: `ansible/`
- **Purpose**: System configuration and application deployment
- **Components**: Playbooks for server setup, Docker installation, application deployment

### CI/CD Pipeline (GitHub Actions)
- **Location**: `.github/workflows/`
- **Purpose**: Automated testing, building, and deployment
- **Components**: Build Docker images, run tests, deploy to staging/production

## Local Development Setup

### Prerequisites
- Docker and Docker Compose
- Python 3.8+
- Git

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd gitops-learning
   ```

2. **Create Docker network**:
   ```bash
   docker network create micro_network
   ```

3. **Build and start services**:
   ```bash
   docker-compose up --build
   ```

4. **Initialize databases**:
   ```bash
   # Initialize user service database
   docker exec -it cuser-service flask db init
   docker exec -it cuser-service flask db migrate
   docker exec -it cuser-service flask db upgrade
   
   # Initialize product service database
   docker exec -it cproduct-service flask db init
   docker exec -it cproduct-service flask db migrate
   docker exec -it cproduct-service flask db upgrade
   
   # Initialize order service database
   docker exec -it corder-service flask db init
   docker exec -it corder-service flask db migrate
   docker exec -it corder-service flask db upgrade
   ```

5. **Populate product database**:
   ```bash
   curl -i -d "name=prod1&slug=prod1&image=product1.jpg&price=100" -X POST localhost:5002/api/product/create
   curl -i -d "name=prod2&slug=prod2&image=product2.jpg&price=200" -X POST localhost:5002/api/product/create
   ```

6. **Access the application**:
   - Frontend: http://localhost:8080
   - User API: http://localhost:5001
   - Product API: http://localhost:5002
   - Order API: http://localhost:5003

## Testing the Application

1. **Register a new user**: http://localhost:5000/register
2. **Login**: http://localhost:5000/login
3. **Browse products and add to cart**
4. **Complete checkout process**

## Production Deployment

### Using Terraform + Ansible + GitHub Actions

1. **Infrastructure Provisioning**:
   ```bash
   cd infra
   terraform init
   terraform plan
   terraform apply
   ```

2. **System Configuration**:
   ```bash
   cd ansible
   ansible-playbook -i inventory playbook.yml
   ```

3. **Application Deployment**:
   - Push to main branch triggers GitHub Actions
   - Automated build and deployment to production

## Service Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frontend  │    │ User Service│    │Product Svc  │    │Order Service│
│   (8080)    │    │   (5001)    │    │   (5002)    │    │   (5003)    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       └───────────────────┼───────────────────┼───────────────────┘
                           │                   │                   │
                    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
                    │  User DB    │    │ Product DB  │    │  Order DB   │
                    │  (32000)    │    │  (32001)    │    │  (32002)    │
                    └─────────────┘    └─────────────┘    └─────────────┘
```

## Technology Stack

### Application
- **Python Flask**: Web framework for microservices
- **MySQL**: Database for each service
- **Docker**: Containerization
- **Docker Compose**: Local development orchestration

### DevOps
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration Management
- **GitHub Actions**: CI/CD Pipeline
- **Docker**: Container orchestration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
