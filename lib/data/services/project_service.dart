import 'package:dio/dio.dart';
import 'package:leave_management/data/models/project_model.dart';
import 'package:leave_management/data/models/task_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class ProjectService {
  final ApiClient _apiClient;

  ProjectService(this._apiClient);

  // ==================== PROJECT ENDPOINTS ====================

  // Get All Projects (filtered by user role)
  Future<List<ProjectModel>> getAllProjects({
    int page = 1,
    int perPage = 20,
    String? status,
    String? priority,
    String? search,
  }) async {
    final response = await _apiClient.get(
      '/projects',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (search != null) 'search': search,
      },
    );

    final projectsData = response.data['projects'] as List;
    return projectsData.map((project) => ProjectModel.fromJson(project)).toList();
  }

  // Get Project by ID
  Future<ProjectModel> getProjectById(int projectId) async {
    final response = await _apiClient.get('/projects/$projectId');
    return ProjectModel.fromJson(response.data['project']);
  }

  // Create Project
  Future<ProjectModel> createProject({
    required String name,
    required String description,
    required String status,
    required DateTime startDate,
    required DateTime endDate,
    required int projectManagerId,
    double? budget,
    int progress = 0,
    String priority = 'medium',
    List<int>? memberIds,
  }) async {
    final response = await _apiClient.post(
      '/projects',
      data: {
        'name': name,
        'description': description,
        'status': status,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'project_manager_id': projectManagerId,
        if (budget != null) 'budget': budget,
        'progress': progress,
        'priority': priority,
        if (memberIds != null) 'member_ids': memberIds,
      },
    );

    return ProjectModel.fromJson(response.data['project']);
  }

  // Update Project
  Future<ProjectModel> updateProject({
    required int projectId,
    String? name,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? projectManagerId,
    double? budget,
    int? progress,
    String? priority,
  }) async {
    final response = await _apiClient.put(
      '/projects/$projectId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        if (projectManagerId != null) 'project_manager_id': projectManagerId,
        if (budget != null) 'budget': budget,
        if (progress != null) 'progress': progress,
        if (priority != null) 'priority': priority,
      },
    );

    return ProjectModel.fromJson(response.data['project']);
  }

  // Delete Project
  Future<void> deleteProject(int projectId) async {
    await _apiClient.delete('/projects/$projectId');
  }

  // Assign Member to Project
  Future<void> assignMember({
    required int projectId,
    required int userId,
    String role = 'member',
  }) async {
    await _apiClient.post(
      '/projects/$projectId/assign-member',
      data: {
        'user_id': userId,
        'role': role,
      },
    );
  }

  // Remove Member from Project
  Future<void> removeMember({
    required int projectId,
    required int userId,
  }) async {
    await _apiClient.post(
      '/projects/$projectId/remove-member',
      data: {
        'user_id': userId,
      },
    );
  }

  // Get Project Statistics
  Future<Map<String, dynamic>> getProjectStatistics() async {
    final response = await _apiClient.get('/projects/statistics');
    return response.data['statistics'];
  }

  // ==================== TASK ENDPOINTS ====================

  // Get All Tasks
  Future<List<TaskModel>> getAllTasks({
    int page = 1,
    int perPage = 20,
    int? projectId,
    String? status,
    String? priority,
    int? assignedTo,
  }) async {
    final response = await _apiClient.get(
      '/tasks',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (projectId != null) 'project_id': projectId,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
      },
    );

    final tasksData = response.data['tasks'] as List;
    return tasksData.map((task) => TaskModel.fromJson(task)).toList();
  }

  // Get Task by ID
  Future<TaskModel> getTaskById(int taskId) async {
    final response = await _apiClient.get('/tasks/$taskId');
    return TaskModel.fromJson(response.data['task']);
  }

  // Create Task
  Future<TaskModel> createTask({
    required int projectId,
    required String title,
    required String description,
    String status = 'todo',
    String priority = 'medium',
    int? assignedTo,
    DateTime? dueDate,
    double? estimatedHours,
  }) async {
    final response = await _apiClient.post(
      '/tasks',
      data: {
        'project_id': projectId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T')[0],
        if (estimatedHours != null) 'estimated_hours': estimatedHours,
      },
    );

    return TaskModel.fromJson(response.data['task']);
  }

  // Update Task
  Future<TaskModel> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? status,
    String? priority,
    int? assignedTo,
    DateTime? dueDate,
    double? estimatedHours,
    double? actualHours,
  }) async {
    final response = await _apiClient.put(
      '/tasks/$taskId',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T')[0],
        if (estimatedHours != null) 'estimated_hours': estimatedHours,
        if (actualHours != null) 'actual_hours': actualHours,
      },
    );

    return TaskModel.fromJson(response.data['task']);
  }

  // Delete Task
  Future<void> deleteTask(int taskId) async {
    await _apiClient.delete('/tasks/$taskId');
  }

  // Assign Task to User
  Future<TaskModel> assignTask({
    required int taskId,
    required int assignedTo,
  }) async {
    final response = await _apiClient.post(
      '/tasks/$taskId/assign',
      data: {
        'assigned_to': assignedTo,
      },
    );

    return TaskModel.fromJson(response.data['task']);
  }

  // Get My Tasks
  Future<List<TaskModel>> getMyTasks({
    int page = 1,
    int perPage = 20,
    String? status,
    String? priority,
  }) async {
    final response = await _apiClient.get(
      '/tasks/my-tasks',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
      },
    );

    final tasksData = response.data['tasks'] as List;
    return tasksData.map((task) => TaskModel.fromJson(task)).toList();
  }

  // Get Task Statistics
  Future<Map<String, dynamic>> getTaskStatistics({int? projectId}) async {
    final response = await _apiClient.get(
      '/tasks/statistics',
      queryParameters: {
        if (projectId != null) 'project_id': projectId,
      },
    );

    return response.data['statistics'];
  }

  // ==================== PROJECT IMAGE ENDPOINTS ====================

  /// Upload project image
  Future<Map<String, dynamic>> uploadProjectImage({
    required int projectId,
    required FormData formData,
  }) async {
    final response = await _apiClient.post(
      '/projects/$projectId/images',
      data: formData,
    );

    return response.data;
  }

  /// Get project images
  Future<Map<String, dynamic>> getProjectImages(int projectId) async {
    final response = await _apiClient.get('/projects/$projectId/images');
    return response.data;
  }

  /// Delete project image
  Future<Map<String, dynamic>> deleteProjectImage({
    required int projectId,
    required int imageId,
  }) async {
    final response = await _apiClient.delete(
      '/projects/$projectId/images/$imageId',
    );
    
    return response.data;
  }
}
