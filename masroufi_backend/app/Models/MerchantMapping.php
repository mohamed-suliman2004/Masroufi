<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MerchantMapping extends Model
{
    protected $fillable = [
        'user_id',
        'keyword',
        'category_id',
        'is_system',
    ];

    protected $casts = [
        'is_system' => 'boolean',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
