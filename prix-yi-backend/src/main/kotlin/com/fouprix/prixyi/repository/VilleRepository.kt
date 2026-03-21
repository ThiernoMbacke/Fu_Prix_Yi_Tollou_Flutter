package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.Ville
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface VilleRepository : JpaRepository<Ville, UUID>
