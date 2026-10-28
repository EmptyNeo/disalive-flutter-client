import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/register/bloc/register_bloc.dart';
import 'package:disalive/presentation/features/register/register_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Users implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Email implements EmailRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RegisterBloc extends RegisterBloc {
  _RegisterBloc() : super(_Users(), _Email()) {
    emit(const RegisterState(currentStep: 3));
  }
}

void main() {
  testWidgets('both consents are required before sending a code', (
    tester,
  ) async {
    await sl.reset();
    final bloc = _RegisterBloc();
    sl.registerSingleton<RegisterBloc>(bloc);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await sl.reset();
    });

    await tester.pumpWidget(const CupertinoApp(home: RegisterScreen()));
    await tester.pump();

    final sendButton = find
        .ancestor(
          of: find.text('Отправить код'),
          matching: find.byType(CupertinoButton),
        )
        .first;
    expect(tester.widget<CupertinoButton>(sendButton).onPressed, isNull);

    final checkboxes = find.byType(CupertinoCheckbox);
    expect(checkboxes, findsNWidgets(2));
    expect(find.textContaining('пользовательским соглашением'), findsOneWidget);
    expect(
      find.textContaining('согласие на обработку персональных данных'),
      findsOneWidget,
    );
    expect(find.textContaining('политике конфиденциальности'), findsOneWidget);

    await tester.tap(checkboxes.at(0));
    await tester.pump();
    expect(tester.widget<CupertinoButton>(sendButton).onPressed, isNull);

    await tester.tap(checkboxes.at(1));
    await tester.pump();
    expect(tester.widget<CupertinoButton>(sendButton).onPressed, isNotNull);

    await tester.tap(checkboxes.at(0));
    await tester.pump();
    expect(tester.widget<CupertinoButton>(sendButton).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
