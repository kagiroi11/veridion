-- Finance Dashboard Database Schema for Supabase
-- Safe version that handles existing tables

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS monthly_debt_history CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- Drop existing functions and triggers
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Categories table
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  is_expense BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions table
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT,
  amount BIGINT NOT NULL, -- amount in paise (cents)
  date DATE NOT NULL,
  is_expense BOOLEAN NOT NULL,
  category_id UUID REFERENCES categories(id),
  user_id TEXT NOT NULL, -- This will come from Supabase Auth
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Monthly debt history table
CREATE TABLE monthly_debt_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  month DATE NOT NULL UNIQUE, -- First day of the month
  debt_amount BIGINT NOT NULL, -- debt amount in paise (cents)
  user_id TEXT NOT NULL, -- This will come from Supabase Auth
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User settings table
CREATE TABLE user_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE, -- This will come from Supabase Auth
  starting_balance BIGINT NOT NULL DEFAULT 789050, -- in paise (cents)
  monthly_budget BIGINT NOT NULL DEFAULT 300000, -- in paise (cents)
  current_debt BIGINT NOT NULL DEFAULT 0, -- in paise (cents)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO categories (name, icon, color, is_expense) VALUES
('Shopping', 'shopping_bag', '#FF6B6B', true),
('Food', 'restaurant', '#4ECDC4', true),
('Rent', 'home', '#45B7D1', true),
('Miscellaneous', 'more_horiz', '#96CEB4', true),
('Debt Payment', 'account_balance', '#FFA07A', true),
('Income', 'trending_up', '#51CF66', false);

-- Enable RLS (Row Level Security)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_debt_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Categories: Everyone can read, no one can write (except service role)
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
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_monthly_debt_user_month ON monthly_debt_history(user_id, month DESC);
CREATE INDEX idx_user_settings_user ON user_settings(user_id);

-- Functions to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_monthly_debt_history_updated_at BEFORE UPDATE ON monthly_debt_history FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
