# Secrets e Variáveis Necessários

Este documento lista todos os secrets e variables que devem ser configurados no GitHub para os pipelines funcionarem.

## 📍 Onde Configurar

**GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**

---

## 🔐 Secrets Obrigatórios

### Infraestrutura AWS (Terraform)

| Secret | Descrição | Exemplo | Usado em |
|--------|-----------|---------|----------|
| `AWS_ROLE_ARN` | ARN da role IAM para OIDC | `arn:aws:iam::123456789:role/GitHubActionsRole` | Todos os workflows AWS |
| `DB_PASSWORD` | Senha do banco RDS | `MinhaSenh@Segura123!` | terraform-deploy.yml |
| `VPC_ID` | ID da VPC AWS | `vpc-0abc123def456` | terraform-deploy.yml, terraform-plan.yml |
| `SUBNET_IDS` | Array JSON com 2+ subnets | `["subnet-abc123", "subnet-def456"]` | terraform-deploy.yml, terraform-plan.yml |
| `ALLOWED_CIDR_BLOCKS` | IPs permitidos (JSON array) | `["0.0.0.0/0"]` ou `["203.0.113.0/24"]` | terraform-deploy.yml, terraform-plan.yml |

### Docker Hub

| Secret | Descrição | Exemplo | Usado em |
|--------|-----------|---------|----------|
| `DOCKERHUB_USERNAME` | Username do Docker Hub | `igortessaro` | docker-publish.yml |
| `DOCKERHUB_TOKEN` | Access Token do Docker Hub | `dckr_pat_xxxxxxxxxxxxx` | docker-publish.yml |

---

## 📝 Variables (Opcionais)

| Variable | Valor Padrão | Descrição | Usado em |
|----------|--------------|-----------|----------|
| `AWS_REGION` | `us-east-1` | Região AWS | Todos os workflows AWS |

---

## 🔧 Como Obter os Secrets

### 1. AWS_ROLE_ARN

Após criar a role IAM com OIDC trust policy:

```bash
aws iam get-role --role-name GitHubActionsSmartWorkshopDB --query 'Role.Arn' --output text
```

### 2. VPC_ID

```bash
# VPC padrão
aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text

# Ou listar todas
aws ec2 describe-vpcs --query "Vpcs[].[VpcId,Tags[?Key=='Name'].Value|[0],IsDefault]" --output table
```

### 3. SUBNET_IDS

```bash
# Listar subnets da VPC (precisa de 2 em AZs diferentes)
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=SEU_VPC_ID" \
  --query "Subnets[].[SubnetId,AvailabilityZone,CidrBlock]" \
  --output table

# Formatar como JSON array
["subnet-abc123def", "subnet-456ghi789"]
```

### 4. ALLOWED_CIDR_BLOCKS

```bash
# Seu IP público
curl https://checkip.amazonaws.com

# Formatar como JSON array
["SEU_IP/32"]

# Ou permitir todos (apenas DEV!)
["0.0.0.0/0"]
```

### 5. DOCKERHUB_TOKEN

1. Login no [Docker Hub](https://hub.docker.com/)
2. **Account Settings** → **Security** → **New Access Token**
3. Name: `GitHub Actions - Smart Workshop`
4. Permissions: `Read & Write`
5. **Generate** → Copiar token (só aparece uma vez!)

---

## ✅ Checklist de Configuração

Antes de rodar os pipelines, verifique:

- [ ] Todos os secrets AWS configurados
- [ ] Role IAM com Trust Policy para GitHub OIDC
- [ ] Role IAM com permissões necessárias (RDS, EC2, VPC, IAM, S3, DynamoDB)
- [ ] VPC com 2+ subnets em AZs diferentes
- [ ] Docker Hub access token gerado
- [ ] Secrets DOCKERHUB_USERNAME e DOCKERHUB_TOKEN configurados
- [ ] Repositório Docker Hub existe (`igortessaro/smart-mechanical-workshop-db`)

---

## 🔒 Segurança

### Boas Práticas

✅ **Usar OIDC** ao invés de Access Keys permanentes
✅ **Tokens com permissões mínimas** (least privilege)
✅ **Rotacionar tokens** periodicamente (90 dias)
✅ **Não commitar secrets** no código
✅ **Usar environment protection rules** para ambientes sensíveis

### Rotação de Secrets

**Docker Hub Token** (a cada 90 dias):
```bash
# 1. Gerar novo token no Docker Hub
# 2. Atualizar secret DOCKERHUB_TOKEN no GitHub
# 3. Revogar token antigo no Docker Hub
```

**DB_PASSWORD** (a cada 90 dias):
```bash
# 1. Gerar nova senha forte
# 2. Atualizar secret DB_PASSWORD no GitHub
# 3. Atualizar RDS:
aws rds modify-db-instance \
  --db-instance-identifier smart-workshop-dev-db \
  --master-user-password "NovaSenhaSegura123!" \
  --apply-immediately
```

---

## 🐛 Troubleshooting

### Erro: "Secret not found"

```
Error: Secret AWS_ROLE_ARN not found
```

**Solução:** Verificar se o secret foi criado em **Repository secrets** (não Organization ou Environment)

### Erro: "Could not assume role"

```
Error: Could not assume role with OIDC
```

**Possíveis causas:**
- OIDC Provider não existe no IAM
- Trust Policy incorreta (repo name errado?)
- Role ARN incorreto no secret

### Erro: "unauthorized: incorrect username or password"

```
Error: unauthorized: authentication required
```

**Solução:** Token Docker Hub expirado ou inválido. Gerar novo token.

---

## 📚 Referências

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
