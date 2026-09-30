<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            // Expenses
            ['name' => 'مطاعم وكافيهات', 'icon' => 'restaurant', 'color' => '#E53E3E', 'type' => 'expense', 'is_system' => true],
            ['name' => 'بقالة ومواد غذائية', 'icon' => 'shopping_cart', 'color' => '#3182CE', 'type' => 'expense', 'is_system' => true],
            ['name' => 'مواصلات ووقود', 'icon' => 'local_gas_station', 'color' => '#DD6B20', 'type' => 'expense', 'is_system' => true],
            ['name' => 'فواتير واشتراكات', 'icon' => 'receipt_long', 'color' => '#805AD5', 'type' => 'expense', 'is_system' => true],
            ['name' => 'تسوق وملابس', 'icon' => 'checkroom', 'color' => '#D53F8C', 'type' => 'expense', 'is_system' => true],
            ['name' => 'صحة وعلاج', 'icon' => 'medical_services', 'color' => '#38A169', 'type' => 'expense', 'is_system' => true],
            ['name' => 'إيجار وسكن', 'icon' => 'home', 'color' => '#4A5568', 'type' => 'expense', 'is_system' => true],
            ['name' => 'صيانة وسيارات', 'icon' => 'build', 'color' => '#718096', 'type' => 'expense', 'is_system' => true],
            ['name' => 'تعليم ودورات', 'icon' => 'school', 'color' => '#319795', 'type' => 'expense', 'is_system' => true],
            ['name' => 'مصاريف أخرى', 'icon' => 'more_horiz', 'color' => '#A0AEC0', 'type' => 'expense', 'is_system' => true],

            // Income
            ['name' => 'المرتب الشهري', 'icon' => 'payments', 'color' => '#2B6CB0', 'type' => 'income', 'is_system' => true],
            ['name' => 'عمل حر وتجارة', 'icon' => 'storefront', 'color' => '#2C7A7B', 'type' => 'income', 'is_system' => true],
            ['name' => 'حوالة واردة', 'icon' => 'call_received', 'color' => '#2F855A', 'type' => 'income', 'is_system' => true],
            ['name' => 'أرباح واستثمارات', 'icon' => 'trending_up', 'color' => '#D69E2E', 'type' => 'income', 'is_system' => true],
            ['name' => 'دخل آخر', 'icon' => 'savings', 'color' => '#4FD1C5', 'type' => 'income', 'is_system' => true],
        ];

        foreach ($categories as $cat) {
            Category::firstOrCreate(
                ['name' => $cat['name'], 'is_system' => true],
                $cat
            );
        }
    }
}
