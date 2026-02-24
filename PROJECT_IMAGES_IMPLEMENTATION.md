# Project Images Implementation Guide

## Overview
This guide provides complete implementation details for adding image upload and display functionality to projects. Project Managers can upload multiple images to showcase their projects visually.

---

## 📱 Frontend Implementation (Flutter)

### Current Status
✅ **Already Implemented:**
- UI components in PM Project Detail Screen
- Image picker integration (camera, gallery, file picker)
- Image grid display with full-screen view
- Upload and delete dialogs
- Empty state UI

### Components Added:

1. **Image Upload Methods:**
   - `_showImageUploadOptions()` - Shows bottom sheet with upload options
   - `_pickImageFromCamera()` - Captures new photo
   - `_pickImageFromGallery()` - Selects from gallery
   - `_pickFile()` - Picks image file
   - `_uploadProjectImage(File file)` - Handles upload (requires backend)

2. **Image Display:**
   - `_buildProjectImagesSection()` - Main images section widget
   - `_buildImageCard()` - Individual image card with menu
   - `_viewImageFullScreen()` - Full-screen image viewer
   - `_deleteProjectImage()` - Delete image handler (requires backend)

3. **UI Features:**
   - Grid layout (3 columns)
   - Upload button with loading state
   - Empty state with call-to-action
   - Full-screen image viewer with zoom
   - Context menu (View, Delete)
   - Image loading indicators

---

## 🔧 Backend Implementation (Laravel)

### 1. Create Migration

```bash
php artisan make:migration create_project_images_table
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
        Schema::create('project_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained()->onDelete('cascade');
            $table->string('file_name');
            $table->string('file_path');
            $table->string('file_type')->default('image');
            $table->integer('file_size'); // in bytes
            $table->text('description')->nullable();
            $table->integer('display_order')->default(0);
            $table->foreignId('uploaded_by')->constrained('users');
            $table->timestamps();
            
            $table->index(['project_id', 'display_order']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('project_images');
    }
};
```

Run migration:
```bash
php artisan migrate
```

### 2. Create Model

Create `app/Models/ProjectImage.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProjectImage extends Model
{
    protected $fillable = [
        'project_id',
        'file_name',
        'file_path',
        'file_type',
        'file_size',
        'description',
        'display_order',
        'uploaded_by',
    ];

    protected $appends = ['file_url'];

    public function project()
    {
        return $this->belongsTo(Project::class);
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
        return $this->file_type === 'image';
    }
}
```

### 3. Update Project Model

Add relationship to `app/Models/Project.php`:

```php
/**
 * Get all images for this project
 */
public function images()
{
    return $this->hasMany(ProjectImage::class)->orderBy('display_order');
}
```

Update the `show()` method in ProjectController to include images:

```php
public function show($id)
{
    try {
        $project = Project::with([
            'projectManager',
            'members',
            'tasks.assignedUser',
            'images.uploader' // Add this line
        ])->findOrFail($id);

        return response()->json([
            'success' => true,
            'project' => $project,
        ], 200);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Project not found',
        ], 404);
    }
}
```

### 4. Add ProjectController Methods

Update `app/Http/Controllers/Api/ProjectController.php`:

