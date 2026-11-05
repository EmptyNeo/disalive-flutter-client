import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/server/bloc/server_deletion_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServerDeletionScreen extends StatefulWidget {
  const ServerDeletionScreen({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  final int serverId;
  final String serverName;

  static Future<bool> open(
    BuildContext context, {
    required int serverId,
    required String serverName,
  }) async {
    final deleted = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              ServerDeletionBloc(sl<ServerRepository>(), serverId)
                ..add(const RequestServerDeletionCode()),
          child: ServerDeletionScreen(
            serverId: serverId,
            serverName: serverName,
          ),
        ),
      ),
    );
    return deleted ?? false;
  }

  @override
  State<ServerDeletionScreen> createState() => _ServerDeletionScreenState();
}

class _ServerDeletionScreenState extends State<ServerDeletionScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ServerDeletionBloc, ServerDeletionState>(
    listener: (context, state) {
      if (state.completed) Navigator.of(context).pop(true);
    },
    builder: (context, state) => CupertinoPageScaffold(
      backgroundColor: AppColors.mainBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Удалить сервер'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  Icon(
                    CupertinoIcons.delete_solid,
                    color: AppColors.errorRed,
                    size: 54,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Удалить «${widget.serverName}»?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Сервер и его каналы будут удалены без возможности восстановления.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.greyple, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  if (state.loading && state.method == null)
                    const Center(child: CupertinoActivityIndicator())
                  else if (state.method == null)
                    CupertinoButton.filled(
                      onPressed: () => context.read<ServerDeletionBloc>().add(
                        const RequestServerDeletionCode(),
                      ),
                      child: const Text('Запросить код повторно'),
                    )
                  else ...[
                    Text(
                      state.method == 'totp'
                          ? 'Введите код из приложения аутентификации'
                          : 'Введите код, отправленный на вашу почту',
                      style: TextStyle(color: AppColors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    CupertinoTextField(
                      key: const ValueKey('server_deletion_code'),
                      controller: _codeController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      placeholder: '000000',
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        letterSpacing: 6,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.actionGrey,
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    CupertinoButton(
                      key: const ValueKey('server_deletion_confirm'),
                      color: AppColors.errorRed,
                      onPressed:
                          state.submitting || _codeController.text.length != 6
                          ? null
                          : () => context.read<ServerDeletionBloc>().add(
                              ConfirmServerDeletion(_codeController.text),
                            ),
                      child: state.submitting
                          ? const CupertinoActivityIndicator()
                          : const Text('Удалить сервер'),
                    ),
                    if (state.method == 'email') ...[
                      const SizedBox(height: 8),
                      CupertinoButton(
                        key: const ValueKey('server_deletion_resend'),
                        onPressed: state.loading
                            ? null
                            : () => context.read<ServerDeletionBloc>().add(
                                const RequestServerDeletionCode(),
                              ),
                        child: state.loading
                            ? const CupertinoActivityIndicator()
                            : const Text('Отправить код повторно'),
                      ),
                    ],
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.errorRed),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
