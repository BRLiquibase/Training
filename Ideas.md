# Liquibase Cheat Sheet - Customer Requirements

## Overview
This sheet addresses key requirements for implementing Liquibase with Azure SQL for metadata and data platform configuration management.

Please note, it requires some configuration. Also, these are some ideas - not rules. :) 

---

## 1. Schema + Static Data Changes

**Requirement:** Track both schema changes and static/configuration data in changesets.

**Solution:** Use SQL formatted changelogs with `<loadData>` or INSERT statements
```sql
--liquibase formatted sql
--changeset demo:schema-change
CREATE TABLE config (id INT, param_name VARCHAR(100), param_value VARCHAR(500));

--changeset demo:static-data
INSERT INTO config VALUES (1, 'max_retries', '3');
INSERT INTO config VALUES (2, 'timeout_seconds', '30');
```
---

## 2. Stick to Native SQL (No XML)

**Requirement:** Use native Azure SQL syntax without learning XML format.

**Solution:** Use `.sql` files with `--liquibase formatted sql` header
```sql
--liquibase formatted sql
--changeset author:change-id
--rollback DROP TABLE example;

CREATE TABLE example (
    id INT PRIMARY KEY, 
    name VARCHAR(100),
    created_date DATETIME DEFAULT GETDATE()
);
```

**Key Points:**
- Pure Azure SQL syntax
- Works with existing SQL scripts
- Just add Liquibase header comments

---

## 3. Parallel Development & Merge Conflicts

**Requirement:** Multiple developers working on features simultaneously without conflicts.

**Solution:** Structured file naming + includeAll

**Directory Structure:**
```
changelog/
├── main.xml (or main.sql)
├── feature-A/
│   ├── 001-add-table.sql
│   └── 002-insert-data.sql
├── feature-B/
│   ├── 001-add-column.sql
│   └── 002-update-config.sql
└── hotfix/
    └── 001-urgent-fix.sql
```

**main.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog>
    <includeAll path="changelog/feature-A/" relativeToChangelogFile="false"/>
    <includeAll path="changelog/feature-B/" relativeToChangelogFile="false"/>
    <includeAll path="changelog/hotfix/" relativeToChangelogFile="false"/>
</databaseChangeLog>
```

**Benefits:**
- Each feature gets its own folder
- Numeric prefixes ensure order
- Git merges cleanly (different files)
- Easy to comment out entire features

---

## 4. Track What's Deployed Where

**Requirement:** Know exactly which scripts have been executed in which environment.

**Solution:** DATABASECHANGELOG table (automatic)

Liquibase automatically creates and maintains this table:
```sql
-- View deployment history
SELECT * FROM DATABASECHANGELOG 
WHERE DATEEXECUTED > '2026-01-01'
ORDER BY DATEEXECUTED DESC;

## 5. Feature Branches + Separate Databases

**Requirement:** Develop features in separate branches with separate databases.

**Solution:** Labels for feature-based deployment control
```sql
--liquibase formatted sql
--changeset demo:feature-x-table labels:feature-x
--context:dev,test

CREATE TABLE new_feature_table (
    id INT PRIMARY KEY,
    feature_data VARCHAR(500)
);

--changeset demo:feature-x-data labels:feature-x
--context:dev,test

INSERT INTO new_feature_table VALUES (1, 'Feature X data');
```

**Deploy specific feature to feature database:**
```bash
liquibase update \
  --url=jdbc:sqlserver://dev-server:1433;databaseName=feature_x_db \
  --label-filter="feature-x"
```

**Deploy everything to main DEV:**
```bash
liquibase update \
  --url=jdbc:sqlserver://dev-server:1433;databaseName=main_dev_db
```

---

## 6. Different Static Data Per Environment

**Requirement:** DEV/TEST/PROD have different configuration values.

**Solution:** Context-based data loading
```sql
--liquibase formatted sql

--changeset demo:dev-config context:dev
INSERT INTO config VALUES (1, 'api_url', 'https://dev.api.com');
INSERT INTO config VALUES (2, 'log_level', 'DEBUG');

--changeset demo:test-config context:test
INSERT INTO config VALUES (1, 'api_url', 'https://test.api.com');
INSERT INTO config VALUES (2, 'log_level', 'INFO');

--changeset demo:prod-config context:prod
INSERT INTO config VALUES (1, 'api_url', 'https://prod.api.com');
INSERT INTO config VALUES (2, 'log_level', 'WARN');
```

**Deploy to specific environment:**
```bash
# DEV
 liquibase update --context-filter="dev"

# TEST
 liquibase update --context-filter="test"

# PROD
 liquibase update --context-filter="prod"
```

