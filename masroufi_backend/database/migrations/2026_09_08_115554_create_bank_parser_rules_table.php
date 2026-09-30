<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bank_parser_rules', function (Blueprint $table) {
            $table->id();
            $table->string('bank_code')->unique();
            $table->string('bank_name');
            $table->jsonb('sender_patterns');
            $table->jsonb('regex_rules');
            $table->integer('version')->default(1);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bank_parser_rules');
    }
};
