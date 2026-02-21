package com.fouprix.prixyi.service

import com.fouprix.prixyi.exception.OtpBlockedException
import com.fouprix.prixyi.exception.OtpInvalidException
import com.fouprix.prixyi.exception.TokenExpiredException
import com.fouprix.prixyi.model.dto.AuthResponse
import com.fouprix.prixyi.model.dto.OtpVerifyRequest
import com.fouprix.prixyi.model.dto.SendOtpRequest
import com.fouprix.prixyi.model.dto.UserDto
import com.fouprix.prixyi.model.entity.RefreshToken
import com.fouprix.prixyi.model.entity.User
import com.fouprix.prixyi.model.enums.Role
import com.fouprix.prixyi.repository.RefreshTokenRepository
import com.fouprix.prixyi.repository.UserRepository
import com.fouprix.prixyi.util.ValidationUtils
import com.fouprix.prixyi.util.RateLimiter
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.*
import javax.servlet.http.HttpServletRequest

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val otpService: OtpService,
    private val smsService: SmsService,
    private val jwtService: JwtService,
    private val rateLimiter: RateLimiter,
) {

    @Transactional
    fun sendOtp(request: SendOtpRequest, httpRequest: HttpServletRequest?) {
        val phone = request.phoneNumber.replace("\\s".toRegex(), "")
        require(ValidationUtils.isValidSenegalPhone(phone)) { "Numéro invalide" }
        val ip = httpRequest?.remoteAddr
        rateLimiter.checkIp(ip)
        rateLimiter.checkAndRecordPhone(phone, ip)
        val code = otpService.generateAndStore(phone)
        val sent = smsService.sendOtp(phone, code)
        if (!sent) throw IllegalStateException("Impossible d'envoyer le SMS")
    }

    @Transactional
    fun verifyOtp(request: OtpVerifyRequest): AuthResponse {
        val phone = request.phoneNumber.replace("\\s".toRegex(), "")
        val code = request.code
        if (!otpService.verify(phone, code)) throw OtpInvalidException()
        var user = userRepository.findByPhone(phone).orElse(null)
            ?: userRepository.save(
                User(phone = phone, role = Role.USER)
            )
        val accessToken = jwtService.generateAccessToken(user)
        val refreshTokenValue = jwtService.generateRefreshToken()
        val expiresAt = Instant.now().plusMillis(jwtService.getRefreshTokenExpirationMs())
        refreshTokenRepository.save(
            RefreshToken(user = user, token = refreshTokenValue, expiresAt = expiresAt)
        )
        return AuthResponse(
            accessToken = accessToken,
            refreshToken = refreshTokenValue,
            expiresIn = jwtService.getAccessTokenExpirationMs() / 1000,
            user = UserDto.from(user),
        )
    }

    @Transactional
    fun refreshToken(refreshToken: String): AuthResponse {
        val token = refreshTokenRepository.findByTokenAndIsRevokedFalse(refreshToken)
            .orElseThrow { TokenExpiredException() }
        if (token.expiresAt.isBefore(Instant.now())) {
            token.isRevoked = true
            refreshTokenRepository.save(token)
            throw TokenExpiredException()
        }
        val user = token.user
        token.isRevoked = true
        refreshTokenRepository.save(token)
        val newAccess = jwtService.generateAccessToken(user)
        val newRefreshValue = jwtService.generateRefreshToken()
        val expiresAt = Instant.now().plusMillis(jwtService.getRefreshTokenExpirationMs())
        refreshTokenRepository.save(
            RefreshToken(user = user, token = newRefreshValue, expiresAt = expiresAt)
        )
        return AuthResponse(
            accessToken = newAccess,
            refreshToken = newRefreshValue,
            expiresIn = jwtService.getAccessTokenExpirationMs() / 1000,
            user = UserDto.from(user),
        )
    }

    @Transactional
    fun logout(refreshToken: String?) {
        if (refreshToken.isNullOrBlank()) return
        refreshTokenRepository.findByTokenAndIsRevokedFalse(refreshToken).ifPresent {
            it.isRevoked = true
            refreshTokenRepository.save(it)
        }
    }

}
