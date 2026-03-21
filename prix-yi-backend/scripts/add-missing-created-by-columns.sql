-- Colonnes manquantes : Postgres 42703 "column created_by of relation produits does not exist"
-- Executer dans Supabase SQL Editor. Prerequis : public.users existe.

ALTER TABLE produits ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE produits ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE marches ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE marches ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE prix ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE prix ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE produits DROP CONSTRAINT IF EXISTS produits_created_by_fkey;
ALTER TABLE produits
  ADD CONSTRAINT produits_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;

ALTER TABLE marches DROP CONSTRAINT IF EXISTS marches_created_by_fkey;
ALTER TABLE marches
  ADD CONSTRAINT marches_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;

ALTER TABLE prix DROP CONSTRAINT IF EXISTS prix_created_by_fkey;
ALTER TABLE prix
  ADD CONSTRAINT prix_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;
