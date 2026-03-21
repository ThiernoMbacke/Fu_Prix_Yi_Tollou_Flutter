import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../../widgets/backend_url_dialog.dart';

/// Formulaire création produit (POST /api/produits, JWT requis).
class AddProduitScreen extends StatefulWidget {
  const AddProduitScreen({super.key});

  static const List<String> categories = [
    'Légumes',
    'Fruits',
    'Céréales',
    'Viandes',
    'Poissons',
    'Autres',
  ];

  @override
  State<AddProduitScreen> createState() => _AddProduitScreenState();
}

class _AddProduitScreenState extends State<AddProduitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  String? _categorie;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final produit = await api.addProduit(
        nom: _nomController.text,
        categorie: _categorie!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit créé'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.pop(context, produit);
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erreur: $e';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) msg = data['message'].toString();
      }
      final isConnection = e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          action: isConnection
              ? SnackBarAction(
                  label: 'Configurer l\'URL',
                  textColor: Colors.white,
                  onPressed: () => showBackendUrlDialog(context),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau produit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                  hintText: 'Ex : Oignons violet',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Entrez un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                value: _categorie,
                items: AddProduitScreen.categories
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _categorie = v),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Créer le produit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
