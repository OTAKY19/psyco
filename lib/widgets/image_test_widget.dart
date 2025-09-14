import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';

/// Widget de test pour vérifier le chargement des images
class ImageTestWidget extends StatelessWidget {
  const ImageTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Images'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test du logo principal
            Text(
              'Logo Principal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo/psychotest_logo.svg',
                    width: 20.w,
                    height: 20.w,
                  ),
                  SizedBox(height: 2.h),
                  Text('Chemin: assets/images/logo/psychotest_logo.svg'),
                ],
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Test du logo alternatif
            Text(
              'Logo Alternatif',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/psychotest_logo.svg',
                    width: 20.w,
                    height: 20.w,
                  ),
                  SizedBox(height: 2.h),
                  Text('Chemin: assets/images/psychotest_logo.svg'),
                ],
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Test de l'image de l'app
            Text(
              'Image App',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/img_app_logo.svg',
                    width: 20.w,
                    height: 20.w,
                  ),
                  SizedBox(height: 2.h),
                  Text('Chemin: assets/images/img_app_logo.svg'),
                ],
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Test de l'image de tristesse
            Text(
              'Image Tristesse',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/sad_face.svg',
                    width: 20.w,
                    height: 20.w,
                  ),
                  SizedBox(height: 2.h),
                  Text('Chemin: assets/images/sad_face.svg'),
                ],
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Test de l'image de fallback
            Text(
              'Image de Fallback',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/no-image.jpg',
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 2.h),
                  Text('Chemin: assets/images/no-image.jpg'),
                ],
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Instructions
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text('• Si une image ne se charge pas, vérifiez le chemin'),
                  Text('• Les images SVG doivent utiliser SvgPicture.asset'),
                  Text('• Les images JPG/PNG doivent utiliser Image.asset'),
                  Text('• Vérifiez que les fichiers existent dans le dossier assets'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
