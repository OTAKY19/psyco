import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final File? avatarImage;
  final Function(ImageSource) onPickImage;

  const ProfileAvatarWidget({
    super.key,
    required this.avatarImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Photo de profil (optionnel)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showImageSourceDialog(context),
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  image: avatarImage != null && !kIsWeb
                      ? DecorationImage(
                          image: FileImage(avatarImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarImage == null
                    ? Icon(
                        Icons.person_outline,
                        size: 15.w,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 4.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        TextButton.icon(
          onPressed: () => _showImageSourceDialog(context),
          icon: const CustomIconWidget(iconName: 'add_a_photo'),
          label: Text(
            avatarImage == null ? 'Ajouter une photo' : 'Changer la photo',
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const CustomIconWidget(iconName: 'photo_camera'),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CustomIconWidget(iconName: 'photo_library'),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.gallery);
              },
            ),
            if (avatarImage != null)
              ListTile(
                leading: const CustomIconWidget(
                  iconName: 'delete_outline',
                ),
                title: const Text('Supprimer'),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                  // Handle remove avatar
                },
              ),
          ],
        ),
      ),
    );
  }
}