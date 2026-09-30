import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masroufi_mobile/core/state/app_state.dart';
import 'package:masroufi_mobile/core/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('User state, zero initial demo transactions for new accounts, and user binding', () async {
    final state = AppState.instance;
    await state.init();

    // 1. Initial user - new account starts with zero transactions!
    const testUser = UserModel(
      id: 1,
      name: 'سليمان علي',
      phoneNumber: '0912345678',
      email: 'suliman@masroufi.ly',
    );
    state.setUser(testUser);
    expect(state.currentUser.name, 'سليمان علي');
    expect(state.currentUser.displayName, 'سليمان علي');
    expect(state.currentUser.phoneNumber, '0912345678');
    
    // VERIFY: Demo transactions are completely canceled for new accounts
    expect(state.transactions.isEmpty, true);

    // 2. Update Profile details
    state.updateCurrentUser(
      name: 'سليمان محمد علي',
      phoneNumber: '0919998877',
      email: 'suliman.new@masroufi.ly',
    );
    expect(state.currentUser.name, 'سليمان محمد علي');
    expect(state.currentUser.displayName, 'سليمان محمد علي');
    expect(state.currentUser.phoneNumber, '0919998877');
    expect(state.transactions.isEmpty, true);

    // 3. Add a real transaction
    state.addTransaction(
      title: 'راتب شهري',
      amount: 500.0,
      category: 'دخل وراتب',
      isExpense: false,
    );
    expect(state.transactions.length, 1);
    expect(state.transactions.first.title, 'راتب شهري');

    // 4. Test Custom Bank Addition & Removal
    final initialBanksCount = state.allBankSenders.length;
    expect(state.allBankSenders.any((b) => b.senderId == 'NCB'), true);
    expect(state.allBankSenders.any((b) => b.senderId == '18787'), true);

    await state.addCustomBank(name: 'مصرف الواحة', senderId: '15050');
    expect(state.allBankSenders.length, initialBanksCount + 1);
    expect(state.allBankSenders.any((b) => b.senderId == '15050'), true);

    await state.removeCustomBank('15050');
    expect(state.allBankSenders.length, initialBanksCount);
  });
}
