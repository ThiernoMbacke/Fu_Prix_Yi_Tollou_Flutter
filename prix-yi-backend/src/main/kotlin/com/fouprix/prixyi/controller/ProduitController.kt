package com.fouprix.prixyi.controller

import com.fouprix.prixyi.service.ProduitService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*
import java.util.*

@RestController
@RequestMapping("/api/produits")
class ProduitController(
    private val produitService: ProduitService,
) {

    @PostMapping
    fun createProduit(
        @AuthenticationPrincipal userDetails: UserDetails,
        @RequestBody body: Map<String, Any>,
    ): ResponseEntity<Map<String, Any>> {
        val userId = UUID.fromString(userDetails.username)
        val nom = (body["nom"] as? String)?.trim().orEmpty()
        val categorie = (body["categorie"] as? String)?.trim().orEmpty()
        require(nom.isNotEmpty()) { "Le nom du produit est requis" }
        require(categorie.isNotEmpty()) { "La catégorie est requise" }

        val saved = produitService.create(nom = nom, categorie = categorie, userId = userId)
        val id = saved.id!!.toString()
        return ResponseEntity.ok(
            mapOf(
                "success" to true,
                "id" to id,
                "nom" to saved.nom,
                "categorie" to saved.categorie,
            ),
        )
    }
}
