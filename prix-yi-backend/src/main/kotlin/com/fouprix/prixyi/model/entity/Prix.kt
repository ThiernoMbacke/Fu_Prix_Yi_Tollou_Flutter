package com.fouprix.prixyi.model.entity

import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "prix")
class Prix(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "produit_id", nullable = false)
    val produitId: UUID,

    @Column(name = "marche_id", nullable = false)
    val marcheId: UUID,

    @Column(nullable = false, precision = 10, scale = 2)
    val prix: BigDecimal,

    @Column(nullable = false)
    val date: LocalDate = LocalDate.now(),

    @Column(name = "created_by")
    val createdBy: UUID? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant = Instant.now(),

    // Option premium : coordonnées et paiement
    @Column(name = "contact_phone")
    val contactPhone: String? = null,

    @Column(name = "contact_location")
    val contactLocation: String? = null,

    @Column(name = "contact_lat")
    val contactLat: Double? = null,

    @Column(name = "contact_lng")
    val contactLng: Double? = null,

    @Column(name = "is_premium", nullable = false)
    val isPremium: Boolean = false,

    @Column(name = "premium_amount")
    val premiumAmount: Int? = null,

    @Column(name = "payment_method")
    val paymentMethod: String? = null,

    @Column(name = "payment_reference")
    val paymentReference: String? = null,

    @Column(name = "premium_paid_at")
    val premiumPaidAt: Instant? = null,
)
