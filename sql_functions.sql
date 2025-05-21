-- Modify RLS policy for categories to allow access to global categories
DROP POLICY IF EXISTS category_select_own ON categories;
CREATE POLICY category_select_own ON categories
    FOR SELECT USING (auth.uid()::text = user_id OR user_id IS NULL);
    
DROP POLICY IF EXISTS category_insert_own ON categories;
CREATE POLICY category_insert_own ON categories
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);
    
DROP POLICY IF EXISTS category_update_own ON categories;
CREATE POLICY category_update_own ON categories
    FOR UPDATE USING (auth.uid()::text = user_id);
    
DROP POLICY IF EXISTS category_delete_own ON categories;
CREATE POLICY category_delete_own ON categories
    FOR DELETE USING (auth.uid()::text = user_id);

-- Function to check if global categories exist
CREATE OR REPLACE FUNCTION check_global_categories_exist()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  category_count int;
BEGIN
  SELECT COUNT(*) INTO category_count FROM categories WHERE user_id IS NULL;
  RETURN category_count > 0;
END;
$$;

-- Function to insert global categories
CREATE OR REPLACE FUNCTION insert_global_categories(categories jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Loop through the categories and insert them
  FOR i IN 0..jsonb_array_length(categories) - 1 LOOP
    INSERT INTO categories (
      category_id,
      name,
      icon,
      color,
      is_income,
      is_default,
      user_id
    ) VALUES (
      (categories->i->>'category_id'),
      (categories->i->>'name'),
      (categories->i->>'icon'),
      (categories->i->>'color'),
      (categories->i->>'is_income')::boolean,
      (categories->i->>'is_default')::boolean,
      NULL
    );
  END LOOP;
END;
$$;

-- Create a function to get categories for the current user, including global categories
CREATE OR REPLACE FUNCTION get_available_categories(is_income_param boolean DEFAULT NULL)
RETURNS SETOF categories
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM categories 
  WHERE user_id = auth.uid()::text OR user_id IS NULL
  AND (is_income_param IS NULL OR is_income = is_income_param)
  ORDER BY name;
$$;

-- Function to create default global categories
CREATE OR REPLACE FUNCTION upsert_default_categories()
RETURNS VOID AS $$
BEGIN
    -- Insert default expense categories (with user_id as NULL to make them global)
    
    -- Food & Drinks categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('expense-groceries', 'Groceries', 'shopping_cart', 'FF4CAF50', false, true, NULL),
        ('expense-restaurant', 'Restaurant', 'restaurant', 'FFFF9800', false, true, NULL),
        ('expense-coffee', 'Coffee', 'coffee', 'FF795548', false, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
    -- Housing categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('expense-rent', 'Rent', 'home', 'FF3F51B5', false, true, NULL),
        ('expense-utilities', 'Utilities', 'power', 'FF9C27B0', false, true, NULL),
        ('expense-internet', 'Internet', 'wifi', 'FF2196F3', false, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
    -- Transportation categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('expense-fuel', 'Fuel', 'local_gas_station', 'FFE91E63', false, true, NULL),
        ('expense-public-transit', 'Public Transit', 'directions_bus', 'FFCDDC39', false, true, NULL),
        ('expense-car-maintenance', 'Car Maintenance', 'directions_car', 'FF009688', false, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
    -- Entertainment categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('expense-movies', 'Movies', 'movie', 'FFE91E63', false, true, NULL),
        ('expense-games', 'Games', 'videogame_asset', 'FF673AB7', false, true, NULL),
        ('expense-subscription', 'Subscriptions', 'subscriptions', 'FF00BCD4', false, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
    -- Health categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('expense-medical', 'Medical', 'medical_services', 'FFF44336', false, true, NULL),
        ('expense-fitness', 'Fitness', 'fitness_center', 'FF4CAF50', false, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
    -- Other expense categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('expense-shopping', 'Shopping', 'shopping_bag', 'FFFF5722', false, true, NULL),
        ('expense-education', 'Education', 'school', 'FF3F51B5', false, true, NULL),
        ('expense-travel', 'Travel', 'flight', 'FF2196F3', false, true, NULL),
        ('expense-gifts', 'Gifts', 'card_giftcard', 'FFE91E63', false, true, NULL),
        ('expense-other', 'Other Expenses', 'more_horiz', 'FF607D8B', false, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
    -- Income categories
    INSERT INTO categories (category_id, name, icon, color, is_income, is_default, user_id)
    VALUES 
        ('income-salary', 'Salary', 'work', 'FF4CAF50', true, true, NULL),
        ('income-business', 'Business', 'business', 'FF2196F3', true, true, NULL),
        ('income-investments', 'Investments', 'trending_up', 'FFFF9800', true, true, NULL),
        ('income-freelance', 'Freelance', 'computer', 'FF9C27B0', true, true, NULL),
        ('income-gifts', 'Gifts', 'card_giftcard', 'FFE91E63', true, true, NULL),
        ('income-other', 'Other Income', 'more_horiz', 'FF607D8B', true, true, NULL)
    ON CONFLICT (category_id) DO UPDATE 
    SET name = EXCLUDED.name, icon = EXCLUDED.icon, color = EXCLUDED.color;
    
END;
$$ LANGUAGE plpgsql;

-- Call the function
SELECT upsert_default_categories();

-- Function to update user's profile image URL
CREATE OR REPLACE FUNCTION update_user_avatar(user_id_param TEXT, image_url_param TEXT)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated_rows int;
BEGIN
  -- Security check: Only allow users to update their own avatar
  IF auth.uid()::text <> user_id_param THEN
    RAISE EXCEPTION 'You can only update your own avatar';
    RETURN FALSE;
  END IF;

  -- Update the user's profile_image_url in the users table
  UPDATE users
  SET profile_image_url = image_url_param
  WHERE user_id = user_id_param;
  
  GET DIAGNOSTICS updated_rows = ROW_COUNT;
  
  -- Return true if a row was updated, false otherwise
  RETURN updated_rows > 0;
END;
$$;

-- Function to get user profile information including avatar
CREATE OR REPLACE FUNCTION get_user_profile(user_id_param TEXT DEFAULT NULL)
RETURNS TABLE (
  user_id TEXT,
  email TEXT,
  display_name TEXT,
  profile_image_url TEXT,
  color_mode TEXT,
  language TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If no user_id provided, use the current authenticated user
  IF user_id_param IS NULL THEN
    user_id_param := auth.uid()::text;
  END IF;

  -- Security check: Only allow users to get their own profile
  IF auth.uid()::text <> user_id_param THEN
    RAISE EXCEPTION 'You can only access your own profile';
  END IF;

  -- Return user profile from database
  RETURN QUERY
  SELECT 
    u.user_id,
    u.email,
    u.display_name,
    u.profile_image_url,
    u.color_mode,
    u.language
  FROM users u
  WHERE u.user_id = user_id_param;
END;
$$;

-- Function for settings page to handle avatar uploads and profile update
CREATE OR REPLACE FUNCTION settings_update_avatar(
  avatar_url_param TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  profile_image_url TEXT,
  user_id TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_id_var TEXT;
  updated_rows INT;
BEGIN
  -- Get the authenticated user ID
  user_id_var := auth.uid()::text;
  
  IF user_id_var IS NULL THEN
    -- No authenticated user found
    RETURN QUERY SELECT false, NULL::TEXT, NULL::TEXT;
    RETURN;
  END IF;
  
  -- Update the user's profile_image_url in the users table
  UPDATE users
  SET profile_image_url = avatar_url_param
  WHERE user_id = user_id_var;
  
  GET DIAGNOSTICS updated_rows = ROW_COUNT;
  
  -- If user doesn't exist in the users table, insert them
  IF updated_rows = 0 THEN
    -- Get user email from auth session
    DECLARE
      user_email TEXT;
      display_name TEXT;
    BEGIN
      SELECT email, raw_user_meta_data->>'name' 
      INTO user_email, display_name 
      FROM auth.users 
      WHERE id = user_id_var::uuid;
      
      -- Insert user if we have the email
      IF user_email IS NOT NULL THEN
        INSERT INTO users (user_id, email, profile_image_url, display_name)
        VALUES (user_id_var, user_email, avatar_url_param, display_name);
        updated_rows := 1;
      END IF;
    END;
  END IF;
  
  -- Return the result
  RETURN QUERY SELECT 
    updated_rows > 0, 
    avatar_url_param,
    user_id_var;
END;
$$;

-- Update the trigger that recalculates account balance to account for budget changes
CREATE OR REPLACE FUNCTION update_account_balance() RETURNS TRIGGER AS $$
BEGIN
  -- Update the balance of the account when a transaction is inserted, updated, or deleted
  IF TG_OP = 'INSERT' THEN
    UPDATE accounts 
    SET balance = balance + NEW.amount
    WHERE account_id = NEW.account_id;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Only update if account_id or amount changed
    IF NEW.account_id <> OLD.account_id OR NEW.amount <> OLD.amount THEN
      -- Revert the old amount from the old account
      IF OLD.account_id IS NOT NULL THEN
        UPDATE accounts 
        SET balance = balance - OLD.amount
        WHERE account_id = OLD.account_id;
      END IF;
      
      -- Add the new amount to the new account
      IF NEW.account_id IS NOT NULL THEN
        UPDATE accounts 
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;
      END IF;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Remove the amount from the account balance when a transaction is deleted
    IF OLD.account_id IS NOT NULL THEN
      UPDATE accounts 
      SET balance = balance - OLD.amount
      WHERE account_id = OLD.account_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql; 