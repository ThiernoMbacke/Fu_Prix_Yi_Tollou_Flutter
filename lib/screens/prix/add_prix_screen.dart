import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/backend_url_dialog.dart';
import 'map_picker_screen.dart';

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
  final _contactPhoneController = TextEditingController();
  final _contactLocationController = TextEditingController();
  final _paymentReferenceController = TextEditingController();
  final _newMarcheNomController = TextEditingController();
  final _newMarcheAdresseController = TextEditingController();
  final _newMarcheLatController = TextEditingController();
  final _newMarcheLngController = TextEditingController();

  List<Ville> _villes = [];
  List<Marche> _marches = [];
  List<Marche> _filteredMarches = [];
  
  String? _selectedVilleId;
  String? _selectedMarcheId;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isCreatingMarche = false;
  bool _isPremium = false;
  String? _paymentMethod; // 'ORANGE_MONEY', 'WAVE', 'CARD'
  double? _contactLat;
  double? _contactLng;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _prixController.dispose();
    _contactPhoneController.dispose();
    _contactLocationController.dispose();
    _paymentReferenceController.dispose();
    _newMarcheNomController.dispose();
    _newMarcheAdresseController.dispose();
    _newMarcheLatController.dispose();
    _newMarcheLngController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final villes = await _dbService.getVilles();
      final marches = await _dbService.getMarches();
      // Pré-remplir le téléphone de contact avec le numéro du profil, si dispo.
      final auth = context.read<AuthProvider>();
      final userPhone = auth.userProfile?.phone;
      if (userPhone != null && userPhone.isNotEmpty) {
        _contactPhoneController.text = userPhone;
      }

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

  Future<void> _showNewMarcheDialog() async {
    final villeId = _selectedVilleId;
    if (villeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez d’abord une ville')),
      );
      return;
    }

    _newMarcheNomController.clear();
    _newMarcheAdresseController.clear();
    _newMarcheLatController.clear();
    _newMarcheLngController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau marché'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newMarcheNomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du marché',
                  hintText: 'Ex : Marché Sandaga',
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newMarcheAdresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  hintText: 'Ex : Avenue Bourguiba, Dakar',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newMarcheLatController,
                decoration: const InputDecoration(
                  labelText: 'Latitude (optionnel)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              TextField(
                controller: _newMarcheLngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude (optionnel)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (_newMarcheNomController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCreatingMarche = true);
    try {
      final apiService = context.read<ApiService>();
      double? lat;
      double? lng;
      final latStr = _newMarcheLatController.text.trim();
      final lngStr = _newMarcheLngController.text.trim();
      if (latStr.isNotEmpty) lat = double.tryParse(latStr.replaceAll(',', '.'));
      if (lngStr.isNotEmpty) lng = double.tryParse(lngStr.replaceAll(',', '.'));

      final newId = await apiService.addMarche(
        nom: _newMarcheNomController.text.trim(),
        villeId: villeId,
        latitude: lat,
        longitude: lng,
        adresse: _newMarcheAdresseController.text.trim().isEmpty
            ? null
            : _newMarcheAdresseController.text.trim(),
      );

      final marches = await _dbService.getMarches();
      if (!mounted) return;

      var filtered = _marches.where((m) => m.villeId == villeId).toList();
      final nomMarche = _newMarcheNomController.text.trim();
      if (!filtered.any((m) => m.id == newId)) {
        filtered = [
          ...filtered,
          Marche(
            id: newId,
            nom: nomMarche,
            villeId: villeId,
            adresse: _newMarcheAdresseController.text.trim().isEmpty
                ? null
                : _newMarcheAdresseController.text.trim(),
          ),
        ];
      }

      setState(() {
        _marches = marches;
        _filteredMarches = filtered;
        _selectedMarcheId = newId;
        _isCreatingMarche = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marché créé. Vous pouvez enregistrer le prix.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erreur: $e';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) msg = data['message'].toString();
      }
      final isConnectionError = e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          action: isConnectionError
              ? SnackBarAction(
                  label: 'Configurer l\'URL',
                  textColor: Colors.white,
                  onPressed: () => showBackendUrlDialog(context),
                )
              : null,
        ),
      );
      setState(() => _isCreatingMarche = false);
    }
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

      bool isPremium = _isPremium;
      String? contactPhone;
      String? contactLocation;
      String? paymentMethod;
      String? paymentReference;

      if (isPremium) {
        contactPhone = _contactPhoneController.text.trim();
        contactLocation = _contactLocationController.text.trim();
        if (contactLocation.isEmpty && _contactLat != null && _contactLng != null) {
          contactLocation = '${_contactLat!.toStringAsFixed(5)}, ${_contactLng!.toStringAsFixed(5)}';
        }
        paymentMethod = _paymentMethod;
        paymentReference = _paymentReferenceController.text.trim();

        final hasLocation = contactLocation.isNotEmpty || (_contactLat != null && _contactLng != null);
        if (contactPhone.isEmpty || !hasLocation || paymentMethod == null || paymentReference.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pour l\'option premium : téléphone, localisation (texte ou carte), moyen de paiement et numéro de carte/téléphone.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Confirmation de paiement (simulation)
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmer le paiement'),
            content: const Text(
              'Vous allez payer 2000 FCFA pour mettre ce prix en avant, avec votre numéro et votre localisation visibles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Payer 2000 FCFA'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      await apiService.addPrix(
        produitId: widget.produit.id,
        marcheId: _selectedMarcheId!,
        prix: prix,
        isPremium: isPremium,
        contactPhone: contactPhone,
        contactLocation: contactLocation,
        contactLat: _contactLat,
        contactLng: _contactLng,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
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
      String msg = 'Erreur: $e';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) msg = data['message'].toString();
      }
      final isConnectionError = e is DioException && (
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout
      ) || (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('failed host'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          action: isConnectionError
              ? SnackBarAction(
                  label: 'Configurer l\'URL',
                  textColor: Colors.white,
                  onPressed: () => showBackendUrlDialog(context),
                )
              : null,
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

                    if (_selectedVilleId != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _isCreatingMarche ? null : _showNewMarcheDialog,
                          icon: _isCreatingMarche
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_circle_outline),
                          label: Text(
                            _isCreatingMarche ? 'Création…' : '+ Nouveau marché',
                          ),
                        ),
                      ),
                    ],

                    if (_selectedVilleId != null && _filteredMarches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Aucun marché pour cette ville — ajoutez-en un avec « + Nouveau marché ».',
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

                    const SizedBox(height: 24),

                    // Option premium
                    SwitchListTile.adaptive(
                      value: _isPremium,
                      onChanged: (v) {
                        setState(() => _isPremium = v);
                      },
                      title: const Text('Mettre ce prix en avant (2000 FCFA)'),
                      subtitle: const Text(
                        'Votre numéro et votre localisation seront visibles pour être contacté directement.',
                      ),
                      secondary: const Icon(Icons.star, color: Colors.amber),
                    ),

                    if (_isPremium) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Localisation (boutique, quartier...)',
                          prefixIcon: Icon(Icons.location_on),
                          hintText: 'Ex: Marché Kermel, Dakar',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          LatLng? initial;
                          if (_contactLat != null && _contactLng != null) {
                            initial = LatLng(_contactLat!, _contactLng!);
                          }
                          final result = await Navigator.push<LatLng>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapPickerScreen(initialPosition: initial),
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() {
                              _contactLat = result.latitude;
                              _contactLng = result.longitude;
                              if (_contactLocationController.text.trim().isEmpty) {
                                _contactLocationController.text =
                                    '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: Text(
                          _contactLat != null && _contactLng != null
                              ? 'Position : ${_contactLat!.toStringAsFixed(4)}, ${_contactLng!.toStringAsFixed(4)}'
                              : 'Choisir sur la carte',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone de contact',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Moyen de paiement (simulation)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Orange Money'),
                            selected: _paymentMethod == 'ORANGE_MONEY',
                            onSelected: (selected) {
                              setState(() {
                                _paymentMethod = selected ? 'ORANGE_MONEY' : null;
                                _paymentReferenceController.clear();
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Wave'),
                            selected: _paymentMethod == 'WAVE',
                            onSelected: (selected) {
                              setState(() {
                                _paymentMethod = selected ? 'WAVE' : null;
                                _paymentReferenceController.clear();
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Carte bancaire'),
                            selected: _paymentMethod == 'CARD',
                            onSelected: (selected) {
                              setState(() {
                                _paymentMethod = selected ? 'CARD' : null;
                                _paymentReferenceController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_paymentMethod != null)
                        TextFormField(
                          controller: _paymentReferenceController,
                          decoration: InputDecoration(
                            labelText: _paymentMethod == 'CARD'
                                ? 'Numéro de carte (16 chiffres)'
                                : 'Numéro pour le paiement (9 chiffres)',
                            hintText: _paymentMethod == 'CARD'
                                ? '4242 4242 4242 4242'
                                : '77 123 45 67',
                            prefixIcon: Icon(
                              _paymentMethod == 'CARD' ? Icons.credit_card : Icons.phone,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: _paymentMethod == 'CARD' ? 19 : 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Simulation — aucun prélèvement réel. En production : Orange Money / Wave / passerelle carte.',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 8),

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Le prix sera visible par tous les utilisateurs.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Avec l\'option premium, votre contact et localisation sont affichés pour être appelé directement.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
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