import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../domain/entities/table_entity.dart';
import '../providers/tables_provider.dart';

class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('pos.tables'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 28),
            tooltip: 'tables.add_table'.tr(),
            onPressed: () => _showAddTableSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<TablesProvider>(
        builder: (context, provider, child) {
          final zones = provider.zones;

          if (provider.tables.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'tables.title'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tables.zone_hint'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddTableSheet(context),
                      icon: const Icon(Icons.add),
                      label: Text('tables.add_table'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Zones Filter
              Container(
                height: 60,
                color: AppColors.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: zones.length,
                  itemBuilder: (context, index) {
                    final zone = zones[index];
                    final isSelected = provider.selectedZone == zone;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(zone),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) provider.setZone(zone);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Tables Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: provider.filteredTables.length,
                  itemBuilder: (context, index) {
                    final table = provider.filteredTables[index];
                    return _buildTableCard(context, table);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, TableEntity table) {
    Color cardColor;
    IconData icon;

    switch (table.status) {
      case TableStatus.available:
        cardColor = AppColors.success.withValues(alpha: 0.2);
        icon = Icons.event_seat;
        break;
      case TableStatus.occupied:
        cardColor = AppColors.error.withValues(alpha: 0.2);
        icon = Icons.restaurant;
        break;
      case TableStatus.billRequested:
        cardColor = AppColors.warning.withValues(alpha: 0.2);
        icon = Icons.receipt_long;
        break;
      case TableStatus.cleaning:
        cardColor = Colors.grey.withValues(alpha: 0.3);
        icon = Icons.cleaning_services;
        break;
      case TableStatus.outOfService:
        cardColor = Colors.redAccent.withValues(alpha: 0.1);
        icon = Icons.block;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context, table);
      },
      onLongPress: () {
        _showEditDeleteSheet(context, table);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.textPrimary),
            const SizedBox(height: 6),
            Text(
              table.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              '${table.capacity} ${"tables.capacity".tr().split(" ")[0]}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTableSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddTableSheet(),
    );
  }

  void _showEditDeleteSheet(BuildContext context, TableEntity table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  table.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${table.zone} • ${table.capacity} kishi',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                  title: Text('tables.edit_table'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditTableDialog(context, table);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text('tables.delete_table'.tr(), style: const TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteTable(context, table);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditTableDialog(BuildContext context, TableEntity table) {
    final nameCtrl = TextEditingController(text: table.name);
    final zoneCtrl = TextEditingController(text: table.zone);
    int capacity = table.capacity;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('tables.edit_table'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'tables.table_name'.tr(),
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zoneCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'tables.zone'.tr(),
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('tables.capacity'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.blueAccent),
                            onPressed: capacity > 1 ? () => setDialogState(() => capacity--) : null,
                          ),
                          Text(
                            '$capacity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                            onPressed: () => setDialogState(() => capacity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await context.read<TablesProvider>().updateTableDetails(
                    table.id,
                    name: nameCtrl.text.trim(),
                    zone: zoneCtrl.text.trim().isEmpty ? 'Umumiy' : zoneCtrl.text.trim(),
                    capacity: capacity,
                  );
                  if (context.mounted) {
                    ToastUtils.showSuccess(context, 'tables.success_updated'.tr());
                  }
                },
                child: Text('common.save'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteTable(BuildContext context, TableEntity table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('tables.delete_table'.tr(), style: const TextStyle(color: Colors.redAccent)),
        content: Text(
          'tables.delete_confirm'.tr(),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TablesProvider>().deleteTable(table.id);
              if (context.mounted) {
                ToastUtils.showSuccess(context, 'tables.success_deleted'.tr());
              }
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}

class _AddTableSheet extends StatefulWidget {
  const _AddTableSheet();

  @override
  State<_AddTableSheet> createState() => _AddTableSheetState();
}

class _AddTableSheetState extends State<_AddTableSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Single table controllers
  final _nameController = TextEditingController();
  final _zoneController = TextEditingController(text: 'Umumiy');
  int _singleCapacity = 4;

  // Batch tables controllers
  final _batchZoneController = TextEditingController(text: 'Umumiy');
  final _prefixController = TextEditingController(text: 'Stol');
  final _startNumController = TextEditingController(text: '1');
  final _countController = TextEditingController(text: '10');
  int _batchCapacity = 4;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _zoneController.dispose();
    _batchZoneController.dispose();
    _prefixController.dispose();
    _startNumController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'tables.add_table'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'tables.single_add'.tr()),
                Tab(text: 'tables.batch_add'.tr()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 270,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSingleTab(),
                _buildBatchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'tables.table_name'.tr(),
              hintText: 'tables.table_name_hint'.tr(),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _zoneController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'tables.zone'.tr(),
              hintText: 'tables.zone_hint'.tr(),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('tables.capacity'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.blueAccent),
                      onPressed: _singleCapacity > 1 ? () => setState(() => _singleCapacity--) : null,
                    ),
                    Text(
                      '$_singleCapacity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                      onPressed: () => setState(() => _singleCapacity++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _saveSingleTable,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('common.save'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prefixController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'tables.prefix'.tr(),
                    hintText: 'tables.prefix_hint'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _batchZoneController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'tables.zone'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startNumController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'tables.start_number'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'tables.count'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('tables.capacity'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.blueAccent),
                      onPressed: _batchCapacity > 1 ? () => setState(() => _batchCapacity--) : null,
                    ),
                    Text(
                      '$_batchCapacity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                      onPressed: () => setState(() => _batchCapacity++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _saveBatchTables,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('tables.batch_add'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSingleTable() async {
    final name = _nameController.text.trim();
    final zone = _zoneController.text.trim().isEmpty ? 'Umumiy' : _zoneController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await context.read<TablesProvider>().addTable(
        name: name,
        zone: zone,
        capacity: _singleCapacity,
      );
      if (mounted) {
        Navigator.pop(context);
        ToastUtils.showSuccess(context, 'tables.success_added'.tr());
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBatchTables() async {
    final prefix = _prefixController.text.trim();
    final zone = _batchZoneController.text.trim().isEmpty ? 'Umumiy' : _batchZoneController.text.trim();
    final startNum = int.tryParse(_startNumController.text.trim()) ?? 1;
    final count = int.tryParse(_countController.text.trim()) ?? 10;

    setState(() => _isLoading = true);
    try {
      await context.read<TablesProvider>().addBatchTables(
        zone: zone,
        startNumber: startNum,
        count: count,
        capacity: _batchCapacity,
        prefix: prefix,
      );
      if (mounted) {
        Navigator.pop(context);
        ToastUtils.showSuccess(context, 'tables.success_added'.tr());
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
