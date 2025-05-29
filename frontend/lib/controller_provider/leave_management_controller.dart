  import 'package:flutter/foundation.dart';
  import '../models/leave_model.dart';
  import '../services/leave_service.dart';

  class LeaveManagementController extends ChangeNotifier {
    final LeaveService _leaveService = LeaveService();
    final Map<String, List<LeaveAllocation>> _employeeAllocations = {};
    final Map<String, bool> _loadingStates = {};
    final Map<String, String?> _errorStates = {};

    bool isLoading(String employeeId) => _loadingStates[employeeId] ?? false;
    String? getError(String employeeId) => _errorStates[employeeId];
    bool hasLoadedAllocations(String employeeId) => _employeeAllocations.containsKey(employeeId);
    List<LeaveAllocation> getEmployeeAllocations(String employeeId) =>
        _employeeAllocations[employeeId] ?? [];

    Future<void> loadEmployeeLeaveAllocations(String employeeId) async {
      if (_loadingStates[employeeId] == true) return;

      _loadingStates[employeeId] = true;
      _errorStates[employeeId] = null;
      notifyListeners();

      try {
        final allocations = await _leaveService.getEmployeeLeaveAllocations(employeeId);
        _employeeAllocations[employeeId] = allocations;
      } catch (e) {
        _errorStates[employeeId] = 'Failed to load leave allocations: $e';
      } finally {
        _loadingStates[employeeId] = false;
        notifyListeners();
      }
    }

    void clearAllocations(String employeeId) {
      _employeeAllocations.remove(employeeId);
      _loadingStates.remove(employeeId);
      _errorStates.remove(employeeId);
      notifyListeners();
    }
  }