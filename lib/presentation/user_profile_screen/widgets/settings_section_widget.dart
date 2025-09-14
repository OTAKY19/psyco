import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
            child: Text(
              title,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              indent: 4.w,
              endIndent: 4.w,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSettingsItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(SettingsItem item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      leading: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: item.iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: item.iconName,
          color: item.iconColor,
          size: 20,
        ),
      ),
      title: Text(
        item.title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: item.isToggle
          ? Switch(
              value: item.toggleValue ?? false,
              onChanged: item.onToggleChanged,
              activeColor: AppTheme.lightTheme.colorScheme.primary,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.trailingText != null) ...[
                  Text(
                    item.trailingText!,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
      onTap: item.isToggle ? null : item.onTap,
    );
  }
}

class SettingsItem {
  final String title;
  final String? subtitle;
  final String iconName;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final String? trailingText;

  SettingsItem({
    required this.title,
    this.subtitle,
    required this.iconName,
    required this.iconColor,
    this.onTap,
    this.isToggle = false,
    this.toggleValue,
    this.onToggleChanged,
    this.trailingText,
  });
}
