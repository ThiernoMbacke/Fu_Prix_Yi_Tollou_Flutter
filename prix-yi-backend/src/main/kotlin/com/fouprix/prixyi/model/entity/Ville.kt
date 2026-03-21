package com.fouprix.prixyi.model.entity

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "villes")
class Ville(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    /** Colonne Postgres `TEXT` (pas varchar) — requis pour ddl-auto: validate */
    @Column(nullable = false, unique = true, columnDefinition = "text")
    val nom: String = "",

    @Column(name = "created_at", updatable = false, insertable = false)
    val createdAt: Instant? = null,
)
