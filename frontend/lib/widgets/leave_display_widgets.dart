// widgets/leave_display_widgets.dart
import 'package:flutter/material.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controller_provider/leave_management_controller.dart';
import '../models/absence_model.dart';
import '../models/leave_model.dart';
import '../uttils/navigator.dart';

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

extension LeaveTypeExtension on LeaveType {
  String get displayName {
    // Safely access context; fallback to enum name if context is null
    final context = AppNavigator.globalKey.currentContext;
    if (context == null) {
      return name; // Fallback to raw enum name
    }
    final appLocalizations = AppLocalizations.of(context)!;
    switch (this) {
      case LeaveType.sick:
        return appLocalizations.sick_leave;
      case LeaveType.vacation:
        return appLocalizations.vacation_leave;
      case LeaveType.off:
        return appLocalizations.off_leave;
    }
  }
}

class LeaveAllocationDialog extends StatelessWidget {
  final List<LeaveAllocation> allocations;
  final String employeeName;

  const LeaveAllocationDialog({
    super.key,
    required this.allocations,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text('${appLocalizations.leave_details} - $employeeName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: allocations.isEmpty
              ? [Text(appLocalizations.no_leave_allocations)]
              : allocations
                  .map((allocation) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(allocation.type.displayName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${appLocalizations.allocated}: ${allocation.allocatedDays} ${appLocalizations.days}'),
                              Text(
                                  '${appLocalizations.used}: ${allocation.usedDays} ${appLocalizations.days}'),
                              Text(
                                '${appLocalizations.remaining}: ${allocation.allocatedDays - allocation.usedDays} ${appLocalizations.days}',
                                style: TextStyle(
                                  color: allocation.allocatedDays -
                                              allocation.usedDays <=
                                          0
                                      ? Colors.red
                                      : null,
                                ),
                              ),
                              Text('${'year'}: ${allocation.year}'),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.close),
        ),
      ],
    );
  }
}

class LeaveAllocationSummary extends StatelessWidget {
  final List<LeaveAllocation> allocations;
  final bool showTitle;
  final bool showDetailedView;

