package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.Marche
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface MarcheRepository : JpaRepository<Marche, UUID> {
    fun existsByVilleIdAndNomIgnoreCase(villeId: UUID, nom: String): Boolean
}
