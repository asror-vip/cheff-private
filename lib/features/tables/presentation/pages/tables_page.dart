import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/table_entity.dart';
import '../providers/tables_provider.dart';

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

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
      ),
      body: Consumer<TablesProvider>(
        builder: (context, provider, child) {
          final zones = provider.zones;
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
      case TableStatus.reserved:
        cardColor = AppColors.warning.withValues(alpha: 0.2);
        icon = Icons.access_time;
        break;
      case TableStatus.needsCleaning:
        cardColor = Colors.grey.withValues(alpha: 0.3);
        icon = Icons.cleaning_services;
        break;
    }

    return InkWell(
      onTap: () {
        // Handle table click - Open POS with this table attached
        if (table.status == TableStatus.available) {
            context.read<TablesProvider>().updateTableStatus(table.id, TableStatus.occupied, orderId: 'temp_${table.id}');
            Navigator.pop(context, table); // Return table to POS
        } else if (table.status == TableStatus.occupied) {
            Navigator.pop(context, table); // Return table to POS
        }
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
            Icon(icon, size: 32, color: AppColors.textPrimary),
            const SizedBox(height: 8),
            Text(
              table.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${table.capacity} kishi',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
