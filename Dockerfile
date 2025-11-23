# Multi-stage build para imagem otimizada do banco de dados
# Imagem base: MySQL 8.4.3 + Migrations Flyway
# Uso: Desenvolvimento local, testes E2E, CI/CD

# Stage 1: Preparar migrations
FROM flyway/flyway:10-alpine AS migrations
WORKDIR /flyway/sql
# As migrations serão copiadas durante o build

# Stage 2: Imagem final MySQL
FROM mysql:8.4.3

# Metadata
LABEL org.opencontainers.image.title="Smart Mechanical Workshop Database"
LABEL org.opencontainers.image.description="MySQL 8.4.3 com schema e migrations do projeto FIAP/SOAT"
LABEL org.opencontainers.image.vendor="FIAP-SOAT-Net"
LABEL org.opencontainers.image.authors="Igor Tessaro"
LABEL org.opencontainers.image.url="https://github.com/FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database"
LABEL org.opencontainers.image.source="https://github.com/FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database"
LABEL org.opencontainers.image.licenses="Proprietary"

# Argumentos de build (será injetado pelo pipeline)
ARG GIT_COMMIT_SHA=unknown
ARG BUILD_DATE=unknown
ARG VERSION=unknown

# Labels dinâmicos
LABEL org.opencontainers.image.revision="${GIT_COMMIT_SHA}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${VERSION}"

# Variáveis de ambiente padrão (podem ser sobrescritas no docker run)
ENV MYSQL_ROOT_PASSWORD=root_password_change_me
ENV MYSQL_DATABASE=smart_workshop
ENV MYSQL_USER=workshop_user
ENV MYSQL_PASSWORD=workshop_password_change_me

# Configurações do MySQL para desenvolvimento
# Otimizado para uso local/CI (não para produção)
ENV MYSQL_INIT_CONNECT='SET NAMES utf8mb4'
ENV MYSQL_CHARACTER_SET_SERVER=utf8mb4
ENV MYSQL_COLLATION_SERVER=utf8mb4_unicode_ci

# Copiar migrations SQL para inicialização automática
# MySQL executa automaticamente todos os .sql em /docker-entrypoint-initdb.d/
# na ordem alfabética durante a primeira inicialização
COPY migrations/sql/*.sql /docker-entrypoint-initdb.d/

# Copiar configuração customizada do MySQL (opcional)
COPY docker/mysql.cnf /etc/mysql/conf.d/custom.cnf

# Healthcheck para verificar se MySQL está pronto
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} || exit 1

# Expor porta padrão do MySQL
EXPOSE 3306

# Volume para persistência de dados (opcional em desenvolvimento)
VOLUME /var/lib/mysql

# Informações úteis no startup
RUN echo "=====================================" && \
    echo "Smart Workshop Database Image" && \
    echo "Version: ${VERSION}" && \
    echo "Git Commit: ${GIT_COMMIT_SHA}" && \
    echo "Build Date: ${BUILD_DATE}" && \
    echo "=====================================" && \
    echo "" && \
    echo "Migrations incluídas:" && \
    ls -lh /docker-entrypoint-initdb.d/ || true

# Usar entrypoint padrão do MySQL
# docker-entrypoint.sh executa migrations automaticamente
