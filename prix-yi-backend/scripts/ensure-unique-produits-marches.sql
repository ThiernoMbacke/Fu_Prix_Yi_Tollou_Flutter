-- Unicité logique (insensible à la casse) — exécuter dans Supabase SQL Editor
-- Avant : supprimez ou fusionnez les doublons existants, sinon CREATE INDEX échouera.

CREATE UNIQUE INDEX IF NOT EXISTS produits_nom_categorie_lower_unique
    ON public.produits (lower(trim(nom)), lower(trim(categorie)));

CREATE UNIQUE INDEX IF NOT EXISTS marches_ville_nom_lower_unique
    ON public.marches (ville_id, lower(trim(nom)))
    WHERE ville_id IS NOT NULL;
