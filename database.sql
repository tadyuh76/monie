-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- Create tables with appropriate data types and constraints
-- users table
CREATE TABLE users (
   user_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   email VARCHAR(100) UNIQUE NOT NULL,
   display_name VARCHAR(50),
   profile_image_url VARCHAR(255),
   color_mode VARCHAR(20) DEFAULT 'light',
   language VARCHAR(20) DEFAULT 'en'
);


-- accounts table
CREATE TABLE accounts (
   account_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   name VARCHAR(100) NOT NULL,
   type VARCHAR(30) NOT NULL,
   balance NUMERIC(15,2) DEFAULT 0,
   currency VARCHAR(3) DEFAULT 'USD',
   color VARCHAR(20),
   archived BOOLEAN DEFAULT false,
   pinned BOOLEAN DEFAULT false
);


-- budgets table
CREATE TABLE budgets (
   budget_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   name VARCHAR(100) NOT NULL,
   amount NUMERIC(15,2) NOT NULL,
   start_date DATE NOT NULL,
   end_date DATE,
   is_recurring BOOLEAN DEFAULT FALSE,
   is_saving BOOLEAN DEFAULT FALSE,
   frequency VARCHAR(20),
   color VARCHAR(20)
);


-- transactions table
CREATE TABLE transactions (
   transaction_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   account_id uuid REFERENCES accounts(account_id) ON DELETE SET NULL,
   budget_id uuid REFERENCES budgets(budget_id) ON DELETE SET NULL,
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   amount NUMERIC(15,2) NOT NULL,
   date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   title VARCHAR(255),
   description TEXT,
   category_name VARCHAR(100),
   color VARCHAR(30),
   is_recurring BOOLEAN DEFAULT FALSE,
   receipt_url VARCHAR(255)
);


-- groups table
CREATE TABLE groups (
   group_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   admin_id uuid REFERENCES users(user_id) ON DELETE SET NULL,
   name VARCHAR(100) NOT NULL,
   description TEXT,
   is_settled BOOLEAN
);


-- group_transactions linking table
CREATE TABLE group_transactions (
   group_transaction_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   group_id uuid REFERENCES groups(group_id) ON DELETE CASCADE NOT NULL,
   transaction_id uuid REFERENCES transactions(transaction_id) ON DELETE CASCADE NOT NULL,
   status VARCHAR(30) DEFAULT 'pending'
   approved_at timestamptz
);


-- group_members linking table
CREATE TABLE group_members (
   group_id uuid REFERENCES groups(group_id) ON DELETE CASCADE NOT NULL,
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   role VARCHAR(30) DEFAULT 'member',
   PRIMARY KEY (group_id, user_id)
);


-- notifications table
CREATE TABLE notifications (
   notification_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   amount NUMERIC(15,2),
   type VARCHAR(30) NOT NULL,
   title VARCHAR(100) NOT NULL,
   message TEXT,
   is_read BOOLEAN DEFAULT FALSE,
   created_at timestamptz DEFAULT NOW()
);


-- recurring_transactions table
CREATE TABLE recurring_transactions (
   recurring_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   account_id uuid REFERENCES accounts(account_id) ON DELETE CASCADE NOT NULL,
   budget_id uuid REFERENCES budgets(budget_id) ON DELETE SET NULL,
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   amount NUMERIC(15,2) NOT NULL,
   title VARCHAR(255) NOT NULL,
   description TEXT,
   category_name VARCHAR(100),
   color VARCHAR(30),
   frequency VARCHAR(20) NOT NULL,
   start_date DATE NOT NULL,
   end_date DATE,
   is_active BOOLEAN DEFAULT TRUE,
   day_of_month SMALLINT CHECK (day_of_month BETWEEN 1 AND 31),
   day_of_week SMALLINT CHECK (day_of_week BETWEEN 0 AND 6)
);


