// Path: lib/screens/update_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  // روابط التطبيق في المتاجر (قم بتغييرها بروابط تطبيقك الحقيقية)
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sideeg.markaz_al_furqan';
  static const String appStoreUrl = 'https://apps.apple.com/app/id1234567890';

  Future<void> _launchStore() async {
    final url = Platform.isIOS ? appStoreUrl : playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الألوان المستقاة من ثيم التطبيق
    const bgColor = Color(0xFF071A14); // Deep Forest
    const gold = Color(0xFFC4973A);
    const textLight = Color(0xFFF0E6C8); // Parchment

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgColor,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // أيقونة التحديث مع تأثير جميل
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withOpacity(0.1),
                    border: Border.all(color: gold.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 80,
                    color: gold,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'تحديث ضروري',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textLight,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'لقد قمنا بإصدار نسخة جديدة من التطبيق تحتوي على ميزات أحدث وإصلاحات هامة. لا يمكنك متابعة استخدام التطبيق إلا بعد التحديث.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    color: textLight.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),

                const Spacer(),

                // زر التحديث
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: gold.withOpacity(0.5),
                    ),
                    child: const Text(
                      'تحديث التطبيق الآن',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