**Or use properties file per environment:**

**liquibase-dev.properties:**
```properties
contexts=dev
url=jdbc:sqlserver://dev-server:1433;databaseName=platform_db
```

**liquibase-prod.properties:**
```properties
contexts=prod
url=jdbc:sqlserver://prod-server:1433;databaseName=platform_db
```

---

## 7. Check Differences Between Environments

**Requirement:** Validate what's deployed in each environment and identify drift.

**Solution:** Use `status`, `diff`, and `history` commands

**Check what's pending in an environment:**
```bash
liquibase status \
  --url=jdbc:sqlserver://prod-server:1433;databaseName=db \
  --verbose
```

**Generate SQL for missing changes:**
```bash
liquibase update-sql \
  --url=jdbc:sqlserver://prod-server:1433;databaseName=db \
  > pending-prod-changes.sql
```

**Compare two databases directly:**
```bash
liquibase diff \
  --url=jdbc:sqlserver://prod-server:1433;databaseName=db \
  --reference-url=jdbc:sqlserver://dev-server:1433;databaseName=db
```

**View deployment history:**
```bash
liquibase history \
  --url=jdbc:sqlserver://prod-server:1433;databaseName=db
```

**Query DATABASECHANGELOG across environments:**
```sql
-- Run on each environment, compare results
SELECT 
    ID, 
    AUTHOR, 
    FILENAME, 
    DATEEXECUTED,
    ORDEREXECUTED
FROM DATABASECHANGELOG 
ORDER BY ORDEREXECUTED;
```

---

## 8. GitHub Actions Automation

**Requirement:** Automate validation on PRs and deployment on merge to main.

**Solution:** Github

https://www.liquibase.com/blog/introducing-the-new-liquibase-setup-github-action-streamlined-ci-cd-for-database-devops


**Required GitHub Secrets:**
- `DEV_DB_URL`: `jdbc:sqlserver://dev-server:1433;databaseName=platform_db`
- `DEV_DB_USER`: Database username for DEV
- `DEV_DB_PASSWORD`: Database password for DEV
- (Same for TEST and PROD)

---

## Quick Start Commands

### Initial Setup
```bash
# Initialize Liquibase project
liquibase init project

# Create properties file
cat > liquibase.properties << EOF
changelog-file=changelog/main.xml
url=jdbc:sqlserver://localhost:1433;databaseName=platform_db
username=sa
password=YourPassword
driver=com.microsoft.sqlserver.jdbc.SQLServerDriver
EOF
```

### Daily Commands
```bash
# Validate changelog syntax
liquibase validate

# See what will be deployed
liquibase status

# Preview SQL without executing
liquibase update-sql

# Deploy changes
liquibase update

# Rollback last deployment
liquibase rollback-count 1

# View deployment history
liquibase history
```

### Advanced Commands
```bash
# Generate changelog from existing database
liquibase generate-changelog

# Compare two databases
liquibase diff \
  --reference-url=jdbc:sqlserver://other-server:1433;databaseName=db

# Deploy specific labels only
liquibase update --label-filter="feature-x"

# Deploy with specific context
liquibase update --contexts="dev"
```

---

## POC Success Criteria

✅ **Track schema + data in version control**
- All changes in SQL files
- Version controlled in Git
- Audit trail via DATABASECHANGELOG

✅ **Native SQL (no XML learning curve)**
- Use `.sql` files with Liquibase headers
- Existing SQL scripts work with minor modifications

✅ **Parallel feature development without conflicts**
- Feature-based folder structure
- Labels and contexts for isolation
- Clean Git merges

✅ **Know exactly what's deployed where**
- Query DATABASECHANGELOG per environment
- Use `status` and `diff` commands
- Compare environments easily

✅ **Automated PR validation + deployment**
- GitHub Actions validates PRs
- Auto-deploy on merge
- Manual approval gates for PROD

---

## Next Steps

1. **Set up empty test environment**
   - Create Azure SQL database in new resource group
   - Install Liquibase locally
   - Create initial changelog structure

2. **Test basic workflow**
   - Create schema change in SQL file
   - Add static data changeset
   - Deploy with `liquibase update`
   - Verify DATABASECHANGELOG

3. **Test feature branch flow**
   - Create feature branch
   - Add changesets with labels
   - Deploy to feature database
   - Merge to main and deploy

4. **Set up GitHub Actions**
   - Configure secrets
   - Test PR validation
   - Test auto-deployment to DEV

5. **Test environment-specific data**
   - Create context-based changesets
   - Deploy to DEV, TEST, PROD
   - Verify correct data per environment

**Questions?**  
Contact: Ben Riley - briley@liquibase.com