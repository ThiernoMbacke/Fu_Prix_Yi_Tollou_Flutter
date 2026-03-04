package com.fouprix.prixyi.util

object ValidationUtils {
    /** Format normalisé stocké : +221XXXXXXXXX */
    private val PHONE_NORMALIZED_REGEX = Regex("^\\+221[0-9]{9}$")
    /** Préfixes Sénégal mobiles : 70, 71, 76, 77, 78 — 9 chiffres au total */
    private val PHONE_9_DIGITS_PREFIX = Regex("^7[01678][0-9]{7}$")
    private val OTP_REGEX = Regex("^[0-9]{6}$")

    fun isValidSenegalPhone(phone: String): Boolean =
        PHONE_NORMALIZED_REGEX.matches(phone.replace("\\s".toRegex(), ""))

    /**
     * Normalise un numéro saisi par l'utilisateur.
     * Accepte : 771234567, 77 123 45 67, +221771234567.
     * Exige 9 chiffres avec préfixe 70, 71, 76, 77 ou 78.
     * @return numéro au format +221XXXXXXXXX ou null si invalide
     */
    fun normalizeSenegalPhone(input: String?): String? {
        if (input.isNullOrBlank()) return null
        val digits = input.replace(Regex("[^0-9]"), "")
        return when {
            digits.length == 9 && PHONE_9_DIGITS_PREFIX.matches(digits) -> "+221$digits"
            digits.length == 12 && digits.startsWith("221") && PHONE_9_DIGITS_PREFIX.matches(digits.drop(3)) -> "+221${digits.drop(3)}"
            else -> null
        }
    }

    fun isValidOtp(code: String): Boolean = OTP_REGEX.matches(code)
}
