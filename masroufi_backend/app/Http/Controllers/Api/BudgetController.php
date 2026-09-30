<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Budget;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    public function index(Request $request)
    {
        $month = $request->input('month', date('Y-m'));
        $budgets = Budget::where('user_id', $request->user()->id)
            ->where('month', $month)
            ->with('category')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $budgets,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'category_id' => 'nullable|exists:categories,id',
            'monthly_limit' => 'required|numeric|min:0',
            'month' => 'required|string|size:7', // 'YYYY-MM'
        ]);

        $budget = Budget::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'category_id' => $request->category_id,
                'month' => $request->month,
            ],
            [
                'monthly_limit' => $request->monthly_limit,
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $budget,
        ]);
    }
}
