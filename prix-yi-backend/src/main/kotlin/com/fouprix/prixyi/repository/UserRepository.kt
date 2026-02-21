package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.User
import org.springframework.data.jpa.repository.JpaRepository
import java.util.*

interface UserRepository : JpaRepository<User, UUID> {
    fun findByPhone(phone: String): Optional<User>
    fun existsByPhone(phone: String): Boolean
}
