# 🗄️ Oficina Mecânica Inteligente - Infraestrutura de Banco de Dados

Infraestrutura como Código (IaC) para o banco de dados MySQL 8.4 na AWS usando Terraform, Flyway para migrations e GitHub Actions para CI/CD.

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Pré-requisitos](#-pré-requisitos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Arquitetura](#-arquitetura)
- [Deploy da Infraestrutura](#-deploy-da-infraestrutura)
  - [Deploy Local (Docker)](#deploy-local-docker)
  - [Deploy na AWS](#deploy-na-aws)
- [Gestão de Migrations](#-gestão-de-migrations)
- [Conexão com o Banco de Dados](#-conexão-com-o-banco-de-dados)
- [Pipeline CI/CD](#-pipeline-cicd)
- [Monitoramento](#-monitoramento)
- [Backup e Recuperação](#-backup-e-recuperação)
- [Relatório de Custos](#-relatório-de-custos)
- [Segurança](#-segurança)
- [Troubleshooting](#-troubleshooting)
- [Destruição da Infraestrutura](#-destruição-da-infraestrutura)

---

## 🎯 Visão Geral

Este repositório gerencia toda a infraestrutura de banco de dados para o projeto Oficina Mecânica Inteligente da FIAP/SOAT, incluindo:

- **AWS RDS MySQL 8.4.3** - Banco de dados gerenciado na nuvem
- **Terraform** - Provisionamento declarativo da infraestrutura
- **Flyway** - Versionamento e controle de migrations do schema
- **Docker Compose** - Ambiente de desenvolvimento local
- **GitHub Actions** - Automação de deploy e CI/CD
- **S3 + DynamoDB** - Backend remoto para estado do Terraform

### Por que essas tecnologias?

**AWS RDS MySQL**
- ✅ Banco gerenciado (sem necessidade de manutenção de SO)
- ✅ Backups automáticos e point-in-time recovery
- ✅ Alta disponibilidade com Multi-AZ (quando necessário)
- ✅ Performance Insights para monitoramento
- ✅ Escalabilidade vertical e horizontal

**Terraform**
- ✅ Infraestrutura como código versionada no Git
- ✅ Previsibilidade com `plan` antes de aplicar mudanças
- ✅ Estado compartilhado entre equipe via S3
- ✅ Reutilizável em múltiplos ambientes (dev/staging/prod)

**Flyway**
- ✅ Controle de versão do schema do banco
- ✅ Migrations idempotentes e reversíveis
- ✅ Histórico completo de alterações
- ✅ Validação automática de integridade

**GitHub Actions**
- ✅ CI/CD nativo do GitHub
- ✅ Autenticação OIDC segura (sem access keys)
- ✅ Validação automática em Pull Requests
- ✅ Deploy automático ao fazer merge na main

---

## ✅ Pré-requisitos

### Para Desenvolvimento Local

- [Docker](https://docs.docker.com/get-docker/) 20.10+ e [Docker Compose](https://docs.docker.com/compose/install/) 2.0+
- [Git](https://git-scm.com/downloads) para clonar o repositório
- *(Opcional)* [MySQL Client](https://dev.mysql.com/downloads/shell/) ou [DataGrip](https://www.jetbrains.com/datagrip/) para conectar ao banco

### Para Deploy na AWS

- [AWS CLI](https://aws.amazon.com/cli/) 2.x configurado
- [Terraform](https://www.terraform.io/downloads) 1.5+
- Conta AWS com permissões de administrador
- Acesso ao repositório GitHub

### Recursos AWS Necessários

- **VPC** com pelo menos 2 subnets em AZs diferentes
- **IAM Role** com permissões para RDS, EC2, IAM, S3 e DynamoDB
- **OIDC Provider** configurado para GitHub Actions (instruções abaixo)

---

## 📁 Estrutura do Projeto

```
fiap-soat-oficina-mecanica-infrastructure-database/
│
├── .github/
│   └── workflows/                    # Workflows do GitHub Actions
│       ├── terraform-deploy.yml      # Deploy e migrations
│       ├── terraform-plan.yml        # Preview de mudanças em PRs
│       ├── terraform-validate.yml    # Validação de sintaxe
│       └── sql-validation.yml        # Validação de SQL
│
├── terraform/                        # Configuração Terraform
│   ├── backend-setup/                # Infraestrutura do backend S3
│   │   ├── main.tf                   # Criação de bucket e DynamoDB
│   │   └── README.md                 # Instruções de setup
│   │
│   ├── backend.tf                    # Configuração do backend remoto
│   ├── main.tf                       # Configuração principal
│   ├── variables.tf                  # Definição de variáveis
│   ├── outputs.tf                    # Outputs (endpoint, etc)
│   ├── rds.tf                        # Recursos RDS
│   ├── terraform.tfvars.example      # Exemplo de variáveis
│   └── .terraform.lock.hcl           # Lock de versões de providers
│
├── migrations/
│   └── sql/                          # Migrations SQL do Flyway
│       ├── V1__create_initial_schema.sql
│       ├── V2__add_customers_table.sql
│       ├── V3__add_vehicles_table.sql
│       └── V4__add_service_orders_table.sql
│
├── docker-compose.yml                # Ambiente local MySQL + Flyway
├── .env.example                      # Variáveis de ambiente locais
├── Makefile                          # Comandos úteis
└── README.md                         # Esta documentação
```

---

## 🏗️ Arquitetura

### Diagrama de Infraestrutura

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC (us-west-2)                          │ │
│  │                                                              │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │            DB Subnet Group                            │  │ │
│  │  │  ┌───────────────────┐  ┌───────────────────┐       │  │ │
│  │  │  │ Subnet us-west-2a │  │ Subnet us-west-2b │       │  │ │
│  │  │  └─────────┬─────────┘  └─────────┬─────────┘       │  │ │
│  │  │            │                       │                  │  │ │
│  │  │            └───────────┬───────────┘                  │  │ │
│  │  │                        │                              │  │ │
│  │  │           ┌────────────▼──────────────┐              │  │ │
│  │  │           │  RDS MySQL 8.4.3          │              │  │ │
│  │  │           │  smart-workshop-dev-db    │              │  │ │
│  │  │           │  ├─ db.t4g.micro          │              │  │ │
│  │  │           │  ├─ 20GB gp3 Storage      │              │  │ │
│  │  │           │  ├─ Publicly Accessible   │              │  │ │
│  │  │           │  ├─ Encrypted at rest     │              │  │ │
│  │  │           │  └─ Backup: 1 day         │              │  │ │
│  │  │           └───────────────────────────┘              │  │ │
│  │  │                        ▲                              │  │ │
│  │  └────────────────────────┼──────────────────────────────┘  │ │
│  │                           │                                  │ │
│  │           ┌───────────────┴──────────────┐                  │ │
│  │           │   Security Group              │                  │ │
│  │           │   - Port 3306 TCP             │                  │ │
│  │           │   - Source: 0.0.0.0/0 (dev)   │                  │ │
│  │           └───────────────────────────────┘                  │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │               Remote State Management                       │ │
│  │                                                              │ │
│  │  ┌─────────────────────┐    ┌──────────────────────────┐  │ │
│  │  │ S3 Bucket            │    │ DynamoDB Table           │  │ │
│  │  │ smart-workshop-      │    │ smart-workshop-          │  │ │
│  │  │ terraform-state      │    │ terraform-locks          │  │ │
│  │  │ ├─ Versioned         │    │ └─ State Locking         │  │ │
│  │  │ └─ Encrypted         │    │                          │  │ │
│  │  └─────────────────────┘    └──────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                           ▲
                           │
                  ┌────────┴─────────┐
                  │                  │
         ┌────────▼────────┐  ┌──────▼──────┐
         │ GitHub Actions  │  │ Desenvol-   │
         │ (CI/CD)         │  │ vedores     │
         │ - Deploy        │  │ - Local Dev │
         │ - Migrations    │  │ - DataGrip  │
         └─────────────────┘  └─────────────┘
```

### Componentes e Justificativas

**1. RDS Instance (`db.t4g.micro`)**
- Instância ARM Graviton2 de baixo custo (~$12/mês)
- Adequada para ambientes de desenvolvimento e baixo volume
- Pode escalar para `db.t4g.small/medium` conforme necessidade

**2. Storage (`20GB gp3`)**
- SSD de propósito geral com melhor custo-benefício
- 3000 IOPS baseline (adequado para workloads médios)
- Auto-scaling até 50GB configurado

**3. Security Group**
- Aberto para `0.0.0.0/0` apenas em DEV (GitHub Actions precisa acessar)
- **IMPORTANTE**: Em produção, restringir para IPs específicos ou usar VPN/Bastion

**4. Publicly Accessible = true**
- Facilita desenvolvimento e acesso via DataGrip
- Em produção, considerar `false` e usar VPN ou AWS Systems Manager Session Manager

**5. Single-AZ**
- Economia de custos em desenvolvimento
- Em produção, ativar Multi-AZ para alta disponibilidade

**6. Backup Retention (1 dia)**
- Mínimo do Free Tier
- Em produção, aumentar para 7-35 dias

**7. S3 Backend**
- Estado do Terraform compartilhado entre pipeline e desenvolvedores
- Previne conflitos e perda de estado local
- Versionamento habilitado para auditoria

**8. DynamoDB Locking**
- Previne aplicação concorrente do Terraform por múltiplos agentes
- Pay-per-request (custo praticamente zero)

---

## 🚀 Deploy da Infraestrutura

### Deploy Local (Docker)

Ideal para desenvolvimento local antes de provisionar na AWS.

#### 1. Clonar o Repositório

```bash
git clone https://github.com/FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database.git
cd fiap-soat-oficina-mecanica-infrastructure-database
```

#### 2. Configurar Variáveis de Ambiente

```bash
cp .env.example .env
nano .env
```

Ajuste as variáveis conforme necessário:

```bash
# .env
MYSQL_ROOT_PASSWORD=root_password_123
MYSQL_DATABASE=smart_workshop
MYSQL_USER=workshop_user
MYSQL_PASSWORD=workshop_pass_456
```

#### 3. Iniciar o Ambiente

```bash
# Subir MySQL e executar migrations automaticamente
docker-compose up -d

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs -f mysql
```

#### 4. Conectar ao Banco Local

```bash
# Usando MySQL CLI
mysql -h 127.0.0.1 -P 3306 -u workshop_user -p smart_workshop

# Ou via Docker
docker exec -it smart-workshop-db mysql -u workshop_user -p smart_workshop
```

#### 5. Executar Migrations Manualmente

```bash
# Rodar migrations
docker-compose run --rm flyway migrate

# Ver status
docker-compose run --rm flyway info

# Validar migrations
docker-compose run --rm flyway validate
```

#### 6. Parar o Ambiente

```bash
# Parar serviços
docker-compose down

# Parar e remover volumes (⚠️ DELETA TODOS OS DADOS)
docker-compose down -v
```

---

### Deploy na AWS

#### Passo 1: Configurar Backend Remoto (Apenas uma vez)

Antes de provisionar o RDS, crie o bucket S3 e tabela DynamoDB para armazenar o estado do Terraform:

```bash
cd terraform/backend-setup
terraform init
terraform apply
```

**O que será criado:**
- Bucket S3: `smart-workshop-terraform-state` (versionado, criptografado)
- Tabela DynamoDB: `smart-workshop-terraform-locks` (pay-per-request)
- **Custo**: ~$0.10/mês (praticamente grátis)

#### Passo 2: Configurar AWS OIDC Provider

**2.1. Criar OIDC Provider no IAM:**

1. Acesse o [Console IAM](https://console.aws.amazon.com/iam/)
2. Vá em **Identity Providers** → **Add Provider**
3. Configurações:
   - **Provider Type**: OpenID Connect
   - **Provider URL**: `https://token.actions.githubusercontent.com`
   - **Audience**: `sts.amazonaws.com`
4. Clique em **Add Provider**

**2.2. Criar IAM Role para GitHub Actions:**

Crie uma role com a seguinte Trust Policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::SUA_CONTA_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database:*"
        }
      }
    }
  ]
}
```

**2.3. Anexar Policies à Role:**

Anexe as seguintes managed policies:
- `AmazonRDSFullAccess`
- `AmazonVPCFullAccess`
- `IAMFullAccess`

E crie uma inline policy para acesso ao S3/DynamoDB:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::smart-workshop-terraform-state/*"
    },
    {
      "Sid": "TerraformStateS3List",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::smart-workshop-terraform-state"
    },
    {
      "Sid": "TerraformStateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-west-2:SUA_CONTA_ID:table/smart-workshop-terraform-locks"
    }
  ]
}
```

#### Passo 3: Configurar Secrets no GitHub

No repositório GitHub, vá em **Settings** → **Secrets and variables** → **Actions**:

**Secrets Obrigatórios:**

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `AWS_ROLE_ARN` | ARN da role IAM criada | `arn:aws:iam::123456789:role/GitHubActionsRole` |
| `DB_PASSWORD` | Senha do banco (mínimo 8 caracteres) | `MinhaSenh@Segura123!` |
| `VPC_ID` | ID da sua VPC | `vpc-0abc123def456` |
| `SUBNET_IDS` | Array JSON com 2+ subnets | `["subnet-abc123", "subnet-def456"]` |
| `ALLOWED_CIDR_BLOCKS` | IPs permitidos (JSON array) | `["0.0.0.0/0"]` (dev) ou `["203.0.113.0/24"]` |

**Variables (opcional):**

| Variable | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `AWS_REGION` | `us-east-1` | Região AWS |

#### Passo 4: Obter Informações da AWS

**4.1. Descobrir VPC ID:**

```bash
aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`true\`].VpcId" --output text
```

**4.2. Listar Subnets (precisa de 2 em AZs diferentes):**

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=SEU_VPC_ID" \
  --query "Subnets[].[SubnetId,AvailabilityZone,CidrBlock]" \
  --output table
```

Escolha 2 subnets em AZs diferentes e monte o JSON:
```json
["subnet-abc123def", "subnet-456ghi789"]
```

**4.3. Obter seu IP público (para desenvolvimento):**

```bash
curl https://checkip.amazonaws.com
```

Monte o JSON:
```json
["SEU_IP/32"]
```

#### Passo 5: Configurar Variáveis Terraform (Deploy Local)

Se quiser rodar o Terraform localmente ao invés do pipeline:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Preencha os valores:

```hcl
# terraform/terraform.tfvars

# Região AWS
aws_region = "us-west-2"

# Ambiente
environment  = "dev"
project_name = "smart-workshop"

# Credenciais do Banco
db_name     = "smart_workshop"
db_username = "admin"
db_password = "SuaSenhaSegura123!"  # ⚠️ NÃO COMMITAR ESTE ARQUIVO!

# Instância RDS
db_instance_class       = "db.t4g.micro"
db_allocated_storage    = 20
db_max_allocated_storage = 50

# Rede
vpc_id     = "vpc-0abc123def456"
subnet_ids = [
  "subnet-abc123def",  # us-west-2a
  "subnet-456ghi789",  # us-west-2b
]

# Segurança (⚠️ 0.0.0.0/0 apenas para DEV!)
allowed_cidr_blocks = ["0.0.0.0/0"]

# Backup
backup_retention_period = 1  # Free tier
backup_window           = "03:00-04:00"
maintenance_window      = "mon:04:00-mon:05:00"

# Otimizações de Custo
multi_az                     = false
publicly_accessible          = true
performance_insights_enabled = false
deletion_protection          = false
skip_final_snapshot          = true
```

**⚠️ IMPORTANTE:** Adicione `terraform.tfvars` ao `.gitignore` para não commitar senhas!

#### Passo 6: Executar Deploy

**Opção A: Via GitHub Actions (Recomendado)**

1. Faça push das mudanças para a branch `main`
2. Acesse **Actions** no GitHub
3. Selecione o workflow **"🚀 Deploy Infrastructure"**
4. Clique em **"Run workflow"**
5. Escolha **"apply"**
6. Aguarde ~5-10 minutos

O pipeline irá:
- ✅ Inicializar Terraform com backend S3
- ✅ Provisionar RDS MySQL
- ✅ Aguardar RDS ficar disponível
- ✅ Executar migrations automaticamente via Flyway

**Opção B: Deploy Local via Terraform**

```bash
cd terraform

# Inicializar (migra state para S3)
terraform init

# Validar configuração
terraform validate

# Preview das mudanças
terraform plan

# Aplicar (cria infraestrutura)
terraform apply

# Pegar informações de conexão
terraform output
```

#### Passo 7: Verificar Deploy

Após o deploy bem-sucedido:

```bash
# Ver endpoint do RDS
terraform output rds_endpoint

# Ver comando de conexão MySQL
terraform output mysql_cli_command

# Listar todas as tabelas criadas pelas migrations
terraform output -raw rds_address | xargs -I {} mysql -h {} -P 3306 -u admin -p -e "SHOW TABLES;" smart_workshop
```

---

## 🔄 Gestão de Migrations

### Conceito

O Flyway mantém um histórico de todas as migrations aplicadas na tabela `flyway_schema_history`. Cada migration tem uma versão sequencial e nunca deve ser alterada após aplicada.

### Estrutura de uma Migration

```sql
-- migrations/sql/V5__add_mechanics_table.sql
-- Versão: V5
-- Descrição: add_mechanics_table (separado por underscores)

CREATE TABLE mechanics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    specialization VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Convenção de Nomenclatura

```
V{VERSÃO}__{DESCRIÇÃO}.sql

- VERSÃO: Número inteiro sequencial (V1, V2, V3, ...)
- __: Duplo underscore (obrigatório)
- DESCRIÇÃO: Snake_case descritivo
```

**Exemplos:**
- ✅ `V1__create_initial_schema.sql`
- ✅ `V2__add_customers_table.sql`
- ✅ `V10__add_index_to_email.sql`
- ❌ `V1_create_schema.sql` (underscore único)
- ❌ `v2__add-table.sql` (V minúsculo, hífen na descrição)

### Criar uma Nova Migration

1. **Criar arquivo SQL:**

```bash
# Próxima versão é V5
nano migrations/sql/V5__add_payments_table.sql
```

2. **Escrever SQL:**

```sql
CREATE TABLE payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    status VARCHAR(20) DEFAULT 'PENDING',
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES service_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

3. **Testar localmente:**

```bash
# Subir MySQL local
docker-compose up -d mysql

# Rodar nova migration
docker-compose run --rm flyway migrate

# Verificar aplicação
docker-compose run --rm flyway info
```

4. **Commitar e fazer push:**

```bash
git add migrations/sql/V5__add_payments_table.sql
git commit -m "feat: add payments table migration"
git push origin main
```

5. **Pipeline aplica automaticamente na AWS**

### Verificar Status das Migrations

**Localmente:**
```bash
docker-compose run --rm flyway info
```

**Na AWS:**
```bash
# Via MySQL
mysql -h SEU_RDS_ENDPOINT -u admin -p -e "SELECT * FROM flyway_schema_history;" smart_workshop

# Ou via Terraform output
terraform output -raw mysql_cli_command | bash -c "$(cat -) -e 'SELECT * FROM flyway_schema_history;'"
```

### Regras de Ouro

❌ **NUNCA alterar uma migration já aplicada**
✅ **Sempre criar uma nova migration para correções**

```sql
-- ❌ ERRADO: Editar V2__add_customers_table.sql depois de aplicada

-- ✅ CORRETO: Criar V6__fix_customers_table.sql
ALTER TABLE customers ADD COLUMN phone VARCHAR(20);
```

---

## 🔌 Conexão com o Banco de Dados

### Obter Informações de Conexão

```bash
cd terraform
terraform output
```

Saída:
```
rds_endpoint = "smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com:3306"
rds_address = "smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com"
database_name = "smart_workshop"
mysql_cli_command = "mysql -h smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com -P 3306 -u admin -p smart_workshop"
```

### DataGrip / IntelliJ Database Tools

1. **Abrir DataGrip** → **File** → **New** → **Data Source** → **MySQL**

2. **Preencher campos:**
   - **Host**: Copie de `terraform output rds_address`
   - **Port**: `3306`
   - **Database**: `smart_workshop`
   - **User**: `admin`
   - **Password**: Sua senha do secret `DB_PASSWORD`

3. **Configurações avançadas (aba Advanced):**
   - **SSL**: Disabled (ambiente dev)
   - **Allow Public Key Retrieval**: ✅ Enabled

4. **Testar conexão** → **OK**

### MySQL Workbench

1. **New Connection**
2. **Connection Name**: `Smart Workshop Dev`
3. **Hostname**: Saída de `terraform output rds_address`
4. **Port**: `3306`
5. **Username**: `admin`
6. **Password**: Store in Keychain... (sua senha do secret)
7. **Test Connection** → **OK**

### MySQL CLI

```bash
# Obter comando completo
terraform output -raw mysql_cli_command

# Executar (será solicitada a senha)
mysql -h smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com -P 3306 -u admin -p smart_workshop
```

### Aplicação Java (JDBC)

```java
String url = "jdbc:mysql://smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com:3306/smart_workshop?allowPublicKeyRetrieval=true&useSSL=false";
String user = "admin";
String password = System.getenv("DB_PASSWORD");

Connection conn = DriverManager.getConnection(url, user, password);
```

### Python (PyMySQL)

```python
import pymysql
import os

connection = pymysql.connect(
    host='smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com',
    port=3306,
    user='admin',
    password=os.getenv('DB_PASSWORD'),
    database='smart_workshop'
)
```

### Node.js (mysql2)

```javascript
const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'smart-workshop-dev-db.xxxxx.us-west-2.rds.amazonaws.com',
  port: 3306,
  user: 'admin',
  password: process.env.DB_PASSWORD,
  database: 'smart_workshop'
});
```

---

## 🤖 Pipeline CI/CD

O repositório possui 4 workflows automatizados no GitHub Actions:

### 1. 🚀 Deploy Infrastructure (`terraform-deploy.yml`)

**Trigger:**
- Push na branch `main` com mudanças em `terraform/` ou workflows
- Dispatch manual via interface do GitHub

**Jobs:**
1. **deploy**: Aplica infraestrutura Terraform
2. **migrate**: Executa migrations Flyway após RDS disponível

**Uso manual:**
```
Actions → 🚀 Deploy Infrastructure → Run workflow
- Branch: main
- Action: apply (ou destroy)
```

### 2. 📋 Terraform Plan (`terraform-plan.yml`)

**Trigger:**
- Pull Request com mudanças em `terraform/`

**Função:**
- Mostra preview das mudanças de infraestrutura
- Comenta o plano no PR para revisão
- Não aplica mudanças (apenas preview)

### 3. ✅ Terraform Validate (`terraform-validate.yml`)

**Trigger:**
- Push ou PR com mudanças em `terraform/`

**Função:**
- Valida sintaxe HCL do Terraform
- Verifica formatação (`terraform fmt`)
- Bloqueia merge se houver erros

### 4. 🔍 SQL Validation (`sql-validation.yml`)

**Trigger:**
- Push ou PR com mudanças em `migrations/sql/`

**Função:**
- Valida sintaxe SQL com sqlfluff
- Verifica convenção de nomenclatura Flyway
- Executa `flyway validate` localmente

### Fluxo de Trabalho Típico

```
1. Desenvolver localmente
   ↓
2. Criar branch feature/nova-tabela
   ↓
3. Adicionar migration V5__add_nova_tabela.sql
   ↓
4. Commitar e push
   ↓
5. Abrir Pull Request
   ↓
6. CI valida SQL e Terraform → ✅
   ↓
7. Revisor aprova PR
   ↓
8. Merge na main
   ↓
9. Pipeline deploy roda automaticamente
   ↓
10. RDS provisionado/atualizado
    ↓
11. Migrations aplicadas
    ↓
12. ✅ Deploy concluído!
```

---

## 📊 Monitoramento

### CloudWatch Metrics

O RDS envia métricas automaticamente para o CloudWatch:

**Acessar:**
1. Console AWS → CloudWatch → Metrics
2. Namespace: `AWS/RDS`
3. Dimension: `DBInstanceIdentifier` = `smart-workshop-dev-db`

**Métricas Principais:**
- `CPUUtilization`: Uso de CPU (%)
- `FreeableMemory`: Memória disponível
- `DatabaseConnections`: Conexões ativas
- `ReadLatency` / `WriteLatency`: Latência de I/O
- `FreeStorageSpace`: Espaço em disco disponível

### Performance Insights (opcional)

Para habilitar (aumenta custo em ~$0.10/dia):

```hcl
# terraform/terraform.tfvars
performance_insights_enabled = true
performance_insights_retention_period = 7
```

**Acessar:**
Console RDS → smart-workshop-dev-db → Performance Insights

### Logs

**Enhanced Monitoring**: Habilitado por padrão (métricas a nível de SO)

**Logs disponíveis:**
- Error Log
- Slow Query Log (queries > 2 segundos)
- General Log (desabilitado por padrão, verbose demais)

**Ver logs:**
```bash
aws rds download-db-log-file-portion \
  --db-instance-identifier smart-workshop-dev-db \
  --log-file-name error/mysql-error.log \
  --output text
```

### Alarmes Recomendados

```bash
# Criar alarme de CPU alta
aws cloudwatch put-metric-alarm \
  --alarm-name rds-cpu-high \
  --alarm-description "RDS CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=smart-workshop-dev-db \
  --evaluation-periods 2
```

---

## 💾 Backup e Recuperação

### Backups Automáticos

Configurados por padrão no Terraform:

```hcl
backup_retention_period = 1  # dias (Free tier)
backup_window           = "03:00-04:00"  # UTC
```

**Características:**
- Backups diários automáticos durante a janela especificada
- Retenção de 1 dia (desenvolvimento) ou 7-35 dias (produção)
- Point-in-time recovery (PITR) até o último backup

### Criar Snapshot Manual

```bash
aws rds create-db-snapshot \
  --db-instance-identifier smart-workshop-dev-db \
  --db-snapshot-identifier smart-workshop-manual-backup-$(date +%Y%m%d)
```

### Restaurar de Backup

**Via Console AWS:**
1. RDS → Snapshots
2. Selecionar snapshot
3. Actions → Restore Snapshot
4. Configurar nova instância

**Via CLI:**
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier smart-workshop-restored \
  --db-snapshot-identifier smart-workshop-manual-backup-20250122
```

### Point-in-Time Recovery

Restaurar para qualquer momento nos últimos N dias (retention period):

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier smart-workshop-dev-db \
  --target-db-instance-identifier smart-workshop-restored \
  --restore-time 2025-01-22T10:30:00Z
```

### Exportar Dados (Backup Lógico)

```bash
# Dump completo
mysqldump -h SEU_RDS_ENDPOINT -u admin -p \
  --single-transaction \
  --routines \
  --triggers \
  smart_workshop > backup_$(date +%Y%m%d).sql

# Comprimir
gzip backup_$(date +%Y%m%d).sql

# Upload para S3
aws s3 cp backup_$(date +%Y%m%d).sql.gz s3://seu-bucket-backups/
```

---

## 💰 Relatório de Custos

### Ambiente de Desenvolvimento (Atual)

| Componente | Especificação | Custo Mensal (USD) |
|------------|---------------|---------------------|
| **RDS Instance** | db.t4g.micro (ARM) | $12.41 |
| **Storage** | 20GB gp3 SSD | $2.30 |
| **Backup Storage** | 1 dia retenção (~20GB) | $0.00 (Free Tier) |
| **Data Transfer** | Saída internet (<1GB/mês) | $0.00 |
| **S3 State Backend** | <1MB estado Terraform | $0.01 |
| **DynamoDB Locks** | Pay-per-request (~100 req/mês) | $0.00 |
| **CloudWatch Logs** | <1GB/mês | $0.00 (Free Tier) |
| **Enhanced Monitoring** | Métricas de SO (60s) | $0.00 (Free Tier) |
| **Total Mensal** | | **~$14.72** |

### Otimizações Aplicadas

✅ **Instância ARM Graviton2** (`db.t4g.micro`) - 20% mais barata que x86
✅ **Storage gp3** - 20% mais barato que gp2 com mesmo desempenho
✅ **Single-AZ** - Economiza 50% vs Multi-AZ
✅ **Backup 1 dia** - Dentro do Free Tier (gratuito)
✅ **Performance Insights desabilitado** - Economiza $3/mês
✅ **Multi-AZ desabilitado** - Economiza ~$12/mês

### Estimativa para Produção

| Componente | Configuração | Custo Mensal (USD) |
|------------|--------------|---------------------|
| **RDS Instance** | db.t4g.medium (Multi-AZ) | $81.12 |
| **Storage** | 100GB gp3 SSD | $11.50 |
| **Backup Storage** | 7 dias retenção (~100GB) | $9.50 |
| **IOPS Provisionadas** | 6000 IOPS (se necessário) | $0.00 (incluído em gp3) |
| **Performance Insights** | 7 dias retenção | $3.10 |
| **Data Transfer** | ~10GB/mês saída | $0.90 |
| **Total Mensal** | | **~$106.12** |

### Calculadora de Custos

Use a [AWS Pricing Calculator](https://calculator.aws/) para cenários específicos:

**Fatores que aumentam custo:**
- ⬆️ Classe de instância maior (db.t4g.small, medium, large...)
- ⬆️ Multi-AZ habilitado (+100% custo da instância)
- ⬆️ Storage adicional (cada GB extra = $0.115/mês)
- ⬆️ IOPS provisionadas acima de 3000
- ⬆️ Backup retention > 1 dia ($0.095/GB/mês)
- ⬆️ Performance Insights habilitado ($0.01/hora = $7.20/mês)
- ⬆️ Data transfer para internet

**Fatores que reduzem custo:**
- ⬇️ Usar instâncias ARM Graviton2 (t4g) vs x86 (t3)
- ⬇️ Storage gp3 vs gp2
- ⬇️ Single-AZ em ambientes não críticos
- ⬇️ Reduzir backup retention period
- ⬇️ Usar Reserved Instances (commit 1-3 anos, desconto de até 62%)

### Monitorar Custos

**AWS Cost Explorer:**
1. Console AWS → Cost Management → Cost Explorer
2. Filtrar por serviço: `Amazon RDS`
3. Agrupar por: `Usage Type`

**Configurar Budget Alert:**
```bash
aws budgets create-budget \
  --account-id 123456789 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

---

## 🔒 Segurança

### Considerações Atuais

**⚠️ Security Group Aberto (0.0.0.0/0)**
- **Justificativa**: GitHub Actions precisa acessar o RDS de IPs dinâmicos
- **Risco**: Banco exposto publicamente (mitigado por senha forte)
- **Recomendação**: Em produção, usar VPN ou AWS Systems Manager Session Manager

### Melhorias para Produção

**1. Restringir Security Group:**
```hcl
# terraform/terraform.tfvars
allowed_cidr_blocks = [
  "203.0.113.0/24",  # VPN corporativa
  "198.51.100.0/24"  # Escritório
]

# Ou usar security group do EKS
allowed_security_group_ids = ["sg-0abc123def456"]
```

**2. Habilitar SSL/TLS:**
```hcl
# terraform/variables.tf
resource "aws_db_instance" "main" {
  # ... outras configs
  ca_cert_identifier = "rds-ca-rsa2048-g1"
}
```

Na aplicação:
```java
String url = "jdbc:mysql://HOST:3306/DB?useSSL=true&requireSSL=true";
```

**3. Secrets Manager para Senha (ao invés de GitHub Secret):**
```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "smart-workshop-db-password"
}

resource "aws_db_instance" "main" {
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.rds.id
}
```

**4. Encryption at Rest (já habilitado):**
```hcl
storage_encrypted = true  # ✅ Já configurado
```

**5. IAM Database Authentication:**
```hcl
iam_database_authentication_enabled = true
```

Aplicação usa token temporário ao invés de senha fixa.

**6. Private Subnet + Bastion Host:**
```
[Internet] → [Bastion em Subnet Pública] → [RDS em Subnet Privada]
```

**7. AWS WAF + Application Load Balancer:**
Protege aplicação antes de chegar ao banco.

### Auditoria e Compliance

**Habilitar Database Activity Streams:**
```hcl
activity_stream_mode = "async"
activity_stream_kms_key_id = aws_kms_key.rds.id
```

**Exportar logs para S3:**
```hcl
enabled_cloudwatch_logs_exports = ["error", "slowquery", "audit"]
```

### Rotação de Senhas

**Manual:**
```bash
aws rds modify-db-instance \
  --db-instance-identifier smart-workshop-dev-db \
  --master-user-password "NovaSenhaSegura456!" \
  --apply-immediately
```

**Automatizado via Secrets Manager:**
Configurar rotação automática a cada 90 dias.

---

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Erro: "DBInstance not found"

**Sintoma:**
```
Error: DBInstance smart-workshop-dev-db not found
```

**Causa:** Instância foi deletada ou nome incorreto

**Solução:**
```bash
# Verificar instâncias existentes
aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"

# Se não existir, recriar
cd terraform
terraform apply
```

#### 2. Erro: "Connection timed out"

**Sintoma:**
```
ERROR: Can't connect to MySQL server on 'smart-workshop-dev-db.xxxxx.rds.amazonaws.com' (110)
```

**Possíveis causas:**
- Security Group não permite seu IP
- RDS não está publicly accessible
- RDS ainda está sendo criado

**Solução:**
```bash
# 1. Verificar status do RDS
aws rds describe-db-instances \
  --db-instance-identifier smart-workshop-dev-db \
  --query "DBInstances[0].DBInstanceStatus"

# 2. Verificar Security Group
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id) \
  --query "SecurityGroups[0].IpPermissions"

# 3. Testar conectividade
nc -zv smart-workshop-dev-db.xxxxx.rds.amazonaws.com 3306
```

#### 3. Erro: "Access denied for user 'admin'"

**Sintoma:**
```
ERROR 1045 (28000): Access denied for user 'admin'@'xxx.xxx.xxx.xxx' (using password: YES)
```

**Causa:** Senha incorreta

**Solução:**
```bash
# Verificar senha no GitHub Secret DB_PASSWORD
# Ou resetar senha:
aws rds modify-db-instance \
  --db-instance-identifier smart-workshop-dev-db \
  --master-user-password "NovaSenha123!" \
  --apply-immediately
```

#### 4. Erro: "RSA public key not available"

**Sintoma:**
```
RSA public key is not available client side (option serverRsaPublicKeyFile not set)
```

**Solução:** Adicionar parâmetros na URL JDBC:
```
jdbc:mysql://HOST:3306/DB?allowPublicKeyRetrieval=true&useSSL=false
```

#### 5. Migration Falha: "Checksum mismatch"

**Sintoma:**
```
ERROR: Migration checksum mismatch for migration version 3
```

**Causa:** Migration V3 foi editada após aplicação

**Solução:**
```sql
-- Conectar ao banco e corrigir checksum manualmente
UPDATE flyway_schema_history 
SET checksum = NULL 
WHERE version = '3';

-- Ou deletar entrada e recriar migration correta
DELETE FROM flyway_schema_history WHERE version = '3';
```

**Melhor prática:** NUNCA editar migrations aplicadas!

#### 6. Erro: "Insufficient storage"

**Sintoma:**
```
ERROR: Insufficient storage space available
```

**Solução:**
```bash
# Aumentar storage
cd terraform
nano terraform.tfvars
# db_allocated_storage = 50

terraform apply
```

#### 7. Terraform State Locked

**Sintoma:**
```
Error: Error acquiring the state lock
```

**Causa:** Pipeline ou desenvolvedor anterior não finalizou

**Solução:**
```bash
# Verificar lock no DynamoDB
aws dynamodb get-item \
  --table-name smart-workshop-terraform-locks \
  --key '{"LockID":{"S":"smart-workshop-terraform-state/database/terraform.tfstate"}}'

# Forçar remoção do lock (⚠️ apenas se tiver certeza!)
terraform force-unlock LOCK_ID
```

#### 8. GitHub Actions Falha: "AssumeRole"

**Sintoma:**
```
Error: Could not assume role with OIDC
```

**Solução:**
- Verificar se OIDC Provider está criado no IAM
- Verificar Trust Policy da role (repository correto?)
- Verificar se `AWS_ROLE_ARN` secret está correto
- Verificar se role tem permissões necessárias

---

## 🗑️ Destruição da Infraestrutura

### Via GitHub Actions

1. **Actions** → **🚀 Deploy Infrastructure** → **Run workflow**
2. **Action**: Selecionar `destroy`
3. **Aguardar conclusão** (~5 minutos)

### Via Terraform Local

```bash
cd terraform

# Preview do que será deletado
terraform plan -destroy

# Confirmar e destruir
terraform destroy

# Ou forçar sem confirmação
terraform destroy -auto-approve
```

### Limpeza Completa (incluindo S3 Backend)

```bash
# 1. Destruir RDS e recursos principais
cd terraform
terraform destroy -auto-approve

# 2. Destruir backend S3/DynamoDB
cd backend-setup

# Esvaziar bucket S3 antes de deletar
aws s3 rm s3://smart-workshop-terraform-state --recursive

# Destruir bucket e tabela DynamoDB
terraform destroy -auto-approve
```

**⚠️ ATENÇÃO:**
- Destruir o RDS **DELETA TODOS OS DADOS** permanentemente!
- Certifique-se de ter backups antes de destruir
- Em produção, habilite `deletion_protection = true`

### Verificar Limpeza

```bash
# Verificar RDS deletados
aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"

# Verificar Security Groups órfãos
aws ec2 describe-security-groups --filters "Name=group-name,Values=smart-workshop-*"

# Verificar S3 bucket vazio
aws s3 ls s3://smart-workshop-terraform-state
```

---

## 📚 Referências

- [Documentação AWS RDS](https://docs.aws.amazon.com/rds/)
- [Documentação Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Documentação Flyway](https://flywaydb.org/documentation/)
- [GitHub Actions OIDC com AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [MySQL 8.4 Reference Manual](https://dev.mysql.com/doc/refman/8.4/en/)
