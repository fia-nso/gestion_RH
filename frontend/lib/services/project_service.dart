import 'package:frontend/models/project_model.dart';
import 'package:frontend/uttils/api_fetcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProjectService {
  final SupabaseClient client = Supabase.instance.client;
  late ApiFetcher apiFetcher;

  ProjectService() {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    apiFetcher = ApiFetcher(accessToken: accessToken);
  }

  Future<bool> createProject({
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String size,
    required String scope,
    ProjectStatus status = ProjectStatus.planning,
    List<Map<String, String>>? employerAssignments,
    // String? peopleManagerId,
  }) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final roleResponse = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', currentUser.id)
          .single();

      if (roleResponse['role_id'] != 'admin') {
        throw Exception('Only admins can create projects');
      }

      final projectData = {
        'name': name.trim(),
        'description': description.trim(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'size': size.trim(),
        'scope': scope.trim(),
        'status': status.value,
        // 'people_manager_id': peopleManagerId,
        'employer_assignments': employerAssignments
            ?.map((a) => {
                  'employer_id': a['employer_id'],
                  'role': a['role'],
                })
            .toList(),
      };

      final projectResponse = await apiFetcher.post('projects', projectData);

      if (!projectResponse.isSuccess) {
        print(
            'Failed to create project: ${projectResponse.error} (Status: ${projectResponse.status})');
        return false;
      }

      return true;
    } catch (e) {
      print('createProject failed: $e');
      return false;
    }
  }

  Future<bool> updateProject({
    required String projectId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? size,
    String? scope,
    ProjectStatus? status,
    List<Map<String, String>>? employerAssignments,
    ProjectRole? role,
  }) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final roleResponse = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', currentUser.id)
          .single();

      if (roleResponse['role_id'] != 'admin') {
        throw Exception('Only admins can update projects');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (description != null) updates['description'] = description.trim();
      if (startDate != null) {
        updates['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        updates['end_date'] = endDate.toIso8601String();
      }
      if (size != null) updates['size'] = size.trim();
      if (scope != null) updates['scope'] = scope.trim();
      if (status != null) updates['status'] = status.value;
      // if (role != null)
      //   updates['role'] = role;
      // updates['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await client.from('projects').update(updates).eq('id', projectId);

      print('Project updated successfully: $projectId');
      return true;
    } catch (e) {
      print('updateProject failed: $e');
      return false;
    }
  }

  Future<List<Project>> getAllProjects() async {
    try {
      print('Fetching all projects...');

      final response = await client.from('projects').select('*');

      print('Raw Supabase response: $response');

      if (response.isEmpty) {
        print('No projects found.');
        return [];
      }

      final projects = response.map((map) {
        print('Mapping project: $map');
        return Project.fromMap(map);
      }).toList();

      print('Fetched ${projects.length} projects');
      return projects;
    } catch (e) {
      print('getAllProjects() failed: $e');
      return [];
    }
  }

  Future<Project?> getProject(String projectId) async {
    try {
      final response = await apiFetcher.get('projects/$projectId');
      if (!response.isSuccess) {
        print(
            'Failed to fetch project: ${response.error} (Status: ${response.status})');
        return null;
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Project.fromMap(data);
      }
      return null;
    } catch (e) {
      print('getProject failed: $e');
      return null;
    }
  }
}
