# Office Leave Management System - Laravel API Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [Installation & Setup](#installation--setup)
3. [Authentication](#authentication)
4. [User Management](#user-management)
5. [Leave Management](#leave-management)
6. [Time Log Management](#time-log-management)
7. [Notifications](#notifications)
8. [Reports & Statistics](#reports--statistics)
9. [Database Schema](#database-schema)
10. [Error Handling](#error-handling)

---

## Introduction

This document provides comprehensive API documentation for the Office Leave Management System (OLMS) backend built with Laravel. The API follows RESTful principles and returns JSON responses.

**Base URL:** `http://localhost:8000/api`

**API Version:** v1

---

## Installation & Setup

### Prerequisites
- PHP >= 8.1
- Composer
- MySQL/PostgreSQL
- Laravel 10.x

### Installation Steps

```bash
# Clone the repository
git clone <repository-url>
cd leave-management-api

# Install dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure database in .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=leave_management
DB_USERNAME=root
DB_PASSWORD=

# Run migrations
php artisan migrate

# Seed the database (optional)
php artisan db:seed

# Start the server
php artisan serve
```

---

## Authentication

All API requests (except login and register) require authentication using Bearer tokens.

### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

### Login
**POST** `/auth/login`

Request:
```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Login successful",
  "token": "1|xxxxxxxxxxxxxxxxxxxxxx",
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@example.com",
    "role": "admin",
    "phone": "+1234567890",
    "department": "IT",
    "designation": "System Administrator",
    "profile_image": null,
    "joined_date": "2024-01-01",
    "casual_leave_balance": 12,
    "short_leave_balance": 10,
    "is_active": true,
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

### Register
**POST** `/auth/register`

Request:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "phone": "+1234567890",
  "department": "Sales"
}
```

Response (201):
```json
{
  "success": true,
  "message": "Registration successful",
  "token": "2|xxxxxxxxxxxxxxxxxxxxxx",
  "user": { ... }
}
```

### Logout
**POST** `/auth/logout`

Response (200):
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### Get Current User
**GET** `/auth/user`

Response (200):
```json
{
  "success": true,
  "user": { ... }
}
```

### Update Profile
**PUT** `/auth/profile/{userId}`

Request:
```json
{
  "name": "John Updated",
  "phone": "+9876543210",
  "department": "Marketing",
  "designation": "Manager"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": { ... }
}
```

### Change Password
**POST** `/auth/change-password`

Request:
```json
{
  "current_password": "oldpassword",
  "new_password": "newpassword123",
  "new_password_confirmation": "newpassword123"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## User Management

### Get All Users (Admin/HR)
**GET** `/users`

Query Parameters:
- `page` (int, optional): Page number
- `per_page` (int, optional): Items per page (default: 20)
- `role` (string, optional): Filter by role (admin, hr, staff)
- `search` (string, optional): Search by name or email

Response (200):
```json
{
  "success": true,
  "users": [
    { ... },
    { ... }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total": 50,
    "last_page": 3
  }
}
```

### Get User by ID
**GET** `/users/{userId}`

Response (200):
```json
{
  "success": true,
  "user": { ... }
}
```

### Create User (Admin Only)
**POST** `/users`

Request:
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "password123",
  "role": "staff",
  "phone": "+1234567890",
  "department": "HR",
  "designation": "HR Executive"
}
```

Response (201):
```json
{
  "success": true,
  "message": "User created successfully",
  "user": { ... }
}
```

### Update User (Admin Only)
**PUT** `/users/{userId}`

Request:
```json
{
  "name": "Jane Updated",
  "role": "hr",
  "casual_leave_balance": 15,
  "short_leave_balance": 12,
  "is_active": true
}
```

Response (200):
```json
{
  "success": true,
  "message": "User updated successfully",
  "user": { ... }
}
```

### Delete User (Admin Only)
**DELETE** `/users/{userId}`

Response (200):
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

### Update Leave Balance (Admin/HR)
**POST** `/users/{userId}/update-balance`

Request:
```json
{
  "casual_leave_balance": 12,
  "short_leave_balance": 10
}
```

Response (200):
```json
{
  "success": true,
  "message": "Leave balance updated successfully",
  "user": { ... }
}
```

### Get User Statistics (Admin)
**GET** `/users/statistics`

Response (200):
```json
{
  "success": true,
  "statistics": {
    "total_users": 100,
    "total_admins": 2,
    "total_hr": 5,
    "total_staff": 93,
    "active_users": 95,
    "inactive_users": 5
  }
}
```

---

## Leave Management

### Apply for Leave
**POST** `/leaves`

Request:
```json
{
  "leave_type": "casual",
  "start_date": "2024-02-10",
  "end_date": "2024-02-12",
  "reason": "Family vacation",
  "total_days": 3
}
```

Response (201):
```json
{
  "success": true,
  "message": "Leave application submitted successfully",
  "leave": {
    "id": 1,
    "user_id": 5,
    "user_name": "John Doe",
    "leave_type": "casual",
    "start_date": "2024-02-10",
    "end_date": "2024-02-12",
    "reason": "Family vacation",
    "status": "pending",
    "approved_by": null,
    "approved_by_name": null,
    "approved_at": null,
    "rejection_reason": null,
    "total_days": 3,
    "created_at": "2024-02-05T10:30:00.000000Z",
    "updated_at": "2024-02-05T10:30:00.000000Z"
  }
}
```

### Get My Leaves
**GET** `/leaves/my-leaves`

Query Parameters:
- `page` (int, optional)
- `per_page` (int, optional)
- `status` (string, optional): pending, approved, rejected

Response (200):
```json
{
  "success": true,
  "leaves": [
    { ... },
    { ... }
  ],
  "pagination": { ... }
}
```

### Get All Leaves (Admin/HR)
**GET** `/leaves`

Query Parameters:
- `page` (int, optional)
- `per_page` (int, optional)
- `status` (string, optional)
- `user_id` (int, optional): Filter by user

Response (200):
```json
{
  "success": true,
  "leaves": [
    { ... },
    { ... }
  ],
  "pagination": { ... }
}
```

### Get Leave by ID
**GET** `/leaves/{leaveId}`

Response (200):
```json
{
  "success": true,
  "leave": { ... }
}
```

### Approve Leave (Admin/HR)
**POST** `/leaves/{leaveId}/approve`

Response (200):
```json
{
  "success": true,
  "message": "Leave approved successfully",
  "leave": {
    "id": 1,
    "status": "approved",
    "approved_by": 1,
    "approved_by_name": "Admin User",
    "approved_at": "2024-02-05T11:00:00.000000Z",
    ...
  }
}
```

### Reject Leave (Admin/HR)
**POST** `/leaves/{leaveId}/reject`

Request:
```json
{
  "reason": "Insufficient leave balance"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Leave rejected successfully",
  "leave": {
    "id": 1,
    "status": "rejected",
    "approved_by": 1,
    "approved_by_name": "Admin User",
    "rejection_reason": "Insufficient leave balance",
    ...
  }
}
```

### Cancel Leave
**DELETE** `/leaves/{leaveId}`

Response (200):
```json
{
  "success": true,
  "message": "Leave cancelled successfully"
}
```

### Get Leave Balance
**GET** `/leaves/balance`

Response (200):
```json
{
  "success": true,
  "casual_leave": 12,
  "short_leave": 10
}
```

### Get Leave Policy
**GET** `/leave-policies`

Response (200):
```json
{
  "success": true,
  "policy": {
    "id": 1,
    "casual_leave_count": 12,
    "short_leave_count": 10,
    "reset_cycle": "yearly",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

### Update Leave Policy (Admin Only)
**PUT** `/leave-policies`

Request:
```json
{
  "casual_leave_count": 15,
  "short_leave_count": 12,
  "reset_cycle": "yearly"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Leave policy updated successfully",
  "policy": { ... }
}
```

### Get Leave Statistics (Admin/HR)
**GET** `/leaves/statistics`

Query Parameters:
- `start_date` (date, optional)
- `end_date` (date, optional)

Response (200):
```json
{
  "success": true,
  "statistics": {
    "total_leaves": 150,
    "pending_leaves": 10,
    "approved_leaves": 130,
    "rejected_leaves": 10,
    "casual_leaves": 80,
    "short_leaves": 50,
    "half_day_leaves": 20
  }
}
```

---

## Time Log Management

### Start Work Session
**POST** `/time-logs/start`

Response (201):
```json
{
  "success": true,
  "message": "Work session started successfully",
  "time_log": {
    "id": 1,
    "user_id": 5,
    "user_name": "John Doe",
    "date": "2024-02-05",
    "start_time": "2024-02-05T09:00:00.000000Z",
    "end_time": null,
    "end_reason": null,
    "custom_reason": null,
    "total_duration": null,
    "is_active": true,
    "created_at": "2024-02-05T09:00:00.000000Z",
    "updated_at": "2024-02-05T09:00:00.000000Z"
  }
}
```

### End Work Session
**POST** `/time-logs/{timeLogId}/end`

Request:
```json
{
  "end_reason": "lunch",
  "custom_reason": null
}
```

Response (200):
```json
{
  "success": true,
  "message": "Work session ended successfully",
  "time_log": {
    "id": 1,
    "end_time": "2024-02-05T13:00:00.000000Z",
    "end_reason": "lunch",
    "total_duration": 14400,
    "is_active": false,
    ...
  }
}
```

### Resume Session
**POST** `/time-logs/{timeLogId}/resume`

Response (200):
```json
{
  "success": true,
  "message": "Session resumed successfully",
  "time_log": { ... }
}
```

### Get Active Session
**GET** `/time-logs/active`

Response (200):
```json
{
  "success": true,
  "time_log": { ... }
}
```

Response (404) - No active session:
```json
{
  "success": false,
  "message": "No active session found",
  "time_log": null
}
```

### Get My Time Logs
**GET** `/time-logs/my-logs`

Query Parameters:
- `page` (int, optional)
- `per_page` (int, optional)
- `start_date` (date, optional)
- `end_date` (date, optional)

Response (200):
```json
{
  "success": true,
  "time_logs": [
    { ... },
    { ... }
  ],
  "pagination": { ... }
}
```

### Get All Time Logs (Admin/HR)
**GET** `/time-logs`

Query Parameters:
- `page` (int, optional)
- `per_page` (int, optional)
- `user_id` (int, optional)
- `start_date` (date, optional)
- `end_date` (date, optional)

Response (200):
```json
{
  "success": true,
  "time_logs": [
    { ... },
    { ... }
  ],
  "pagination": { ... }
}
```

### Get Time Log by ID
**GET** `/time-logs/{timeLogId}`

Response (200):
```json
{
  "success": true,
  "time_log": { ... }
}
```

### Get Today's Working Hours
**GET** `/time-logs/today-hours`

Response (200):
```json
{
  "success": true,
  "total_seconds": 28800,
  "formatted": "8h 0m"
}
```

### Get Monthly Working Hours
**GET** `/time-logs/monthly-hours`

Query Parameters:
- `month` (int, required): 1-12
- `year` (int, required): e.g., 2024

Response (200):
```json
{
  "success": true,
  "total_hours": 160,
  "total_days": 20,
  "average_hours": 8
}
```

### Get Working Hours Report (Admin/HR)
**GET** `/time-logs/report`

Query Parameters:
- `start_date` (date, required)
- `end_date` (date, required)
- `user_id` (int, optional)

Response (200):
```json
{
  "success": true,
  "report": [
    {
      "user_id": 5,
      "user_name": "John Doe",
      "total_hours": 40,
      "total_days": 5,
      "average_hours": 8
    },
    ...
  ]
}
```

### Get Attendance Summary
**GET** `/time-logs/attendance-summary`

Query Parameters:
- `month` (int, required)
- `year` (int, required)

Response (200):
```json
{
  "success": true,
  "summary": {
    "total_working_days": 22,
    "total_present_days": 20,
    "total_absent_days": 2,
    "attendance_percentage": 90.91
  }
}
```

---

## Notifications

### Get All Notifications
**GET** `/notifications`

Query Parameters:
- `page` (int, optional)
- `per_page` (int, optional)
- `is_read` (boolean, optional)

Response (200):
```json
{
  "success": true,
  "notifications": [
    {
      "id": 1,
      "user_id": 5,
      "title": "Leave Application",
      "message": "Your leave application has been approved",
      "type": "leave_approval",
      "related_id": 10,
      "is_read": false,
      "created_at": "2024-02-05T10:30:00.000000Z"
    },
    ...
  ],
  "pagination": { ... }
}
```

### Get Unread Count
**GET** `/notifications/unread-count`

Response (200):
```json
{
  "success": true,
  "count": 5
}
```

### Mark as Read
**POST** `/notifications/{notificationId}/read`

Response (200):
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

### Mark All as Read
**POST** `/notifications/read-all`

Response (200):
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

### Delete Notification
**DELETE** `/notifications/{notificationId}`

Response (200):
```json
{
  "success": true,
  "message": "Notification deleted successfully"
}
```

### Clear All Notifications
**DELETE** `/notifications/clear-all`

Response (200):
```json
{
  "success": true,
  "message": "All notifications cleared successfully"
}
```

---

## Reports & Statistics

### Dashboard Statistics (Admin/HR)
**GET** `/dashboard/statistics`

Response (200):
```json
{
  "success": true,
  "statistics": {
    "total_users": 100,
    "active_users": 95,
    "pending_leaves": 10,
    "approved_leaves_today": 5,
    "total_working_hours_today": 760,
    "average_attendance_rate": 92.5
  }
}
```

---

## Database Schema

### users table
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'hr', 'staff') NOT NULL DEFAULT 'staff',
    phone VARCHAR(20) NULL,
    department VARCHAR(100) NULL,
    designation VARCHAR(100) NULL,
    profile_image VARCHAR(255) NULL,
    joined_date DATE NULL,
    casual_leave_balance INT DEFAULT 0,
    short_leave_balance INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    remember_token VARCHAR(100) NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

### leaves table
```sql
CREATE TABLE leaves (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    leave_type ENUM('casual', 'short', 'half_day', 'other') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    reason TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    approved_by BIGINT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    rejection_reason TEXT NULL,
    total_days INT DEFAULT 1,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
);
```

### time_logs table
```sql
CREATE TABLE time_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    date DATE NOT NULL,
    start_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    end_reason ENUM('lunch', 'prayer', 'short_leave', 'half_day', 'other') NULL,
    custom_reason TEXT NULL,
    total_duration INT NULL, -- in seconds
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### leave_policies table
```sql
CREATE TABLE leave_policies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    casual_leave_count INT NOT NULL DEFAULT 12,
    short_leave_count INT NOT NULL DEFAULT 10,
    reset_cycle ENUM('monthly', 'yearly') DEFAULT 'yearly',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

### notifications table
```sql
CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('leave_application', 'leave_approval', 'leave_rejection', 'time_management') NOT NULL,
    related_id BIGINT UNSIGNED NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### personal_access_tokens table (Laravel Sanctum)
```sql
CREATE TABLE personal_access_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tokenable_type VARCHAR(255) NOT NULL,
    tokenable_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    token VARCHAR(64) UNIQUE NOT NULL,
    abilities TEXT NULL,
    last_used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    INDEX personal_access_tokens_tokenable (tokenable_type, tokenable_id)
);
```

---

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "message": "Error message here",
  "errors": {
    "field_name": [
      "Validation error message"
    ]
  }
}
```

### HTTP Status Codes
- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation errors
- `500 Internal Server Error`: Server error

### Common Error Examples

**Validation Error (422):**
```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "The email field is required."
    ],
    "password": [
      "The password must be at least 6 characters."
    ]
  }
}
```

**Unauthorized (401):**
```json
{
  "success": false,
  "message": "Unauthorized. Please login again."
}
```

**Forbidden (403):**
```json
{
  "success": false,
  "message": "You do not have permission to perform this action."
}
```

**Not Found (404):**
```json
{
  "success": false,
  "message": "Resource not found."
}
```

---

## Additional Notes

### Middleware & Permissions

1. **auth:sanctum**: Protects all routes except login/register
2. **role:admin**: Only admins can access
3. **role:admin,hr**: Admins and HR can access
4. **role:staff**: Only staff can access

### Rate Limiting

API requests are rate-limited to prevent abuse:
- Authenticated users: 60 requests per minute
- Unauthenticated users: 10 requests per minute

### Pagination

All list endpoints support pagination with default values:
- Default page: 1
- Default per_page: 20
- Maximum per_page: 100

### Date Formats

All dates should be in ISO 8601 format:
- Date: `YYYY-MM-DD` (e.g., 2024-02-05)
- DateTime: `YYYY-MM-DDTHH:mm:ss.sssZ` (e.g., 2024-02-05T10:30:00.000000Z)

---

## Contact & Support

For API support or questions, please contact:
- Email: support@olms.com
- Developer: dev@olms.com

**Version:** 1.0.0  
**Last Updated:** February 5, 2026
