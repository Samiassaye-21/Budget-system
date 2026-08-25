-- ==============================================================================
-- MARAKI POS & KITCHEN SYSTEM - COMPLETE SUPABASE SQL SCHEMA (v2.7.0)
-- Copy and Paste this entire file into your Supabase SQL Editor and click "RUN"
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    amharic_name TEXT,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Food', 'Juice', 'Beverage')),
    image_url TEXT,
    tone TEXT NOT NULL DEFAULT 'mango',
    emoji TEXT NOT NULL DEFAULT '🍹',
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Shifts Table
CREATE TABLE IF NOT EXISTS public.shifts (
    id TEXT PRIMARY KEY,
    shift_type TEXT NOT NULL CHECK (shift_type IN ('day', 'night')),
    cashier_name TEXT NOT NULL,
    opening_cups INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('active', 'closed')) DEFAULT 'active',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

-- 4. Orders Table (Realtime Orders & Payment Records)
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    shift_id TEXT,
    shift_type TEXT DEFAULT 'day',
    cashier_name TEXT DEFAULT 'Cashier',
    items JSONB NOT NULL,
    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    tax NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total NUMERIC(10, 2) NOT NULL,
    payment_method TEXT NOT NULL,
    notes TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Kitchen Tickets Table (Kitchen Display & Transfer System)
