// supabase/functions/verify-phone-otp/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID");
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN");
const TWILIO_VERIFY_SERVICE_SID = Deno.env.get("TWILIO_VERIFY_SERVICE_SID");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { phoneNumber, code } = await req.json();

    if (!phoneNumber || !code) {
      return new Response(
        JSON.stringify({ error: "Numéro et code requis" }),
        { 
          status: 400, 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        }
      );
    }

    // Vérifier le code avec Twilio
    const url = `https://verify.twilio.com/v2/Services/${TWILIO_VERIFY_SERVICE_SID}/VerificationCheck`;
    
    const twilioResponse = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
      },
      body: new URLSearchParams({
        To: phoneNumber,
        Code: code,
      }),
    });

    const data = await twilioResponse.json();

    if (!twilioResponse.ok || data.status !== "approved") {
      return new Response(
        JSON.stringify({ 
          success: false,
          error: "Code incorrect ou expiré" 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Code vérifié avec succès, créer/récupérer l'utilisateur dans Supabase
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // Chercher si l'utilisateur existe déjà
    const { data: existingProfile } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('phone', phoneNumber)
      .maybeSingle();

    let userId: string;

    if (existingProfile) {
      // L'utilisateur existe
      userId = existingProfile.id;
    } else {
      // Créer un nouvel utilisateur dans auth.users
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        phone: phoneNumber,
        phone_confirm: true,
      });

      if (authError || !authData.user) {
        throw new Error("Erreur lors de la création de l'utilisateur");
      }

      userId = authData.user.id;

      // Créer le profil
      await supabase.from('user_profiles').insert({
        id: userId,
        phone: phoneNumber,
        contributions_count: 0,
      });
    }

    // Générer un token de session pour l'utilisateur
    const { data: sessionData, error: sessionError } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      phone: phoneNumber,
    });

    if (sessionError || !sessionData) {
      throw new Error("Erreur lors de la génération du token");
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        userId: userId,
        accessToken: sessionData.properties.action_link,
        message: "Vérification réussie" 
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Erreur:", error);
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});