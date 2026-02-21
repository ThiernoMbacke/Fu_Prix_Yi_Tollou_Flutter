package com.fouprix.prixyi.service

import com.fouprix.prixyi.util.ValidationUtils
import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.stereotype.Service
import java.util.concurrent.TimeUnit

@Service
class OtpService(private val redis: StringRedisTemplate) {

    companion object {
        private const val OTP_PREFIX = "otp:"
        private const val OTP_TTL_MINUTES = 5L
    }

    fun generateAndStore(phone: String): String {
        val normalized = phone.replace("\\s".toRegex(), "")
        require(ValidationUtils.isValidSenegalPhone(normalized)) { "Numéro invalide" }
        val code = (100000..999999).random().toString()
        redis.opsForValue().set(OTP_PREFIX + normalized, code, OTP_TTL_MINUTES, TimeUnit.MINUTES)
        return code
    }

    fun verify(phone: String, code: String): Boolean {
        val normalized = phone.replace("\\s".toRegex(), "")
        val stored = redis.opsForValue().get(OTP_PREFIX + normalized) ?: return false
        if (stored != code) return false
        redis.delete(OTP_PREFIX + normalized)
        return true
    }

    fun getStoredCode(phone: String): String? {
        val normalized = phone.replace("\\s".toRegex(), "")
        return redis.opsForValue().get(OTP_PREFIX + normalized)
    }
}
