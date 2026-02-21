package com.fouprix.prixyi.exception

open class AppException(message: String) : RuntimeException(message)

class OtpBlockedException(message: String = "Trop de tentatives. Réessayez plus tard.") : AppException(message)
class OtpInvalidException(message: String = "Code incorrect ou expiré.") : AppException(message)
class OtpRateLimitException(message: String = "Trop de demandes. Réessayez dans quelques minutes.") : AppException(message)
class TokenExpiredException(message: String = "Session expirée.") : AppException(message)
class UnauthorizedException(message: String = "Non authentifié.") : AppException(message)
