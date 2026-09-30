<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\RecurringCashTransaction;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class SyncController extends Controller
{
    /**
     * Two-Way Offline-First Sync for Transactions
     */
    public function sync(Request $request)
    {
        $user = $request->user();
        $lastSyncedAt = $request->input('last_synced_at');
        $incomingTransactions = $request->input('transactions', []);
        $incomingRecurring = $request->input('recurring_cash', []);

        $serverNow = Carbon::now();

        DB::beginTransaction();
        try {
            // 1. Process incoming transactions (Push from mobile client)
            foreach ($incomingTransactions as $txData) {
                if (empty($txData['client_uuid'])) {
                    continue;
                }

                $existing = Transaction::withTrashed()
                    ->where('user_id', $user->id)
                    ->where('client_uuid', $txData['client_uuid'])
                    ->first();

                // If deleted on mobile
                if (!empty($txData['is_deleted'])) {
                    if ($existing) {
                        $existing->delete();
                    }
                    continue;
                }

                $fields = [
                    'category_id' => $txData['category_id'] ?? null,
                    'amount' => $txData['amount'],
                    'type' => $txData['type'] ?? 'expense',
                    'source' => $txData['source'] ?? 'sms_auto',
                    'bank_code' => $txData['bank_code'] ?? null,
                    'sender' => $txData['sender'] ?? null,
                    'merchant' => $txData['merchant'] ?? null,
                    'notes' => $txData['notes'] ?? null,
                    'sms_hash' => $txData['sms_hash'] ?? null,
                    'transaction_date' => $txData['transaction_date'],
                    'client_updated_at' => $txData['client_updated_at'] ?? $serverNow,
                ];

                if ($existing) {
                    // Update only if client is newer
                    $existing->update($fields);
                    if ($existing->trashed()) {
                        $existing->restore();
                    }
                } else {
                    Transaction::create(array_merge($fields, [
                        'user_id' => $user->id,
                        'client_uuid' => $txData['client_uuid'],
                    ]));
                }
            }

            // 2. Process incoming recurring cash transactions
            foreach ($incomingRecurring as $recData) {
                if (empty($recData['client_uuid'])) {
                    continue;
                }

                $existing = RecurringCashTransaction::withTrashed()
                    ->where('user_id', $user->id)
                    ->where('client_uuid', $recData['client_uuid'])
                    ->first();

                if (!empty($recData['is_deleted'])) {
                    if ($existing) {
                        $existing->delete();
                    }
                    continue;
                }

                $fields = [
                    'category_id' => $recData['category_id'] ?? null,
                    'title' => $recData['title'],
                    'amount' => $recData['amount'],
                    'frequency' => $recData['frequency'] ?? 'monthly',
                    'day_of_month' => $recData['day_of_month'] ?? 1,
                    'is_active' => $recData['is_active'] ?? true,
                    'last_generated_at' => $recData['last_generated_at'] ?? null,
                    'client_updated_at' => $recData['client_updated_at'] ?? $serverNow,
                ];

                if ($existing) {
                    $existing->update($fields);
                    if ($existing->trashed()) {
                        $existing->restore();
                    }
                } else {
                    RecurringCashTransaction::create(array_merge($fields, [
                        'user_id' => $user->id,
                        'client_uuid' => $recData['client_uuid'],
                    ]));
                }
            }

            // 3. Pull records updated on server since last_synced_at
            $pulledTransactionsQuery = Transaction::withTrashed()
                ->where('user_id', $user->id);

            $pulledRecurringQuery = RecurringCashTransaction::withTrashed()
                ->where('user_id', $user->id);

            if ($lastSyncedAt) {
                $pulledTransactionsQuery->where('updated_at', '>', $lastSyncedAt);
                $pulledRecurringQuery->where('updated_at', '>', $lastSyncedAt);
            }

            $pulledTransactions = $pulledTransactionsQuery->get();
            $pulledRecurring = $pulledRecurringQuery->get();

            // 4. Update user's last_synced_at
            $user->last_synced_at = $serverNow;
            $user->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'server_time' => $serverNow->toIso8601String(),
                'pulled' => [
                    'transactions' => $pulledTransactions,
                    'recurring_cash' => $pulledRecurring,
                ],
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'فشلت المزامنة: ' . $e->getMessage(),
            ], 500);
        }
    }
}
