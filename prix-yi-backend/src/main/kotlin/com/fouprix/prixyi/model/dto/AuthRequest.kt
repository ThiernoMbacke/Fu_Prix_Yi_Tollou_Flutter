package com.fouprix.prixyi.model.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern

data class SendOtpRequest(
    @field:NotBlank(message = "Le numéro est requis")
    @field:Pattern(regexp = "^\\+221[0-9]{9}$", message = "Format invalide. Ex: +221771234567")
    val phoneNumber: String,
)

data class OtpVerifyRequest(
    @field:NotBlank(message = "Le numéro est requis")
    @field:Pattern(regexp = "^\\+221[0-9]{9}$", message = "Format invalide")
    val phoneNumber: String,

    @field:NotBlank(message = "Le code est requis")
    @field:Pattern(regexp = "^[0-9]{6}$", message = "Le code doit contenir 6 chiffres")
    val code: String,
)

data class RefreshTokenRequest(
    @field:NotBlank(message = "Le refresh token est requis")
    val refreshToken: String,
)

/** Connexion démo sans OTP : test1 ou test2. À n'utiliser qu'en démo. */
data class DemoLoginRequest(
    @field:NotBlank(message = "demoUser requis (test1 ou test2)")
    @field:Pattern(regexp = "^(test1|test2)$", message = "demoUser doit être test1 ou test2")
    val demoUser: String,
)
