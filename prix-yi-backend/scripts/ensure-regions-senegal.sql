-- Table + données de référence : régions administratives du Sénégal (14).
-- Pas d’API de création côté app : lecture seule depuis Supabase si besoin.
-- Exécuter dans Supabase SQL Editor (projet existant).

CREATE TABLE IF NOT EXISTS public.regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO public.regions (nom) VALUES
  ('Dakar'),
  ('Diourbel'),
  ('Fatick'),
  ('Kaffrine'),
  ('Kaolack'),
  ('Kédougou'),
  ('Kolda'),
  ('Louga'),
  ('Matam'),
  ('Saint-Louis'),
  ('Sédhiou'),
  ('Tambacounda'),
  ('Thiès'),
  ('Ziguinchor')
ON CONFLICT (nom) DO NOTHING;

ALTER TABLE public.regions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lecture publique regions" ON public.regions;
CREATE POLICY "Lecture publique regions" ON public.regions FOR SELECT USING (true);
