package com.fouprix.prixyi.model.entity

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "otp_attempts", indexes = [Index(name = "idx_otp_phone", columnList = "phone")])
class OtpAttempt(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(nullable = false, length = 20)
    val phone: String,

    @Column(length = 50)
    val ipAddress: String? = null,

    @Column(nullable = false)
    var attempts: Int = 1,

    @Column(nullable = false)
    var lastAttempt: Instant = Instant.now(),

    @Column(nullable = false)
    var isBlocked: Boolean = false,
)
