import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/utils/phone_number.dart';
import 'package:new_flutter_project/features/auth/application/providers/auth_provider.dart';
import 'package:new_flutter_project/features/auth/domain/entities/user.dart';
import 'package:new_flutter_project/features/auth/domain/repositories/auth_repository.dart';
import 'package:new_flutter_project/features/auth/presentation/screens/login_screen.dart';

/// Sign-in resolves the driver by an exact phone-string match, so the number
/// this screen sends must be the same shape the admin console registered them
/// with — `+91` and all. A bare ten-digit send would miss the record and the
/// server would auto-register a fresh customer account instead.
void main() {
  Future<_SpyAuthRepository> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1140, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _SpyAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => const MaterialApp(home: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Finder phoneField() => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '00000 00000',
      );

  Future<void> sendOtp(WidgetTester tester, String typed) async {
    await tester.enterText(phoneField(), typed);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
  }

  testWidgets('+91 is shown on the field, not typed', (tester) async {
    await pumpLogin(tester);
    expect(find.text('+91'), findsOneWidget);
  });

  testWidgets('sends the number in the same form the console registers',
      (tester) async {
    final repo = await pumpLogin(tester);
    await sendOtp(tester, '9746863592');

    expect(repo.sentPhones, ['+919746863592']);
  });

  testWidgets('a pasted country code is not doubled up', (tester) async {
    final repo = await pumpLogin(tester);
    await sendOtp(tester, '+91 97468 63592');

    expect(repo.sentPhones, ['+919746863592']);
  });

  testWidgets('an incomplete number never reaches the API', (tester) async {
    final repo = await pumpLogin(tester);
    await sendOtp(tester, '97468');

    expect(repo.sentPhones, isEmpty);
    expect(find.text('Enter all 10 digits.'), findsOneWidget);
  });

  test('the console and the login screen agree on the format', () {
    // Both sides go through the same helper — this is what keeps a driver
    // hired today able to sign in tomorrow.
    expect(PhoneNumber.e164('9746863592'), '+919746863592');
    expect(PhoneNumber.dialCode, '+91');
  });
}

class _SpyAuthRepository implements AuthRepository {
  final List<String> sentPhones = [];

  @override
  Future<void> sendOtp({required String phone, required String role}) async {
    sentPhones.add(phone);
  }

  @override
  Future<User> verifyOtp({
    required String phone,
    required String otpCode,
    required String role,
  }) async {
    sentPhones.add(phone);
    throw UnimplementedError('not exercised by these tests');
  }

  @override
  Future<User> login({required String username, required String password}) =>
      throw UnimplementedError();

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearLocalSession() async {}

  @override
  Future<bool> isSessionValid() async => false;
}
