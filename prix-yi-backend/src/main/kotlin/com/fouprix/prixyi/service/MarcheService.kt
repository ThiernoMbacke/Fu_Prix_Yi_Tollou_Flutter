package com.fouprix.prixyi.service

import com.fouprix.prixyi.model.entity.Marche
import com.fouprix.prixyi.repository.MarcheRepository
import com.fouprix.prixyi.repository.UserRepository
import com.fouprix.prixyi.repository.VilleRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class MarcheService(
    private val marcheRepository: MarcheRepository,
    private val villeRepository: VilleRepository,
    private val userRepository: UserRepository,
) {

    @Transactional
    fun create(
        nom: String,
        villeId: UUID,
        userId: UUID,
        latitude: Double?,
        longitude: Double?,
        adresse: String = "",
    ): Marche {
        require(villeRepository.existsById(villeId)) { "Ville inconnue" }
        require(userRepository.existsById(userId)) {
            "Utilisateur introuvable en base (id=$userId). Reconnectez-vous ou vérifiez public.users."
        }
        require(!marcheRepository.existsByVilleIdAndNomIgnoreCase(villeId, nom)) {
            "Un marché avec ce nom existe déjà pour cette ville."
        }
        val entity = Marche(
            nom = nom,
            villeId = villeId,
            latitude = latitude,
            longitude = longitude,
            adresse = adresse.trim(),
        ).apply { createdByUserId = userId }
        val saved = marcheRepository.saveAndFlush(entity)
        require(saved.id != null) { "ID marché non généré après enregistrement." }
        return saved
    }
}
