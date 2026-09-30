<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Category;
use Illuminate\Support\Facades\Hash;

class MasroufiApiTest extends TestCase
{
    public function test_can_fetch_bank_rules()
    {
        $response = $this->getJson('/api/v1/bank-rules');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         '*' => ['id', 'bank_code', 'bank_name', 'sender_patterns', 'regex_rules', 'version']
                     ]
                 ]);
    }

    public function test_can_fetch_categories()
    {
        $response = $this->getJson('/api/v1/categories');

        $response->assertStatus(200)
                 ->assertJson(['success' => true]);
    }

    public function test_register_and_login_flow()
    {
        $uniquePhone = '091' . rand(1000000, 9999999);
        $uniqueEmail = 'user_' . rand(1000, 9999) . '@test.com';

        // 1. Register
        $registerResponse = $this->postJson('/api/v1/auth/register', [
            'name' => 'سليمان الليبي',
            'phone_number' => $uniquePhone,
            'email' => $uniqueEmail,
            'password' => '123456',
            'password_confirmation' => '123456',
        ]);

        $registerResponse->assertStatus(201)
                         ->assertJsonStructure([
                             'success',
                             'token',
                             'user' => ['id', 'name', 'phone_number', 'email']
                         ]);

        // 2. Login using phone_number
        $loginPhoneResponse = $this->postJson('/api/v1/auth/login', [
            'login' => $uniquePhone,
            'password' => '123456',
        ]);

        $loginPhoneResponse->assertStatus(200)
                           ->assertJson(['success' => true]);

        // 3. Login using email
        $loginEmailResponse = $this->postJson('/api/v1/auth/login', [
            'login' => $uniqueEmail,
            'password' => '123456',
        ]);

        $loginEmailResponse->assertStatus(200)
                           ->assertJson(['success' => true]);

        $token = $loginEmailResponse->json('token');

        // 4. Authenticated Me endpoint
        $meResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
                           ->getJson('/api/v1/auth/me');

        $meResponse->assertStatus(200)
                   ->assertJson(['success' => true, 'user' => ['name' => 'سليمان الليبي']]);

        // 5. Change Password (via In-App / Biometrics)
        $changePassResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
                                   ->postJson('/api/v1/auth/change-password', [
                                       'password' => 'newpass654321',
                                       'password_confirmation' => 'newpass654321',
                                   ]);

        $changePassResponse->assertStatus(200)
                           ->assertJson(['success' => true]);
    }

    public function test_forgot_and_reset_password_flow()
    {
        $uniqueEmail = 'forgot_' . rand(1000, 9999) . '@test.com';
        $user = User::create([
            'name' => 'نسيان باسوورد',
            'phone_number' => '093' . rand(1000000, 9999999),
            'email' => $uniqueEmail,
            'password' => Hash::make('oldpassword'),
            'is_active' => true,
        ]);

        // 1. Request forgot password code
        $forgotResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => $uniqueEmail,
        ]);

        $forgotResponse->assertStatus(200)
                       ->assertJson(['success' => true]);

        $code = $forgotResponse->json('dev_code');

        // 2. Reset Password
        $resetResponse = $this->postJson('/api/v1/auth/reset-password', [
            'email' => $uniqueEmail,
            'code' => $code,
            'password' => 'newpass123',
            'password_confirmation' => 'newpass123',
        ]);

        $resetResponse->assertStatus(200)
                      ->assertJson(['success' => true]);

        // 3. Login with new password
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'login' => $uniqueEmail,
            'password' => 'newpass123',
        ]);

        $loginResponse->assertStatus(200)
                      ->assertJson(['success' => true]);
    }

    public function test_sync_transactions_offline_first()
    {
        $uniquePhone = '092' . rand(1000000, 9999999);
        $user = User::create([
            'name' => 'مستخدم المزامنة',
            'phone_number' => $uniquePhone,
            'password' => Hash::make('123456'),
            'is_active' => true,
        ]);
        $token = $user->createToken('test_token')->plainTextToken;

        $category = Category::first();
        $clientUuid = 'drift-uuid-' . rand(10000, 99999);

        $syncPayload = [
            'last_synced_at' => null,
            'transactions' => [
                [
                    'client_uuid' => $clientUuid,
                    'category_id' => $category ? $category->id : null,
                    'amount' => 120.750,
                    'type' => 'expense',
                    'source' => 'sms_auto',
                    'bank_code' => 'NCB',
                    'sender' => 'NCB',
                    'merchant' => 'Almadina Market',
                    'transaction_date' => now()->toIso8601String(),
                ]
            ],
            'recurring_cash' => []
        ];

        $syncResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
                             ->postJson('/api/v1/sync', $syncPayload);

        $syncResponse->assertStatus(200)
                     ->assertJson(['success' => true]);

        $this->assertDatabaseHas('transactions', [
            'client_uuid' => $clientUuid,
            'user_id' => $user->id,
            'bank_code' => 'NCB',
        ]);
    }
}
