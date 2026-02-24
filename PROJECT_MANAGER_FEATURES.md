# Project Manager Features Documentation

## Overview
This document outlines the Project Manager (PM) specific features and screens in the Leave Management application.

## PM Role
- Role identifier: `project_manager`
- Access level: Can manage their own projects, assign team members, create tasks, and track project progress
- Distinct from: Staff (read-only on assigned tasks) and Admin/HR (full system access)

## Authentication Flow
When a user with `project_manager` role logs in, they are redirected to `/pm/dashboard`

## PM Screens

### 1. PM Dashboard (`/pm/dashboard`)
**File**: `lib/presentation/screens/pm/pm_dashboard.dart`

**Features**:
- Welcome section with gradient background
- Statistics cards showing:
  - Total Projects
  - In Progress Projects
  - Completed Projects
  - On Hold Projects
- Quick Actions grid:
  - My Projects
  - Create Project
  - My Tasks
  - Reports (coming soon)
- Recent projects list with navigation
- Floating Action Button for quick project creation
- Profile menu with logout

### 2. PM Projects List (`/pm/projects`)
**File**: `lib/presentation/screens/pm/pm_projects_screen.dart`

**Features**:
- Search bar for filtering projects
- Status filter chips: All, Planning, In Progress, On Hold, Completed
- Project cards showing:
  - Project name and description
  - Progress bar with percentage
  - Due date with overdue indicator
  - Task completion count
  - Team member count
  - Status badge
- Context menu on each card:
  - Edit Project
  - Delete Project
- Floating Action Button for creating new project
- Pull-to-refresh functionality

**Key Differences from Staff View**:
- Can edit and delete projects
- Can create new projects
- Sees all their managed projects (not just assigned ones)

### 3. PM Project Form (`/pm/projects/create`, `/pm/projects/:id/edit`)
**File**: `lib/presentation/screens/pm/pm_project_form_screen.dart`

**Features**:
- Form fields:
  - Project Name (required)
  - Description (required)
  - Status (dropdown: planning, in_progress, on_hold, completed, cancelled)
  - Priority (dropdown: urgent, high, medium, low)
  - Start Date (date picker, required)
  - End Date (date picker, required)
  - Budget (optional, numeric)
  - Progress (slider, 0-100%)
- Validation:
  - Required field checks
  - End date must be after start date
  - Budget must be positive number
- Dual purpose:
  - Create mode: projectId is null
  - Edit mode: loads existing project data

**API Integration**:
- Create: `POST /api/projects`
- Update: `PUT /api/projects/{id}`

### 4. PM Project Detail (`/pm/projects/:id`)
**File**: `lib/presentation/screens/pm/pm_project_detail_screen.dart`

**Features**:
- Tabbed interface with 3 tabs:
  1. **Overview Tab**:
     - Full project description
     - Progress indicator
     - Project details grid showing:
       - Start Date
       - End Date
       - Priority
       - Budget
       - Task count
       - Team size
  
  2. **Tasks Tab**:
     - List of all project tasks
     - Task cards with status badges and assigned users
     - Empty state with create task button
     - Tap to view task details
  
  3. **Team Tab**:
     - "Add Team Member" button
     - List of current members with:
       - Name avatar
       - Role designation
       - Remove button (except for manager)
     - Empty state message

- App Bar features:
  - Project name as title
  - Edit button (navigates to edit form)
  - Refresh button
  - Status badge in header
- Floating Action Button for creating new task

**Key Dialogs**:

1. **Add Member Dialog**:
   - Simple user ID input (can be enhanced with user selection)
   - Assigns member with 'member' role
   - Validates against existing members

2. **Create Task Dialog**:
   - Task name (required)
   - Description (required)
   - Priority dropdown (urgent/high/medium/low)
   - Status dropdown (todo/in_progress/in_review/completed/blocked)
   - Assign to (dropdown from project members)
   - Due date picker
   - Full validation

3. **Remove Member Confirmation**:
   - Confirms removal action
   - Cannot remove project manager

**Key Differences from Staff View**:
- Can add/remove team members
- Can create tasks and assign to team
- Can edit project details
- Sees all project tasks (not just own)
- Full management controls

## Navigation Routes

```dart
// PM Routes
'/pm/dashboard'                 -> PMDashboard
'/pm/projects'                  -> PMProjectsScreen
'/pm/projects/create'           -> PMProjectFormScreen (create mode)
'/pm/projects/:id'              -> PMProjectDetailScreen
'/pm/projects/:id/edit'         -> PMProjectFormScreen (edit mode)

// Staff routes accessible to PM
'/staff/tasks'                  -> MyTasksScreen (PM's assigned tasks)
'/staff/tasks/:id'              -> TaskDetailScreen
```

## State Management

### ProjectProvider Methods Used
- `fetchProjects()` - Get all PM's projects
- `fetchProjectById(id)` - Get project details
- `createProject(...)` - Create new project
- `updateProject(...)` - Update project
- `deleteProject(id)` - Delete project
- `assignMember(projectId, userId, role)` - Add team member
- `removeMember(projectId, userId)` - Remove team member
- `fetchTasks(projectId)` - Get project tasks
- `createTask(...)` - Create task in project
- `fetchProjectStatistics()` - Get stats for dashboard

