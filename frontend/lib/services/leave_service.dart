import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/absence_model.dart';
import '../models/leave_model.dart';

class LeaveService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<LeaveAllocation>> getEmployeeLeaveAllocations(String employeeId, [int? year]) async {
    try {
      print('Fetching leave allocations for employee: $employeeId');
      
      var query = client
          .from('leave_allocations')
          .select('*')
          .eq('employee_id', employeeId);
      
      if (year != null) {
        query = query.eq('year', year);
      }
      
      final response = await query.order('year', ascending: false);
      
      print('Leave allocations response: $response');
      
      return response.map((map) => LeaveAllocation.fromMap(map)).toList();
    } catch (e) {
      print("getEmployeeLeaveAllocations() failed: $e");
      return [];
    }
  }

  Future<Map<String, List<LeaveAllocation>>> getAllEmployeesLeaveAllocations([int? year]) async {
    try {
      print('Fetching all employees leave allocations for year: ${year ?? 'all years'}');
      
      var query = client.from('leave_allocations').select('*');
      
      if (year != null) {
        query = query.eq('year', year);
      }
      
      final response = await query.order('employee_id').order('year', ascending: false);
      
      print('All leave allocations response: ${response.length} records');
      
      final Map<String, List<LeaveAllocation>> employeeAllocations = {};
      
      for (final map in response) {
        final allocation = LeaveAllocation.fromMap(map);
        if (!employeeAllocations.containsKey(allocation.employeeId)) {
          employeeAllocations[allocation.employeeId] = [];
        }
        employeeAllocations[allocation.employeeId]!.add(allocation);
      }
      
      return employeeAllocations;
    } catch (e) {
      print("getAllEmployeesLeaveAllocations() failed: $e");
      return {};
    }
  }

  Future<bool> createLeaveAllocation({
    required String employeeId,
    required LeaveType type,
    required int allocatedDays,
    int usedDays = 0,
    int? year,
  }) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      final response = await client.from('leave_allocations').insert({
        'employee_id': employeeId,
        'leave_type': type.name,
        'allocated_days': allocatedDays,
        'used_days': usedDays,
        'year': targetYear,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('Leave allocation created successfully');
      return true;
    } catch (e) {
      print("createLeaveAllocation() failed: $e");
      return false;
    }
  }

  Future<bool> updateLeaveAllocation({
    required String id,
    int? allocatedDays,
    int? usedDays,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (allocatedDays != null) updates['allocated_days'] = allocatedDays;
      if (usedDays != null) updates['used_days'] = usedDays;
      
      await client.from('leave_allocations').update(updates).eq('id', id);
      
      print('Leave allocation updated successfully');
      return true;
    } catch (e) {
      print("updateLeaveAllocation() failed: $e");
      return false;
    }
  }

  Future<bool> initializeEmployeeLeaveAllocations(String employeeId, [int? year]) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      // Check if allocations already exist for this year
      final existing = await getEmployeeLeaveAllocations(employeeId, targetYear);
      if (existing.isNotEmpty) {
        print('Leave allocations already exist for employee $employeeId in year $targetYear');
        return true;
      }
      
      // Create default allocations for all leave types
      final defaultAllocations = [
        {'type': LeaveType.sick, 'days': 10},
        {'type': LeaveType.vacation, 'days': 20},
        {'type': LeaveType.off, 'days': 5},
      ];
      
      for (final allocation in defaultAllocations) {
        await createLeaveAllocation(
          employeeId: employeeId,
          type: allocation['type'] as LeaveType,
          allocatedDays: allocation['days'] as int,
          year: targetYear,
        );
      }
      
      print('Initialized leave allocations for employee $employeeId');
      return true;
    } catch (e) {
      print("initializeEmployeeLeaveAllocations() failed: $e");
      return false;
    }
  }

  Future<List<Absence>> getEmployeeAbsences(String employeeId, [int? year]) async {
    try {
      print('Fetching absences for employee: $employeeId');
      var query = client
          .from('absences')
          .select('*')
          .eq('employee_id', employeeId);

      if (year != null) {
        query = query.gte('date', DateTime(year).toIso8601String())
                    .lte('date', DateTime(year, 12, 31).toIso8601String());
      }

      final response = await query.order('date', ascending: false);
      print('Absences response: $response');
      return response.map((map) => Absence.fromMap(map)).toList();
    } catch (e) {
      print("getEmployeeAbsences() failed: $e");
      return [];
    }
  }

  Future<bool> createAbsence({
    required String employeeId,
    required AbsenceType type,
    required DateTime date,
    required Duration duration,
    String? reason,
  }) async {
    try {
      final response = await client.from('absences').insert({
        'employee_id': employeeId,
        'absence_type': type.name,
        'date': date.toIso8601String(),
        'duration_minutes': duration.inMinutes,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Absence created successfully');
      return true;
    } catch (e) {
      print("createAbsence() failed: $e");
      return false;
    }
  }
  
}