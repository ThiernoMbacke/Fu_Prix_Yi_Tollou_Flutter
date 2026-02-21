import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class AddPrixScreen extends StatefulWidget {
  final Produit produit;

  const AddPrixScreen({super.key, required this.produit});

  @override
  State<AddPrixScreen> createState() => _AddPrixScreenState();
}

class _AddPrixScreenState extends State<AddPrixScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _prixController = TextEditingController();

  List<Ville> _villes = [];
  List<Marche> _marches = [];
  List<Marche> _filteredMarches = [];
  
  String? _selectedVilleId;
  String? _selectedMarcheId;
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final villes = await _dbService.getVilles();
      final marches = await _dbService.getMarches();

      setState(() {
        _villes = villes;
        _marches = marches;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterMarches(String? villeId) {
    if (villeId == null) {
      setState(() {
        _filteredMarches = [];
        _selectedMarcheId = null;
      });
      return;
    }

    setState(() {
      _filteredMarches = _marches.where((m) => m.villeId == villeId).toList();
      _selectedMarcheId = null;
    });
  }

  Future<void> _savePrix() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMarcheId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un marché')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prix = double.parse(_prixController.text);
      final apiService = context.read<ApiService>();

      await apiService.addPrix(
        produitId: widget.produit.id,
        marcheId: _selectedMarcheId!,
        prix: prix,
      );
      // Le backend incrémente les contributions automatiquement

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prix ajouté avec succès !'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      context.read<AuthProvider>().loadUserProfile();

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un prix'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Produit sélectionné
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_basket,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.produit.nom,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.produit.categorie,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sélection de la ville
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      value: _selectedVilleId,
                      items: _villes.map((ville) {
                        return DropdownMenuItem(
                          value: ville.id,
                          child: Text(ville.nom),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVilleId = value;
                          _filterMarches(value);
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner une ville';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sélection du marché
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Marché',
                        prefixIcon: Icon(Icons.store),
                      ),
                      value: _selectedMarcheId,
                      items: _filteredMarches.map((marche) {
                        return DropdownMenuItem(
                          value: marche.id,
                          child: Text(marche.nom),
                        );
                      }).toList(),
                      onChanged: _selectedVilleId == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedMarcheId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un marché';
                        }
                        return null;
                      },
                    ),

                    if (_selectedVilleId != null && _filteredMarches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Aucun marché disponible pour cette ville',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Saisie du prix
                    TextFormField(
                      controller: _prixController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix (FCFA)',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: '1000',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix';
                        }
                        final prix = int.tryParse(value);
                        if (prix == null || prix <= 0) {
                          return 'Prix invalide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Le prix sera visible par tous les utilisateurs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton enregistrer
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePrix,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Enregistrer le prix'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}