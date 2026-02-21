package com.fouprix.prixyi.service

import com.fouprix.prixyi.config.JwtConfig
import com.fouprix.prixyi.exception.TokenExpiredException
import com.fouprix.prixyi.model.entity.User
import io.jsonwebtoken.Claims
import io.jsonwebtoken.ExpiredJwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.stereotype.Service
import java.util.*
import javax.crypto.SecretKey

@Service
class JwtService(private val jwtConfig: JwtConfig) {

    private val key: SecretKey by lazy {
        val bytes = jwtConfig.secret.encodeToByteArray()
        Keys.hmacShaKeyFor(if (bytes.size < 32) ByteArray(32).also { bytes.copyInto(it) } else bytes)
    }

    fun generateAccessToken(user: User): String {
        val now = Date()
        val expiry = Date(now.time + jwtConfig.accessTokenExpiration)
        return Jwts.builder()
            .subject(user.id.toString())
            .claim("phone", user.phone)
            .claim("role", user.role.name)
            .issuedAt(now)
            .expiration(expiry)
            .signWith(key)
            .compact()
    }

    fun generateRefreshToken(): String = UUID.randomUUID().toString().replace("-", "") +
        UUID.randomUUID().toString().replace("-", "")

    fun getAccessTokenExpirationMs(): Long = jwtConfig.accessTokenExpiration
    fun getRefreshTokenExpirationMs(): Long = jwtConfig.refreshTokenExpiration

    fun parseUserId(token: String): UUID? {
        return try {
            val claims = parseClaims(token)
            UUID.fromString(claims.subject)
        } catch (e: ExpiredJwtException) {
            throw TokenExpiredException()
        } catch (_: Exception) {
            null
        }
    }

    fun parseClaims(token: String): Claims {
        return Jwts.parser()
            .verifyWith(key)
            .build()
            .parseSignedClaims(token)
            .payload
    }

    fun validateToken(token: String): Boolean {
        return try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token)
            true
        } catch (_: Exception) {
            false
        }
    }
}