```php
use Illuminate\Support\Facades\Storage;
use App\Models\ProjectImage;

/**
 * Upload project image
 */
public function uploadImage(Request $request, $projectId)
{
    try {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:10240', // 10MB max
            'description' => 'nullable|string|max:500',
        ]);

        $project = Project::findOrFail($projectId);
        $user = $request->user();

        // Check authorization - only PM, admin, or HR can upload
        if (!$user->isAdmin() && 
            !$user->isHR() && 
            !$project->isProjectManager($user->id)) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to upload images',
            ], 403);
        }

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $fileName = time() . '_' . preg_replace('/[^A-Za-z0-9\-\.]/', '_', $file->getClientOriginalName());
            $fileType = 'image';
            $fileSize = $file->getSize();

            // Store file
            $path = $file->storeAs('project_images/' . $projectId, $fileName, 'public');

            // Get next display order
            $maxOrder = ProjectImage::where('project_id', $projectId)->max('display_order');
            $displayOrder = ($maxOrder ?? -1) + 1;

            // Create image record
            $image = ProjectImage::create([
                'project_id' => $projectId,
                'file_name' => $fileName,
                'file_path' => $path,
                'file_type' => $fileType,
                'file_size' => $fileSize,
                'description' => $request->description,
                'display_order' => $displayOrder,
                'uploaded_by' => $user->id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Image uploaded successfully',
                'image' => $image->load('uploader'),
            ], 201);
        }

        return response()->json([
            'success' => false,
            'message' => 'No image uploaded',
        ], 400);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Failed to upload image',
            'error' => $e->getMessage(),
        ], 500);
    }
}

/**
 * Get project images
 */
public function getImages($projectId)
{
    try {
        $images = ProjectImage::where('project_id', $projectId)
            ->with('uploader:id,name')
            ->orderBy('display_order')
            ->get()
            ->map(function ($image) {
                return [
                    'id' => $image->id,
                    'project_id' => $image->project_id,
                    'file_name' => $image->file_name,
                    'file_path' => $image->file_path,
                    'url' => $image->file_url,
                    'file_type' => $image->file_type,
                    'file_size' => $image->file_size,
                    'description' => $image->description,
                    'display_order' => $image->display_order,
                    'uploaded_by' => $image->uploaded_by,
                    'uploader_name' => $image->uploader->name ?? null,
                    'created_at' => $image->created_at,
                ];
            });

        return response()->json([
            'success' => true,
            'images' => $images,
        ], 200);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Failed to fetch images',
        ], 500);
    }
}

/**
 * Delete project image
 */
public function deleteImage($projectId, $imageId)
{
    try {
        $image = ProjectImage::where('project_id', $projectId)
            ->where('id', $imageId)
            ->firstOrFail();

        $user = auth()->user();
        $project = $image->project;

        // Only uploader, PM, admin, or HR can delete
        if ($image->uploaded_by != $user->id &&
            !$user->isAdmin() && 
            !$user->isHR() && 
            !$project->isProjectManager($user->id)) {
            
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to delete this image',
            ], 403);
        }

        // Delete file from storage
        Storage::disk('public')->delete($image->file_path);

        // Delete record
        $image->delete();

        return response()->json([
            'success' => true,
            'message' => 'Image deleted successfully',
        ], 200);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Failed to delete image',
        ], 500);
    }
}

/**
 * Reorder project images
 */
public function reorderImages(Request $request, $projectId)
{
    try {
        $request->validate([
            'image_ids' => 'required|array',
            'image_ids.*' => 'integer|exists:project_images,id',
        ]);

        $project = Project::findOrFail($projectId);
        $user = $request->user();

        // Check authorization
        if (!$user->isAdmin() && 
            !$user->isHR() && 
            !$project->isProjectManager($user->id)) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to reorder images',
            ], 403);
        }

        foreach ($request->image_ids as $index => $imageId) {
            ProjectImage::where('id', $imageId)
                ->where('project_id', $projectId)
                ->update(['display_order' => $index]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Images reordered successfully',
        ], 200);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Failed to reorder images',
        ], 500);
    }
}
```

### 5. Add Routes

Update `routes/api.php`:

```php
Route::middleware('auth:sanctum')->group(function () {
    // Project Image Routes
    Route::post('/projects/{projectId}/images', [ProjectController::class, 'uploadImage']);
    Route::get('/projects/{projectId}/images', [ProjectController::class, 'getImages']);
    Route::delete('/projects/{projectId}/images/{imageId}', [ProjectController::class, 'deleteImage']);
    Route::put('/projects/{projectId}/images/reorder', [ProjectController::class, 'reorderImages']);
});
```

### 6. Create Storage Link

If not already created:
```bash
php artisan storage:link
```

---

## 🔄 Complete Flutter Integration

### Update ProjectProvider

Add methods to `lib/providers/project_provider.dart`:

```dart
import 'dart:io';
import 'package:dio/dio.dart';

class ProjectProvider extends ChangeNotifier {
  // ... existing code ...

  List<Map<String, dynamic>> _projectImages = [];
  List<Map<String, dynamic>> get projectImages => _projectImages;

  /// Upload project image
  Future<bool> uploadProjectImage({
    required int projectId,
    required File file,
    String? description,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'project_id': projectId,
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

      if (response.statusCode == 201) {
        // Refresh images
        await fetchProjectImages(projectId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to upload image';
      notifyListeners();
      return false;
    }
  }

  /// Fetch project images
  Future<void> fetchProjectImages(int projectId) async {
    try {
      final response = await _projectService.getProjectImages(projectId);
      
      if (response.statusCode == 200 && response.data['success']) {
        _projectImages = List<Map<String, dynamic>>.from(
          response.data['images'] ?? []
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch images';
      notifyListeners();
    }
  }

  /// Delete project image
  Future<bool> deleteProjectImage({
    required int projectId,
    required int imageId,
  }) async {
    try {
      final response = await _projectService.deleteProjectImage(
        projectId: projectId,
        imageId: imageId,
      );

      if (response.statusCode == 200) {
        await fetchProjectImages(projectId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete image';
      notifyListeners();
      return false;
    }
  }
}
```

### Update ProjectService

Add methods to your project service class:

```dart
import 'package:dio/dio.dart';

class ProjectService {
  final ApiClient _apiClient;

  ProjectService(this._apiClient);

  /// Upload project image
  Future<Response> uploadProjectImage({
    required int projectId,
    required FormData formData,
  }) async {
    return await _apiClient.post(
      '/projects/$projectId/images',
      data: formData,
    );
  }

  /// Get project images
  Future<Response> getProjectImages(int projectId) async {
    return await _apiClient.get('/projects/$projectId/images');
  }

  /// Delete project image
  Future<Response> deleteProjectImage({
    required int projectId,
    required int imageId,
  }) async {
    return await _apiClient.delete('/projects/$projectId/images/$imageId');
  }
}
```

