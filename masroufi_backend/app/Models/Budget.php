<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Budget extends Model
{
    protected $fillable = [
        'user_id',
        'category_id',
        'monthly_limit',
        'month',
        'alert_80_sent',
        'alert_100_sent',
    ];

    protected $casts = [
        'monthly_limit' => 'decimal:3',
        'alert_80_sent' => 'boolean',
        'alert_100_sent' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
