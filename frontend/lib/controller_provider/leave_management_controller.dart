// leave_management_controller.dart
import 'package:flutter/foundation.dart';
import '../models/leave_model.dart';
import '../models/absence_model.dart';
import '../services/leave_service.dart';

class LeaveManagementController extends ChangeNotifier {
  final LeaveService _leaveService = LeaveService();
  final Map<String, List<LeaveAllocation>> _employeeAllocations = {};
  final Map<String, List<Absence>> _employeeAbsences = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errorStates = {};

  bool isLoading(String employeeId) => _loadingStates[employeeId] ?? false;
  String? getError(String employeeId) => _errorStates[employeeId];
  bool hasLoadedAllocations(String employeeId) => _employeeAllocations.containsKey(employeeId);
  bool hasLoadedAbsences(String employeeId) => _employeeAbsences.containsKey(employeeId);
  List<LeaveAllocation> getEmployeeAllocations(String employeeId) =>
      _employeeAllocations[employeeId] ?? [];
  List<Absence> getEmployeeAbsences(String employeeId) =>
      _employeeAbsences[employeeId] ?? [];

  Future<void> loadEmployeeLeaveAllocations(String employeeId) async {
    if (_loadingStates[employeeId] == true) return;

    _loadingStates[employeeId] = true;
    _errorStates[employeeId] = null;
    notifyListeners();

    try {
      final allocations = await _leaveService.getEmployeeLeaveAllocations(employeeId);
      final absences = await _leaveService.getEmployeeAbsences(employeeId);
      _employeeAllocations[employeeId] = allocations;
      _employeeAbsences[employeeId] = absences;
    } catch (e) {
      _errorStates[employeeId] = 'Failed to load leave or absence data: $e';
    } finally {
      _loadingStates[employeeId] = false;
      notifyListeners();
    }
  }

  Future<void> recordAbsence({
    required String employeeId,
    required AbsenceType type,
    required DateTime date,
    required Duration duration,
    String? reason,
  }) async {
    _loadingStates[employeeId] = true;
    _errorStates[employeeId] = null;
    notifyListeners();

    try {
      final success = await _leaveService.createAbsence(
        employeeId: employeeId,
        type: type,
        date: date,
        duration: duration,
        reason: reason,
      );
      if (success) {
        await loadEmployeeLeaveAllocations(employeeId); // Refresh absences
      } else {
        throw Exception('Failed to record absence');
      }
    } catch (e) {
      _errorStates[employeeId] = 'Failed to record absence: $e';
    } finally {
      _loadingStates[employeeId] = false;
      notifyListeners();
    }
  }

  double getTotalAbsenceHours(String employeeId) {
    final absences = _employeeAbsences[employeeId] ?? [];
    final totalMinutes = absences.fold<int>(
        0, (sum, absence) => sum + absence.duration.inMinutes);
    return totalMinutes / 60.0; // Convert to hours
  }

  void clearAllocations(String employeeId) {
    _employeeAllocations.remove(employeeId);
    _employeeAbsences.remove(employeeId);
    _loadingStates.remove(employeeId);
    _errorStates.remove(employeeId);
    notifyListeners();
  }
}