### Update PM Project Detail Screen

Replace the placeholder upload method in `pm_project_detail_screen.dart`:

```dart
Future<void> _uploadProjectImage(File file) async {
  setState(() {
    _isUploadingImage = true;
  });

  try {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.uploadProjectImage(
      projectId: widget.projectId,
      file: file,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadProjectData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectProvider.errorMessage ?? 'Failed to upload image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    setState(() {
      _isUploadingImage = false;
    });
  }
}
```

Update `_loadProjectData()` to load images:

```dart
Future<void> _loadProjectData() async {
  final projectProvider = context.read<ProjectProvider>();
  await projectProvider.fetchProjectById(widget.projectId);
  await projectProvider.fetchTasks(projectId: widget.projectId);
  await projectProvider.fetchProjectImages(widget.projectId);
  
  setState(() {
    _projectImages = projectProvider.projectImages;
  });
}
```

Update `_deleteProjectImage()`:

```dart
Future<void> _deleteProjectImage(int imageId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Image'),
      content: const Text('Are you sure you want to delete this image?'),
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
    final projectProvider = context.read<ProjectProvider>();
    final success = await projectProvider.deleteProjectImage(
      projectId: widget.projectId,
      imageId: imageId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadProjectData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
```

---

## 🧪 Testing

### Backend Testing

**1. Upload Image:**
```bash
curl -X POST http://localhost:8000/api/projects/1/images \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/image.jpg" \
  -F "description=Project overview"
```

**2. Get Images:**
```bash
curl -X GET http://localhost:8000/api/projects/1/images \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**3. Delete Image:**
```bash
curl -X DELETE http://localhost:8000/api/projects/1/images/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Frontend Testing

1. Open PM Project Detail Screen
2. Navigate to Overview tab
3. Scroll to "Project Images" section
4. Click "Add Image" button
5. Select image source (Camera/Gallery/File)
6. Verify upload and display
7. Test full-screen view
8. Test delete functionality

---

## 📝 Features Summary

✅ **Upload project images** from camera, gallery, or files  
✅ **Grid display** with 3 columns  
✅ **Full-screen viewer** with InteractiveViewer (zoom/pan)  
✅ **Context menu** for each image (View, Delete)  
✅ **Empty state** with call-to-action  
✅ **Loading states** during upload  
✅ **Authorization** - Only PM, Admin, HR can upload  
✅ **Display order** for image sequencing  
✅ **File size limits** (10MB max)  
✅ **Storage optimization** through public disk  

---

## 🔒 Security Considerations

1. **Authorization**: Only Project Manager, Admin, and HR can upload/delete images
2. **File Validation**: Only image types allowed (jpeg, png, jpg, gif, webp)
3. **Size Limits**: Maximum 10MB per image
4. **Secure Storage**: Images stored in storage/app/public with proper permissions
5. **Filename Sanitization**: Special characters removed from filenames

---

## 🛠️ Troubleshooting

**Images Not Displaying:**
- Verify `php artisan storage:link` was run
- Check APP_URL in .env matches your domain
- Verify file permissions on storage directory

**Upload Fails:**
- Check file size (max 10MB)
- Verify image format is supported
- Check storage space on server

**Permission Denied:**
- Verify user has PM, Admin, or HR role
- Check project ownership

---

## 📋 Implementation Checklist

### Backend:
- [ ] Run migration to create `project_images` table
- [ ] Create `ProjectImage` model
- [ ] Add `images()` relationship to `Project` model
- [ ] Add methods to `ProjectController`
- [ ] Add routes to `api.php`
- [ ] Run `php artisan storage:link`
- [ ] Test endpoints with Postman/curl

### Frontend:
- [ ] Update `ProjectProvider` with image methods
- [ ] Update `ProjectService` with API calls
- [ ] Update `_uploadProjectImage()` in PM detail screen
- [ ] Update `_loadProjectData()` to fetch images
- [ ] Update `_deleteProjectImage()` with real API call
- [ ] Test upload functionality
- [ ] Test delete functionality
- [ ] Test full-screen viewer

---

## 🚀 Next Steps

1. **Backend Setup:**
   ```bash
   cd d:\laragon\www\leave_management_backend
   php artisan make:migration create_project_images_table
   # Edit migration file
   php artisan migrate
   php artisan storage:link
   ```

2. **Update Models and Controllers** as shown above

3. **Test Backend APIs** using Postman

4. **Update Flutter Code** in ProjectProvider and ProjectService

5. **Test Complete Flow** in the app

---

## 💡 Additional Features (Optional)

Consider adding:
- Image captions/descriptions
- Drag-and-drop reordering
- Bulk upload
- Image compression before upload
- Cover image selection
- Image gallery carousel view
- Share images functionality

---

## 📚 Related Documentation

- [Task Screenshot Upload Guide](SCREENSHOT_UPLOAD_IMPLEMENTATION.md)
- Laravel File Storage: https://laravel.com/docs/filesystem
- Flutter Image Picker: https://pub.dev/packages/image_picker
