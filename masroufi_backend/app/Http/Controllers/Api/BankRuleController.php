<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankParserRule;
use Illuminate\Http\Request;

class BankRuleController extends Controller
{
    /**
     * Get all active bank parsing rules (Dynamic Regex for Libyan Banks)
     */
    public function index()
    {
        $rules = BankParserRule::where('is_active', true)->get();

        return response()->json([
            'success' => true,
            'data' => $rules,
        ]);
    }

    /**
     * Check for rule updates based on local client versions
     * Input: { "versions": { "NCB": 1, "JUMHOURIA": 1 } }
     */
    public function checkUpdates(Request $request)
    {
        $clientVersions = $request->input('versions', []);
        $allRules = BankParserRule::where('is_active', true)->get();
        $updatedRules = [];

        foreach ($allRules as $rule) {
            $clientVer = $clientVersions[$rule->bank_code] ?? 0;
            if ($rule->version > $clientVer) {
                $updatedRules[] = $rule;
            }
        }

        return response()->json([
            'success' => true,
            'has_updates' => count($updatedRules) > 0,
            'updated_rules' => $updatedRules,
        ]);
    }
}
