package com.fouprix.prixyi.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.context.annotation.Configuration

@Configuration
@ConfigurationProperties(prefix = "jwt")
data class JwtConfig(
    var secret: String = "",
    var accessTokenExpiration: Long = 900000L,
    var refreshTokenExpiration: Long = 604800000L,
)