CREATE TABLE IF NOT EXISTS public.kitchen_tickets (
    id TEXT PRIMARY KEY,
    route TEXT NOT NULL, -- 'Day shift' | 'Night shift' | 'Bue delivery'
    items JSONB NOT NULL,
    total_quantity INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'cooking' | 'ready' | 'delivered'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Shift Expenses Table
CREATE TABLE IF NOT EXISTS public.shift_expenses (
    id TEXT PRIMARY KEY,
    shift_id TEXT,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Customer Debts Table (Past & Recovered Credit Debts)
CREATE TABLE IF NOT EXISTS public.customer_debts (
    id TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    note TEXT DEFAULT '',
    cup_count INT NOT NULL DEFAULT 0,
    price_per_cup NUMERIC(10, 2) NOT NULL DEFAULT 170.00,
    amount NUMERIC(10, 2) NOT NULL,
    is_recovered BOOLEAN NOT NULL DEFAULT false,
    shift_id_created TEXT,
    shift_id_recovered TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    recovered_at TIMESTAMPTZ
);

-- 8. Shift Reconciliations Table (End of Shift Guided Wizard Record)
CREATE TABLE IF NOT EXISTS public.shift_reconciliations (
    id TEXT PRIMARY KEY,
    shift_id TEXT,
    shift_type TEXT NOT NULL,
    cashier_name TEXT NOT NULL,
    
    -- Step 1: Sales breakdown
    gross_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    cash_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    transfer_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    credit_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    delivery_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    tip_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_orders_count INT NOT NULL DEFAULT 0,

    -- Step 2: Cup inventory count
    opening_cups INT NOT NULL DEFAULT 0,
    added_cups INT NOT NULL DEFAULT 0,
    leftover_cups INT NOT NULL DEFAULT 0,
    calculated_cups_sold INT NOT NULL DEFAULT 0,
    tablet_cups_sold INT NOT NULL DEFAULT 0,
    cups_variance INT NOT NULL DEFAULT 0,

    -- Step 3: Kitchen Food Cross-Check
    total_kitchen_food_cooked INT NOT NULL DEFAULT 0,
    total_waiter_food_sold INT NOT NULL DEFAULT 0,
    food_variance INT NOT NULL DEFAULT 0,

    -- Step 4: Expenses & Recovered Debts
    total_expenses NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_recovered_cups INT NOT NULL DEFAULT 0,
    total_recovered_debts NUMERIC(10, 2) NOT NULL DEFAULT 0.00,

    -- Step 5: Cash Handover
    net_cash_to_owner NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    shift_notes TEXT DEFAULT '',
    closed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 9. PERMISSIONS & ROW LEVEL SECURITY (RLS)
-- Enables RLS + Full open access policies for anon & authenticated mobile apps
-- ==============================================================================
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access products" ON public.products;
CREATE POLICY "Public full access products" ON public.products FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access shifts" ON public.shifts;
CREATE POLICY "Public full access shifts" ON public.shifts FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access orders" ON public.orders;
CREATE POLICY "Public full access orders" ON public.orders FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.kitchen_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access kitchen_tickets" ON public.kitchen_tickets;
CREATE POLICY "Public full access kitchen_tickets" ON public.kitchen_tickets FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.shift_expenses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access shift_expenses" ON public.shift_expenses;
CREATE POLICY "Public full access shift_expenses" ON public.shift_expenses FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.customer_debts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access customer_debts" ON public.customer_debts;
CREATE POLICY "Public full access customer_debts" ON public.customer_debts FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.shift_reconciliations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public full access shift_reconciliations" ON public.shift_reconciliations;
CREATE POLICY "Public full access shift_reconciliations" ON public.shift_reconciliations FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ==============================================================================
-- 10. SEED INITIAL MENU PRODUCTS (20 Fresh Foods & Juices)
-- ==============================================================================
INSERT INTO public.products (id, name, amharic_name, description, price, category, image_url, is_available) VALUES
('f-1', 'Maraki Combo Salad', 'ማራኪ ኮመቦ ሳላድ', 'Signature mixed combo salad', 430.00, 'Food', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500', true),
('f-2', 'Salad', 'ሳላድ', 'Fresh vegetable salad', 320.00, 'Food', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500', true),
('f-3', 'Pasta with Salad', 'ፓስታ በሳላድ', 'Pasta served with salad', 320.00, 'Food', 'https://images.unsplash.com/photo-1621996346565-e3def616403c?w=500', true),
('f-4', 'Rice with Salad', 'ሩዝ በሳላድ', 'Rice served with salad', 320.00, 'Food', 'https://images.unsplash.com/photo-1516714435131-44d6b64dc6a2?w=500', true),
('f-5', 'Pasta with Vegetables', 'ፓስታ በአትክልት', 'Pasta with fresh veggies', 320.00, 'Food', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500', true),
('f-6', 'Rice with Vegetables', 'ሩዝ በአትክልት', 'Rice with mixed veggies', 320.00, 'Food', 'https://images.unsplash.com/photo-1516714435131-44d6b64dc6a2?w=500', true),
('f-7', 'Pasta with Egg', 'ፓስታ በእንቁላል', 'Pasta topped with fried egg', 320.00, 'Food', 'https://images.unsplash.com/photo-1621996346565-e3def616403c?w=500', true),
('f-8', 'Rice with Egg', 'ሩዝ በእንቁላል', 'Rice topped with fried egg', 320.00, 'Food', 'https://images.unsplash.com/photo-1516714435131-44d6b64dc6a2?w=500', true),
('f-9', 'Egg Firfir', 'እንቁላል ፍርፍር', 'Scrambled eggs with injera', 230.00, 'Food', 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500', true),
('f-10', 'Egg Sils', 'እንቁላል ስልስ', 'Spicy tomato scrambled eggs', 230.00, 'Food', 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500', true),
('f-11', 'Egg Sandwich', 'እንቁላል ሳንድዊች', 'Fresh egg toast sandwich', 120.00, 'Food', 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500', true),
('f-12', 'Vegetable Sandwich', 'አትክልት ሳንድዊች', 'Healthy green vegetable sandwich', 100.00, 'Food', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500', true),
('f-13', 'Fruit Punch', 'ፍሩት ፓንች', 'Fresh assorted fruit cuts', 320.00, 'Food', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500', true),
('f-14', 'Firfir', 'ፍርፍር', 'Traditional spiced firfir', 200.00, 'Food', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500', true),
('f-15', 'Pasta with Sauce', 'ፓስታ በስጎ', 'Pasta with seasoned tomato sauce', 200.00, 'Food', 'https://images.unsplash.com/photo-1621996346565-e3def616403c?w=500', true),
('f-16', 'Tasty Soya', 'ቴስቲሶያ', 'Savory seasoned soya dish', 200.00, 'Food', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500', true),
('j-1', 'Avocado', 'አቮካዶ', 'Fresh creamy avocado juice', 170.00, 'Juice', 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=500', true),
('j-2', 'Mango', 'ማንጎ', 'Sweet tropical mango juice', 170.00, 'Juice', 'https://images.unsplash.com/photo-1546173159-315724a31696?w=500', true),
('j-3', 'Papaya', 'ፓፓያ', 'Fresh ripe papaya juice', 170.00, 'Juice', 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500', true),
('j-4', 'Spriss', 'ስፕሪስ', 'Layered mixed juice', 170.00, 'Juice', 'https://images.unsplash.com/photo-1546173159-315724a31696?w=500', true)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    amharic_name = EXCLUDED.amharic_name,
    price = EXCLUDED.price,
    category = EXCLUDED.category;

-- ==============================================================================
-- 11. SEED SAMPLE UNPAID CUSTOMER DEBTS
-- ==============================================================================
INSERT INTO public.customer_debts (id, customer_name, note, cup_count, price_per_cup, amount, is_recovered) VALUES
('debt-1', 'Abebe Bikila', 'Office tab from yesterday', 3, 170.00, 510.00, false),
('debt-2', 'Tigist Haile', 'Lunch order credit', 2, 170.00, 340.00, false),
('debt-3', 'Kebede Tassew', 'Juice boxes delivery credit', 1, 170.00, 170.00, false)
ON CONFLICT (id) DO NOTHING;
