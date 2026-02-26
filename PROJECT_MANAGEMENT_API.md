# Project Management API Documentation

## Overview
This API provides complete project management functionality including project creation, member assignment, and task management. Project managers can create projects, assign staff members, and manage tasks.

## User Roles

### New Role: Project Manager
- Can create and manage their own projects
- Can assign/remove members from their projects
- Can create and assign tasks to project members
- Can update project progress and status

### Existing Roles
- **Admin/HR**: Full access to all projects and tasks
- **Staff**: Can view projects they're assigned to and their tasks

## Database Schema

### Projects Table
- `id`: Primary key
- `name`: Project name
- `description`: Project description
- `status`: Enum (planning, in_progress, on_hold, completed, cancelled)
- `start_date`: Project start date
- `end_date`: Project end date
- `project_manager_id`: Foreign key to users table
- `budget`: Project budget (decimal)
- `progress`: Progress percentage (0-100)
- `priority`: Enum (low, medium, high, urgent)
- `timestamps`, `soft_deletes`

### Project Members Table (Pivot)
- `id`: Primary key
- `project_id`: Foreign key to projects
- `user_id`: Foreign key to users
- `role`: Member role (member, lead, contributor)
- `joined_at`: When member joined the project
- Unique constraint on (project_id, user_id)

### Tasks Table
- `id`: Primary key
- `project_id`: Foreign key to projects
- `title`: Task title
- `description`: Task description
- `status`: Enum (todo, in_progress, in_review, completed, blocked)
- `priority`: Enum (low, medium, high, urgent)
- `assigned_to`: Foreign key to users (nullable)
- `created_by`: Foreign key to users
- `due_date`: Task due date
- `completed_at`: Task completion timestamp
- `estimated_hours`: Estimated hours to complete
- `actual_hours`: Actual hours spent
- `timestamps`, `soft_deletes`

## API Endpoints

### Project Endpoints

#### 1. Get All Projects
```
GET /api/projects
```
**Authorization**: All authenticated users
- Admin/HR: See all projects
- Project Manager: See only their projects
- Staff: See only projects they're assigned to

**Query Parameters**:
- `status`: Filter by status (planning, in_progress, on_hold, completed, cancelled)
- `priority`: Filter by priority (low, medium, high, urgent)
- `search`: Search by project name
- `per_page`: Items per page (default: 20)

**Response**:
```json
{
  "success": true,
  "projects": [
    {
      "id": 1,
      "name": "Leave Management System",
      "description": "Complete leave management system",
      "status": "in_progress",
      "priority": "high",
      "progress": 45,
      "budget": "50000.00",
      "start_date": "2026-01-25",
      "end_date": "2026-04-25",
      "project_manager_id": 3,
      "project_manager": {
        "id": 3,
        "name": "Project Manager",
        "email": "pm@example.com"
      },
      "members": [
        {
          "id": 4,
          "name": "John Doe",
          "role": "lead",
          "joined_at": "2026-02-24"
        }
      ]
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total": 2,
    "last_page": 1
  }
}
```

#### 2. Get Project by ID
```
GET /api/projects/{id}
```
**Authorization**: All authenticated users

**Response**: Single project with members and tasks

#### 3. Create Project
```
POST /api/projects
```
**Authorization**: Admin, HR, Project Manager

**Request Body**:
```json
{
  "name": "New Project",
  "description": "Project description",
  "status": "planning",
  "start_date": "2026-03-01",
  "end_date": "2026-06-01",
  "project_manager_id": 3,
  "budget": 50000,
  "progress": 0,
  "priority": "high",
  "member_ids": [4, 5]
}
```

#### 4. Update Project
```
PUT /api/projects/{id}
```
**Authorization**: Admin, HR, or Project Manager of the project

**Request Body**: Same fields as create (all optional)

#### 5. Delete Project
```
DELETE /api/projects/{id}
```
**Authorization**: Admin, HR only

#### 6. Assign Member to Project
```
POST /api/projects/{id}/assign-member
```
**Authorization**: Admin, HR, or Project Manager of the project

**Request Body**:
```json
{
  "user_id": 4,
  "role": "lead"
}
```
**Roles**: member, lead, contributor

#### 7. Remove Member from Project
```
POST /api/projects/{id}/remove-member
```
**Authorization**: Admin, HR, or Project Manager of the project

**Request Body**:
```json
{
  "user_id": 4
}
```

#### 8. Get Project Statistics
```
GET /api/projects/statistics
```
**Authorization**: All authenticated users

**Response**:
```json
{
  "success": true,
  "statistics": {
    "total_projects": 5,
    "in_progress": 3,
    "completed": 1,
    "on_hold": 1,
    "planning": 0
  }
}
```

### Task Endpoints

