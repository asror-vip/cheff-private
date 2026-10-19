import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order.dart';
import '../providers/purchases_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../../core/utils/search_utils.dart';

class CreateRequestPage extends StatefulWidget {
  final PurchaseOrder? initialOrder;
  final List<Map<String, dynamic>>? initialItems;
  const CreateRequestPage({super.key, this.initialOrder, this.initialItems});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final List<Map<String, dynamic>> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedUnit = 'kg';
  final List<String> _units = ['kg', 'litr', 'dona', 'gr', 'quti'];

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _items.addAll(widget.initialItems!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchInventory(background: true);
    });
  }

  void _addItem() {
    final name = _itemController.text.trim();
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    
    if (name.isNotEmpty && qty > 0) {
      setState(() {
        _items.add({
          'name': name,
          'quantity': qty,
          'unit': _selectedUnit, 
        });
      });
      _itemController.clear();
      _quantityController.clear();
    }
  }

  Future<void> _sendToSupplier() async {
    if (_items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return _SupplierSelectionSheet(
          items: _items,
          onSupplierSelected: (Map<String, dynamic> supplier) async {
            Navigator.pop(sheetContext);
            await _createRequestAndOpenTelegram(supplier);
          },
        );
      },
    );
  }

  Future<void> _createRequestAndOpenTelegram(Map<String, dynamic> supplier) async {
    try {
      final provider = context.read<PurchasesProvider>();
      if (widget.initialOrder != null) {
        await provider.updateRequest(widget.initialOrder!.id, _items, supplier['id']);
      } else {
        await provider.createRequest(_items, supplier['id']);
      }
      // After saving, open telegram
      await _openTelegram(supplier['phone'] ?? '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'purchases.save_error'.tr()}: $e'), 
            backgroundColor: AppColors.error
          ),
        );
      }
    }
  }

  Future<void> _openTelegram(String phone) async {
    final buffer = StringBuffer();
    buffer.writeln("purchases.telegram_msg_title".tr());
    buffer.writeln("purchases.telegram_msg_subtitle".tr());
    buffer.writeln("📅 ${DateTime.now().toString().substring(0, 10)}\n");
    
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      buffer.writeln("${i + 1}. ${item['name']} - ${item['quantity']} ${item['unit']}");
    }
    
    buffer.writeln("\n${"purchases.telegram_msg_footer".tr()}");

    final text = Uri.encodeComponent(buffer.toString());
    
    String formattedPhone = phone.trim();
    bool isUsername = false;
    
    if (formattedPhone.startsWith('@')) {
      formattedPhone = formattedPhone.substring(1);
      isUsername = true;
    } else if (double.tryParse(formattedPhone.replaceAll('+', '')) == null) {
      isUsername = true;
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    Uri directUrl;
    if (isUsername) {
      directUrl = Uri.parse("tg://resolve?domain=$formattedPhone&text=$text");
    } else {
      directUrl = Uri.parse("tg://msg?to=$formattedPhone&text=$text");
    }
    final webUrl = Uri.parse("https://t.me/$formattedPhone?text=$text");
    
    try {
      bool launched = await launchUrl(directUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('purchases.cant_send_telegram'.tr()), 
              backgroundColor: AppColors.error
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('purchases.create_request'.tr(), style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item name input
            InkWell(
              onTap: () async {
                final provider = context.read<InventoryProvider>();
                final selected = await showSearch<dynamic>(
                  context: context,
                  delegate: ProductSearchDelegate(provider.items),
                );
                if (selected != null) {
                  setState(() {
                    if (selected is Map) {
                      _itemController.text = selected['name'];
                      if (!_units.contains(selected['unit'])) {
                        _units.add(selected['unit']);
                      }
                      _selectedUnit = selected['unit'];
                    } else {
                      _itemController.text = selected.name;
                      if (!_units.contains(selected.unit)) {
                        _units.add(selected.unit);
                      }
                      _selectedUnit = selected.unit;
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: TextField(
                  controller: _itemController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'purchases.product_name_hint'.tr(),
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: const Icon(Icons.search, color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quantity and Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'purchases.quantity'.tr(),
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedUnit = v);
                      },
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_items.isNotEmpty)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7), // Receipt paper color
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'purchases.request_title'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.black38, thickness: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${index + 1}. ', style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(item['name'], style: const TextStyle(color: Colors.black87, fontSize: 16)),
                                  ),
                                  Text('${item['quantity']} ${item['unit']}', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                    child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _sendToSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('purchases.send'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic> supplier) onSupplierSelected;

  const _SupplierSelectionSheet({required this.items, required this.onSupplierSelected});

  @override
  State<_SupplierSelectionSheet> createState() => _SupplierSelectionSheetState();
}

class _SupplierSelectionSheetState extends State<_SupplierSelectionSheet> {
  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSuppliers();
    });
  }

  Future<void> _fetchSuppliers({bool force = false}) async {
    final provider = context.read<PurchasesProvider>();
    
    if (!force && provider.suppliers.isNotEmpty) {
      if (mounted) {
        setState(() {
          _suppliers = provider.suppliers;
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
    });
    
    try {
      final res = await provider.getSuppliers(force: force);
      if (mounted) {
        setState(() {
          _suppliers = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final TextEditingController usernameController = TextEditingController();
    
    String searchStatus = 'idle'; // idle, loading, found, not_found, error
    String foundName = '';
    String foundUsername = '';
    String foundAvatar = '';
    String errorMsg = '';
    
    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('purchases.new_supplier'.tr(), style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('purchases.enter_telegram_username'.tr(), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '@username',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      suffixIcon: searchStatus == 'loading' 
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      if (searchStatus != 'idle') {
                        setDialogState(() => searchStatus = 'idle');
                      }
                    },
                  ),
                  
                  if (searchStatus == 'not_found')
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text('purchases.profile_not_found'.tr(), style: const TextStyle(color: Colors.redAccent)),
                    ),
                    
                  if (searchStatus == 'error')
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(errorMsg, style: const TextStyle(color: Colors.redAccent)),
                    ),
                    
                  if (searchStatus == 'found')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueAccent,
                              backgroundImage: (foundAvatar.isNotEmpty && foundAvatar.startsWith('http')) ? NetworkImage(foundAvatar) : null,
                              child: (foundAvatar.isEmpty || !foundAvatar.startsWith('http')) ? const Icon(Icons.person, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(foundName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('@$foundUsername', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
                ),
                
                if (searchStatus == 'idle' || searchStatus == 'not_found' || searchStatus == 'error')
                  ElevatedButton(
                    onPressed: searchStatus == 'loading' ? null : () async {
                      String username = usernameController.text.trim();
                      if (username.isEmpty) return;
                      
                      if (username.startsWith('@')) {
                        username = username.substring(1);
                      }
                      
                      setDialogState(() => searchStatus = 'loading');
                      
                      try {
                        final url = Uri.parse('https://t.me/$username');
                        final response = await http.get(url);
                        
                        if (response.statusCode == 200) {
                          final html = response.body;
                          final titleMatch = RegExp(r'<meta property="og:title" content="([^"]+)">').firstMatch(html);
                          final imageMatch = RegExp(r'<meta property="og:image" content="([^"]+)">').firstMatch(html);
                          
                          String title = titleMatch?.group(1) ?? '';
                          String imageUrl = imageMatch?.group(1) ?? '';
                          
                          if (title.isNotEmpty && !title.contains('Telegram: Contact')) {
                            setDialogState(() {
                              searchStatus = 'found';
                              foundName = title;
                              foundUsername = username;
                              foundAvatar = imageUrl;
                            });
                          } else {
                            setDialogState(() => searchStatus = 'not_found');
                          }
                        } else {
                          setDialogState(() => searchStatus = 'not_found');
                        }
                      } catch (e) {
                        setDialogState(() {
                          searchStatus = 'error';
                          errorMsg = e.toString();
                        });
                      }
                    },
                    child: Text('purchases.search_btn'.tr()),
                  )
                else if (searchStatus == 'found' || searchStatus == 'adding')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: searchStatus == 'adding' ? null : () async {
                      setDialogState(() => searchStatus = 'adding');
                      try {
                        final provider = context.read<PurchasesProvider>();
                        await provider.addSupplier(
                          name: foundName,
                          contactName: foundAvatar, 
                          phone: foundUsername
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          _fetchSuppliers(force: true);
                        }
                      } catch (e) {
                        setDialogState(() {
                          searchStatus = 'error';
                          errorMsg = e.toString();
                        });
                      }
                    },
                    child: searchStatus == 'adding'
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('common.add'.tr(), style: const TextStyle(color: Colors.white)),
                  )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('purchases.who_to_send'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator())
          else if (_suppliers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('purchases.empty_suppliers'.tr(), style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showAddSupplierDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: Text('purchases.new_supplier'.tr(), style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _suppliers.length,
                itemBuilder: (context, index) {
                  final sup = _suppliers[index];
                  final String? imageUrl = sup['contact_name']; // We stored og:image here
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: (imageUrl != null && imageUrl.startsWith('http')) ? NetworkImage(imageUrl) : null,
                      child: (imageUrl == null || !imageUrl.startsWith('http')) ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(sup['name'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text('@${sup['phone'] ?? ''}', style: const TextStyle(color: Colors.white54)),
                    trailing: const Icon(Icons.telegram, color: Colors.blue, size: 32),
                    onTap: () {
                      if (sup['phone'] != null && sup['phone'].toString().isNotEmpty) {
                        widget.onSupplierSelected(sup);
                      }
                    },
                  );
                },
              ),
            ),
          
          if (_suppliers.isNotEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _showAddSupplierDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('purchases.new_supplier'.tr(), style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<dynamic> {
  final List<dynamic> items;

  ProductSearchDelegate(this.items);

  @override
  String get searchFieldLabel => 'common.search'.tr();

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.textPrimary),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final normalizedQuery = SearchUtils.normalize(query);
    
    final filteredItems = items.where((item) {
      final normalizedName = SearchUtils.normalize(item.name);
      return normalizedName.contains(normalizedQuery);
    }).toList();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          if (query.trim().isNotEmpty)
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.success),
              title: Text('${'common.add'.tr()}: "${query.trim()}"', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              onTap: () => close(context, {'name': query.trim(), 'unit': 'kg', 'isCustom': true}),
            ),
          if (query.trim().isNotEmpty)
            const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(child: Text('common.not_found'.tr(), style: const TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        title: Text(item.name, style: const TextStyle(color: AppColors.textPrimary)),
                        subtitle: Text('${'recipes.in_stock'.tr()}: ${item.quantity} ${item.unit}', style: const TextStyle(color: AppColors.textSecondary)),
                        onTap: () => close(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
