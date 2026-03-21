package com.fouprix.prixyi.controller

import com.fouprix.prixyi.service.MarcheService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*
import java.util.*

@RestController
@RequestMapping("/api/marches")
class MarcheController(
    private val marcheService: MarcheService,
) {

    @PostMapping
    fun createMarche(
        @AuthenticationPrincipal userDetails: UserDetails,
        @RequestBody body: Map<String, Any>,
    ): ResponseEntity<Map<String, Any>> {
        val userId = UUID.fromString(userDetails.username)
        val nom = (body["nom"] as? String)?.trim().orEmpty()
        require(nom.isNotEmpty()) { "Le nom du marché est requis" }

        val villeIdStr = body["villeId"] as? String ?: body["ville_id"] as? String
        require(!villeIdStr.isNullOrBlank()) { "La ville est requise" }
        val villeId = UUID.fromString(villeIdStr.trim())

        val latitude = (body["latitude"] as? Number)?.toDouble()
        val longitude = (body["longitude"] as? Number)?.toDouble()
        val adresse = (body["adresse"] as? String)?.trim().orEmpty()

        val saved = marcheService.create(
            nom = nom,
            villeId = villeId,
            userId = userId,
            latitude = latitude,
            longitude = longitude,
            adresse = adresse,
        )
        return ResponseEntity.ok(
            mapOf(
                "success" to true,
                "id" to saved.id!!.toString(),
                "nom" to saved.nom,
                "villeId" to (saved.villeId?.toString() ?: villeId.toString()),
                "adresse" to saved.adresse,
            ),
        )
    }
}
