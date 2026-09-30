<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recurring_cash_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('client_uuid')->unique();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('category_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('title');
            $table->decimal('amount', 12, 3);
            $table->enum('frequency', ['monthly', 'weekly', 'yearly'])->default('monthly');
            $table->integer('day_of_month')->default(1);
            $table->boolean('is_active')->default(true);
            $table->date('last_generated_at')->nullable();
            $table->timestamp('client_updated_at')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recurring_cash_transactions');
    }
};