  const LeaveAllocationSummary({
    super.key,
    required this.allocations,
    this.showTitle = true,
    this.showDetailedView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (showTitle)
                Text(
                  'Leave Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              const SizedBox(height: 16),
              const Text(
                'No leave allocations found for this year.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Group allocations by year
    final Map<int, List<LeaveAllocation>> allocationsByYear = {};
    for (final allocation in allocations) {
      allocationsByYear.putIfAbsent(allocation.year, () => []).add(allocation);
    }

    // Get current year allocations first
    final currentYear = DateTime.now().year;
    final currentYearAllocations = allocationsByYear[currentYear] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Leave Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

        // Current Year Section
        if (currentYearAllocations.isNotEmpty) ...[
          Text(
            'Current Year ($currentYear)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          _buildAllocationCards(context, currentYearAllocations),
        ],

        // Other Years Section (if detailed view)
        if (showDetailedView && allocationsByYear.length > 1) ...[
          const SizedBox(height: 16),
          ...allocationsByYear.entries
              .where((entry) => entry.key != currentYear)
              .map(
                  (entry) => _buildYearSection(context, entry.key, entry.value))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildYearSection(
      BuildContext context, int year, List<LeaveAllocation> yearAllocations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year $year',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        _buildAllocationCards(context, yearAllocations),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAllocationCards(
      BuildContext context, List<LeaveAllocation> yearAllocations) {
    return Column(
      children: yearAllocations
          .map((allocation) => _buildLeaveCard(context, allocation))
          .toList(),
    );
  }

  Widget _buildLeaveCard(BuildContext context, LeaveAllocation allocation) {
    final usagePercentage = allocation.usagePercentage;
    final isOverused = allocation.usedDays > allocation.allocatedDays;

    Color progressColor;
    if (isOverused) {
      progressColor = Colors.red;
    } else if (usagePercentage >= 80) {
      progressColor = Colors.orange;
    } else if (usagePercentage >= 60) {
      progressColor = Colors.yellow[700]!;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getLeaveTypeIcon(allocation.type),
                      color: _getLeaveTypeColor(allocation.type),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      allocation.type.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Text(
                  '${allocation.remainingDays} days left',
                  style: TextStyle(
                    color: isOverused ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: ${allocation.usedDays}/${allocation.allocatedDays}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${usagePercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: isOverused ? 1.0 : (usagePercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            if (isOverused)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Overused by ${allocation.usedDays - allocation.allocatedDays} days',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getLeaveTypeIcon(LeaveType type) {
    switch (type) {
      case LeaveType.sick:
        return Icons.local_hospital;
      case LeaveType.vacation:
        return Icons.beach_access;
      case LeaveType.off:
        return Icons.time_to_leave;
    }
  }

  Color _getLeaveTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.sick:
        return Colors.red[400]!;
      case LeaveType.vacation:
        return Colors.blue[400]!;
      case LeaveType.off:
        return Colors.green[400]!;
    }
  }
}

class AbsenceSummary extends StatelessWidget {
  final List<Absence> absences;
  final double totalAbsenceHours;
  final bool showTitle;
  final bool showDetailedView;

  const AbsenceSummary({
    super.key,
    required this.absences,
    required this.totalAbsenceHours,
    this.showTitle = true,
    this.showDetailedView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (absences.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Absence Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'No absences recorded.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    // Group absences by type
    final Map<AbsenceType, List<Absence>> absencesByType = {};
    for (final absence in absences) {
      absencesByType.putIfAbsent(absence.type, () => []).add(absence);
    }

    // Calculate hours by type
    final Map<AbsenceType, double> hoursByType = {};
    for (final entry in absencesByType.entries) {
      final totalMinutes = entry.value.fold<int>(
        0,
        (sum, absence) => sum + absence.duration.inMinutes,
      );
      hoursByType[entry.key] = totalMinutes / 60.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Absence Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        const SizedBox(height: 4),

        // Total hours card
        Card(
          margin: const EdgeInsets.all(8.0),
          color: Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Absence Hours',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${totalAbsenceHours.toStringAsFixed(1)} hours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Breakdown by type
        ...absencesByType.entries
            .map((entry) => _buildAbsenceTypeCard(
                context, entry.key, entry.value, hoursByType[entry.key]!))
            .toList(),

        if (showDetailedView) ...[
          const SizedBox(height: 16),
          Text(
            'Recent Absences',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...absences
              .take(5)
              .map((absence) => _buildAbsenceDetailCard(context, absence))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildAbsenceTypeCard(BuildContext context, AbsenceType type,
      List<Absence> typeAbsences, double hours) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              _getAbsenceTypeIcon(type),
              color: _getAbsenceTypeColor(type),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    '${typeAbsences.length} incidents • ${hours.toStringAsFixed(1)} hours',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceDetailCard(BuildContext context, Absence absence) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              _getAbsenceTypeIcon(absence.type),
              color: _getAbsenceTypeColor(absence.type),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(absence.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (absence.reason != null && absence.reason!.isNotEmpty)
                    Text(
                      absence.reason!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ),
            ),
            Text(
              '${(absence.duration.inMinutes / 60).toStringAsFixed(1)}h',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getAbsenceTypeColor(absence.type),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAbsenceTypeIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.illness:
        return Icons.sick;
      case AbsenceType.lateArrival:
        return Icons.schedule;
      case AbsenceType.approvedTimeOff:
        return Icons.event_available;
    }
  }

  Color _getAbsenceTypeColor(AbsenceType type) {
    switch (type) {
      case AbsenceType.illness:
        return Colors.red[400]!;
      case AbsenceType.lateArrival:
        return Colors.orange[400]!;
      case AbsenceType.approvedTimeOff:
        return Colors.green[400]!;
    }
  }
}

class RecordAbsenceForm extends StatefulWidget {
  final String employeeId;
  final VoidCallback? onAbsenceRecorded;

  const RecordAbsenceForm({
    super.key,
    required this.employeeId,
    this.onAbsenceRecorded,
  });

  @override
  State<RecordAbsenceForm> createState() => _RecordAbsenceFormState();
}

class _RecordAbsenceFormState extends State<RecordAbsenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  AbsenceType _selectedType = AbsenceType.illness;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isPartialDay = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Absence',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Absence Type
              DropdownButtonFormField<AbsenceType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Absence Type',
                  border: OutlineInputBorder(),
                ),
                items: AbsenceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getAbsenceTypeIcon(type), size: 16),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),

              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ),
              ),

              const SizedBox(height: 16),

              // Partial day checkbox
              CheckboxListTile(
                title: const Text('Partial Day Absence'),
                subtitle:
                    const Text('Select specific hours instead of full day'),
                value: _isPartialDay,
                onChanged: (value) => setState(() => _isPartialDay = value!),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              if (_isPartialDay) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Provide additional details...',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Duration display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${_calculateDuration().toStringAsFixed(1)} hours',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAbsence,
                  child: const Text('Record Absence'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAbsenceTypeIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.illness:
        return Icons.sick;
      case AbsenceType.lateArrival:
        return Icons.schedule;
      case AbsenceType.approvedTimeOff:
        return Icons.event_available;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  double _calculateDuration() {
    if (_isPartialDay) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      final duration = endMinutes - startMinutes;
      return duration > 0 ? duration / 60.0 : 0.0;
    } else {
      // Full day = 7 hours (10 AM to 5 PM)
      return 7.0;
    }
  }

  Future<void> _submitAbsence() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = _calculateDuration();
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid time range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final leaveController = context.read<LeaveManagementController>();

    try {
      await leaveController.recordAbsence(
        employeeId: widget.employeeId,
        type: _selectedType,
        date: _selectedDate,
        duration: Duration(minutes: (duration * 60).round()),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      // Reset form
      setState(() {
        _reasonController.clear();
        _selectedType = AbsenceType.illness;
        _selectedDate = DateTime.now();
        _startTime = const TimeOfDay(hour: 10, minute: 0);
        _endTime = const TimeOfDay(hour: 17, minute: 0);
        _isPartialDay = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absence recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onAbsenceRecorded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record absence: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class AbsenceDialog extends StatelessWidget {
  final List<Absence> absences;
  final String employeeName;

  const AbsenceDialog({
    super.key,
    required this.absences,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text('${appLocalizations.absence_details} - $employeeName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: absences.isEmpty
              ? [Text(appLocalizations.no_absences)]
              : absences
                  .map((absence) => ListTile(
                        title: Text(absence.type.displayName),
                        subtitle: Text(
                          'Date: ${DateFormat.yMMMd().format(absence.date)}\n'
                          'Duration: ${(absence.duration.inMinutes / 60.0).toStringAsFixed(2)} hrs\n'
                          'Reason: ${absence.reason ?? 'N/A'}',
                        ),
                      ))
                  .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.close),
        ),
      ],
    );
  }
}
