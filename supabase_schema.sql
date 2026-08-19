-- MARAKI JUICE POS & SHIFT RECONCILIATION - SUPABASE SQL SCHEMA
-- Run this script in your Supabase SQL Editor to set up all tables, indexes, and initial products.

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Food', 'Juice', 'Beverage')),
    tone TEXT NOT NULL DEFAULT 'mango',
    emoji TEXT NOT NULL DEFAULT '🍹',
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Shifts Table
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_type TEXT NOT NULL CHECK (shift_type IN ('day', 'night')),
    cashier_name TEXT NOT NULL,
    opening_cups INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('active', 'closed')) DEFAULT 'active',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

-- 4. Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    cashier_name TEXT NOT NULL,
    items JSONB NOT NULL,
    subtotal NUMERIC(10, 2) NOT NULL,
    tax NUMERIC(10, 2) NOT NULL,
    total NUMERIC(10, 2) NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Cash', 'Transfer', 'Pay later', 'Credit', 'Delivery')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Shift Expenses Table
CREATE TABLE IF NOT EXISTS public.shift_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID REFERENCES public.shifts(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Customer Debts Table (Past & Recovered Credit Debts)
CREATE TABLE IF NOT EXISTS public.customer_debts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_name TEXT NOT NULL,
    note TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    is_recovered BOOLEAN NOT NULL DEFAULT false,
    shift_id_created UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    shift_id_recovered UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    recovered_at TIMESTAMPTZ
);

-- 7. Shift Reconciliations Table (End of Shift Guided Wizard Record)
CREATE TABLE IF NOT EXISTS public.shift_reconciliations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID UNIQUE REFERENCES public.shifts(id) ON DELETE CASCADE,
    shift_type TEXT NOT NULL,
    cashier_name TEXT NOT NULL,
    
    -- Step 1: Sales breakdown
    gross_revenue NUMERIC(10, 2) NOT NULL,
    cash_sales NUMERIC(10, 2) NOT NULL,
    transfer_sales NUMERIC(10, 2) NOT NULL,
    credit_sales NUMERIC(10, 2) NOT NULL,
    delivery_sales NUMERIC(10, 2) NOT NULL,
    tip_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_orders_count INT NOT NULL,

    -- Step 2: Cup inventory count
    opening_cups INT NOT NULL,
    added_cups INT NOT NULL,
    leftover_cups INT NOT NULL,
    calculated_cups_sold INT NOT NULL,
    tablet_cups_sold INT NOT NULL,
    cups_variance INT NOT NULL,

    -- Step 3: Expenses
    total_expenses NUMERIC(10, 2) NOT NULL,

    -- Step 4: Recovered Debts
    total_recovered_debts NUMERIC(10, 2) NOT NULL,

    -- Step 5: Cash Handover
    net_cash_to_owner NUMERIC(10, 2) NOT NULL,
    shift_notes TEXT,
    closed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Initial Menu Products
INSERT INTO public.products (name, description, price, category, tone, emoji, is_available) VALUES
('ማራኪ ኮመቦ ሳላድ', 'Maraki combo salad', 430.00, 'Food', 'salad', '🥗', true),
('ሳላድ', 'Fresh seasonal salad', 320.00, 'Food', 'salad', '🥗', true),
('ፓስታ በሳላድ', 'Pasta served with salad', 320.00, 'Food', 'pasta', '🍝', true),
('ሩዝ በሳላድ', 'Rice served with salad', 320.00, 'Food', 'rice', '🍚', true),
('ፓስታ በአትክልት', 'Pasta with vegetables', 320.00, 'Food', 'pasta', '🍝', true),
('ሩዝ በአትክልት', 'Rice with vegetables', 320.00, 'Food', 'rice', '🍚', true),
('ፓስታ በአንቁላል', 'Pasta with egg', 320.00, 'Food', 'pasta', '🍝', true),
('ሩዝ በእንቁላል', 'Rice with egg', 320.00, 'Food', 'rice', '🍚', true),
('እንቁላል ፍርፍር', 'Egg firfir', 230.00, 'Food', 'egg', '🍳', true),
('እንቁላል ስልስ', 'Egg sils', 230.00, 'Food', 'egg', '🍳', true),
('እንቁላል ሳንድዊች', 'Egg sandwich', 120.00, 'Food', 'sandwich', '🥪', true),
('አትክልት ሳንድዊች', 'Vegetable sandwich', 100.00, 'Food', 'sandwich', '🥪', true),
('ፍሩት ፓንች', 'Fresh fruit punch', 320.00, 'Food', 'fruit', '🍹', true),
('ፍርፍር', 'Traditional firfir', 200.00, 'Food', 'firfir', '🍲', true),
('ፓስታ በስጎ', 'Pasta with sauce', 200.00, 'Food', 'pasta', '🍝', true),
('ቴስቲሶያ', 'Tasty soya', 200.00, 'Food', 'soya', '🍛', true),
('Maraki Special Juice', 'Mango, avocado & passion fruit', 180.00, 'Juice', 'mango', '🥭', true),
('Fresh Avocado Juice', 'Creamy avocado blended fresh', 140.00, 'Juice', 'avocado', '🥑', true),
('Mango Puree Juice', 'Pure organic mango juice', 150.00, 'Juice', 'mango', '🥭', true),
('Strawberry Passion', 'Freshly pressed strawberry juice', 160.00, 'Juice', 'berry', '🍓', true)
ON CONFLICT DO NOTHING;

-- Seed Initial Unpaid Customer Debts for Step 4 Testing
INSERT INTO public.customer_debts (customer_name, note, amount, is_recovered) VALUES
('Abebe Bikila', 'Office tab from yesterday', 450.00, false),
('Tigist Haile', 'Lunch order credit', 320.00, false),
('Kebede Tassew', 'Juice boxes delivery credit', 200.00, false)
ON CONFLICT DO NOTHING;
