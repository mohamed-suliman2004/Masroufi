<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BankParserRule extends Model
{
    protected $fillable = [
        'bank_code',
        'bank_name',
        'sender_patterns',
        'regex_rules',
        'version',
        'is_active',
    ];

    protected $casts = [
        'sender_patterns' => 'array',
        'regex_rules' => 'array',
        'is_active' => 'boolean',
        'version' => 'integer',
    ];
}
