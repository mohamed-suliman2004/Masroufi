<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Transaction extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'client_uuid',
        'user_id',
        'category_id',
        'amount',
        'type',
        'source',
        'bank_code',
        'sender',
        'merchant',
        'notes',
        'sms_hash',
        'transaction_date',
        'client_updated_at',
    ];

    protected $casts = [
        'amount' => 'decimal:3',
        'transaction_date' => 'datetime',
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
