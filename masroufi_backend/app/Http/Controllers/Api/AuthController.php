<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class AuthController extends Controller
{
    /**
     * إنشاء حساب جديد
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'phone_number' => 'required|string|max:20|unique:users,phone_number',
            'email' => 'nullable|email|max:150|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
        ], [
            'name.required' => 'الاسم مطلوب',
            'phone_number.required' => 'رقم الهاتف مطلوب',
            'phone_number.unique' => 'رقم الهاتف مستخدم بالفعل',
            'email.email' => 'يرجى إدخال بريد إلكتروني صالح',
            'email.unique' => 'البريد الإلكتروني مستخدم بالفعل',
            'password.required' => 'كلمة المرور مطلوبة',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 خانات',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'phone_number' => $request->phone_number,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'is_active' => true,
        ]);

        $token = $user->createToken('masroufi_mobile_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء الحساب بنجاح',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone_number' => $user->phone_number,
                'email' => $user->email,
                'last_synced_at' => $user->last_synced_at,
            ],
        ], 201);
    }

    /**
     * تسجيل الدخول
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login' => 'required|string',
            'password' => 'required|string',
        ], [
            'login.required' => 'يرجى إدخال رقم الهاتف أو البريد الإلكتروني',
            'password.required' => 'كلمة المرور مطلوبة',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $login = $request->login;

        $user = User::where('phone_number', $login)
            ->orWhere('email', $login)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'بيانات الدخول غير صحيحة، يرجى التأكد من الرقم أو كلمة المرور',
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'تم تعطيل هذا الحساب، يرجى مراجعة الدعم الفني',
            ], 403);
        }

        $token = $user->createToken('masroufi_mobile_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'تم تسجيل الدخول بنجاح',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone_number' => $user->phone_number,
                'email' => $user->email,
                'last_synced_at' => $user->last_synced_at,
            ],
        ]);
    }

    /**
     * طلب استعادة كلمة المرور عبر الإيميل
     */
    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ], [
            'email.required' => 'يرجى إدخال البريد الإلكتروني',
            'email.email' => 'يرجى إدخال بريد إلكتروني صالح',
            'email.exists' => 'هذا البريد الإلكتروني غير مسجل لدينا',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // كود استعادة من 6 أرقام
        $resetCode = (string) random_int(100000, 999999);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => Hash::make($resetCode),
                'created_at' => Carbon::now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
            'dev_code' => config('app.debug') ? $resetCode : null,
        ]);
    }

    /**
     * تعيين كلمة مرور جديدة باستخدام كود الإيميل
     */
    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'code' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ], [
            'code.required' => 'رمز الاسترداد مطلوب',
            'password.required' => 'كلمة المرور الجديدة مطلوبة',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 خانات',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $record = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'لا يوجد طلب استعادة فعال لهذا البريد',
            ], 400);
        }

        // صلاحية الكود: 15 دقيقة
        if (Carbon::parse($record->created_at)->addMinutes(15)->isPast()) {
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();
            return response()->json([
                'success' => false,
                'message' => 'انتهت صلاحية رمز الاسترداد، يرجى طلب رمز جديد',
            ], 400);
        }

        if (!Hash::check($request->code, $record->token)) {
            return response()->json([
                'success' => false,
                'message' => 'رمز الاسترداد غير صحيح',
            ], 400);
        }

        // تحديث كلمة المرور
        $user = User::where('email', $request->email)->first();
        $user->password = Hash::make($request->password);
        $user->save();

        // حذف رمز الاسترداد المستخدم
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم تعيين كلمة المرور الجديدة بنجاح، يمكنك تسجيل الدخول الآن',
        ]);
    }

    /**
     * تغيير كلمة المرور من داخل التطبيق (للمستخدم الموثق / عبر البصمة)
     */
    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'password' => 'required|string|min:6|confirmed',
        ], [
            'password.required' => 'كلمة المرور الجديدة مطلوبة',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 خانات',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث كلمة المرور بنجاح',
        ]);
    }

    /**
     * بيانات المستخدم الحالي
     */
    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => [
                'id' => $request->user()->id,
                'name' => $request->user()->name,
                'phone_number' => $request->user()->phone_number,
                'email' => $request->user()->email,
                'last_synced_at' => $request->user()->last_synced_at,
            ],
        ]);
    }

    /**
     * تسجيل الخروج
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم تسجيل الخروج بنجاح',
        ]);
    }

    /**
     * تحديث بيانات الحساب (الاسم، رقم الهاتف، الإيميل، وكلمة المرور)
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone_number' => 'required|string|unique:users,phone_number,' . $user->id,
            'email' => 'nullable|email|unique:users,email,' . $user->id,
            'current_password' => 'nullable|string',
            'new_password' => 'nullable|string|min:6|confirmed',
        ], [
            'name.required' => 'يرجى إدخال الاسم الكامل',
            'phone_number.required' => 'رقم الهاتف مطلوب',
            'phone_number.unique' => 'رقم الهاتف مستخدم مسبقاً بحساب آخر',
            'email.email' => 'يرجى إدخال بريد إلكتروني صحيح',
            'email.unique' => 'البريد الإلكتروني مستخدم مسبقاً',
            'new_password.min' => 'كلمة المرور الجديدة يجب ألا تقل عن 6 خانات',
            'new_password.confirmed' => 'تأكيد كلمة المرور غير متطابق',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // إذا تم إدخال كلمة مرور جديدة، يتم التحقق من الحالية
        if ($request->filled('new_password')) {
            if (!$request->filled('current_password')) {
                return response()->json([
                    'success' => false,
                    'message' => 'يرجى إدخال كلمة المرور الحالية لتأكيد التغيير',
                ], 422);
            }

            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'كلمة المرور الحالية غير صحيحة',
                ], 422);
            }

            $user->password = Hash::make($request->new_password);
        }

        $user->name = $request->name;
        $user->phone_number = $request->phone_number;
        if ($request->has('email')) {
            $user->email = $request->email;
        }
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث بيانات الحساب بنجاح',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone_number' => $user->phone_number,
                'email' => $user->email,
                'last_synced_at' => $user->last_synced_at,
            ],
        ]);
    }


    /**
     * إعادة تعيين كلمة المرور فوراً عبر مصادقة بصمة الجهاز
     */
    public function resetPasswordBiometric(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ], [
            'login.required' => 'يرجى تحديد رقم الهاتف أو البريد الإلكتروني',
            'password.required' => 'كلمة المرور الجديدة مطلوبة',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 خانات',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $login = trim($request->login);

        // البحث برقم الهاتف أو البريد
        $user = User::where('phone_number', $login)
            ->orWhere('email', $login)
            ->first();

        if (!$user) {
            // تجربة إزالة كود الدولة +218 أو الصفر في البداية
            $stripped = preg_replace('/^(\+?218|0)/', '', $login);
            $user = User::where('phone_number', 'like', "%{$stripped}%")->first();
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'لم يتم العثور على حساب مسجل بهذا الرقم أو البريد الإلكتروني',
            ], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // إصدار توكن جديد لتسجيل الدخول المباشر
        $token = $user->createToken('masroufi_mobile_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'تم إعادة تعيين كلمة المرور بنجاح وتسجيل الدخول',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone_number' => $user->phone_number,
                'email' => $user->email,
                'last_synced_at' => $user->last_synced_at,
            ],
        ]);
    }


    /**
     * حذف الحساب وكافة البيانات التابعة له نهائياً (متطلب إلزامي لـ Google Play)
     */
    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'المستخدم غير موجود أو تم حذفه مسبقاً',
            ], 404);
        }

        // حذف كافة السجلات التابعة
        $user->transactions()->delete();
        $user->budgets()->delete();
        $user->recurringCashTransactions()->delete();
        $user->categories()->delete();

        // حذف كافة التوكنات
        $user->tokens()->delete();

        // حذف الحساب نفسه
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم حذف الحساب وجميع البيانات التابعة له نهائياً',
        ]);
    }

}
