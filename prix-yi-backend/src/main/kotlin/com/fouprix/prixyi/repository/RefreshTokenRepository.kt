package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.RefreshToken
import com.fouprix.prixyi.model.entity.User
import org.springframework.data.jpa.repository.JpaRepository
import java.util.*

interface RefreshTokenRepository : JpaRepository<RefreshToken, UUID> {
    fun findByTokenAndIsRevokedFalse(token: String): Optional<RefreshToken>
    fun deleteAllByUser(user: User)
}
