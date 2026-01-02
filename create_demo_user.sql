-- Create Demo User Script
-- Run this in your Supabase SQL Editor after applying the main schema

-- Insert demo user settings (this will be used when demo user signs up)
-- The user_id should match the auth.uid() of the demo user

-- Note: This will be created automatically when the user first signs in
-- through the app's initialization logic, but you can manually create it if needed:

-- INSERT INTO user_settings (user_id, starting_balance, monthly_budget, current_debt)
-- VALUES ('demo-user-id', 789050, 300000, 0);

-- For testing purposes, you can create some sample transactions:
-- INSERT INTO transactions (title, subtitle, amount, date, is_expense, category_id, user_id)
-- VALUES 
--   ('Grocery Shopping', 'Weekly groceries', 250000, '2026-01-15', true, 
--    (SELECT id FROM categories WHERE name = 'Food'), 'demo-user-id'),
--   ('Monthly Salary', 'January salary', 500000, '2026-01-01', false,
--    (SELECT id FROM categories WHERE name = 'Income'), 'demo-user-id');

-- The demo user credentials are:
-- Email: demo@example.com
-- Password: demo123

-- When the demo user signs up for the first time, the app will automatically
-- create their user_settings record with default values.
