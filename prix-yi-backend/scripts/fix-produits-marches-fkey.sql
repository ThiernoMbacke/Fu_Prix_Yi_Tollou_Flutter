-- ============================================================
-- Si INSERT produits / marches échoue sur une FK vers users :
-- anciennes bases pointent parfois vers auth.users au lieu de public.users.
-- Exécuter dans Supabase → SQL Editor (une fois).
-- ============================================================

-- PRODUITS
ALTER TABLE produits DROP CONSTRAINT IF EXISTS produits_created_by_fkey;
ALTER TABLE produits
  ADD CONSTRAINT produits_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;

-- MARCHES
ALTER TABLE marches DROP CONSTRAINT IF EXISTS marches_created_by_fkey;
ALTER TABLE marches
  ADD CONSTRAINT marches_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;

-- PRIX (au cas où)
ALTER TABLE prix DROP CONSTRAINT IF EXISTS prix_created_by_fkey;
ALTER TABLE prix
  ADD CONSTRAINT prix_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;
