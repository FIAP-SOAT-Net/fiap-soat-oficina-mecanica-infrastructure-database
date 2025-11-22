# SQL Style Guide

SQL coding standards for the Smart Mechanical Workshop project.

## General Rules

### 1. Use Uppercase for Keywords
```sql
-- ✅ Good
SELECT id, name FROM customers WHERE active = 1;

-- ❌ Bad
select id, name from customers where active = 1;
```

### 2. Use Snake_Case for Names
```sql
-- ✅ Good
CREATE TABLE customer_orders (
  order_id BIGINT,
  customer_id BIGINT,
  order_date DATE
);

-- ❌ Bad (camelCase)
CREATE TABLE CustomerOrders (
  OrderId BIGINT,
  CustomerId BIGINT,
  OrderDate DATE
);
```

### 3. Indent Consistently
Use 2 spaces for indentation:

```sql
SELECT 
  c.id,
  c.name,
  COUNT(o.id) AS order_count
FROM customers c
  LEFT JOIN orders o ON c.id = o.customer_id
WHERE 
  c.active = 1
  AND c.created_at >= '2024-01-01'
GROUP BY 
  c.id,
  c.name
HAVING 
  COUNT(o.id) > 0
ORDER BY 
  order_count DESC;
```

### 4. One Column Per Line (in CREATE/SELECT)
```sql
-- ✅ Good
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ❌ Bad
CREATE TABLE users (id BIGINT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50) NOT NULL, email VARCHAR(255) NOT NULL);
```

## Naming Conventions

### Tables
- Use plural nouns: `customers`, `orders`, `vehicles`
- Use snake_case: `customer_orders`, `service_records`

### Columns
- Use descriptive names: `created_at` not `crt_dt`
- Boolean columns: prefix with `is_` or `has_`: `is_active`, `has_warranty`
- Foreign keys: `{table}_id`: `customer_id`, `vehicle_id`

### Indexes
- Prefix with `idx_`: `idx_customers_email`
- Include table and column: `idx_orders_customer_id`
- For composite: `idx_orders_customer_date`

### Constraints
- Primary key: `pk_{table}`
- Foreign key: `fk_{table}_{referenced_table}`
- Unique: `uq_{table}_{column}`
- Check: `chk_{table}_{column}`

## Data Types

### Use Appropriate Types
```sql
-- ✅ Good
CREATE TABLE products (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL,
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ❌ Bad (TEXT for name, VARCHAR for price)
CREATE TABLE products (
  id INT,
  name TEXT,
  price VARCHAR(50),
  quantity VARCHAR(20),
  is_available CHAR(1),
  created_at VARCHAR(30)
);
```

### Common Types
- **IDs**: `BIGINT AUTO_INCREMENT`
- **Names**: `VARCHAR(255)`
- **Descriptions**: `TEXT`
- **Money**: `DECIMAL(10,2)`
- **Dates**: `DATE`
- **Timestamps**: `TIMESTAMP`
- **Booleans**: `BOOLEAN` or `TINYINT(1)`

## Character Sets

Always specify UTF-8MB4:

```sql
CREATE TABLE customers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci;
```

## Constraints

### Primary Keys
```sql
-- ✅ Preferred (inline)
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL
);

-- ✅ Also good (separate)
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  PRIMARY KEY (id)
);
```

### Foreign Keys
```sql
CREATE TABLE orders (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id) 
    REFERENCES customers(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
```

### Unique Constraints
```sql
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  username VARCHAR(50) NOT NULL,
  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT uq_users_username UNIQUE (username)
);
```

## Indexes

### Creating Indexes
```sql
-- Single column
CREATE INDEX idx_customers_email ON customers(email);

-- Multiple columns (order matters!)
CREATE INDEX idx_orders_customer_date 
  ON orders(customer_id, order_date);

-- Unique index
CREATE UNIQUE INDEX idx_users_username ON users(username);
```

### When to Index
✅ Index:
- Foreign keys
- Columns used in WHERE clauses
- Columns used in JOIN conditions
- Columns used in ORDER BY

