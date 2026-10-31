import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/supabase_service.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = false;

  List<dynamic> _products = [];
  List<dynamic> _recipes = [];

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _products.clear();
        _recipes.clear();
      });
      return;
    }
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final restId = SupabaseService.currentRestaurantId;
    try {
      final pRes = await SupabaseService.client
          .from('products')
          .select()
          .eq('restaurant_id', restId)
          .ilike('name', '%$query%')
          .limit(10);

      final rRes = await SupabaseService.client
          .from('recipes')
          .select()
          .eq('restaurant_id', restId)
          .ilike('name', '%$query%')
          .limit(10);

      if (mounted) {
        setState(() {
          _products = pRes;
          _recipes = rRes;
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Qidirish (Taom yoki Mahsulot nomi)...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_products.isEmpty && _recipes.isEmpty)
          ? const Center(
              child: Text('Natijalar topilmadi', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_products.isNotEmpty) ...[
                  const Text('Ombor mahsulotlari', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._products.map((p) => ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.blueAccent),
                    title: Text(p['name'], style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text('${p['category'] ?? ''} - ${p['unit'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                  )),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                ],
                if (_recipes.isNotEmpty) ...[
                  const Text('Menyudagi taomlar', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._recipes.map((r) => ListTile(
                    leading: const Icon(Icons.restaurant_menu, color: Colors.orangeAccent),
                    title: Text(r['name'], style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text('${r['selling_price'] ?? 0} UZS', style: const TextStyle(color: AppColors.textSecondary)),
                  )),
                ]
              ],
            ),
    );
  }
}