-- Database change logging table
CREATE TABLE audit_logs (
   log_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   table_name VARCHAR(50) NOT NULL,
   operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
   record_id uuid NOT NULL,
   user_id uuid REFERENCES users(user_id) ON DELETE SET NULL,
   changed_data JSONB,
   previous_data JSONB,
   ip_address VARCHAR(45),
   user_agent TEXT,
   timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Create trigger functions for each table to log changes
CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER AS $$
DECLARE
   record_id uuid;
   current_user_id uuid;
BEGIN
   -- Get the proper record ID
   IF TG_OP = 'DELETE' THEN
       record_id := OLD.user_id;
       IF TG_TABLE_NAME = 'users' THEN
           record_id := OLD.user_id;
       ELSIF TG_TABLE_NAME = 'accounts' THEN
           record_id := OLD.account_id;
           current_user_id := OLD.user_id;
       ELSIF TG_TABLE_NAME = 'budgets' THEN
           record_id := OLD.budget_id;
           current_user_id := OLD.user_id;
       ELSIF TG_TABLE_NAME = 'groups' THEN
           record_id := OLD.group_id;
           current_user_id := OLD.admin_id;
       ELSIF TG_TABLE_NAME = 'transactions' THEN
           record_id := OLD.transaction_id;
           current_user_id := OLD.user_id;
       ELSIF TG_TABLE_NAME = 'group_transactions' THEN
           record_id := OLD.group_transaction_id;
       ELSIF TG_TABLE_NAME = 'group_members' THEN
           record_id := OLD.user_id;
           current_user_id := OLD.user_id;
       ELSIF TG_TABLE_NAME = 'notifications' THEN
           record_id := OLD.notification_id;
           current_user_id := OLD.user_id;
       ELSIF TG_TABLE_NAME = 'recurring_transactions' THEN
           record_id := OLD.recurring_id;
           current_user_id := OLD.user_id;
       END IF;
      
       INSERT INTO audit_logs (table_name, operation, record_id, user_id, previous_data, changed_data)
       VALUES (TG_TABLE_NAME, TG_OP, record_id, current_user_id, to_jsonb(OLD), NULL);
      
       RETURN OLD;
   ELSIF TG_OP = 'UPDATE' THEN
       IF TG_TABLE_NAME = 'users' THEN
           record_id := NEW.user_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'accounts' THEN
           record_id := NEW.account_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'budgets' THEN
           record_id := NEW.budget_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'groups' THEN
           record_id := NEW.group_id;
           current_user_id := NEW.admin_id;
       ELSIF TG_TABLE_NAME = 'transactions' THEN
           record_id := NEW.transaction_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'group_transactions' THEN
           record_id := NEW.group_transaction_id;
       ELSIF TG_TABLE_NAME = 'group_members' THEN
           record_id := NEW.user_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'notifications' THEN
           record_id := NEW.notification_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'recurring_transactions' THEN
           record_id := NEW.recurring_id;
           current_user_id := NEW.user_id;
       END IF;


       INSERT INTO audit_logs (table_name, operation, record_id, user_id, previous_data, changed_data)
       VALUES (TG_TABLE_NAME, TG_OP, record_id, current_user_id, to_jsonb(OLD), to_jsonb(NEW));
      
       RETURN NEW;
   ELSIF TG_OP = 'INSERT' THEN
       IF TG_TABLE_NAME = 'users' THEN
           record_id := NEW.user_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'accounts' THEN
           record_id := NEW.account_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'budgets' THEN
           record_id := NEW.budget_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'groups' THEN
           record_id := NEW.group_id;
           current_user_id := NEW.admin_id;
       ELSIF TG_TABLE_NAME = 'transactions' THEN
           record_id := NEW.transaction_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'group_transactions' THEN
           record_id := NEW.group_transaction_id;
       ELSIF TG_TABLE_NAME = 'group_members' THEN
           record_id := NEW.user_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'notifications' THEN
           record_id := NEW.notification_id;
           current_user_id := NEW.user_id;
       ELSIF TG_TABLE_NAME = 'recurring_transactions' THEN
           record_id := NEW.recurring_id;
           current_user_id := NEW.user_id;
       END IF;
      
       INSERT INTO audit_logs (table_name, operation, record_id, user_id, previous_data, changed_data)
       VALUES (TG_TABLE_NAME, TG_OP, record_id, current_user_id, NULL, to_jsonb(NEW));
      
       RETURN NEW;
   END IF;
  
   RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Create triggers for each table
CREATE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER accounts_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER budgets_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON budgets
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER groups_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON groups
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER transactions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON transactions
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER group_transactions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON group_transactions
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER group_members_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON group_members
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER notifications_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON notifications
FOR EACH ROW EXECUTE FUNCTION log_changes();


CREATE TRIGGER recurring_transactions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON recurring_transactions
FOR EACH ROW EXECUTE FUNCTION log_changes();



