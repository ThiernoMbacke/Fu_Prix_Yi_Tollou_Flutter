package com.fouprix.prixyi.util

import com.fouprix.prixyi.config.RateLimitConfig
import com.fouprix.prixyi.exception.OtpRateLimitException
import com.fouprix.prixyi.model.entity.OtpAttempt
import com.fouprix.prixyi.repository.OtpAttemptRepository
import org.springframework.stereotype.Component
import java.time.Instant

@Component
class RateLimiter(
    private val config: RateLimitConfig,
    private val otpAttemptRepo: OtpAttemptRepository,
) {

    fun checkAndRecordPhone(phone: String, ipAddress: String?) {
        val normalized = phone.replace("\\s".toRegex(), "")
        val attempt = otpAttemptRepo.findByPhone(normalized).orElseGet {
            OtpAttempt(phone = normalized, ipAddress = ipAddress)
        }
        if (attempt.isBlocked) throw OtpRateLimitException("Numéro temporairement bloqué.")
        val windowStart = Instant.now().minusSeconds(config.windowMinutes * 60L)
        if (attempt.lastAttempt.isBefore(windowStart)) {
            attempt.attempts = 1
            attempt.lastAttempt = Instant.now()
        } else {
            attempt.attempts++
            attempt.lastAttempt = Instant.now()
            if (attempt.attempts > config.otpPerPhone) {
                attempt.isBlocked = true
                otpAttemptRepo.save(attempt)
                throw OtpRateLimitException("Trop de codes demandés pour ce numéro.")
            }
        }
        otpAttemptRepo.save(attempt)
    }

    fun checkIp(ipAddress: String?) {
        if (ipAddress.isNullOrBlank()) return
        val attempt = otpAttemptRepo.findByIpAddress(ipAddress).orElseGet {
            OtpAttempt(phone = "ip:$ipAddress", ipAddress = ipAddress)
        }
        if (attempt.isBlocked) throw OtpRateLimitException("Trop de demandes depuis cette adresse.")
        val windowStart = Instant.now().minusSeconds(config.windowMinutes * 60L)
        if (attempt.lastAttempt.isBefore(windowStart)) {
            attempt.attempts = 1
            attempt.lastAttempt = Instant.now()
        } else {
            attempt.attempts++
            attempt.lastAttempt = Instant.now()
            if (attempt.attempts > config.otpPerIp) {
                attempt.isBlocked = true
                otpAttemptRepo.save(attempt)
                throw OtpRateLimitException("Trop de demandes depuis cette adresse.")
            }
        }
        otpAttemptRepo.save(attempt)
    }
}
