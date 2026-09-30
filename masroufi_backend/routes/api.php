<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BankRuleController;
use App\Http\Controllers\Api\SyncController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\BudgetController;

/*
|--------------------------------------------------------------------------
| Public Routes
|--------------------------------------------------------------------------
*/
Route::prefix('v1')->group(function () {
    // Auth (Register, Login, Forgot & Reset Password)
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/auth/reset-password-biometric', [AuthController::class, 'resetPasswordBiometric']);

    // Dynamic Libyan Bank Rules (Can be fetched publicly or anonymously)
    Route::get('/bank-rules', [BankRuleController::class, 'index']);
    Route::post('/bank-rules/check-updates', [BankRuleController::class, 'checkUpdates']);

    // Categories (System defaults can be viewed publicly)
    Route::get('/categories', [CategoryController::class, 'index']);

    /*
    |--------------------------------------------------------------------------
    | Protected Routes (Sanctum)
    |--------------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {
        // User Profile, Change Password (via Biometrics/Unlock) & Logout
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/change-password', [AuthController::class, 'changePassword']);
        Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::delete('/auth/delete-account', [AuthController::class, 'deleteAccount']);

        // Offline-First Sync
        Route::post('/sync', [SyncController::class, 'sync']);

        // Categories Management
        Route::post('/categories', [CategoryController::class, 'store']);

        // Budgets
        Route::get('/budgets', [BudgetController::class, 'index']);
        Route::post('/budgets', [BudgetController::class, 'store']);
    });
});
