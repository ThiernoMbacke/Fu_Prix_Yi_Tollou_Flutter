package com.fouprix.prixyi.repository

import com.fouprix.prixyi.model.entity.Produit
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface ProduitRepository : JpaRepository<Produit, UUID> {
    fun existsByNomIgnoreCaseAndCategorieIgnoreCase(nom: String, categorie: String): Boolean
}
