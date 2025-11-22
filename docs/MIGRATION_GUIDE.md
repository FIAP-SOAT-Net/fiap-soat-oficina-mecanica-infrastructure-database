# Migration Guide - Existing SQL Scripts to Flyway

Guide to migrate your existing SQL scripts to Flyway versioned migrations.

## Overview

This guide helps you convert your existing database scripts into Flyway-compatible migrations.

## Step 1: Organize Your Existing Scripts

Gather all your SQL scripts:

```
existing-scripts/
├── create_database.sql
├── create_tables.sql
├── create_indexes.sql
├── seed_data.sql
└── stored_procedures.sql
```

## Step 2: Understand Flyway Naming Convention

Flyway uses this naming pattern:

```
V{version}__{description}.sql

Where:
- V = Prefix for versioned migrations
- {version} = Numeric version (1, 2, 3... or 1.0, 1.1, 2.0...)
- __ = Two underscores separator
- {description} = Brief description (lowercase with underscores)
- .sql = File extension
```

Examples:
```
✅ V1__create_schema.sql
✅ V2__create_customers_table.sql
✅ V3__add_vehicles_table.sql
✅ V4__create_indexes.sql
✅ V5__seed_initial_data.sql

❌ v1_create_schema.sql (lowercase v)
❌ V1_create_schema.sql (single underscore)
❌ V1__CREATE_SCHEMA.sql (uppercase description)
```

## Step 3: Split Your Scripts Logically

Recommended order:

### V1: Database Schema
```sql
-- V1__create_initial_schema.sql
-- Creates database structure, character sets, etc.

CREATE DATABASE IF NOT EXISTS smart_workshop
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE smart_workshop;
```

### V2-Vn: Tables
Create one migration per table or logical group:

