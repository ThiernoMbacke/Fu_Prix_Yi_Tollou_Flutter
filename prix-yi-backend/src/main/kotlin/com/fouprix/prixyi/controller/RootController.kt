package com.fouprix.prixyi.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class RootController {

    @GetMapping("/")
    fun root(): Map<String, Any> = mapOf(
        "service" to "Prix Yi API",
        "version" to "1.0",
        "health" to "/actuator/health",
        "demoLogin" to "POST /api/auth/demo body {\"demoUser\":\"test1\"}",
        "note" to "Routes /api/** (sauf /api/auth/**) need header Authorization: Bearer <token>",
    )

    @GetMapping("/api")
    fun apiInfo(): Map<String, Any> = mapOf(
        "message" to "Use POST /api/auth/demo then send JWT on protected routes.",
    )
}
