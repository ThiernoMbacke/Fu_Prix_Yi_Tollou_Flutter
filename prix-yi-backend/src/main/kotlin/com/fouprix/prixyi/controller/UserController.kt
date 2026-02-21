package com.fouprix.prixyi.controller

import com.fouprix.prixyi.model.dto.UserDto
import com.fouprix.prixyi.service.UserService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*
import java.util.*

@RestController
@RequestMapping("/api/users")
class UserController(private val userService: UserService) {

    @GetMapping("/me")
    fun getMe(@AuthenticationPrincipal userDetails: UserDetails): ResponseEntity<UserDto> {
        val userId = UUID.fromString(userDetails.username)
        return ResponseEntity.ok(userService.getById(userId))
    }

    @PutMapping("/me")
    fun updateMe(
        @AuthenticationPrincipal userDetails: UserDetails,
        @RequestBody body: Map<String, String?>,
    ): ResponseEntity<UserDto> {
        val userId = UUID.fromString(userDetails.username)
        userService.updateProfile(userId, body["nom"])
        return ResponseEntity.ok(userService.getById(userId))
    }

    @GetMapping("/stats")
    fun getStats(@AuthenticationPrincipal userDetails: UserDetails): ResponseEntity<Map<String, Any>> {
        val userId = UUID.fromString(userDetails.username)
        return ResponseEntity.ok(userService.getStats(userId))
    }
}