```sql
-- V2__create_customers_table.sql
CREATE TABLE customers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

```sql
-- V3__create_vehicles_table.sql
CREATE TABLE vehicles (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  license_plate VARCHAR(20) NOT NULL UNIQUE,
  brand VARCHAR(100),
  model VARCHAR(100),
  year INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Vn+1: Indexes
```sql
-- V4__create_indexes.sql
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_vehicles_customer_id ON vehicles(customer_id);
CREATE INDEX idx_vehicles_license_plate ON vehicles(license_plate);
```

### Vn+2: Seed Data
```sql
-- V5__seed_initial_data.sql
INSERT INTO customers (name, email, phone) VALUES
  ('John Doe', 'john@example.com', '555-0001'),
  ('Jane Smith', 'jane@example.com', '555-0002');
```

## Step 4: Convert Your Scripts

### Example: Converting Existing Scripts

**Before (monolithic script):**
```sql
-- create_all.sql
CREATE DATABASE smart_workshop;
USE smart_workshop;

CREATE TABLE customers (...);
CREATE TABLE vehicles (...);

INSERT INTO customers VALUES (...);
```

**After (Flyway migrations):**

**V1__create_database.sql:**
```sql
-- Database already created by Flyway, skip this
-- Flyway connects to existing database
```

**V2__create_customers_table.sql:**
```sql
CREATE TABLE IF NOT EXISTS customers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**V3__create_vehicles_table.sql:**
```sql
CREATE TABLE IF NOT EXISTS vehicles (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  license_plate VARCHAR(20) NOT NULL UNIQUE,
  brand VARCHAR(100),
  model VARCHAR(100),
  year INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**V4__seed_customers.sql:**
```sql
INSERT INTO customers (name, email, phone) VALUES
  ('John Doe', 'john@example.com', '555-0001'),
  ('Jane Smith', 'jane@example.com', '555-0002')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  phone = VALUES(phone);
```

## Step 5: Best Practices

### Use Idempotent Statements

Make migrations safe to re-run:

```sql
-- ✅ Good (idempotent)
CREATE TABLE IF NOT EXISTS users (...);
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20);

-- ❌ Bad (fails on re-run)
CREATE TABLE users (...);
ALTER TABLE users ADD COLUMN status VARCHAR(20);
```

### Use Transactions

Wrap DDL statements in transactions (MySQL 8.0+ supports atomic DDL):

```sql
-- V6__add_appointments_table.sql
START TRANSACTION;

CREATE TABLE IF NOT EXISTS appointments (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  vehicle_id BIGINT NOT NULL,
  appointment_date DATETIME NOT NULL,
  status ENUM('pending', 'confirmed', 'completed', 'cancelled') DEFAULT 'pending',
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
) ENGINE=InnoDB;

CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);

COMMIT;
```

### Add Comments

Document your migrations:

```sql
-- V7__add_customer_loyalty_program.sql
-- Purpose: Add loyalty program support for customers
-- Author: DevOps Team
-- Date: 2025-11-22
-- Ticket: WORKSHOP-123

ALTER TABLE customers 
  ADD COLUMN loyalty_points INT DEFAULT 0,
  ADD COLUMN loyalty_tier ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze';

CREATE INDEX idx_customers_loyalty_tier ON customers(loyalty_tier);
```

### Handle Sensitive Data

Never commit real data in migrations:

```sql
-- ✅ Good (sample data only)
INSERT INTO customers (name, email) VALUES
  ('Test Customer 1', 'test1@example.com'),
  ('Test Customer 2', 'test2@example.com');

-- ❌ Bad (real customer data)
INSERT INTO customers (name, email) VALUES
  ('John Real Person', 'john.real@gmail.com');
```

## Step 6: Test Migrations

### Test Locally

```bash
# Start fresh database
docker-compose down -v
docker-compose up -d mysql

# Wait for MySQL to be ready
sleep 10

# Run migrations
docker-compose run --rm flyway migrate

# Verify
docker-compose run --rm flyway info
```

### Verify Data

```bash
# Connect to database
docker exec -it smart-workshop-db mysql -u workshop_user -p smart_workshop

# Check tables
SHOW TABLES;

# Verify flyway history
SELECT * FROM flyway_schema_history ORDER BY installed_rank;

# Check data
SELECT * FROM customers;
```

## Step 7: Common Patterns

### Adding a New Column

```sql
-- V8__add_customer_notes_column.sql
ALTER TABLE customers 
  ADD COLUMN IF NOT EXISTS notes TEXT AFTER phone;
```

### Modifying a Column

```sql
-- V9__increase_vehicle_model_length.sql
ALTER TABLE vehicles 
  MODIFY COLUMN model VARCHAR(200);
```

### Adding a Foreign Key

```sql
-- V10__add_service_records_table.sql
CREATE TABLE IF NOT EXISTS service_records (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  vehicle_id BIGINT NOT NULL,
  service_date DATE NOT NULL,
  description TEXT,
  cost DECIMAL(10,2),
  CONSTRAINT fk_service_vehicle 
    FOREIGN KEY (vehicle_id) 
    REFERENCES vehicles(id) 
    ON DELETE CASCADE
) ENGINE=InnoDB;
```

### Creating an Index

```sql
-- V11__add_performance_indexes.sql
CREATE INDEX idx_service_records_date ON service_records(service_date);
CREATE INDEX idx_service_records_vehicle_date ON service_records(vehicle_id, service_date);
```

## Step 8: Migration Checklist

Before committing new migrations:

- [ ] Migration filename follows Flyway convention
- [ ] Version number is sequential
- [ ] SQL syntax is valid (test locally)
- [ ] Statements are idempotent (safe to re-run)
- [ ] Foreign keys reference existing tables
- [ ] Indexes have meaningful names
- [ ] No sensitive data in migration
- [ ] Comments explain complex changes
- [ ] Tested with `docker-compose`
- [ ] Flyway info shows correct status

## Step 9: Provide Your Scripts

Please share your existing SQL scripts so I can:

1. Review the structure
2. Create appropriate Flyway migrations
3. Ensure proper ordering and dependencies
4. Add any necessary improvements

You can:
- Paste the content here
- Share via file upload
- Provide a link to existing repository

## Example Project Structure

After migration, your structure should look like:

```
migrations/sql/
├── V1__create_initial_schema.sql
├── V2__create_customers_table.sql
├── V3__create_vehicles_table.sql
├── V4__create_appointments_table.sql
├── V5__create_service_records_table.sql
├── V6__create_indexes.sql
├── V7__seed_customer_data.sql
└── V8__seed_vehicle_brands.sql
```

## Need Help?

If you have existing scripts ready, share them and I'll help convert them to proper Flyway migrations!