#### 1. Get All Tasks
```
GET /api/tasks
```
**Authorization**: All authenticated users
- Admin/HR: See all tasks
- Project Manager: See tasks in their projects
- Staff: See their assigned tasks and tasks in their projects

**Query Parameters**:
- `project_id`: Filter by project
- `status`: Filter by status (todo, in_progress, in_review, completed, blocked)
- `priority`: Filter by priority
- `assigned_to`: Filter by assigned user
- `per_page`: Items per page (default: 20)

**Response**:
```json
{
  "success": true,
  "tasks": [
    {
      "id": 1,
      "project_id": 1,
      "title": "Design database schema",
      "description": "Create complete database schema",
      "status": "completed",
      "priority": "high",
      "assigned_to": 4,
      "created_by": 3,
      "due_date": "2026-02-04",
      "completed_at": "2026-02-06",
      "estimated_hours": 8,
      "actual_hours": 10,
      "project": { },
      "assigned_user": { },
      "creator": { }
    }
  ],
  "pagination": { }
}
```

#### 2. Get Task by ID
```
GET /api/tasks/{id}
```
**Authorization**: All authenticated users

#### 3. Create Task
```
POST /api/tasks
```
**Authorization**: Admin, HR, or Project Manager of the project

**Request Body**:
```json
{
  "project_id": 1,
  "title": "Implement feature X",
  "description": "Detailed description",
  "status": "todo",
  "priority": "high",
  "assigned_to": 4,
  "due_date": "2026-03-15",
  "estimated_hours": 20
}
```

#### 4. Update Task
```
PUT /api/tasks/{id}
```
**Authorization**: 
- Admin, HR
- Project Manager of the project
- Assigned user can update their own tasks

**Request Body**: Same fields as create (all optional)

#### 5. Delete Task
```
DELETE /api/tasks/{id}
```
**Authorization**: Admin, HR, or Project Manager of the project

#### 6. Assign Task to User
```
POST /api/tasks/{id}/assign
```
**Authorization**: Admin, HR, or Project Manager of the project

**Request Body**:
```json
{
  "assigned_to": 4
}
```

#### 7. Get My Tasks
```
GET /api/tasks/my-tasks
```
**Authorization**: All authenticated users

Returns all tasks assigned to the authenticated user.

**Query Parameters**:
- `status`: Filter by status
- `priority`: Filter by priority
- `per_page`: Items per page

#### 8. Get Task Statistics
```
GET /api/tasks/statistics
```
**Authorization**: All authenticated users

**Query Parameters**:
- `project_id`: Get statistics for specific project

**Response**:
```json
{
  "success": true,
  "statistics": {
    "total_tasks": 10,
    "todo": 3,
    "in_progress": 4,
    "in_review": 1,
    "completed": 2,
    "blocked": 0
  }
}
```

## Sample Users (Seeded Data)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@example.com | password123 |
| HR | hr@example.com | password123 |
| Project Manager | pm@example.com | password123 |
| Staff | john@example.com | password123 |
| Staff | jane@example.com | password123 |

## Sample Data

The seeder creates:
- 2 sample projects (Leave Management System, Employee Portal)
- 4 sample tasks across both projects
- Project members assigned to projects
- Tasks with various statuses and priorities

## Status Flow

### Project Status
1. **planning** → Initial state
2. **in_progress** → Active development
3. **on_hold** → Temporarily paused
4. **completed** → Successfully finished
5. **cancelled** → Terminated

### Task Status
1. **todo** → Not started
2. **in_progress** → Currently being worked on
3. **in_review** → Awaiting review
4. **completed** → Finished
5. **blocked** → Cannot proceed

## Priority Levels
- **low**: Nice to have
- **medium**: Regular priority
- **high**: Important
- **urgent**: Critical, immediate attention needed

## Business Rules

1. **Project Manager Role**:
   - Can only manage their own projects
   - Can assign staff members to their projects
   - Can create and assign tasks within their projects

2. **Task Assignment**:
   - Users must be project members to be assigned tasks
   - Project manager can be assigned tasks without being a member

3. **Access Control**:
   - Staff can only see projects they're members of
   - Staff can only see and update their assigned tasks
   - Admin and HR have full visibility

4. **Task Completion**:
   - When task status changes to 'completed', `completed_at` is automatically set
   - Staff can update their assigned tasks' status and actual hours

## Integration with Leave Management

The project management system is fully integrated with the existing leave management system:
- All user roles (admin, hr, staff) work seamlessly
- Project managers can also apply for leaves
- Staff assigned to projects can manage both tasks and leaves
- Authentication uses the same Sanctum tokens

## Next Steps

To use this API in your Flutter app:
1. Add project manager role handling in your auth flow
2. Create UI for project listing and creation
3. Implement task assignment interface
4. Add project progress tracking dashboard
5. Create notifications for task assignments
