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
import java.time.Instant
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

        // Option premium : localisation + contact + paiement
        val isPremium = (body["isPremium"] as? Boolean) ?: false
        val contactPhone = body["contactPhone"] as? String
        val contactLocation = body["contactLocation"] as? String
        val contactLat = (body["contactLat"] as? Number)?.toDouble()
        val contactLng = (body["contactLng"] as? Number)?.toDouble()
        val paymentMethod = body["paymentMethod"] as? String
        val paymentReference = body["paymentReference"] as? String

        val normalizedPaymentMethod = paymentMethod?.uppercase()
        val allowedMethods = setOf("ORANGE_MONEY", "WAVE", "CARD")

        var finalIsPremium = false
        var finalAmount: Int? = null
        var finalPaidAt: Instant? = null
        var finalPaymentMethod: String? = null

        if (isPremium) {
            require(!contactPhone.isNullOrBlank()) { "Le numéro de téléphone est requis pour l'option premium." }
            val hasLocationText = !contactLocation.isNullOrBlank()
            val hasLocationCoords = contactLat != null && contactLng != null
            require(hasLocationText || hasLocationCoords) {
                "La localisation est requise (texte ou position sur la carte)."
            }
            require(!normalizedPaymentMethod.isNullOrBlank() && allowedMethods.contains(normalizedPaymentMethod)) {
                "Méthode de paiement invalide (Orange Money, Wave ou Carte)."
            }
            // TODO: intégrer les APIs de paiement Orange Money / Wave / carte.
            // Pour l'instant, on considère que le paiement 2000 FCFA est validé côté client.
            finalIsPremium = true
            finalAmount = 2000
            finalPaidAt = Instant.now()
            finalPaymentMethod = normalizedPaymentMethod
        }

        val prix = Prix(
            produitId = produitId,
            marcheId = marcheId,
            prix = BigDecimal.valueOf(prixValue),
            date = LocalDate.now(),
            contactPhone = contactPhone,
            contactLocation = contactLocation,
            contactLat = contactLat,
            contactLng = contactLng,
            isPremium = finalIsPremium,
            paymentReference = paymentReference,
            premiumAmount = finalAmount,
            paymentMethod = finalPaymentMethod,
            premiumPaidAt = finalPaidAt,
        ).apply { createdByUserId = userId }
        prixRepository.save(prix)
        userService.incrementContributions(userId)
        return ResponseEntity.ok(mapOf("success" to true, "id" to prix.id.toString()))
    }
}
