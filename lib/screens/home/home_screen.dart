import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/models.dart';
import '../../config/app_theme.dart';
import '../auth/phone_auth_screen.dart';
import '../produit/produit_detail_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Ville> _villes = [];
  List<Produit> _produits = [];
  List<Prix> _prixRecents = [];
  String? _selectedVilleId;
  String? _selectedCategorie;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final villes = await _dbService.getVilles();
      final produits = await _dbService.getProduits(
        categorie: _selectedCategorie,
      );
      final prixRecents = await _dbService.getPrixRecents(limit: 20);
      
      setState(() {
        _villes = villes;
        _produits = produits;
        _prixRecents = prixRecents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _searchProduits(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    
    try {
      final produits = await _dbService.getProduits(searchQuery: query);
      setState(() => _produits = produits);
    } catch (e) {
      print('Erreur recherche: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticatedSync;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fou Prix Yi Tollou'),
        actions: [
          IconButton(
            icon: Icon(isAuthenticated ? Icons.person : Icons.login),
            onPressed: () {
              if (isAuthenticated) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
              } else {
                Navigator.pushNamed(context, '/auth-method');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadData();
                                  },
                                )
                              : null,
                        ),
                        onChanged: _searchProduits,
                      ),
                    ),

                    // Filtres
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Filtre par ville
                          _buildFilterChip(
                            label: _selectedVilleId == null
                                ? 'Toutes les villes'
                                : _villes.isEmpty
                                    ? 'Toutes les villes'
                                    : _villes
                                        .firstWhere(
                                          (v) => v.id == _selectedVilleId,
                                          orElse: () => _villes.first,
                                        )
                                        .nom,
                            isSelected: _selectedVilleId != null,
                            onTap: () => _showVilleFilter(),
                          ),
                          const SizedBox(width: 8),
                          // Filtre par catégorie
                          _buildFilterChip(
                            label: _selectedCategorie ?? 'Catégories',
                            isSelected: _selectedCategorie != null,
                            onTap: () => _showCategorieFilter(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Liste des produits
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Produits',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${_produits.length} produits',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    _produits.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Aucun produit trouvé'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _produits.length,
                            itemBuilder: (context, index) {
                              final produit = _produits[index];
                              return _buildProduitCard(produit);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProduitCard(Produit produit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
          child: const Icon(Icons.shopping_basket, color: AppTheme.primaryGreen),
        ),
        title: Text(
          produit.nom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(produit.categorie),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProduitDetailScreen(produit: produit),
            ),
          );
        },
      ),
    );
  }

  void _showVilleFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Toutes les villes'),
              trailing: _selectedVilleId == null
                  ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                  : null,
              onTap: () {
                setState(() => _selectedVilleId = null);
                Navigator.pop(context);
                _loadData();
              },
            ),
            ..._villes.map((ville) {
              return ListTile(
                title: Text(ville.nom),
                trailing: _selectedVilleId == ville.id
                    ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                    : null,
                onTap: () {
                  setState(() => _selectedVilleId = ville.id);
                  Navigator.pop(context);
                  _loadData();
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showCategorieFilter() {
    final categories = ['Légumes', 'Fruits', 'Céréales', 'Viandes', 'Poissons', 'Autres'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Toutes les catégories'),
              trailing: _selectedCategorie == null
                  ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                  : null,
              onTap: () {
                setState(() => _selectedCategorie = null);
                Navigator.pop(context);
                _loadData();
              },
            ),
            ...categories.map((cat) {
              return ListTile(
                title: Text(cat),
                trailing: _selectedCategorie == cat
                    ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                    : null,
                onTap: () async {
                  setState(() => _selectedCategorie = cat);
                  Navigator.pop(context);
                  try {
                    final produits = await _dbService.getProduits(categorie: cat);
                    setState(() => _produits = produits);
                  } catch (e) {
                    print('Erreur: $e');
                  }
                },
              );
            }),
          ],
        );
      },
    );
  }
}