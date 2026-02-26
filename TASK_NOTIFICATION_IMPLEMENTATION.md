# Task Notification Implementation Guide

## Overview
This document outlines the implementation of automatic notifications for task creation and updates. When tasks are created or modified, notifications should be sent to relevant team members (staff and project managers).

## Backend Implementation (Laravel)

### 1. Notification Types

Create notification types for task-related events:

```php
// In TaskController or as Event Listeners

const NOTIFICATION_TYPES = [
    'task_created' => 'Task Created',
    'task_assigned' => 'Task Assigned',
    'task_updated' => 'Task Updated',
    'task_status_changed' => 'Task Status Changed',
    'task_completed' => 'Task Completed',
    'task_comment_added' => 'Task Comment Added',
];
```

### 2. TaskController - Create Task

Update the `store()` method in `TaskController.php`:

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'project_id' => 'required|exists:projects,id',
        'title' => 'required|string|max:255',
        'description' => 'required|string',
        'status' => 'in:todo,in_progress,in_review,completed,blocked',
        'priority' => 'in:urgent,high,medium,low',
        'assigned_to' => 'nullable|exists:users,id',
        'due_date' => 'nullable|date',
        'estimated_hours' => 'nullable|numeric',
    ]);

    $task = Task::create($validated);

    // Get the project to find project manager
    $project = Project::with('projectManager')->findOrFail($validated['project_id']);

    // Notify project manager
    if ($project->projectManager) {
        Notification::create([
            'user_id' => $project->projectManager->id,
            'title' => 'New Task Created',
            'message' => "A new task '{$task->title}' has been created in project '{$project->name}'",
            'type' => 'task_created',
            'related_id' => $task->id,
            'is_read' => false,
        ]);
    }

    // Notify assigned user if exists
    if ($validated['assigned_to'] && $validated['assigned_to'] != $project->project_manager_id) {
        $assignedUser = User::find($validated['assigned_to']);
        
        Notification::create([
            'user_id' => $validated['assigned_to'],
            'title' => 'Task Assigned to You',
            'message' => "You have been assigned to task '{$task->title}' in project '{$project->name}'",
            'type' => 'task_assigned',
            'related_id' => $task->id,
            'is_read' => false,
        ]);
    }

    // Optionally: Notify all project members
    foreach ($project->members as $member) {
        if ($member->id != auth()->id() && 
            $member->id != $validated['assigned_to'] &&
            $member->id != $project->project_manager_id) {
            
            Notification::create([
                'user_id' => $member->id,
                'title' => 'New Task in Project',
                'message' => "A new task '{$task->title}' has been added to project '{$project->name}'",
                'type' => 'task_created',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }
    }

    return response()->json([
        'success' => true,
        'message' => 'Task created successfully and notifications sent',
        'task' => $task->load(['assignedUser', 'project']),
    ], 201);
}
```

### 3. TaskController - Update Task

Update the `update()` method in `TaskController.php`:

```php
public function update(Request $request, $id)
{
    $task = Task::with('project.projectManager')->findOrFail($id);
    
    $validated = $request->validate([
        'title' => 'string|max:255',
        'description' => 'string',
        'status' => 'in:todo,in_progress,in_review,completed,blocked',
        'priority' => 'in:urgent,high,medium,low',
        'assigned_to' => 'nullable|exists:users,id',
        'due_date' => 'nullable|date',
        'estimated_hours' => 'nullable|numeric',
        'actual_hours' => 'nullable|numeric',
    ]);

    $oldStatus = $task->status;
    $oldAssignedTo = $task->assigned_to;
    
    $task->update($validated);

    $project = $task->project;
    $updatedBy = auth()->user();

    // Status changed notification
    if (isset($validated['status']) && $oldStatus != $validated['status']) {
        // Notify project manager
        if ($project->projectManager && $project->projectManager->id != $updatedBy->id) {
            Notification::create([
                'user_id' => $project->projectManager->id,
                'title' => 'Task Status Changed',
                'message' => "{$updatedBy->name} changed task '{$task->title}' status from '{$oldStatus}' to '{$validated['status']}'",
                'type' => 'task_status_changed',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }

        // Notify assigned user
        if ($task->assigned_to && $task->assigned_to != $updatedBy->id && $task->assigned_to != $project->project_manager_id) {
            Notification::create([
                'user_id' => $task->assigned_to,
                'title' => 'Task Status Updated',
                'message' => "Task '{$task->title}' status changed to '{$validated['status']}'",
                'type' => 'task_status_changed',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }

        // Special notification if completed
        if ($validated['status'] == 'completed') {
            Notification::create([
                'user_id' => $project->project_manager_id,
                'title' => 'Task Completed',
                'message' => "{$updatedBy->name} has completed task '{$task->title}'",
                'type' => 'task_completed',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }
    }

    // Assignment changed notification
    if (isset($validated['assigned_to']) && $oldAssignedTo != $validated['assigned_to']) {
        // Notify newly assigned user
        if ($validated['assigned_to']) {
            Notification::create([
                'user_id' => $validated['assigned_to'],
                'title' => 'Task Assigned to You',
                'message' => "You have been assigned to task '{$task->title}'",
                'type' => 'task_assigned',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }

        // Notify previously assigned user
        if ($oldAssignedTo && $oldAssignedTo != $updatedBy->id) {
            Notification::create([
                'user_id' => $oldAssignedTo,
                'title' => 'Task Reassigned',
                'message' => "Task '{$task->title}' has been reassigned",
                'type' => 'task_updated',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }

        // Notify project manager if not involved
        if ($project->project_manager_id != $updatedBy->id && 
            $project->project_manager_id != $validated['assigned_to'] && 
            $project->project_manager_id != $oldAssignedTo) {
            
            Notification::create([
                'user_id' => $project->project_manager_id,
                'title' => 'Task Reassigned',
                'message' => "Task '{$task->title}' has been reassigned",
                'type' => 'task_updated',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }
    }

    // General update notification (for other fields)
    if (!isset($validated['status']) && !isset($validated['assigned_to'])) {
        $recipients = [];
        
        // Add project manager
        if ($project->project_manager_id != $updatedBy->id) {
            $recipients[] = $project->project_manager_id;
        }
        
        // Add assigned user
        if ($task->assigned_to && $task->assigned_to != $updatedBy->id) {
            $recipients[] = $task->assigned_to;
        }

        foreach (array_unique($recipients) as $userId) {
            Notification::create([
                'user_id' => $userId,
                'title' => 'Task Updated',
                'message' => "{$updatedBy->name} updated task '{$task->title}'",
                'type' => 'task_updated',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }
    }

    return response()->json([
        'success' => true,
        'message' => 'Task updated successfully and notifications sent',
        'task' => $task->fresh()->load(['assignedUser', 'project']),
    ]);
}
```

### 4. Alternative: Using Laravel Events (Recommended)

For a cleaner approach, use Laravel Events and Listeners:

**Create Event:**
```bash
php artisan make:event TaskCreated
php artisan make:event TaskUpdated
```

**TaskCreated Event:**
```php
<?php

namespace App\Events;

use App\Models\Task;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TaskCreated
{
    use Dispatchable, SerializesModels;

    public $task;
    public $createdBy;

    public function __construct(Task $task, $createdBy)
    {
        $this->task = $task;
        $this->createdBy = $createdBy;
    }
}
```

**Create Listener:**
```bash
php artisan make:listener SendTaskCreatedNotifications --event=TaskCreated
```

**SendTaskCreatedNotifications Listener:**
```php
<?php

namespace App\Listeners;

use App\Events\TaskCreated;
use App\Models\Notification;

class SendTaskCreatedNotifications
{
    public function handle(TaskCreated $event)
    {
        $task = $event->task->load('project.projectManager', 'project.members');
        $project = $task->project;
        $createdBy = $event->createdBy;

        // Notify project manager
        if ($project->projectManager && $project->projectManager->id != $createdBy->id) {
            Notification::create([
                'user_id' => $project->projectManager->id,
                'title' => 'New Task Created',
                'message' => "{$createdBy->name} created task '{$task->title}' in project '{$project->name}'",
                'type' => 'task_created',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }

        // Notify assigned user
        if ($task->assigned_to && $task->assigned_to != $createdBy->id && $task->assigned_to != $project->project_manager_id) {
            Notification::create([
                'user_id' => $task->assigned_to,
                'title' => 'Task Assigned to You',
                'message' => "You have been assigned to task '{$task->title}' in project '{$project->name}'",
                'type' => 'task_assigned',
                'related_id' => $task->id,
                'is_read' => false,
            ]);
        }
    }
}
```

**Register in EventServiceProvider:**
```php
protected $listen = [
    TaskCreated::class => [
        SendTaskCreatedNotifications::class,
    ],
    TaskUpdated::class => [
        SendTaskUpdatedNotifications::class,
    ],
];
```

**In TaskController:**
```php
use App\Events\TaskCreated;

public function store(Request $request)
{
    // ... validation ...
    
    $task = Task::create($validated);
    
    event(new TaskCreated($task, auth()->user()));
    
    return response()->json([
        'success' => true,
        'message' => 'Task created successfully',
        'task' => $task->load(['assignedUser', 'project']),
    ], 201);
}
```

## Frontend Implementation (Flutter) - Already Completed ✅

The Flutter app has been updated to:

1. **Import NotificationProvider** in relevant screens
2. **Refresh notification count** after task creation/updates:
   ```dart
   context.read<NotificationProvider>().fetchUnreadCount();
   ```
3. **Update success messages** to indicate notifications were sent

### Files Modified:
- ✅ `lib/presentation/screens/pm/pm_project_detail_screen.dart`
- ✅ `lib/presentation/screens/staff/task_detail_screen.dart`

## Testing Checklist

### Backend Testing
- [ ] Create a task → PM and assigned user receive notifications
- [ ] Update task status → PM and assigned user receive notifications
- [ ] Update task assignment → Old user, new user, and PM receive notifications
- [ ] Complete a task → PM receives completion notification
- [ ] Update task details → Relevant users receive update notifications

### Frontend Testing
- [ ] Create task → Notification badge updates immediately
- [ ] Update task → Notification badge updates
- [ ] Pull notifications screen → New notifications appear
- [ ] Tap notification → Navigate to task detail

## Database Considerations

Ensure your `notifications` table has appropriate indexes:

```sql
ALTER TABLE notifications ADD INDEX idx_user_unread (user_id, is_read);
ALTER TABLE notifications ADD INDEX idx_related (type, related_id);
```

## Push Notifications (Optional Future Enhancement)

For real-time push notifications:
1. Use Laravel Broadcasting with Pusher/Socket.io
2. Integrate Firebase Cloud Messaging (FCM) in Flutter
3. Send push notifications along with database notifications

## Notes

- Notifications are sent synchronously. For better performance, consider queuing them using Laravel Queues
- Avoid notifying the user who performed the action (checked with `auth()->id()`)
- Duplicate notifications are prevented by checking recipient lists
- Notification messages are clear and actionable
