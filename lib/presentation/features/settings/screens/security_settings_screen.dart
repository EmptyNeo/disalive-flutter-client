import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/totp_status.dart';
import 'package:disalive/domain/repositories/totp_repository.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      SwipeToDismissRoute.push(context, (_) => const SecuritySettingsScreen());

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _repository = sl<TotpRepository>();
  final _codeController = TextEditingController();
  TotpStatus? _status;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _showSecret = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getStatus();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (status) => setState(() {
        _loading = false;
        _status = status;
      }),
    );
  }

  Future<void> _toggle() async {
    final status = _status;
    final code = _codeController.text.trim();
    if (status == null || _saving) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Введите 6 цифр из приложения-аутентификатора');
      return;
    }
    if (!status.enabled && (status.secret == null || status.secret!.isEmpty)) {
      setState(
        () => _error = 'Не удалось получить секретный ключ. Обновите экран.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.toggle(
      code: code,
      enable: !status.enabled,
      secret: status.enabled ? null : status.secret,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (success) {
        if (!success) {
          setState(() {
            _saving = false;
            _error = 'Не удалось изменить настройку 2FA';
          });
          return;
        }
        _codeController.clear();
        setState(() {
          _saving = false;
          _showSecret = false;
          _status = TotpStatus(enabled: !status.enabled);
        });
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.transparent,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.mainBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    GlassIconButton(
                      icon: CupertinoIcons.back,
                      onTap: () => Navigator.of(context).pop(),
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Безопасность', style: AppText.highTextStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Двухфакторная аутентификация',
                  style: AppText.highTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Код из приложения-аутентификатора защитит вход в аккаунт и подтверждение сброса пароля.',
                  style: AppText.lowTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading) const Center(child: CupertinoActivityIndicator()),
                if (!_loading && _status != null) ...[
                  Text(
                    _status!.enabled ? '2FA включена' : '2FA выключена',
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.blurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_status!.enabled) ...[
                    Text(
                      'Отсканируйте QR-код в приложении-аутентификаторе или введите ключ вручную.',
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_status!.qrUrl?.isNotEmpty == true)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(data: _status!.qrUrl!, size: 200),
                        ),
                      ),
                    if (_status!.secret?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: () =>
                            setState(() => _showSecret = !_showSecret),
                        child: Text(
                          _showSecret
                              ? 'Скрыть ключ'
                              : 'Показать ключ для ручного ввода',
                        ),
                      ),
                      if (_showSecret) ...[
                        SelectableText(
                          _status!.secret!,
                          style: AppText.mediumTextStyle,
                        ),
                        CupertinoButton(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: _status!.secret!),
                          ),
                          child: const Text('Скопировать ключ'),
                        ),
                      ],
                    ],
                  ] else
                    Text(
                      'Для отключения введите текущий код из приложения-аутентификатора.',
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Код подтверждения',
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _codeController,
                    placeholder: 'Код из 6 цифр',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(color: AppColors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.actionGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: _saving ? null : _toggle,
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : Text(
                            _status!.enabled ? 'Отключить 2FA' : 'Включить 2FA',
                          ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: AppColors.errorRed)),
                  if (_status == null)
                    CupertinoButton(
                      onPressed: _load,
                      child: const Text('Повторить'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
