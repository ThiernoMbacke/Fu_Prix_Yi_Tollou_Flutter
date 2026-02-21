package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.Prix
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface PrixRepository : JpaRepository<Prix, UUID>
