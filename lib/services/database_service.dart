import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../config/supabase_config.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== VILLES ==========
  Future<List<Ville>> getVilles() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.villesTable)
          .select()
          .order('nom');

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Ville.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villes: $e');
    }
  }

  // ========== MARCHÉS ==========
  Future<List<Marche>> getMarches({String? villeId}) async {
    try {
      // ✅ CORRECTION : Filtrer AVANT order()
      var query = _supabase
          .from(SupabaseConfig.marchesTable)
          .select('*, villes(*)');

      // Appliquer le filtre si nécessaire
      if (villeId != null) {
        query = query.eq('ville_id', villeId);
      }

      // Ajouter l'ordre à la fin
      final response = await query.order('nom');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final item = json as Map<String, dynamic>;
        return Marche.fromJson(item);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des marchés: $e');
    }
  }

  // ========== PRODUITS ==========
  Future<List<Produit>> getProduits({
    String? searchQuery,
    String? categorie,
  }) async {
    try {
      // ✅ CORRECTION : Filtrer AVANT order()
      var query = _supabase
          .from(SupabaseConfig.produitsTable)
          .select();

      // Appliquer les filtres
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('nom', '%$searchQuery%');
      }

      if (categorie != null && categorie.isNotEmpty) {
        query = query.eq('categorie', categorie);
      }

      // Ajouter l'ordre à la fin
      final response = await query.order('nom');

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Produit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  // ========== PRIX ==========
  Future<List<Prix>> getPrixByProduit(String produitId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.prixTable)
          .select('*, produits(*), marches(*, villes(*))')
          .eq('produit_id', produitId)
          .order('date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final item = json as Map<String, dynamic>;
        return Prix.fromJson(item);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des prix: $e');
    }
  }

  Future<List<Prix>> getPrixRecents({int limit = 10}) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.prixTable)
          .select('*, produits(*), marches(*, villes(*))')
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final item = json as Map<String, dynamic>;
        return Prix.fromJson(item);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des prix récents: $e');
    }
  }

  Future<Map<String, double>> getStatsPrix(String produitId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.prixTable)
          .select('prix')
          .eq('produit_id', produitId);

      final List<dynamic> data = response as List<dynamic>;
      
      if (data.isEmpty) {
        return {'min': 0.0, 'max': 0.0, 'moyenne': 0.0};
      }

      final prixList = data
          .map((item) {
            final prixValue = item is Map<String, dynamic> 
                ? item['prix'] 
                : (item as Map)['prix'];
            return double.parse(prixValue.toString());
          })
          .toList();

      if (prixList.isEmpty) {
        return {'min': 0.0, 'max': 0.0, 'moyenne': 0.0};
      }

      final min = prixList.reduce((a, b) => a < b ? a : b);
      final max = prixList.reduce((a, b) => a > b ? a : b);
      final moyenne = prixList.reduce((a, b) => a + b) / prixList.length;

      return {
        'min': min,
        'max': max,
        'moyenne': moyenne,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  Future<void> addPrix({
    required String produitId,
    required String marcheId,
    required double prix,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      await _supabase.from(SupabaseConfig.prixTable).insert({
        'produit_id': produitId,
        'marche_id': marcheId,
        'prix': prix,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'created_by': user.id,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du prix: $e');
    }
  }
}