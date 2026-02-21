package com.fouprix.prixyi.controller

import com.fouprix.prixyi.model.dto.AuthResponse
import com.fouprix.prixyi.model.dto.OtpVerifyRequest
import com.fouprix.prixyi.model.dto.RefreshTokenRequest
import com.fouprix.prixyi.model.dto.SendOtpRequest
import com.fouprix.prixyi.service.AuthService
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
class AuthController(private val authService: AuthService) {

    @PostMapping("/send-otp")
    fun sendOtp(
        @Valid @RequestBody request: SendOtpRequest,
        httpRequest: HttpServletRequest?,
    ): ResponseEntity<Map<String, Any>> {
        authService.sendOtp(request, httpRequest)
        return ResponseEntity.ok(mapOf("success" to true, "message" to "Code envoyé"))
    }

    @PostMapping("/verify-otp")
    fun verifyOtp(@Valid @RequestBody request: OtpVerifyRequest): ResponseEntity<AuthResponse> {
        val response = authService.verifyOtp(request)
        return ResponseEntity.ok(response)
    }

    @PostMapping("/refresh-token")
    fun refreshToken(@Valid @RequestBody request: RefreshTokenRequest): ResponseEntity<AuthResponse> {
        val response = authService.refreshToken(request.refreshToken)
        return ResponseEntity.ok(response)
    }

    @PostMapping("/logout")
    fun logout(@RequestBody(required = false) body: Map<String, String>?): ResponseEntity<Map<String, Any>> {
        val refreshToken = body?.get("refreshToken")
        authService.logout(refreshToken)
        return ResponseEntity.ok(mapOf("success" to true))
    }
}
