package com.fouprix.prixyi.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.context.annotation.Configuration

@Configuration
@ConfigurationProperties(prefix = "rate-limit")
data class RateLimitConfig(
    var otpPerPhone: Int = 3,
    var otpPerIp: Int = 5,
    var windowMinutes: Int = 15,
)
