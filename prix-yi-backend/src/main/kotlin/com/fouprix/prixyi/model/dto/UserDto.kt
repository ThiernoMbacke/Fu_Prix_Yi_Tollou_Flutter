package com.fouprix.prixyi.model.dto

import com.fouprix.prixyi.model.entity.User
import java.util.*

data class UserDto(
    val id: UUID,
    val phone: String,
    val nom: String?,
    val role: String,
    val contributionsCount: Int,
    val createdAt: String?,
) {
    companion object {
        fun from(user: User): UserDto = UserDto(
            id = user.id!!,
            phone = user.phone,
            nom = user.nom,
            role = user.role.name,
            contributionsCount = user.contributionsCount,
            createdAt = user.createdAt.toString(),
        )
    }
}
