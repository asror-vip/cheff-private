-- ==========================================
-- CHEFCONTROL AI - SUPABASE SCHEMA SETUP
-- (Faqat yetishmayotgan jadvallarni qo'shadi)
-- ==========================================

-- 1. STOLLAR (TABLES) jadvali
CREATE TABLE IF NOT EXISTS public.restaurant_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    capacity INT DEFAULT 4,
    zone VARCHAR(255) DEFAULT 'Umumiy',
    status VARCHAR(50) DEFAULT 'available',
    current_order_id UUID,
    assigned_waiter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. KASSA SMENALARI (CASHIER SHIFTS) jadvali
CREATE TABLE IF NOT EXISTS public.cashier_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    cashier_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    cashier_name VARCHAR(255) NOT NULL,
    opened_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    status VARCHAR(50) DEFAULT 'open',
    initial_cash NUMERIC DEFAULT 0,
    expected_cash NUMERIC DEFAULT 0,
    expected_card NUMERIC DEFAULT 0,
    actual_cash NUMERIC DEFAULT 0,
    difference NUMERIC DEFAULT 0,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. BUYURTMALAR (ORDERS) jadvali
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    table_id UUID REFERENCES public.restaurant_tables(id) ON DELETE SET NULL,
    table_name VARCHAR(255),
    assigned_waiter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    type VARCHAR(50) DEFAULT 'dine_in',
    status VARCHAR(50) DEFAULT 'open',
    service_fee_percentage NUMERIC DEFAULT 10.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. BUYURTMA IDISHLARI (ORDER ITEMS) jadvali
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    quantity NUMERIC DEFAULT 1,
    price NUMERIC DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft',
    comment TEXT,
    station VARCHAR(50) DEFAULT 'none',
    cancel_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. KDS VIEW (Oshxona ekrani uchun VIEW)
CREATE OR REPLACE VIEW public.kds_view AS
SELECT
    oi.id,
    oi.order_id,
    oi.recipe_id,
    r.name,
    oi.quantity,
    oi.status,
    oi.comment,
    oi.station,
    oi.created_at,
    o.table_name,
    o.assigned_waiter_id,
    o.restaurant_id,
    substring(o.id::text from 1 for 6) as order_number
FROM public.order_items oi
JOIN public.orders o ON oi.order_id = o.id
JOIN public.recipes r ON oi.recipe_id = r.id;

-- 6. RPC FUNKSIYALAR (Ofitsiant bir nechta idishni 1 marta yuborishi uchun)
CREATE OR REPLACE FUNCTION public.submit_order_items(
    p_order_id UUID,
    p_items JSONB,
    p_idempotency_key TEXT
) RETURNS TEXT AS $$
DECLARE
    item JSONB;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            id, order_id, recipe_id, quantity, price, status, comment, station, created_at, updated_at
        ) VALUES (
            (item->>'id')::uuid,
            p_order_id,
            (item->>'recipe_id')::uuid,
            (item->>'quantity')::numeric,
            (item->>'price')::numeric,
            item->>'status',
            item->>'comment',
            item->>'station',
            NOW(),
            NOW()
        );
    END LOOP;

    RETURN 'success';
END;
$$ LANGUAGE plpgsql;

-- 7. RLS (Row Level Security) qoidalari - Xavfsizlik
ALTER TABLE public.restaurant_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cashier_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all for authenticated users" ON public.restaurant_tables FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.cashier_shifts FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.orders FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.order_items FOR ALL USING (auth.role() = 'authenticated');