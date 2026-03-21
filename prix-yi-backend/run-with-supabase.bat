@echo off
REM Remplace TON_MOT_DE_PASSE par le mot de passe Supabase (Project Settings > Database > Database password)
set SUPABASE_DB_PASSWORD=TON_MOT_DE_PASSE
call gradlew.bat bootRun
