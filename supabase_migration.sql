-- Migration script to adapt existing schema for Finance Dashboard App
-- This script works with your existing tables and adds missing ones

-- First, let's add missing columns to existing transactions table if they don't exist
DO $$
BEGIN
    -- Check if column exists before adding it
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'transactions' AND column_name = 'is_expense') THEN
        ALTER TABLE transactions ADD COLUMN is_expense BOOLEAN DEFAULT true;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'transactions' AND column_name = 'subtitle') THEN
        ALTER TABLE transactions ADD COLUMN subtitle TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'transactions' AND column_name = 'date') THEN
        ALTER TABLE transactions ADD COLUMN date DATE DEFAULT CURRENT_DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'transactions' AND column_name = 'category_id') THEN
        ALTER TABLE transactions ADD COLUMN category_id UUID;
    END IF;
    
    -- Convert amount from numeric to bigint (paise) if needed
    -- This assumes existing amounts are in rupees, we'll convert to paise
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'transactions' AND column_name = 'amount' 
               AND data_type = 'numeric') THEN
        -- Create a backup of existing data
        CREATE TABLE IF NOT EXISTS transactions_backup AS SELECT * FROM transactions;
        
        -- Convert amounts from rupees to paise (multiply by 100)
        UPDATE transactions SET amount = ROUND(amount * 100);
        
        -- Change column type to bigint
        ALTER TABLE transactions ALTER COLUMN amount TYPE BIGINT USING amount::bigint;
    END IF;
END $$;

-- Create categories table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  is_expense BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create monthly_debt_history table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS monthly_debt_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  month DATE NOT NULL UNIQUE,
  debt_amount BIGINT NOT NULL DEFAULT 0,
  user_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_settings table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE,
  starting_balance BIGINT NOT NULL DEFAULT 789050,
  monthly_budget BIGINT NOT NULL DEFAULT 300000,
  current_debt BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories if they don't exist
INSERT INTO categories (name, icon, color, is_expense) VALUES
('Shopping', 'shopping_bag', '#FF6B6B', true),
('Food', 'restaurant', '#4ECDC4', true),
('Rent', 'home', '#45B7D1', true),
('Miscellaneous', 'more_horiz', '#96CEB4', true),
('Debt Payment', 'account_balance', '#FFA07A', true),
('Income', 'trending_up', '#51CF66', false)
ON CONFLICT (name) DO NOTHING;

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_debt_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON categories;
DROP POLICY IF EXISTS "Categories are not insertable by users" ON categories;
DROP POLICY IF EXISTS "Categories are not updatable by users" ON categories;
DROP POLICY IF EXISTS "Categories are not deletable by users" ON categories;

DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON transactions;

DROP POLICY IF EXISTS "Users can view own debt history" ON monthly_debt_history;
DROP POLICY IF EXISTS "Users can insert own debt history" ON monthly_debt_history;
DROP POLICY IF EXISTS "Users can update own debt history" ON monthly_debt_history;
DROP POLICY IF EXISTS "Users can delete own debt history" ON monthly_debt_history;

DROP POLICY IF EXISTS "Users can view own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can delete own settings" ON user_settings;

-- Create proper RLS policies
CREATE POLICY "Categories are viewable by everyone" ON categories FOR SELECT USING (true);
CREATE POLICY "Categories are not insertable by users" ON categories FOR INSERT WITH CHECK (false);
CREATE POLICY "Categories are not updatable by users" ON categories FOR UPDATE USING (false);
CREATE POLICY "Categories are not deletable by users" ON categories FOR DELETE USING (false);

-- Transactions: Users can only access their own transactions
CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can insert own transactions" ON transactions FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update own transactions" ON transactions FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete own transactions" ON transactions FOR DELETE USING (auth.uid()::text = user_id);

-- Monthly debt history: Users can only access their own data
CREATE POLICY "Users can view own debt history" ON monthly_debt_history FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can insert own debt history" ON monthly_debt_history FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update own debt history" ON monthly_debt_history FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete own debt history" ON monthly_debt_history FOR DELETE USING (auth.uid()::text = user_id);

-- User settings: Users can only access their own settings
CREATE POLICY "Users can view own settings" ON user_settings FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can insert own settings" ON user_settings FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update own settings" ON user_settings FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete own settings" ON user_settings FOR DELETE USING (auth.uid()::text = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_monthly_debt_user_month ON monthly_debt_history(user_id, month DESC);
CREATE INDEX IF NOT EXISTS idx_user_settings_user ON user_settings(user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_monthly_debt_history_updated_at ON monthly_debt_history;
CREATE TRIGGER update_monthly_debt_history_updated_at BEFORE UPDATE ON monthly_debt_history FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON user_settings;
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
