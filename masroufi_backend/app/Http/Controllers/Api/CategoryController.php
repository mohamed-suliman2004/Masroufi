<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        // Return system categories + user created categories
        $categories = Category::where('is_system', true)
            ->orWhere('user_id', $user ? $user->id : null)
            ->orderBy('is_system', 'desc')
            ->orderBy('id', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'icon' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:20',
            'type' => 'required|in:expense,income,both',
        ]);

        $category = Category::create([
            'user_id' => $request->user()->id,
            'name' => $request->name,
            'icon' => $request->icon ?? 'category',
            'color' => $request->color ?? '#4A5568',
            'type' => $request->type,
            'is_system' => false,
        ]);

        return response()->json([
            'success' => true,
            'data' => $category,
        ], 201);
    }
}
