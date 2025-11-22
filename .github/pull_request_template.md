## Description

<!-- Provide a brief description of the changes -->

## Type of Change

<!-- Mark the relevant option with an 'x' -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🎨 Code style update (formatting, renaming)
- [ ] ♻️ Code refactoring (no functional changes)
- [ ] ⚡ Performance improvement
- [ ] ✅ Test update
- [ ] 🔧 Configuration change
- [ ] 🗄️ Database migration

## Changes Made

<!-- List the specific changes made in this PR -->

- 
- 
- 

## Migration Details

<!-- If this PR includes database migrations, provide details -->

**Migration files:**
- 

**Migration description:**
- 

**Backward compatible:**
- [ ] Yes
- [ ] No (explain why below)

## Testing

<!-- Describe the tests you ran to verify your changes -->

### Local Testing

- [ ] Tested with Docker Compose
- [ ] Migrations run successfully
- [ ] No errors in logs
- [ ] Database schema verified

### Commands Used

```bash
# List the commands you used to test
make local-up
make local-migrate
# etc.
```

### Test Results

<!-- Paste relevant test output or screenshots -->

```
# Paste output here
```

## Checklist

<!-- Mark completed items with an 'x' -->

### Code Quality

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings or errors
- [ ] I have checked my code and corrected any misspellings

### Documentation

- [ ] I have updated the documentation accordingly
- [ ] I have updated the README if needed
- [ ] I have added comments in my migrations explaining the purpose

### Database

- [ ] Migration files follow naming convention: `V{version}__{description}.sql`
- [ ] Migrations are idempotent (safe to re-run)
- [ ] Foreign keys and constraints are properly named
- [ ] Indexes have been added for performance
- [ ] SQL follows the style guide

### Terraform

- [ ] Terraform files are formatted (`terraform fmt`)
- [ ] Terraform validates successfully (`terraform validate`)
- [ ] No sensitive data in code or comments
- [ ] Variables have descriptions
- [ ] Outputs are documented

### Security

- [ ] No passwords or API keys in code
- [ ] No hardcoded credentials
- [ ] Environment variables used for sensitive data
- [ ] `.gitignore` updated if needed

### Testing

- [ ] I have tested locally
- [ ] CI/CD checks are passing
- [ ] No breaking changes to existing functionality

## Deployment Notes

<!-- Any special notes for deployment -->

**Deployment order:**
1. 
2. 
3. 

**Post-deployment steps:**
<!-- Any manual steps needed after deployment -->

- 

**Rollback plan:**
<!-- How to rollback if something goes wrong -->

- 

## Related Issues

<!-- Link to related issues -->

Closes #
Related to #

## Screenshots

<!-- If applicable, add screenshots to help explain your changes -->

## Additional Context

<!-- Add any other context about the PR here -->

## Reviewers Checklist

<!-- For reviewers to complete -->

- [ ] Code review completed
- [ ] Documentation reviewed
- [ ] Security considerations verified
- [ ] Performance impact assessed
- [ ] Breaking changes identified
- [ ] Deployment plan reviewed
