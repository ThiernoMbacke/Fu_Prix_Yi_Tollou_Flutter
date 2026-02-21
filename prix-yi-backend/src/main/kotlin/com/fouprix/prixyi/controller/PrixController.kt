package com.fouprix.prixyi.controller

import com.fouprix.prixyi.model.entity.Prix
import com.fouprix.prixyi.repository.PrixRepository
import com.fouprix.prixyi.service.UserService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

@RestController
@RequestMapping("/api/prix")
class PrixController(
    private val prixRepository: PrixRepository,
    private val userService: UserService,
) {

    @PostMapping
    fun addPrix(
        @AuthenticationPrincipal userDetails: UserDetails,
        @RequestBody body: Map<String, Any>,
    ): ResponseEntity<Map<String, Any>> {
        val userId = UUID.fromString(userDetails.username)
        val produitId = UUID.fromString(body["produitId"] as String)
        val marcheId = UUID.fromString(body["marcheId"] as String)
        val prixValue = (body["prix"] as Number).toDouble()
        val prix = Prix(
            produitId = produitId,
            marcheId = marcheId,
            prix = BigDecimal.valueOf(prixValue),
            date = LocalDate.now(),
            createdBy = userId,
        )
        prixRepository.save(prix)
        userService.incrementContributions(userId)
        return ResponseEntity.ok(mapOf("success" to true, "id" to prix.id.toString()))
    }
}
