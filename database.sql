-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables with appropriate data types and constraints

-- users table
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(50),
    profile_image_url VARCHAR(255),
    color_mode VARCHAR(20) DEFAULT 'light',
    language VARCHAR(20) DEFAULT 'en'
);

-- categories table
CREATE TABLE categories (
    category_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    color VARCHAR(20),
    is_income BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE
);

-- accounts table
CREATE TABLE accounts (
    account_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(30) NOT NULL,
    balance NUMERIC(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    color VARCHAR(20)
);

-- budgets table
CREATE TABLE budgets (
    budget_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    category_id VARCHAR(50) REFERENCES categories(category_id),
    amount NUMERIC(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_recurring BOOLEAN DEFAULT FALSE,
    is_saving BOOLEAN DEFAULT FALSE,
    frequency VARCHAR(20),
    color VARCHAR(20)
);

-- groups table
CREATE TABLE groups (
    group_id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- transactions table
CREATE TABLE transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    category_name VARCHAR(100),
    category_color VARCHAR(50),
    account_id VARCHAR(50) REFERENCES accounts(account_id),
    budget_id VARCHAR(50) REFERENCES budgets(budget_id),
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    title VARCHAR(255),
    description VARCHAR(255),
    is_recurring BOOLEAN DEFAULT FALSE,
    receipt_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- group_transactions linking table
CREATE TABLE group_transactions (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id VARCHAR(50) REFERENCES groups(group_id) NOT NULL,
    transaction_id VARCHAR(50) REFERENCES transactions(transaction_id) NOT NULL,
    status VARCHAR(30) DEFAULT 'pending'
);

-- group_members linking table
CREATE TABLE group_members (
    group_id VARCHAR(50) REFERENCES groups(group_id) NOT NULL,
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    role VARCHAR(30) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id)
);

-- notifications table
CREATE TABLE notifications (
    notification_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    amount NUMERIC(15,2),
    type VARCHAR(30) NOT NULL,
    title VARCHAR(100) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- recurring_transactions table
CREATE TABLE recurring_transactions (
    recurring_id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) REFERENCES categories(category_id),
    account_id VARCHAR(50) REFERENCES accounts(account_id) NOT NULL,
    budget_id VARCHAR(50) REFERENCES budgets(budget_id),
    amount NUMERIC(15,2) NOT NULL,
    description VARCHAR(255),
    frequency VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    day_of_month SMALLINT,
    day_of_week SMALLINT
);

-- receipts table
CREATE TABLE receipts (
    receipt_id VARCHAR(50) PRIMARY KEY,
    transaction_id VARCHAR(50) REFERENCES transactions(transaction_id) NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ocr_data JSONB
);

-- Create indexes for foreign keys to improve performance
CREATE INDEX idx_category_user_id ON categories(user_id);
CREATE INDEX idx_account_user_id ON accounts(user_id);
CREATE INDEX idx_budget_user_id ON budgets(user_id);
CREATE INDEX idx_budget_category_id ON budgets(category_id);
CREATE INDEX idx_transaction_user_id ON transactions(user_id);
CREATE INDEX idx_transaction_category_id ON transactions(category_id);
CREATE INDEX idx_transaction_account_id ON transactions(account_id);
CREATE INDEX idx_transaction_budget_id ON transactions(budget_id);
CREATE INDEX idx_group_admin_id ON groups(admin_id);
CREATE INDEX idx_group_transaction_group_id ON group_transactions(group_id);
CREATE INDEX idx_group_transaction_transaction_id ON group_transactions(transaction_id);
CREATE INDEX idx_group_member_group_id ON group_members(group_id);
CREATE INDEX idx_group_member_user_id ON group_members(user_id);
CREATE INDEX idx_notification_user_id ON notifications(user_id);
CREATE INDEX idx_recurring_transaction_account_id ON recurring_transactions(account_id);
CREATE INDEX idx_recurring_transaction_category_id ON recurring_transactions(category_id);
CREATE INDEX idx_recurring_transaction_budget_id ON recurring_transactions(budget_id);
CREATE INDEX idx_receipt_transaction_id ON receipts(transaction_id);

-- Create functions for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Create triggers for updating timestamps
CREATE TRIGGER update_transaction_updated_at
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();

-- Create Row Level Security policies
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Example policies (you can expand these based on your specific authorization needs)

-- users table policies
CREATE POLICY user_select_self ON users
    FOR SELECT USING (auth.uid()::text = user_id);
    
CREATE POLICY user_update_self ON users
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY user_insert ON users
    FOR INSERT WITH CHECK (true);

-- categories table policies
CREATE POLICY category_select_own ON categories
    FOR SELECT USING (auth.uid()::text = user_id);
    
CREATE POLICY category_insert_own ON categories
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);
    
CREATE POLICY category_update_own ON categories
    FOR UPDATE USING (auth.uid()::text = user_id);
    
CREATE POLICY category_delete_own ON categories
    FOR DELETE USING (auth.uid()::text = user_id);

-- Similar policies for other tables...

-- accounts table policies
CREATE POLICY account_select_own ON accounts
    FOR SELECT USING (auth.uid()::text = user_id);
    
CREATE POLICY account_insert_own ON accounts
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);
    
CREATE POLICY account_update_own ON accounts
    FOR UPDATE USING (auth.uid()::text = user_id);
    
CREATE POLICY account_delete_own ON accounts
    FOR DELETE USING (auth.uid()::text = user_id);