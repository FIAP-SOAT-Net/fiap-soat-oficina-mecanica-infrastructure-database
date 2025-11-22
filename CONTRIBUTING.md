# Contributing to Smart Mechanical Workshop Database Infrastructure

Thank you for considering contributing to this project! This document provides guidelines for contributing.

## 🎯 How Can I Contribute?

### Reporting Bugs
- Use GitHub Issues
- Include detailed description
- Provide steps to reproduce
- Include logs/screenshots if applicable

### Suggesting Enhancements
- Use GitHub Issues with "enhancement" label
- Clearly describe the enhancement
- Explain why it would be useful

### Pull Requests
- Fork the repository
- Create a feature branch
- Make your changes
- Submit a pull request

## 🔄 Development Workflow

### 1. Setup Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/fiap-soat-oficina-mecanica-infrastructure-database.git
cd fiap-soat-oficina-mecanica-infrastructure-database

# Add upstream remote
git remote add upstream https://github.com/FIAP-SOAT-Net/fiap-soat-oficina-mecanica-infrastructure-database.git

# Setup local environment
make setup
make local-up
```

### 2. Create Feature Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
```

### 3. Make Changes

Follow our coding standards:
- **SQL**: See `docs/SQL_STYLE_GUIDE.md`
- **Terraform**: Use `terraform fmt`
- **Documentation**: Use Markdown

### 4. Test Your Changes

```bash
# Test locally
make local-migrate
make local-validate

# Validate Terraform
make terraform-validate
make terraform-fmt

# Run all validations
make ci-validate
```

### 5. Commit Your Changes

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: <type>(<scope>): <description>

git commit -m "feat(migrations): add customer loyalty program"
git commit -m "fix(terraform): correct security group rule"
git commit -m "docs(readme): update deployment instructions"
git commit -m "chore(deps): update terraform aws provider"
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### 6. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create Pull Request on GitHub
# Fill in the PR template
```

## 📝 Pull Request Guidelines

### PR Title
Use conventional commits format:
```
feat(migrations): add vehicle maintenance history
fix(terraform): resolve RDS backup window conflict
docs(readme): improve setup instructions
```

### PR Description
Include:
- **What**: What changes were made
- **Why**: Why these changes are needed
- **How**: How the changes work
- **Testing**: How you tested the changes

### PR Checklist
- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated (if needed)
- [ ] Self-review performed
- [ ] No hardcoded secrets or credentials
- [ ] Migration files follow naming convention
- [ ] Terraform formatted with `terraform fmt`

## 📋 Code Review Process

### What We Look For
1. **Correctness**: Does it work as intended?
2. **Security**: No security vulnerabilities?
3. **Performance**: No performance issues?
4. **Maintainability**: Is it readable and maintainable?
5. **Documentation**: Is it properly documented?

### Review Timeline
- Initial review: Within 2-3 business days
- Follow-up reviews: Within 1-2 business days

### Addressing Feedback
- Be responsive to review comments
- Make requested changes
- Mark conversations as resolved
- Re-request review after changes

## 🗄️ Database Migration Guidelines

### Creating New Migrations

1. **Naming Convention**
   ```
   V{version}__{description}.sql
   
   Examples:
   V4__add_customer_addresses.sql
   V5__create_payment_methods.sql
   V6__add_indexes_for_reports.sql
   ```

2. **Migration Content**
   ```sql
   -- V4__add_customer_addresses.sql
   -- Purpose: Add address support for customers
   -- Author: Your Name
   -- Date: YYYY-MM-DD
   
   START TRANSACTION;
   
   -- Your SQL here
   
   COMMIT;
   ```

3. **Best Practices**
   - Use `IF NOT EXISTS` for idempotency
   - Include comments explaining complex logic
   - Use transactions when possible
   - Test locally before committing
   - Keep migrations focused (one logical change)

### Migration Testing

```bash
# Test locally
make local-migrate

# Verify
make local-info
make local-connect

# Check tables
SHOW TABLES;
DESCRIBE your_new_table;
```

## 🏗️ Terraform Guidelines

### Making Terraform Changes

1. **Format Code**
   ```bash
   make terraform-fmt
   ```

2. **Validate**
   ```bash
   make terraform-validate
   ```

3. **Plan**
   ```bash
   make terraform-plan
   ```

4. **Document Changes**
   - Update variable descriptions
   - Update outputs if needed
   - Update README if behavior changes

### Terraform Best Practices
- Use meaningful resource names
- Add comments for complex logic
- Use variables for configurable values
- Include default values when sensible
- Use tags for all resources
- Consider cost implications

## 📚 Documentation Guidelines

### When to Update Documentation

Update docs when you:
- Add new features
- Change behavior
- Add configuration options
- Fix bugs that affected usage
- Improve existing functionality

### Documentation Standards
- Use clear, concise language
- Include code examples
- Add screenshots if helpful
- Update table of contents
- Check links are valid

### Files to Update
- `README.md` - Main documentation
- `docs/PROJECT_STRUCTURE.md` - Structure changes
- `docs/MIGRATION_GUIDE.md` - Migration changes
- `docs/SQL_STYLE_GUIDE.md` - SQL standards changes

## 🔒 Security Guidelines

### Never Commit
- ❌ Passwords or API keys
- ❌ AWS access keys
- ❌ Private keys or certificates
- ❌ Real customer data
- ❌ Internal IP addresses

### Always
- ✅ Use environment variables
- ✅ Use `.env.example` for templates
- ✅ Use AWS Secrets Manager for production
- ✅ Use sample/test data only
- ✅ Review `.gitignore` is working

### If You Accidentally Commit Secrets
1. Rotate the compromised credential immediately
2. Remove from git history: `git filter-branch` or BFG
3. Force push (if safe)
4. Notify team

## 🧪 Testing Standards

### Local Testing Required
- [ ] Docker Compose starts successfully
- [ ] Migrations run without errors
- [ ] Database schema is correct
- [ ] Sample queries work

### CI/CD Testing
- [ ] GitHub Actions workflows pass
- [ ] Terraform validation passes
- [ ] SQL validation passes
- [ ] No lint errors

## 💬 Communication

### Asking Questions
- Use GitHub Discussions for general questions
- Use GitHub Issues for bugs/features
- Be clear and provide context
- Include relevant code/logs

### Getting Help
- Check documentation first
- Search existing issues
- Provide minimal reproducible example
- Include environment details

## 🏆 Recognition

Contributors will be:
- Listed in project documentation
- Mentioned in release notes
- Credited in commit history

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## 🙏 Thank You!

Your contributions make this project better for everyone!

---

For questions about contributing, please open an issue or discussion on GitHub.
