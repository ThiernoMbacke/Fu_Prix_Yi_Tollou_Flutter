package com.fouprix.prixyi.exception

import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.AccessDeniedException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import java.time.Instant

@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(OtpBlockedException::class, OtpRateLimitException::class)
    fun handleOtpBlocked(ex: AppException): ResponseEntity<ErrorBody> =
        ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(ErrorBody(ex.message ?: "Trop de tentatives"))

    @ExceptionHandler(OtpInvalidException::class)
    fun handleOtpInvalid(ex: AppException): ResponseEntity<ErrorBody> =
        ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ErrorBody(ex.message ?: "Code invalide"))

    @ExceptionHandler(InvalidPhoneException::class)
    fun handleInvalidPhone(ex: AppException): ResponseEntity<ErrorBody> =
        ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ErrorBody(ex.message ?: "Numéro invalide"))

    @ExceptionHandler(TokenExpiredException::class, UnauthorizedException::class)
    fun handleUnauthorized(ex: AppException): ResponseEntity<ErrorBody> =
        ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ErrorBody(ex.message ?: "Non authentifie"))

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(ex: AccessDeniedException): ResponseEntity<ErrorBody> =
        ResponseEntity.status(HttpStatus.FORBIDDEN).body(ErrorBody("Acces refuse"))

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(ex: MethodArgumentNotValidException): ResponseEntity<ErrorBody> {
        val errors = ex.bindingResult.allErrors
            .filterIsInstance<FieldError>()
            .associate { err -> (err.field ?: "field") to (err.defaultMessage ?: "invalide") }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
            ErrorBody("Validation echouee", errors)
        )
    }

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(ex: IllegalArgumentException): ResponseEntity<ErrorBody> =
        ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ErrorBody(ex.message ?: "Requête invalide"))

    /** Contrainte SQL (FK, unique, NOT NULL) — souvent FK created_by → public.users mal alignée sur Supabase. */
    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDataIntegrity(ex: DataIntegrityViolationException): ResponseEntity<ErrorBody> {
        val detail = ex.mostSpecificCause.message ?: ex.message ?: "Contrainte base de données"
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
            ErrorBody(
                "Enregistrement impossible : $detail. " +
                    "Si la mention concerne une clé étrangère (created_by), exécutez le script " +
                    "scripts/fix-produits-marches-fkey.sql dans Supabase (SQL Editor).",
            ),
        )
    }

    @ExceptionHandler(Exception::class)
    fun handleGeneric(ex: Exception): ResponseEntity<ErrorBody> {
        val message = ex.message ?: "Une erreur est survenue"
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ErrorBody(message)
        )
    }
}

data class ErrorBody(
    val message: String,
    val errors: Map<String, String>? = null,
    val timestamp: String = Instant.now().toString(),
)
