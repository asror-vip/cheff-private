-- Zagatovka (Yarim tayyor mahsulotlar) uchun bazaga yangi ustun qo'shamiz
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_semi_finished BOOLEAN DEFAULT false;
