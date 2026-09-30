<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class RecurringCashTransaction extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'client_uuid',
        'user_id',
        'category_id',
        'title',
        'amount',
        'frequency',
        'day_of_month',
        'is_active',
        'last_generated_at',
        'client_updated_at',
    ];

    protected $casts = [
        'amount' => 'decimal:3',
        'day_of_month' => 'integer',
        'is_active' => 'boolean',
        'last_generated_at' => 'date',
        'client_updated_at' => 'datetime',
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