❌ Don't index:
- Small tables (< 1000 rows)
- Columns with low cardinality (few unique values)
- Columns rarely used in queries

## Transactions

Always use transactions for data modifications:

```sql
START TRANSACTION;

INSERT INTO customers (name, email) 
VALUES ('John Doe', 'john@example.com');

SET @customer_id = LAST_INSERT_ID();

INSERT INTO addresses (customer_id, street, city)
VALUES (@customer_id, '123 Main St', 'Springfield');

COMMIT;
```

## Comments

### Table Comments
```sql
CREATE TABLE customers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL COMMENT 'Customer full name',
  email VARCHAR(255) NOT NULL COMMENT 'Primary contact email',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Customer master table';
```

### Migration Comments
```sql
-- V5__add_loyalty_program.sql
-- Purpose: Add customer loyalty program functionality
-- Author: DevOps Team
-- Date: 2025-11-22
-- Related: WORKSHOP-123

ALTER TABLE customers 
  ADD COLUMN loyalty_points INT DEFAULT 0 COMMENT 'Accumulated loyalty points';
```

## Complex Queries

### CTEs (Common Table Expressions)
```sql
WITH customer_stats AS (
  SELECT 
    customer_id,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_spent
  FROM orders
  WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  GROUP BY customer_id
)
SELECT 
  c.name,
  c.email,
  cs.order_count,
  cs.total_spent
FROM customers c
  INNER JOIN customer_stats cs ON c.id = cs.customer_id
WHERE cs.order_count >= 5
ORDER BY cs.total_spent DESC;
```

## Anti-Patterns to Avoid

### ❌ SELECT *
```sql
-- Bad
SELECT * FROM customers;

-- Good
SELECT id, name, email FROM customers;
```

### ❌ NOT IN with NULL
```sql
-- Bad (may not work as expected with NULL)
SELECT * FROM customers WHERE id NOT IN (SELECT customer_id FROM orders);

-- Good
SELECT c.* 
FROM customers c
  LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.customer_id IS NULL;
```

### ❌ Implicit Type Conversion
```sql
-- Bad (id is INT, comparing with VARCHAR)
SELECT * FROM users WHERE id = '123';

-- Good
SELECT * FROM users WHERE id = 123;
```

### ❌ Functions on Indexed Columns
```sql
-- Bad (can't use index on created_at)
SELECT * FROM orders WHERE DATE(created_at) = '2024-01-01';

-- Good
SELECT * FROM orders 
WHERE created_at >= '2024-01-01 00:00:00'
  AND created_at < '2024-01-02 00:00:00';
```

## SQLFluff Configuration

Create `.sqlfluff` in project root:

```ini
[sqlfluff]
dialect = mysql
max_line_length = 100
indent_unit = space
indented_joins = True
indented_using_on = True

[sqlfluff:indentation]
tab_space_size = 2

[sqlfluff:rules:capitalisation.keywords]
capitalisation_policy = upper

[sqlfluff:rules:capitalisation.identifiers]
capitalisation_policy = lower

[sqlfluff:rules:capitalisation.functions]
extended_capitalisation_policy = upper
```

## Checklist for New Migrations

- [ ] Uses uppercase SQL keywords
- [ ] Uses snake_case for identifiers
- [ ] Proper indentation (2 spaces)
- [ ] Includes IF NOT EXISTS where appropriate
- [ ] Foreign keys have proper names
- [ ] Indexes have descriptive names
- [ ] Uses appropriate data types
- [ ] Includes comments for complex logic
- [ ] Wrapped in transaction (if applicable)
- [ ] Tested with local database
- [ ] Passes sqlfluff linting

## Resources

- [MySQL 8.4 Reference Manual](https://dev.mysql.com/doc/refman/8.4/en/)
- [SQLFluff Documentation](https://docs.sqlfluff.com/)
- [SQL Style Guide by Simon Holywell](https://www.sqlstyle.guide/)
