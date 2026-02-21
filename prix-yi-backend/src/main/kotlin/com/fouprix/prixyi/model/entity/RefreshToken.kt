package com.fouprix.prixyi.model.entity

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "refresh_tokens")
class RefreshToken(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, unique = true, length = 500)
    val token: String,

    @Column(nullable = false)
    val expiresAt: Instant,

    @Column(nullable = false)
    var isRevoked: Boolean = false,

    @Column(nullable = false, updatable = false)
    val createdAt: Instant = Instant.now(),
)
