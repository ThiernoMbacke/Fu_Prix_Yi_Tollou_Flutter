package com.fouprix.prixyi.model.entity

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "marches")
class Marche(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(nullable = false, length = 500)
    val nom: String = "",

    /** Script SQL historique : pas de NOT NULL sur ville_id */
    @Column(name = "ville_id")
    val villeId: UUID? = null,

    val latitude: Double? = null,

    val longitude: Double? = null,

    /** Souvent NOT NULL en base : chaine vide si non fourni. */
    @Column(name = "adresse", nullable = false, length = 2000)
    val adresse: String = "",
) {
    @Transient
    var createdByUserId: UUID? = null

    /** Non mappe : anciennes tables `marches` sans `created_at`. */
    @Transient
    var createdAt: Instant? = null
}
