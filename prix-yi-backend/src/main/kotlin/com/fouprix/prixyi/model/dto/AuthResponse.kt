package com.fouprix.prixyi.model.dto

data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val tokenType: String = "Bearer",
    val user: UserDto,
)
