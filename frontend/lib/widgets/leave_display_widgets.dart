// widgets/leave_display_widgets.dart
import 'package:flutter/material.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';
import '../models/leave_model.dart';

class LeaveAllocationCard extends StatelessWidget {
  final LeaveAllocation allocation;
  final bool isCompact;

  const LeaveAllocationCard({
    Key? key,
    required this.allocation,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color getLeaveTypeColor() {
      switch (allocation.type) {
        case LeaveType.sick:
          return Colors.red;
        case LeaveType.vacation:
          return Colors.blue;
        case LeaveType.off:
          return Colors.orange;
      }
    }

    Color getStatusColor() {
      if (allocation.remainingDays <= 0) return Colors.red;
      if (allocation.usagePercentage > 80) return Colors.orange;
      return Colors.green;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 4.0 : 8.0,
        horizontal: isCompact ? 0.0 : 8.0,
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getLeaveTypeColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allocation.type.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isCompact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: getStatusColor()),
                    ),
                    child: Text(
                      '${allocation.remainingDays} left',
                      style: TextStyle(
                        color: getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: allocation.allocatedDays > 0 
                    ? allocation.usedDays / allocation.allocatedDays 
                    : 0,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(getLeaveTypeColor()),
                minHeight: 6,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Statistics
            if (isCompact)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${allocation.usedDays}/${allocation.allocatedDays}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${allocation.usagePercentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _StatisticItem(
                      label: 'Allocated',
                      value: allocation.allocatedDays.toString(),
                      color: colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _StatisticItem(
                      label: 'Used',
                      value: allocation.usedDays.toString(),
                      color: getLeaveTypeColor(),
                    ),
                  ),
                  Expanded(
                    child: _StatisticItem(
                      label: 'Remaining',
                      value: allocation.remainingDays.toString(),
                      color: getStatusColor(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatisticItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class LeaveAllocationSummary extends StatelessWidget {
  final List<LeaveAllocation> allocations;
  final bool showTitle;

  const LeaveAllocationSummary({
    Key? key,
    required this.allocations,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentYearAllocations = allocations
        .where((allocation) => allocation.year == DateTime.now().year)
        .toList();

    if (currentYearAllocations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (showTitle) ...[
                Text(
                  'Leave Balance ${DateTime.now().year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No leave allocations found for ${DateTime.now().year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Leave Balance ${DateTime.now().year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        ...currentYearAllocations.map((allocation) => 
          LeaveAllocationCard(allocation: allocation, isCompact: true)
        ),
      ],
    );
  }
}

class LeaveAllocationDialog extends StatelessWidget {
  final List<LeaveAllocation> allocations;
  final String employeeName;

  const LeaveAllocationDialog({
    Key? key,
    required this.allocations,
    required this.employeeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupedByYear = <int, List<LeaveAllocation>>{};
    
    for (final allocation in allocations) {
      if (!groupedByYear.containsKey(allocation.year)) {
        groupedByYear[allocation.year] = [];
      }
      groupedByYear[allocation.year]!.add(allocation);
    }
    
    final years = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leave Allocations - $employeeName',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: allocations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No leave allocations found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Leave allocations will appear here once they are set up.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: years.length,
                      itemBuilder: (context, index) {
                        final year = years[index];
                        final yearAllocations = groupedByYear[year]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (years.length > 1) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  year.toString(),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                            ...yearAllocations.map((allocation) => 
                              LeaveAllocationCard(allocation: allocation)
                            ),
                            if (index < years.length - 1) const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}