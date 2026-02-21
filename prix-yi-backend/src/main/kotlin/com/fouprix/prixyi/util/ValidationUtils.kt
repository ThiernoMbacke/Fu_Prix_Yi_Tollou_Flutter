package com.fouprix.prixyi.util

object ValidationUtils {
    private val PHONE_REGEX = Regex("^\\+221[0-9]{9}$")
    private val OTP_REGEX = Regex("^[0-9]{6}$")

    fun isValidSenegalPhone(phone: String): Boolean =
        PHONE_REGEX.matches(phone.replace("\\s".toRegex(), ""))

    fun isValidOtp(code: String): Boolean = OTP_REGEX.matches(code)
}
