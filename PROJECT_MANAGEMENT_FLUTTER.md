# Project Management Feature - Staff User Documentation

## Overview
The Project Management feature has been successfully developed for the Flutter Leave Management application. This feature allows staff members to:
- View all projects they're assigned to
- View detailed project information including team members and tasks
- Manage their assigned tasks
- Update task status and track actual hours worked

## Components Developed

### 1. Data Models
Created in `lib/data/models/`:
- **project_model.dart** - Project data model with Hive annotations
  - Properties: id, name, description, status, priority, progress, budget, dates, manager info, members
  - Helper methods: statusLabel, priorityLabel, daysRemaining, isOverdue, isActive
  
- **task_model.dart** - Task data model with Hive annotations
  - Properties: id, projectId, title, description, status, priority, assignedTo, dueDate, hours
  - Helper methods: statusLabel, priorityLabel, isOverdue, isCompleted, daysUntilDue, hoursVariance

### 2. Services
Created in `lib/data/services/`:
- **project_service.dart** - API integration service
  - Project endpoints: getAllProjects, getProjectById, createProject, updateProject, deleteProject
  - Member management: assignMember, removeMember
  - Task endpoints: getAllTasks, getTaskById, createTask, updateTask, deleteTask, assignTask
  - Statistics: getProjectStatistics, getTaskStatistics
  - Special endpoint: getMyTasks (for staff to see their tasks)

### 3. State Management
Created in `lib/providers/`:
- **project_provider.dart** - State management for projects and tasks
  - Manages: projects list, tasks lists, selected project/task, statistics
  - Methods for CRUD operations on both projects and tasks
  - Handles loading states and error messages

### 4. User Interface Screens
Created in `lib/presentation/screens/staff/`:

#### a) StaffProjectsScreen (`staff_projects_screen.dart`)
- **Purpose**: Display all projects assigned to the staff member
- **Features**:
  - Search functionality
  - Filter by status (All, Planning, In Progress, On Hold, Completed)
  - Beautiful Material Design 3 cards showing:
    - Project name, manager, description
    - Progress bar with percentage
    - Priority badge
    - Status badge
    - Due date and task count
  - Pull-to-refresh
  - Navigation to project details

#### b) ProjectDetailScreen (`project_detail_screen.dart`)
- **Purpose**: Show complete project information
- **Features**:
  - Project header with status color coding
  - Overall progress visualization
  - Project info cards (start date, end date, budget)
  - Two tabs:
    - **Tasks Tab**: List of all project tasks
    - **Team Tab**: List of all team members with roles
  - Each task card shows status, priority, assignee, due date
  - Click on task to view details

#### c) MyTasksScreen (`my_tasks_screen.dart`)
- **Purpose**: View all tasks assigned to the logged-in staff member
- **Features**:
  - Summary cards showing task counts (To Do, In Progress, Completed, Overdue)
  - Filter by status (All, To Do, In Progress, In Review, Completed)
  - Filter by priority (All, Urgent, High, Medium, Low)
  - Task cards with:
    - Task title and project name
    - Status icon with color coding
    - Priority badge
    - Due date (highlighted if overdue)
    - Estimated hours
    - Overdue indicator (red border and badge)
  - Automatic sorting (overdue tasks first)
  - Pull-to-refresh

#### d) TaskDetailScreen (`task_detail_screen.dart`)
- **Purpose**: View and update task details
- **Features**:
  - Full task information display
  - Task status icon and badges
  - Detailed information section:
    - Assigned to
    - Created by
    - Due date (highlighted if overdue)
    - Completion date (if completed)
  - Time tracking section:
    - Estimated hours (read-only)
    - Actual hours (displayed if logged)
    - Hours variance indicator (over/under estimate)
  - **Two Action Buttons** (for assigned user only):
    - **Update Status Button** - Change task status quickly
    - **Log Hours Button** - Open dialog to log actual hours worked (optional)
  - Status update dialog with 5 options:
    - To Do, In Progress, In Review, Completed, Blocked
  - Hours logging dialog:
    - Simple input field for actual hours
    - Shows estimated hours for reference
    - Optional - not required to update status
  - Completed status indicator
  - Permission checks (only assigned user can update)

### 5. Navigation Updates
Updated in `lib/routes/app_router.dart`:
- `/staff/projects` - Projects list screen
- `/staff/projects/:id` - Project detail screen
- `/staff/tasks` - My tasks screen
- `/staff/tasks/:id` - Task detail screen

### 6. Dashboard Integration
Updated `lib/presentation/screens/staff/staff_dashboard.dart`:
- Added "My Projects" quick action button (purple, folder icon)
- Added "My Tasks" quick action button (orange, task icon)
- Updated grid to 3x2 layout (6 action buttons)

## API Integration

All screens follow the API documentation in `PROJECT_MANAGEMENT_API.md`:

### Authentication
- All requests use Sanctum authentication tokens
- Automatically handled by ApiClient service

### Access Control
- Staff can only view projects they're members of
- Staff can only view and update tasks assigned to them
- All API responses are role-filtered by the backend

## Status and Priority Values

### Project Status
- `planning` - Planning phase
- `in_progress` - Active development
- `on_hold` - Temporarily paused
- `completed` - Successfully finished
- `cancelled` - Terminated

### Task Status
- `todo` - Not started
- `in_progress` - Currently being worked on
- `in_review` - Awaiting review
- `completed` - Finished
- `blocked` - Cannot proceed

### Priority Levels
- `urgent` - Critical (red)
- `high` - Important (orange)
- `medium` - Regular (yellow)
- `low` - Nice to have (blue)

## Color Coding

