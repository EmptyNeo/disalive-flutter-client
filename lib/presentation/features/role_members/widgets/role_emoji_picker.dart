import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/tabs/emojis_tab.dart';
import 'package:flutter/cupertino.dart';

class RoleEmojiPicker {
  static Future<String?> show(BuildContext context) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              height: MediaQuery.sizeOf(sheetContext).height * 0.55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.glassPanelTop, AppColors.glassPanelBottom],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.greyple,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: EmojisTab(
                      onTap: (emoji) {
                        final category = emoji.categoryName;
                        if (category != null) {
                          Navigator.of(
                            sheetContext,
                          ).pop('[$category:${emoji.id}]');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
