-- Ajoute les colonnes attendues par l API sur `public.marches` si elles manquent.
-- Executer dans Supabase SQL Editor.

ALTER TABLE public.marches ADD COLUMN IF NOT EXISTS adresse TEXT NOT NULL DEFAULT '';
ALTER TABLE public.marches ADD COLUMN IF NOT EXISTS ville_id UUID;
ALTER TABLE public.marches ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.marches ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.marches ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE public.marches ADD COLUMN IF NOT EXISTS created_by UUID;

-- Optionnel : lier ville_id aux villes une fois les lignes coherentes
-- ALTER TABLE public.marches DROP CONSTRAINT IF EXISTS marches_ville_id_fkey;
-- ALTER TABLE public.marches ADD CONSTRAINT marches_ville_id_fkey
--   FOREIGN KEY (ville_id) REFERENCES public.villes(id) ON DELETE CASCADE;
