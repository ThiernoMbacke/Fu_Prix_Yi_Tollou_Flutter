-- Migration : ajouter les colonnes premium à la table prix (sans supprimer de données).
-- Exécuter dans Supabase → SQL Editor si la table prix existe déjà.

ALTER TABLE prix
  ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(20),
  ADD COLUMN IF NOT EXISTS contact_location TEXT,
  ADD COLUMN IF NOT EXISTS contact_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS contact_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS premium_amount INT,
  ADD COLUMN IF NOT EXISTS payment_method TEXT,
  ADD COLUMN IF NOT EXISTS payment_reference TEXT,
  ADD COLUMN IF NOT EXISTS premium_paid_at TIMESTAMP;
