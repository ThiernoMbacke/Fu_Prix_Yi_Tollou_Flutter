import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../prix/add_prix_screen.dart';
import '../auth/phone_auth_screen.dart';

class ProduitDetailScreen extends StatefulWidget {
  final Produit produit;

  const ProduitDetailScreen({super.key, required this.produit});

  @override
  State<ProduitDetailScreen> createState() => _ProduitDetailScreenState();
}

class _ProduitDetailScreenState extends State<ProduitDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Prix> _prix = [];
  Map<String, double> _stats = {};
  bool _isLoading = true;
  String? _selectedVille;

  @override
  void initState() {
    super.initState();
    _loadPrix();
  }

  Future<void> _loadPrix() async {
    setState(() => _isLoading = true);

    try {
      final prix = await _dbService.getPrixByProduit(widget.produit.id);
      final stats = await _dbService.getStatsPrix(widget.produit.id);

      setState(() {
        _prix = prix;
        _stats = stats;
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

  List<Prix> get _filteredPrix {
    if (_selectedVille == null) return _prix;
    return _prix.where((p) => p.marche?.ville?.nom == _selectedVille).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticatedSync;
    final numberFormat = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produit.nom),
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPrixScreen(produit: widget.produit),
                  ),
                );
                if (result == true) {
                  _loadPrix();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPrix,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête du produit
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.darkGreen,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_basket,
                              size: 48,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.produit.nom,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.produit.categorie,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Statistiques
                    if (_stats.isNotEmpty && _stats['moyenne']! > 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Prix Min',
                                '${numberFormat.format(_stats['min'])} F',
                                Icons.arrow_downward,
                                AppTheme.lightGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Prix Moy',
                                '${numberFormat.format(_stats['moyenne'])} F',
                                Icons.show_chart,
                                AppTheme.primaryYellow,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Prix Max',
                                '${numberFormat.format(_stats['max'])} F',
                                Icons.arrow_upward,
                                AppTheme.primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Filtre par ville
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildVilleChip('Toutes', _selectedVille == null),
                          ..._getUniqueVilles().map((ville) =>
                              _buildVilleChip(ville, _selectedVille == ville)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Liste des prix
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prix par marché',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${_filteredPrix.length} prix',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (_filteredPrix.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun prix disponible',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Soyez le premier à ajouter un prix',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              if (!isAuthenticated)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/auth-method');
                                  },
                                  icon: const Icon(Icons.login),
                                  label: const Text('Se connecter'),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredPrix.length,
                        itemBuilder: (context, index) {
                          final prix = _filteredPrix[index];
                          return _buildPrixCard(prix, numberFormat);
                        },
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPrixScreen(produit: widget.produit),
                  ),
                );
                if (result == true) {
                  _loadPrix();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un prix'),
              backgroundColor: AppTheme.primaryGreen,
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/auth-method');
              },
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              backgroundColor: AppTheme.primaryGreen,
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVilleChip(String ville, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(ville),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedVille = selected && ville != 'Toutes' ? ville : null;
          });
        },
        selectedColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
  }

  void _showPrixDetail(Prix prix, NumberFormat numberFormat) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hasContact = prix.isPremium &&
        (prix.contactPhone != null ||
            prix.contactLocation != null ||
            (prix.contactLat != null && prix.contactLng != null));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prix.marche?.nom ?? 'Marché inconnu',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${prix.marche?.ville?.nom ?? ''} • ${dateFormat.format(prix.date)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${numberFormat.format(prix.prix)} F',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            if (hasContact) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_pin_circle,
                      color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Contacter l\'annonceur',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (prix.contactPhone != null && prix.contactPhone!.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: AppTheme.primaryGreen),
                  title: const Text('Numéro'),
                  subtitle: Text(prix.contactPhone!),
                  onTap: () async {
                    final uri = Uri.parse(
                        'tel:${prix.contactPhone!.replaceAll(RegExp(r'[\s]'), '')}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ],
              if (prix.contactLocation != null &&
                  prix.contactLocation!.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on,
                      color: AppTheme.primaryGreen),
                  title: const Text('Localisation'),
                  subtitle: Text(prix.contactLocation!),
                ),
              ],
              if (prix.contactLat != null &&
                  prix.contactLng != null &&
                  (prix.contactLat != 0 || prix.contactLng != 0)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final url =
                        'https://www.google.com/maps?q=${prix.contactLat},${prix.contactLng}';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Ouvrir dans la carte'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrixCard(Prix prix, NumberFormat numberFormat) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPrixDetail(prix, numberFormat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.store,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    if (prix.isPremium)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Icon(Icons.star,
                            color: Colors.amber.shade700, size: 14),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prix.marche?.nom ?? 'Marché inconnu',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prix.marche?.ville?.nom ?? '',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(prix.date),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${numberFormat.format(prix.prix)} F',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getUniqueVilles() {
    final villes = _prix
        .map((p) => p.marche?.ville?.nom)
        .where((v) => v != null)
        .cast<String>()
        .toSet()
        .toList();
    villes.sort();
    return villes;
  }
}