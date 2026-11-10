import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/utils/ui/birth_date_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optional date and calendar validation', () {
    expect(BirthDateInput.normalize(''), isNull);
    expect(BirthDateInput.normalize('29.02.2000'), '2000-02-29');
    expect(BirthDateInput.display('2000-02-29'), '29.02.2000');
    expect(() => BirthDateInput.normalize('29.02.2001'), throwsFormatException);
    expect(() => BirthDateInput.normalize('01.01.9999'), throwsFormatException);
    expect(() => BirthDateInput.normalize('12.03.20'), throwsFormatException);
  });

  test('formatter inserts separators and supports deleting them', () {
    const formatter = BirthDateInputFormatter();
    final typed = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '12032000',
        selection: TextSelection.collapsed(offset: 8),
      ),
    );
    expect(typed.text, '12.03.2000');
    final deletedSeparator = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '12.3',
        selection: TextSelection.collapsed(offset: 3),
      ),
      const TextEditingValue(
        text: '123',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(deletedSeparator.text, '13');
  });

  test('profile update includes date only when supplied or cleared', () {
    final user = UserModel.fromMap(const {
      'id': 7,
      'dateOfBirth': '2000-02-29',
    });
    expect(user.dateOfBirth, '2000-02-29');
    expect(user.toMap()['dateOfBirth'], '2000-02-29');
    expect(
      user
          .copyWith(clearDateOfBirth: true, changeDateOfBirth: true)
          .toMap()['dateOfBirth'],
      '',
    );
    expect(const UserModel().toMap().containsKey('dateOfBirth'), isFalse);
  });
}