### Status Colors
- Planning: Yellow/Warning
- In Progress: Blue/Info
- On Hold: Orange
- Completed: Green/Success
- Cancelled: Red/Error
- Blocked: Red/Error

### Priority Colors
- Urgent: Red
- High: Orange
- Medium: Yellow
- Low: Blue

## Usage Guide for Staff Users

### Viewing Projects
1. Open the app and go to Staff Dashboard
2. Tap "My Projects" in Quick Actions
3. Browse your assigned projects
4. Use search bar to find specific projects
5. Filter by status using chips at the top
6. Tap any project card to view details

### Viewing Project Details
1. From projects list, tap a project
2. View project information in the header
3. Switch between "Tasks" and "Team" tabs
4. Tap any task to view/update it

### Managing Your Tasks
1. From dashboard, tap "My Tasks"
2. View summary of your tasks at the top
3. Filter by status or priority
4. Tap any task to view details

### Updating Task Status
1. Open a task assigned to you
2. Review task information
3. Tap "Update Status" button
4. Select new status from dialog
5. Status updates immediately (no hours required)

### Logging Actual Hours (Optional)
1. Open a task assigned to you
2. Tap "Log Hours" button
3. Enter actual hours worked in the dialog
4. Tap "Save Hours"
5. View hours variance if estimated hours exist
6. Hours logging is completely optional

## Overdue Task Handling
- Overdue tasks are highlighted with red borders
- "OVERDUE" badge displayed prominently
- Overdue tasks appear first in task lists
- Due dates shown in red when overdue

## Error Handling
- Loading states shown with progress indicators
- Error messages displayed with retry buttons
- Network errors handled gracefully
- Success/error messages shown via SnackBar

## Technical Implementation

### State Management
- Uses Provider for reactive state updates
- Separate provider for project/task management
- Efficient rebuilds using Consumer widgets

### Navigation
- Uses GoRouter for declarative routing
- Path parameters for dynamic routes
- Type-safe navigation with context.push()

### UI Design
- Material Design 3 principles
- Consistent color scheme from AppColors
- Responsive layouts
- Smooth animations and transitions
- Pull-to-refresh support

### Performance
- Lazy loading with pagination support
- Efficient list rendering
- Image optimization (when applicable)
- Minimal rebuilds

## Files Modified/Created

### New Files (10)
1. `lib/data/models/project_model.dart`
2. `lib/data/models/task_model.dart`
3. `lib/data/services/project_service.dart`
4. `lib/providers/project_provider.dart`
5. `lib/presentation/screens/staff/staff_projects_screen.dart`
6. `lib/presentation/screens/staff/project_detail_screen.dart`
7. `lib/presentation/screens/staff/my_tasks_screen.dart`
8. `lib/presentation/screens/staff/task_detail_screen.dart`

### Modified Files (3)
1. `lib/main.dart` - Added ProjectService and ProjectProvider
2. `lib/routes/app_router.dart` - Added project/task routes
3. `lib/presentation/screens/staff/staff_dashboard.dart` - Added navigation buttons

### Generated Files (2)
1. `lib/data/models/project_model.g.dart` - Hive adapter
2. `lib/data/models/task_model.g.dart` - Hive adapter

## Testing the Feature

### Prerequisites
1. Ensure Laravel backend is running with project management API
2. Database seeded with sample projects and tasks
3. User should be assigned to at least one project

### Test Scenarios

#### 1. View Projects
- Login as staff user
- Navigate to "My Projects"
- Verify only assigned projects are visible
- Test search functionality
- Test status filters

#### 2. View Project Details
- Open a project
- Verify project information is correct
- Switch between Tasks and Team tabs
- Verify all data displays correctly

#### 3. View My Tasks
- Navigate to "My Tasks"
- Verify summary cards show correct counts
- Test status and priority filters
- Verify overdue tasks are highlighted

#### 4. Update Task Status
- Open a task assigned to you
- Tap "Update Status" button
- Change status (no hours required)
- Verify status updates in UI
- Verify backend is updated (check API response)

#### 5. Log Actual Hours (Optional)
- Open a task assigned to you
- Tap "Log Hours" button
- Enter hours in dialog
- Tap "Save Hours"
- Verify hours variance calculation
- Verify backend is updated
- Verify status can be changed without logging hours

#### 6. Permission Testing
- Try to update a task not assigned to you (button should not appear)
- Verify completed tasks cannot be edited
- Verify status options are appropriate

## Troubleshooting

### Projects Not Loading
- Check API base URL in ApiClient
- Verify authentication token is valid
- Check network connectivity
- Review API response in debug console

### Tasks Not Updating
- Verify user is assigned to the task
- Check API permissions
- Ensure backend validation passes
- Review error messages

### UI Not Responsive
- Pull to refresh
- Check loading indicators
- Verify provider is properly connected
- Review console for errors

## Future Enhancements

### Potential Improvements
1. Add offline support with Hive caching
2. Implement push notifications for task assignments
3. Add file attachments to tasks
4. Add task comments/discussions
5. Add Gantt chart view for projects
6. Add calendar view for task due dates
7. Add task time tracking with start/stop timer
8. Add project/task templates
9. Add task dependencies
10. Add sprint/milestone management

## Support and Documentation
For API reference, see: `PROJECT_MANAGEMENT_API.md`
For overall project documentation, see: `PROJECT_SUMMARY.md`

## Conclusion
The Project Management feature is now fully integrated into the Flutter application. Staff users can effectively view projects they're assigned to, manage their tasks, track time, and update task status - all following the API specifications in the PROJECT_MANAGEMENT_API.md document.
