import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:leave_management/data/models/project_model.dart';
import 'package:leave_management/data/models/task_model.dart';
import 'package:leave_management/data/services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService;

  List<ProjectModel> _projects = [];
  List<TaskModel> _myTasks = [];
  List<TaskModel> _projectTasks = [];
  ProjectModel? _selectedProject;
  TaskModel? _selectedTask;
  Map<String, dynamic> _projectStatistics = {};
  Map<String, dynamic> _taskStatistics = {};
  List<Map<String, dynamic>> _projectImages = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProjectProvider(this._projectService);

  List<ProjectModel> get projects => _projects;
  List<TaskModel> get myTasks => _myTasks;
  List<TaskModel> get projectTasks => _projectTasks;
  ProjectModel? get selectedProject => _selectedProject;
  TaskModel? get selectedTask => _selectedTask;
  Map<String, dynamic> get projectStatistics => _projectStatistics;
  Map<String, dynamic> get taskStatistics => _taskStatistics;
  List<Map<String, dynamic>> get projectImages => _projectImages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Helper to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }

  // ==================== PROJECT METHODS ====================

  // Fetch All Projects
  Future<void> fetchProjects({
    String? status,
    String? priority,
    String? search,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _projects = await _projectService.getAllProjects(
        status: status,
        priority: priority,
        search: search,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Fetch Project by ID
  Future<void> fetchProjectById(int projectId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedProject = await _projectService.getProjectById(projectId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Create Project
  Future<bool> createProject({
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
    _setLoading(true);
    _errorMessage = null;

    try {
      final project = await _projectService.createProject(
        name: name,
        description: description,
        status: status,
        startDate: startDate,
        endDate: endDate,
        projectManagerId: projectManagerId,
        budget: budget,
        progress: progress,
        priority: priority,
        memberIds: memberIds,
      );

      _projects.insert(0, project);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update Project
  Future<bool> updateProject({
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
    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedProject = await _projectService.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        status: status,
        startDate: startDate,
        endDate: endDate,
        projectManagerId: projectManagerId,
        budget: budget,
        progress: progress,
        priority: priority,
      );

      // Update in projects list
      final index = _projects.indexWhere((project) => project.id == projectId);
      if (index != -1) {
        _projects[index] = updatedProject;
      }

      // Update selected project if it's the same
      if (_selectedProject?.id == projectId) {
        _selectedProject = updatedProject;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete Project
  Future<bool> deleteProject(int projectId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _projectService.deleteProject(projectId);
      _projects.removeWhere((project) => project.id == projectId);
      
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Assign Member to Project
  Future<bool> assignMember({
    required int projectId,
    required int userId,
    String role = 'member',
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _projectService.assignMember(
        projectId: projectId,
        userId: userId,
        role: role,
      );
      
      // Refresh project details
      await fetchProjectById(projectId);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Remove Member from Project
  Future<bool> removeMember({
    required int projectId,
    required int userId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _projectService.removeMember(
        projectId: projectId,
        userId: userId,
      );
      
      // Refresh project details
      await fetchProjectById(projectId);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Fetch Project Statistics
  Future<void> fetchProjectStatistics() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _projectStatistics = await _projectService.getProjectStatistics();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ==================== TASK METHODS ====================

  // Fetch All Tasks
  Future<void> fetchTasks({
    int? projectId,
    String? status,
    String? priority,
    int? assignedTo,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final tasks = await _projectService.getAllTasks(
        projectId: projectId,
        status: status,
        priority: priority,
        assignedTo: assignedTo,
      );

      if (projectId != null) {
        _projectTasks = tasks;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Fetch Task by ID
  Future<void> fetchTaskById(int taskId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedTask = await _projectService.getTaskById(taskId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Create Task
  Future<bool> createTask({
    required int projectId,
    required String title,
    required String description,
    String status = 'todo',
    String priority = 'medium',
    int? assignedTo,
    DateTime? dueDate,
    double? estimatedHours,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final task = await _projectService.createTask(
        projectId: projectId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
        estimatedHours: estimatedHours,
      );

      _projectTasks.insert(0, task);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update Task
  Future<bool> updateTask({
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
    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedTask = await _projectService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
        estimatedHours: estimatedHours,
        actualHours: actualHours,
      );

      // Update in project tasks list
      final index = _projectTasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _projectTasks[index] = updatedTask;
      }

      // Update in my tasks list
      final myTaskIndex = _myTasks.indexWhere((task) => task.id == taskId);
      if (myTaskIndex != -1) {
        _myTasks[myTaskIndex] = updatedTask;
      }

      // Update selected task if it's the same
      if (_selectedTask?.id == taskId) {
        _selectedTask = updatedTask;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete Task
  Future<bool> deleteTask(int taskId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _projectService.deleteTask(taskId);
      _projectTasks.removeWhere((task) => task.id == taskId);
      _myTasks.removeWhere((task) => task.id == taskId);
      
      if (_selectedTask?.id == taskId) {
        _selectedTask = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Assign Task to User
  Future<bool> assignTask({
    required int taskId,
    required int assignedTo,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedTask = await _projectService.assignTask(
        taskId: taskId,
        assignedTo: assignedTo,
      );

      // Update in project tasks list
      final index = _projectTasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _projectTasks[index] = updatedTask;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Fetch My Tasks
  Future<void> fetchMyTasks({
    String? status,
    String? priority,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _myTasks = await _projectService.getMyTasks(
        status: status,
        priority: priority,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Fetch Task Statistics
  Future<void> fetchTaskStatistics({int? projectId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _taskStatistics = await _projectService.getTaskStatistics(
        projectId: projectId,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ==================== PROJECT IMAGE METHODS ====================

  /// Upload project image
  Future<bool> uploadProjectImage({
    required int projectId,
    required File file,
    String? description,
  }) async {
    _errorMessage = null;

    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        if (description != null) 'description': description,
      });

      final response = await _projectService.uploadProjectImage(
        projectId: projectId,
        formData: formData,
      );

      if (response['success'] == true) {
        // Refresh images after successful upload
        await fetchProjectImages(projectId);
        return true;
      }
      
      _errorMessage = response['message'] ?? 'Failed to upload image';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to upload image: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Fetch project images
  Future<void> fetchProjectImages(int projectId) async {
    _errorMessage = null;

    try {
      final response = await _projectService.getProjectImages(projectId);
      
      if (response['success'] == true) {
        _projectImages = List<Map<String, dynamic>>.from(
          response['images'] ?? []
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch images: ${e.toString()}';
      _projectImages = [];
      notifyListeners();
    }
  }

  /// Delete project image
  Future<bool> deleteProjectImage({
    required int projectId,
    required int imageId,
  }) async {
    _errorMessage = null;

    try {
      final response = await _projectService.deleteProjectImage(
        projectId: projectId,
        imageId: imageId,
      );

      if (response['success'] == true) {
        // Refresh images after successful deletion
        await fetchProjectImages(projectId);
        return true;
      }
      
      _errorMessage = response['message'] ?? 'Failed to delete image';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete image: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear selected project
  void clearSelectedProject() {
    _selectedProject = null;
    notifyListeners();
  }

  // Clear selected task
  void clearSelectedTask() {
    _selectedTask = null;
    notifyListeners();
  }
}
