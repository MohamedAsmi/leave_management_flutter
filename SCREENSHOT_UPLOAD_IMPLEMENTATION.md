# Task Screenshot Upload Implementation Guide

## Overview
This guide provides complete implementation details for adding screenshot/attachment upload functionality to tasks. Users can upload multiple screenshots to document task progress, issues, or completion.

---

## 📱 Frontend Implementation (Flutter)

### 1. Install Required Packages

Add to `pubspec.yaml`:
```yaml
dependencies:
  image_picker: ^1.0.7  # For selecting images from gallery/camera
  file_picker: ^8.1.6   # For selecting any files
  path_provider: ^2.1.5 # Already installed
  http: ^1.2.0          # Already installed
```

Run:
```bash
flutter pub get
```

### 2. Configure Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
    <!-- Add these permissions before <application> tag -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <application>
        <!-- Add FileProvider for Android 10+ -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
```

Create `android/app/src/main/res/xml/file_paths.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <cache-path name="cache" path="." />
</paths>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<dict>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photo library to upload screenshots</string>
    <key>NSCameraUsageDescription</key>
    <string>We need access to your camera to take screenshots</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>We need access to your microphone for video recording</string>
</dict>
```

### 3. Create Upload Service

Create `lib/data/services/file_upload_service.dart`:

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:leave_management/data/services/api_client.dart';

class FileUploadService {
  final ApiClient _apiClient;

  FileUploadService(this._apiClient);

  /// Upload task screenshot/attachment
  Future<Map<String, dynamic>> uploadTaskAttachment({
    required int taskId,
    required File file,
    String? description,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'task_id': taskId,
        'attachment': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        if (description != null) 'description': description,
      });

      final response = await _apiClient.post(
        '/tasks/$taskId/attachments',
        data: formData,
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get task attachments
  Future<List<Map<String, dynamic>>> getTaskAttachments(int taskId) async {
    try {
      final response = await _apiClient.get('/tasks/$taskId/attachments');
      return List<Map<String, dynamic>>.from(response.data['attachments']);
    } catch (e) {
      return [];
    }
  }

  /// Delete attachment
  Future<bool> deleteAttachment(int taskId, int attachmentId) async {
    try {
      await _apiClient.delete('/tasks/$taskId/attachments/$attachmentId');
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### 4. Update Task Model

Add to `lib/data/models/task_model.dart`:

```dart
class TaskAttachment {
  final int id;
  final int taskId;
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final String fileType;
  final int fileSize;
  final String? description;
  final int uploadedBy;
  final String? uploaderName;
  final DateTime createdAt;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.description,
    required this.uploadedBy,
    this.uploaderName,
    required this.createdAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'],
      taskId: json['task_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      description: json['description'],
      uploadedBy: json['uploaded_by'],
      uploaderName: json['uploader_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp']
      .contains(fileType.toLowerCase());

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Add to TaskModel class:
class TaskModel {
  // ... existing fields...
  final List<TaskAttachment>? attachments;

  // Update fromJson to include attachments
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      // ... existing fields...
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => TaskAttachment.fromJson(a))
              .toList()
          : null,
    );
  }
}
```

### 5. Update Task Detail Screen

Update `lib/presentation/screens/staff/task_detail_screen.dart`:

```dart
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  List<TaskAttachment> _attachments = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    // Load attachments from API
    final projectProvider = context.read<ProjectProvider>();
    // You'll need to add this method to ProjectProvider
    await projectProvider.fetchTaskAttachments(int.parse(widget.taskId));
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAttachment(File(image.path));
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAttachment(File(image.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await _uploadAttachment(file);
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _uploadAttachment(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final projectProvider = context.read<ProjectProvider>();
      final taskId = int.parse(widget.taskId);

      final success = await projectProvider.uploadTaskAttachment(
        taskId: taskId,
        file: file,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadAttachments();
      } else {
        _showError('Failed to upload file');
      }
    } catch (e) {
      _showError('Error uploading file: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppColors.primary),
              title: const Text('Attach File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attachments & Screenshots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (task.assignedTo == authProvider.currentUser?.id)
              IconButton.filled(
                onPressed: _isUploading ? null : _showUploadOptions,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_attachments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No attachments yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (task.assignedTo == authProvider.currentUser?.id) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showUploadOptions,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Screenshot'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              final attachment = _attachments[index];
              return _buildAttachmentCard(attachment);
            },
          ),
      ],
    );
  }

  Widget _buildAttachmentCard(TaskAttachment attachment) {
    return GestureDetector(
      onTap: () => _viewAttachment(attachment),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: attachment.isImage && attachment.fileUrl != null
                  ? Image.network(
                      attachment.fileUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFileIcon(attachment.fileType),
                    )
                  : _buildFileIcon(attachment.fileType),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteAttachment(attachment);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileType) {
    IconData icon;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(icon, size: 40, color: color),
      ),
    );
  }

  void _viewAttachment(TaskAttachment attachment) {
    // Show full screen image or open file
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(attachment.fileName),
              automaticallyImplyLeading: true,
            ),
            if (attachment.isImage && attachment.fileUrl != null)
              InteractiveViewer(
                child: Image.network(attachment.fileUrl!),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFileIcon(attachment.fileType),
                    const SizedBox(height: 16),
                    Text(attachment.fileName),
                    Text(attachment.fileSizeFormatted),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement download functionality
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAttachment(TaskAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: const Text('Are you sure you want to delete this attachment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete attachment via API
      final success = await context.read<ProjectProvider>().deleteTaskAttachment(
            int.parse(widget.taskId),
            attachment.id,
          );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment deleted')),
        );
        await _loadAttachments();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

// In the build method, add this section after Time Tracking:
children: [
  // ... existing sections...
  
  const SizedBox(height: 24),
  _buildAttachmentsSection(task),
  
  const SizedBox(height: 24),
  // ... rest of sections...
]
```

---

## 🔧 Backend Implementation (Laravel)

### 1. Create Migration

```bash
php artisan make:migration create_task_attachments_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('task_attachments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained()->onDelete('cascade');
            $table->string('file_name');
            $table->string('file_path');
            $table->string('file_type');
            $table->integer('file_size'); // in bytes
            $table->text('description')->nullable();
            $table->foreignId('uploaded_by')->constrained('users');
            $table->timestamps();
            
            $table->index(['task_id', 'created_at']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('task_attachments');
    }
};
```

```bash
php artisan migrate
```

### 2. Create Model

`app/Models/TaskAttachment.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaskAttachment extends Model
{
    protected $fillable = [
        'task_id',
        'file_name',
        'file_path',
        'file_type',
        'file_size',
        'description',
        'uploaded_by',
    ];

    protected $appends = ['file_url'];

    public function task()
    {
        return $this->belongsTo(Task::class);
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function getFileUrlAttribute()
    {
        return url('storage/' . $this->file_path);
    }

    public function isImage()
    {
        $imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        return in_array(strtolower($this->file_type), $imageTypes);
    }
}
```

### 3. Update TaskController

`app/Http/Controllers/Api/TaskController.php`:

```php
use Illuminate\Support\Facades\Storage;
use App\Models\TaskAttachment;

class TaskController extends Controller
{
    /**
     * Upload task attachment
     */
    public function uploadAttachment(Request $request, $taskId)
    {
        try {
            $request->validate([
                'attachment' => 'required|file|max:10240', // 10MB max
                'description' => 'nullable|string|max:500',
            ]);

            $task = Task::findOrFail($taskId);
            $user = $request->user();

            // Check authorization
            if (!$user->isAdmin() && 
                !$user->isHR() && 
                !$task->project->isProjectManager($user->id) &&
                $task->assigned_to != $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'You do not have permission to upload attachments',
                ], 403);
            }

            if ($request->hasFile('attachment')) {
                $file = $request->file('attachment');
                $fileName = time() . '_' . $file->getClientOriginalName();
                $fileType = $file->getClientOriginalExtension();
                $fileSize = $file->getSize();

                // Store file
                $path = $file->storeAs('task_attachments/' . $taskId, $fileName, 'public');

                // Create attachment record
                $attachment = TaskAttachment::create([
                    'task_id' => $taskId,
                    'file_name' => $fileName,
                    'file_path' => $path,
                    'file_type' => $fileType,
                    'file_size' => $fileSize,
                    'description' => $request->description,
                    'uploaded_by' => $user->id,
                ]);

                // Notify project manager
                if ($task->project->projectManager && 
                    $task->project->projectManager->id != $user->id) {
                    
                    Notification::create([
                        'user_id' => $task->project->projectManager->id,
                        'title' => 'Task Attachment Added',
                        'message' => "{$user->name} uploaded an attachment to task '{$task->title}'",
                        'type' => 'task_attachment',
                        'related_id' => $taskId,
                        'is_read' => false,
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Attachment uploaded successfully',
                    'attachment' => $attachment->load('uploader'),
                ], 201);
            }

            return response()->json([
                'success' => false,
                'message' => 'No file uploaded',
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload attachment',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get task attachments
     */
    public function getAttachments($taskId)
    {
        try {
            $attachments = TaskAttachment::where('task_id', $taskId)
                ->with('uploader:id,name')
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($attachment) {
                    return [
                        'id' => $attachment->id,
                        'task_id' => $attachment->task_id,
                        'file_name' => $attachment->file_name,
                        'file_path' => $attachment->file_path,
                        'file_url' => $attachment->file_url,
                        'file_type' => $attachment->file_type,
                        'file_size' => $attachment->file_size,
                        'description' => $attachment->description,
                        'uploaded_by' => $attachment->uploaded_by,
                        'uploader_name' => $attachment->uploader->name ?? null,
                        'created_at' => $attachment->created_at,
                    ];
                });

            return response()->json([
                'success' => true,
                'attachments' => $attachments,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch attachments',
            ], 500);
        }
    }

    /**
     * Delete attachment
     */
    public function deleteAttachment($taskId, $attachmentId)
    {
        try {
            $attachment = TaskAttachment::where('task_id', $taskId)
                ->where('id', $attachmentId)
                ->firstOrFail();

            $user = auth()->user();

            // Only uploader, admin, HR, or PM can delete
            if ($attachment->uploaded_by != $user->id &&
                !$user->isAdmin() && 
                !$user->isHR() && 
                !$attachment->task->project->isProjectManager($user->id)) {
                
                return response()->json([
                    'success' => false,
                    'message' => 'You do not have permission to delete this attachment',
                ], 403);
            }

            // Delete file from storage
            Storage::disk('public')->delete($attachment->file_path);

            // Delete record
            $attachment->delete();

            return response()->json([
                'success' => true,
                'message' => 'Attachment deleted successfully',
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete attachment',
            ], 500);
        }
    }
}
```

### 4. Add Routes

`routes/api.php`:

```php
Route::middleware('auth:sanctum')->group(function () {
    // Task Attachment Routes
    Route::post('/tasks/{taskId}/attachments', [TaskController::class, 'uploadAttachment']);
    Route::get('/tasks/{taskId}/attachments', [TaskController::class, 'getAttachments']);
    Route::delete('/tasks/{taskId}/attachments/{attachmentId}', [TaskController::class, 'deleteAttachment']);
});
```

### 5. Create Storage Link

```bash
php artisan storage:link
```

### 6. Configure File System

`config/filesystems.php` (should already be configured):

```php
'public' => [
    'driver' => 'local',
    'root' => storage_path('app/public'),
    'url' => env('APP_URL').'/storage',
    'visibility' => 'public',
],
```

---

## 🧪 Testing

### 1. Test Upload
```bash
# Using Postman or curl
curl -X POST http://localhost:8000/api/tasks/1/attachments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "attachment=@/path/to/screenshot.png" \
  -F "description=Bug screenshot"
```

### 2. Test Get Attachments
```bash
curl -X GET http://localhost:8000/api/tasks/1/attachments \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Test Delete
```bash
curl -X DELETE http://localhost:8000/api/tasks/1/attachments/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📝 Usage Instructions for Users

### Uploading Screenshots:

1. Open any task details screen
2. Scroll to "Attachments & Screenshots" section
3. Tap the **+** button (camera icon)
4. Choose:
   - **Take Photo**: Opens camera to take a new screenshot
   - **Choose from Gallery**: Select existing image
   - **Attach File**: Select PDF, DOC, or other files
5. File uploads automatically
6. View uploaded files in grid layout

### Viewing Screenshots:

- Tap any thumbnail to view full size
- Pinch to zoom on images
- Download files if needed

### Deleting Screenshots:

- Tap ⋮ menu on any attachment thumbnail
- Select "Delete"
- Confirm deletion

---

## 🔒 Security Considerations

1. **File Size Limits**: Maximum 10MB per file
2. **File Type Validation**: Only allowed extensions
3. **Authorization**: Only task assignees, PM, and admins can upload
4. **Secure Storage**: Files stored outside public directory
5. **Access Control**: Files served through authenticated endpoints

---

## 📱 Features Summary

✅ Upload multiple screenshots/attachments per task  
✅ Take photo with camera  
✅ Select from gallery  
✅ Attach documents (PDF, DOC, etc.)  
✅ View images in full screen with zoom  
✅ Delete attachments  
✅ See file size and type  
✅ Track who uploaded what  
✅ Notifications when attachments added  
✅ Grid layout display  
✅ Responsive UI  

---

## 🛠️ Troubleshooting

**Permission Denied Error:**
- Check AndroidManifest.xml permissions
- Request runtime permissions for Android 6+
- Check Info.plist for iOS

**Upload Fails:**
- Check file size (max 10MB)
- Verify file extension is allowed
- Check storage space

**Images Not Displaying:**
- Verify storage link created: `php artisan storage:link`
- Check file permissions on storage directory
- Verify APP_URL in .env matches your domain

---

## Next Steps

1. Install dependencies: `flutter pub get`
2. Run migrations: `php artisan migrate`
3. Create storage link: `php artisan storage:link`
4. Update TaskController with new methods
5. Add routes to api.php
6. Test upload functionality
7. Deploy and enjoy! 🎉
