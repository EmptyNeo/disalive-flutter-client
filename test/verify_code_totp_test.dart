import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/verify/bloc/verify_code_bloc.dart';
import 'package:disalive/presentation/features/verify/verify_code_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Users implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Email implements EmailRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TOTP reset hides email and resend controls', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    final bloc = VerifyCodeBloc(_Users(), _Email());
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await bloc.close();
    });

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: VerifyCodeScreen(
            email: 'user@example.com',
            emailType: EmailType.reset,
            newPassword: 'password1',
            verifyPassword: 'password1',
            useTotp: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Подтверждение 2FA'), findsOneWidget);
    expect(find.textContaining('Отправить код повторно'), findsNothing);
    expect(find.text('Не получили код?'), findsNothing);
    expect(find.text('user@example.com'), findsNothing);
  });
}
