<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\BankParserRule;

class BankParserRuleSeeder extends Seeder
{
    public function run(): void
    {
        $rules = [
            [
                'bank_code' => 'BCD',
                'bank_name' => 'مصرف التجارة والتنمية',
                'sender_patterns' => ['18787', 'BCD', 'BCD_BANK'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:خصم|سحب|شراء|قيد خصم)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار|LYD)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:إيداع|حوالة واردة|إيداع نقدي|تغذية)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار|LYD)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد المتاح|الرصيد|رصيد الحساب)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:لدى|في|التاجر)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => '/(?:بطاقة|حساب)[^\d]*(\d{4})/u',
                ],
            ],

            [
                'bank_code' => 'NCB',
                'bank_name' => 'المصرف التجاري الوطني',
                'sender_patterns' => ['NCB', 'ALTIJARI', '11100', 'Tijari'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:خصم|تم خصم|سحب|شراء)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار|LYD)/u',
                        '/مبلغ\s*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:إيداع|تم إيداع|تحويل إليك|استلام)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار|LYD)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد المتبقي|الرصيد|رصيدك)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:لدى|في|نقطة بيع)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => '/(?:بطاقة|بطاقتكم)[^\d]*(\d{4})/u',
                ],
            ],
            [
                'bank_code' => 'JUMHOURIA',
                'bank_name' => 'مصرف الجمهورية',
                'sender_patterns' => ['JUMHOURIA', 'JUMHORIA', '11200'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:خصم|شراء نقدي|خصم عملية)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار|LYD)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:إيداع نقدي|حوالة مصرفية|إضافة مبلغ)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار|LYD)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد الحالي|رصيد الحساب)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:لدى|متجر|بواسطة)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => '/(?:بطاقة|رقم)\s*[*xX]*(\d{4})/u',
                ],
            ],
            [
                'bank_code' => 'WAHDA',
                'bank_name' => 'مصرف الوحدة',
                'sender_patterns' => ['WAHDA', 'ALWAHDA', '11300', 'WahdaBank'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:خصم من حسابك|سحب نقدي|شراء)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:إيداع في حسابك|مرتب|تحويل وارد)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد|رصيدك الآن)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:نقطة بيع|التاجر)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => '/(?:المنتهية بـ|بطاقة)\s*(\d{4})/u',
                ],
            ],
            [
                'bank_code' => 'ONEPAY',
                'bank_name' => 'خدمة ون باي (OnePay)',
                'sender_patterns' => ['ONEPAY', 'ONE_PAY', 'OnePay'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:تم دفع|خصم|شراء بقيمة)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:استلمت|تم شحن|إيداع بقيمة)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'balance_pattern' => '/(?:رصيد محفظتك|الرصيد)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:إلى|لدى|لصالح)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => null,
                ],
            ],
            [
                'bank_code' => 'SADAD',
                'bank_name' => 'خدمة سداد (Sadad)',
                'sender_patterns' => ['SADAD', 'SADAD_LY', 'Sadad'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:سداد فاتورة|دفع تاجر|خصم)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:استلام دفعة|شحن حساب)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد المتبقي|رصيدك)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:للتاجر|لدى)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => null,
                ],
            ],
            [
                'bank_code' => 'YUSR',
                'bank_name' => 'مصرف شمال أفريقيا - بطاقة يسر',
                'sender_patterns' => ['YUSR', 'NANB', 'NorthAfrica'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:خصم|شراء عبر بطاقة يسر)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:إيداع|تغذية بطاقة)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:لدى|متجر)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => '/(?:يسر|بطاقة)\s*[*xX]*(\d{4})/u',
                ],
            ],
            [
                'bank_code' => 'TADAWUL',
                'bank_name' => 'شركة تداول للتقنية والمدفوعات',
                'sender_patterns' => ['TADAWUL', 'Tadawul'],
                'version' => 1,
                'is_active' => true,
                'regex_rules' => [
                    'debit_patterns' => [
                        '/(?:تمت عملية شراء|خصم بمبلغ)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'credit_patterns' => [
                        '/(?:إيداع|استرجاع مبلغ)[^\d]*([\d,]+(?:\.\d+)?)\s*(?:د\.ل|دينار)/u',
                    ],
                    'balance_pattern' => '/(?:الرصيد)[^\d]*([\d,]+(?:\.\d+)?)/u',
                    'merchant_pattern' => '/(?:نقطة بيع|التاجر)\s*([^\n\.,]+)/u',
                    'card_last4_pattern' => null,
                ],
            ],
        ];

        foreach ($rules as $rule) {
            BankParserRule::updateOrCreate(
                ['bank_code' => $rule['bank_code']],
                $rule
            );
        }
    }
}
