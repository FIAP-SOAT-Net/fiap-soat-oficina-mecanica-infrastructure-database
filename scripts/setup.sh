#!/bin/bash

# Quick Setup Script for Smart Mechanical Workshop Database Infrastructure
# This script helps you get started quickly

set -e  # Exit on error

echo "🚀 Smart Mechanical Workshop - Database Infrastructure Setup"
echo "============================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check if Docker is installed
echo "Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker is installed"

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi
print_success "Docker Compose is installed"

echo ""
echo "Setting up configuration files..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    print_success "Created .env file"
    print_warning "Please edit .env with your preferred database credentials"
else
    print_info ".env already exists, skipping"
fi

# Create flyway.conf if it doesn't exist
if [ ! -f flyway.conf ]; then
    cp flyway.conf.example flyway.conf
    print_success "Created flyway.conf file"
else
    print_info "flyway.conf already exists, skipping"
fi

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform/terraform.tfvars ]; then
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    print_success "Created terraform/terraform.tfvars file"
    print_warning "Please edit terraform/terraform.tfvars with your AWS configuration before deploying"
else
    print_info "terraform/terraform.tfvars already exists, skipping"
fi

echo ""
echo "What would you like to do?"
echo "1) Start local development environment (Docker)"
echo "2) Just create configuration files (done above)"
echo "3) Exit"
echo ""
read -p "Enter your choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "🐳 Starting local MySQL database..."
        docker-compose up -d mysql
        
        echo "⏳ Waiting for MySQL to be ready..."
        sleep 10
        
        # Check if MySQL is healthy
        if docker-compose ps | grep -q "healthy"; then
            print_success "MySQL is running and healthy!"
        else
            print_warning "MySQL is starting, please wait a moment..."
        fi
        
        echo ""
        echo "🔄 Running database migrations..."
        docker-compose run --rm flyway migrate
        
        echo ""
        print_success "Setup complete!"
        echo ""
        echo "📊 Database Information:"
        echo "   Host: localhost"
        echo "   Port: 3306"
        echo "   Database: smart_workshop"
        echo "   User: workshop_user"
        echo "   Password: (see .env file)"
        echo ""
        echo "🔌 Connect using:"
        echo "   mysql -h 127.0.0.1 -P 3306 -u workshop_user -p smart_workshop"
        echo ""
        echo "   Or using Docker:"
        echo "   docker exec -it smart-workshop-db mysql -u workshop_user -p smart_workshop"
        echo ""
        echo "📋 Useful commands:"
        echo "   make local-info     - View migration status"
        echo "   make local-logs     - View database logs"
        echo "   make local-down     - Stop database"
        echo "   make help           - Show all available commands"
        ;;
    2)
        echo ""
        print_success "Configuration files created!"
        echo ""
        echo "📝 Next steps:"
        echo "   1. Edit .env with your local database credentials"
        echo "   2. Edit terraform/terraform.tfvars with your AWS configuration"
        echo "   3. Run './scripts/setup.sh' again and choose option 1 to start local environment"
        echo "   4. Or run 'make local-up' to start the local database"
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📚 Documentation:"
echo "   README.md - Complete project documentation"
echo "   docs/GITHUB_ACTIONS_SETUP.md - CI/CD setup guide"
echo "   docs/MIGRATION_GUIDE.md - Database migration guide"
echo "   docs/SQL_STYLE_GUIDE.md - SQL coding standards"
echo ""
echo "Happy coding! 🚀"
