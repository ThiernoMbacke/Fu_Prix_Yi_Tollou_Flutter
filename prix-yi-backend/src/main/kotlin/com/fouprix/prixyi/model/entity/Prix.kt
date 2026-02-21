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
)
