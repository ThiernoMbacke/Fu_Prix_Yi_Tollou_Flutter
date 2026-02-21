package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.OtpAttempt
import org.springframework.data.jpa.repository.JpaRepository
import java.util.*

interface OtpAttemptRepository : JpaRepository<OtpAttempt, UUID> {
    fun findByPhone(phone: String): Optional<OtpAttempt>
    fun findByIpAddress(ipAddress: String): Optional<OtpAttempt>
}
