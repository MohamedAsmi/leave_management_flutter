# Laravel Backend Setup Guide

This guide will help you set up the Laravel backend for the Office Leave Management System.

## Step 1: Install Laravel

```bash
# Navigate to your Laragon www directory
cd d:\laragon\www

# Create a new Laravel project
composer create-project laravel/laravel leave-management-api

# Navigate to the project
cd leave-management-api
```

## Step 2: Install Dependencies

```bash
# Install Laravel Sanctum for API authentication
composer require laravel/sanctum

# Publish Sanctum configuration
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

## Step 3: Configure Database

Edit `.env` file:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=leave_management
DB_USERNAME=root
DB_PASSWORD=
```

Create the database in MySQL:

```sql
CREATE DATABASE leave_management;
```

## Step 4: Create Migrations

```bash
# Create users table migration (modify default)
# Create leaves table migration
php artisan make:migration create_leaves_table

# Create time_logs table migration
php artisan make:migration create_time_logs_table

# Create leave_policies table migration
php artisan make:migration create_leave_policies_table

# Create notifications table migration
php artisan make:migration create_notifications_table
```

### Users Migration

Edit `database/migrations/*_create_users_table.php`:

```php
public function up()
{
    Schema::create('users', function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->string('email')->unique();
        $table->timestamp('email_verified_at')->nullable();
        $table->string('password');
        $table->enum('role', ['admin', 'hr', 'staff'])->default('staff');
        $table->string('phone', 20)->nullable();
        $table->string('department', 100)->nullable();
        $table->string('designation', 100)->nullable();
        $table->string('profile_image')->nullable();
        $table->date('joined_date')->nullable();
        $table->integer('casual_leave_balance')->default(0);
        $table->integer('short_leave_balance')->default(0);
        $table->boolean('is_active')->default(true);
        $table->rememberToken();
        $table->timestamps();
    });
}
```

### Leaves Migration

Edit `database/migrations/*_create_leaves_table.php`:

```php
public function up()
{
    Schema::create('leaves', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->enum('leave_type', ['casual', 'short', 'half_day', 'other']);
        $table->date('start_date');
        $table->date('end_date')->nullable();
        $table->text('reason');
        $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
        $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
        $table->timestamp('approved_at')->nullable();
        $table->text('rejection_reason')->nullable();
        $table->integer('total_days')->default(1);
        $table->timestamps();
    });
}
```

### Time Logs Migration

Edit `database/migrations/*_create_time_logs_table.php`:

```php
public function up()
{
    Schema::create('time_logs', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->date('date');
        $table->timestamp('start_time')->nullable();
        $table->timestamp('end_time')->nullable();
        $table->enum('end_reason', ['lunch', 'prayer', 'short_leave', 'half_day', 'other'])->nullable();
        $table->text('custom_reason')->nullable();
        $table->integer('total_duration')->nullable(); // in seconds
        $table->boolean('is_active')->default(true);
        $table->timestamps();
    });
}
```

### Leave Policies Migration

Edit `database/migrations/*_create_leave_policies_table.php`:

```php
public function up()
{
    Schema::create('leave_policies', function (Blueprint $table) {
        $table->id();
        $table->integer('casual_leave_count')->default(12);
        $table->integer('short_leave_count')->default(10);
        $table->enum('reset_cycle', ['monthly', 'yearly'])->default('yearly');
        $table->timestamps();
    });
}
```

### Notifications Migration

Edit `database/migrations/*_create_notifications_table.php`:

```php
public function up()
{
    Schema::create('notifications', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->string('title');
        $table->text('message');
        $table->enum('type', ['leave_application', 'leave_approval', 'leave_rejection', 'time_management']);
        $table->unsignedBigInteger('related_id')->nullable();
        $table->boolean('is_read')->default(false);
        $table->timestamps();
    });
}
```

## Step 5: Run Migrations

```bash
# Migrate Sanctum tables
php artisan migrate

# Run all migrations
php artisan migrate
```

## Step 6: Create Models

```bash
php artisan make:model Leave
php artisan make:model TimeLog
php artisan make:model LeavePolicy
php artisan make:model Notification
```

### User Model

Edit `app/Models/User.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
        'department',
        'designation',
        'profile_image',
        'joined_date',
        'casual_leave_balance',
        'short_leave_balance',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'joined_date' => 'date',
        'is_active' => 'boolean',
    ];

    public function leaves()
    {
        return $this->hasMany(Leave::class);
    }

    public function timeLogs()
    {
        return $this->hasMany(TimeLog::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function isAdmin()
    {
        return $this->role === 'admin';
    }

    public function isHR()
    {
        return $this->role === 'hr';
    }

    public function isStaff()
    {
        return $this->role === 'staff';
    }
}
```

