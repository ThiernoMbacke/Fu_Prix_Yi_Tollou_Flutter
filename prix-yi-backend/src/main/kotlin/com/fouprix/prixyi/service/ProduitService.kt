package com.fouprix.prixyi.service

import com.fouprix.prixyi.model.entity.Produit
import com.fouprix.prixyi.repository.ProduitRepository
import com.fouprix.prixyi.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class ProduitService(
    private val produitRepository: ProduitRepository,
    private val userRepository: UserRepository,
) {

    @Transactional
    fun create(nom: String, categorie: String, userId: UUID): Produit {
        require(userRepository.existsById(userId)) {
            "Utilisateur introuvable en base (id=$userId). Reconnectez-vous (Test1) ou vérifiez la table public.users."
        }
        require(!produitRepository.existsByNomIgnoreCaseAndCategorieIgnoreCase(nom, categorie)) {
            "Un produit avec ce nom et cette catégorie existe déjà."
        }
        val entity = Produit(nom = nom, categorie = categorie).apply {
            createdByUserId = userId
        }
        val saved = produitRepository.saveAndFlush(entity)
        require(saved.id != null) {
            "ID produit non généré après enregistrement — vérifier la table produits (gen_random_uuid)."
        }
        return saved
    }
}