## Color Coding

### Project Status Colors
- Planning: Warning (Yellow)
- In Progress: Info (Blue)
- On Hold: Orange
- Completed: Success (Green)
- Cancelled: Error (Red)

### Task Status Colors
- To Do: Grey
- In Progress: Info (Blue)
- In Review: Warning (Yellow)
- Completed: Success (Green)
- Blocked: Error (Red)

### Priority Colors
- Urgent: Red 🔴
- High: Orange 🟠
- Medium: Yellow 🟡
- Low: Green 🟢

## User Experience Features

### Empty States
- Projects list shows "Create Project" button when no projects exist
- Tasks tab shows "Create Task" button when project has no tasks
- Team tab shows encouraging message when no members added

### Loading States
- Full-screen loading on initial data fetch
- Inline loading during operations (create/update/delete)
- Refresh indicators on pull-to-refresh

### Error Handling
- Error messages from API displayed in SnackBars
- Retry buttons on failed data loads
- Validation errors highlighted in forms

### Success Feedback
- Green SnackBar confirmations on successful operations
- Automatic navigation after create/update
- Immediate UI updates after state changes

## API Endpoints Reference

All endpoints follow the specifications in `PROJECT_MANAGEMENT_API.md`:

### Projects
- `GET /api/projects` - List all projects
- `POST /api/projects` - Create project
- `GET /api/projects/{id}` - Get project details
- `PUT /api/projects/{id}` - Update project
- `DELETE /api/projects/{id}` - Delete project
- `GET /api/projects/statistics` - Get project statistics

### Members
- `POST /api/projects/{id}/members` - Assign member
- `DELETE /api/projects/{projectId}/members/{userId}` - Remove member

### Tasks
- `GET /api/tasks` - List tasks (filterable by projectId)
- `POST /api/tasks` - Create task
- `GET /api/tasks/{id}` - Get task details
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task

## Future Enhancements

### Potential PM Features
1. **Reports Tab**:
   - Project progress charts
   - Team performance metrics
   - Budget tracking
   - Time analytics

2. **Enhanced Member Management**:
   - Full user search/selection dialog
   - Role management (lead/contributor/member)
   - Member performance tracking
   - Workload distribution view

3. **Bulk Operations**:
   - Bulk task creation
   - Bulk assignment
   - Bulk status updates

4. **Notifications**:
   - Task deadline reminders
   - Project milestone alerts
   - Team member updates

5. **Templates**:
   - Project templates
   - Task templates
   - Recurring task creation

6. **Collaboration**:
   - Comments on tasks
   - File attachments
   - Activity timeline

## Testing Checklist

### PM Dashboard
- [ ] Statistics load correctly
- [ ] Quick actions navigate to correct screens
- [ ] Recent projects display and are clickable
- [ ] FAB creates new project
- [ ] Logout works

### Projects List
- [ ] All projects load and display
- [ ] Search filters projects correctly
- [ ] Status filters work
- [ ] Edit navigates to form with data
- [ ] Delete confirms and removes project
- [ ] Empty state shows when no projects
- [ ] Pull-to-refresh updates data

### Project Form
- [ ] Create mode shows empty form
- [ ] Edit mode loads existing data
- [ ] All validations work
- [ ] Date pickers function correctly
- [ ] Progress slider updates
- [ ] Save creates/updates successfully
- [ ] Navigation works after save

### Project Detail
- [ ] All tabs load correctly
- [ ] Overview shows all project info
- [ ] Tasks tab displays project tasks
- [ ] Team tab shows all members
- [ ] Add member dialog works
- [ ] Remove member confirms and removes
- [ ] Create task dialog creates task successfully
- [ ] Edit button navigates to form
- [ ] Task tap navigates to detail

## Permissions Matrix

| Action | Staff | PM | HR | Admin |
|--------|-------|----|----|-------|
| View assigned projects | ✅ | ✅ | ✅ | ✅ |
| View all projects | ❌ | ✅ (own) | ✅ | ✅ |
| Create project | ❌ | ✅ | ✅ | ✅ |
| Edit project | ❌ | ✅ (own) | ✅ | ✅ |
| Delete project | ❌ | ✅ (own) | ✅ | ✅ |
| Add team member | ❌ | ✅ (own) | ✅ | ✅ |
| Remove team member | ❌ | ✅ (own) | ✅ | ✅ |
| Create task | ❌ | ✅ (own) | ✅ | ✅ |
| Update task status | ✅ (assigned) | ✅ | ✅ | ✅ |
| Log hours | ✅ (assigned) | ✅ | ✅ | ✅ |

## Notes
- PM role is checked via `user.isProjectManager` getter in UserModel
- PMs can also access staff screens for their assigned tasks
- All PM operations require authentication with project_manager role
- Project statistics are calculated server-side
- Team member addition currently uses user ID input (can be enhanced with user picker)
