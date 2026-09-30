<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('client_uuid')->unique();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('category_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->decimal('amount', 12, 3);
            $table->enum('type', ['expense', 'income', 'transfer'])->default('expense');
            $table->enum('source', ['sms_auto', 'cash_manual', 'recurring_cash'])->default('sms_auto');
            $table->string('bank_code')->nullable();
            $table->string('sender')->nullable();
            $table->string('merchant')->nullable();
            $table->text('notes')->nullable();
            $table->string('sms_hash', 64)->nullable();
            $table->timestamp('transaction_date');
            $table->timestamp('client_updated_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['user_id', 'transaction_date']);
            $table->index(['user_id', 'client_uuid']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