### Leave Model

Edit `app/Models/Leave.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Leave extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'leave_type',
        'start_date',
        'end_date',
        'reason',
        'status',
        'approved_by',
        'approved_at',
        'rejection_reason',
        'total_days',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'approved_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }
}
```

### TimeLog Model

Edit `app/Models/TimeLog.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TimeLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'date',
        'start_time',
        'end_time',
        'end_reason',
        'custom_reason',
        'total_duration',
        'is_active',
    ];

    protected $casts = [
        'date' => 'date',
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
```

## Step 7: Create Controllers

```bash
# Create API controllers
php artisan make:controller Api/AuthController
php artisan make:controller Api/LeaveController
php artisan make:controller Api/TimeLogController
php artisan make:controller Api/NotificationController
php artisan make:controller Api/UserController
php artisan make:controller Api/LeavePolicyController
```

## Step 8: Set up Routes

Edit `routes/api.php`:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LeaveController;
use App\Http\Controllers\Api\TimeLogController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\LeavePolicyController;

// Public routes
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/user', [AuthController::class, 'user']);
    Route::put('/auth/profile/{id}', [AuthController::class, 'updateProfile']);
    Route::post('/auth/change-password', [AuthController::class, 'changePassword']);

    // Leave routes
    Route::apiResource('leaves', LeaveController::class);
    Route::get('/leaves/my-leaves', [LeaveController::class, 'myLeaves']);
    Route::post('/leaves/{id}/approve', [LeaveController::class, 'approve']);
    Route::post('/leaves/{id}/reject', [LeaveController::class, 'reject']);
    Route::get('/leaves/balance', [LeaveController::class, 'balance']);
    Route::get('/leaves/statistics', [LeaveController::class, 'statistics']);

    // Time log routes
    Route::apiResource('time-logs', TimeLogController::class);
    Route::post('/time-logs/start', [TimeLogController::class, 'start']);
    Route::post('/time-logs/{id}/end', [TimeLogController::class, 'end']);
    Route::post('/time-logs/{id}/resume', [TimeLogController::class, 'resume']);
    Route::get('/time-logs/active', [TimeLogController::class, 'active']);
    Route::get('/time-logs/my-logs', [TimeLogController::class, 'myLogs']);
    Route::get('/time-logs/today-hours', [TimeLogController::class, 'todayHours']);
    Route::get('/time-logs/monthly-hours', [TimeLogController::class, 'monthlyHours']);
    Route::get('/time-logs/report', [TimeLogController::class, 'report']);
    Route::get('/time-logs/attendance-summary', [TimeLogController::class, 'attendanceSummary']);

    // Notification routes
    Route::apiResource('notifications', NotificationController::class);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/clear-all', [NotificationController::class, 'clearAll']);

    // User routes (Admin/HR only)
    Route::apiResource('users', UserController::class);
    Route::post('/users/{id}/update-balance', [UserController::class, 'updateBalance']);
    Route::get('/users/statistics', [UserController::class, 'statistics']);

    // Leave policy routes
    Route::get('/leave-policies', [LeavePolicyController::class, 'index']);
    Route::put('/leave-policies', [LeavePolicyController::class, 'update']);
});
```

## Step 9: Configure CORS

Edit `config/cors.php`:

```php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
```

## Step 10: Create Seeders

```bash
# Create seeder for default admin user
php artisan make:seeder AdminUserSeeder

# Create seeder for leave policy
php artisan make:seeder LeavePolicySeeder
```

Edit `database/seeders/AdminUserSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run()
    {
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => Hash::make('password'),
            'role' => 'admin',
            'casual_leave_balance' => 12,
            'short_leave_balance' => 10,
            'is_active' => true,
        ]);
    }
}
```

Run seeders:

```bash
php artisan db:seed --class=AdminUserSeeder
php artisan db:seed --class=LeavePolicySeeder
```

## Step 11: Start the Server

```bash
php artisan serve
```

Your API will be available at: `http://localhost:8000`

## Testing the API

Use Postman or any API client to test:

1. **Login**
   - POST `http://localhost:8000/api/auth/login`
   - Body: `{"email": "admin@example.com", "password": "password"}`

2. **Get User**
   - GET `http://localhost:8000/api/auth/user`
   - Header: `Authorization: Bearer {token}`

## Next Steps

1. Implement controller logic for all endpoints
2. Add validation rules
3. Implement middleware for role-based access
4. Add proper error handling
5. Write tests
6. Deploy to production

Refer to [LARAVEL_API_DOCUMENTATION.md](../LARAVEL_API_DOCUMENTATION.md) for complete API reference.
