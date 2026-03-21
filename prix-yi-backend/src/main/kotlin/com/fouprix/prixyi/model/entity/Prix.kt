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

    /** Script SQL : `date` sans NOT NULL */
    @Column
    val date: LocalDate? = LocalDate.now(),

    @Column(name = "created_at", updatable = false, insertable = false)
    val createdAt: Instant? = null,

    // Option premium : coordonnées et paiement
    @Column(name = "contact_phone")
    val contactPhone: String? = null,

    @Column(name = "contact_location", columnDefinition = "text")
    val contactLocation: String? = null,

    @Column(name = "contact_lat")
    val contactLat: Double? = null,

    @Column(name = "contact_lng")
    val contactLng: Double? = null,

    /** Script SQL : `is_premium` sans NOT NULL */
    @Column(name = "is_premium")
    val isPremium: Boolean = false,

    @Column(name = "premium_amount")
    val premiumAmount: Int? = null,

    @Column(name = "payment_method", columnDefinition = "text")
    val paymentMethod: String? = null,

    @Column(name = "payment_reference", columnDefinition = "text")
    val paymentReference: String? = null,

    @Column(name = "premium_paid_at")
    val premiumPaidAt: Instant? = null,
) {
    @Transient
    var createdByUserId: UUID? = null
}
