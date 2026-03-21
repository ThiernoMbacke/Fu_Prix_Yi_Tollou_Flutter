package com.fouprix.prixyi.model.entity

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "produits")
class Produit(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    /** varchar côté JPA ; Postgres accepte l’insert dans une colonne TEXT existante. */
    @Column(nullable = false, length = 500)
    val nom: String = "",

    @Column(nullable = false, length = 120)
    val categorie: String = "",
) {
    @Transient
    var createdByUserId: UUID? = null

    @Transient
    var createdAt: Instant? = null
}
