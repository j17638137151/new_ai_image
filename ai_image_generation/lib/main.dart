import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'pages/main_page.dart';

void main() {
  // 使用Zone来拦截所有print输出
  runZoned(
    () {
      runApp(Phoenix(child: const ReminiApp()));
    },
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        // 过滤flutter_sound的所有日志输出
        if (line.contains('🐛') ||
            line.contains('FS:') ||
            line.contains('iOS:') ||
            line.contains('IOS:') ||
            line.contains('flutter_sound') ||
            line.contains('channelMethodCallHandler') ||
            line.contains('┌───') ||
            line.contains('├┄┄') ||
            line.contains('└───') ||
            line.contains('│')) {
          // 静默忽略flutter_sound的日志
          return;
        }
        // 保留其他日志
        parent.print(zone, line);
      },
    ),
  );
}

class ReminiApp extends StatelessWidget {
  const ReminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFFF4757),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4757),
          secondary: Color(0xFF2F2F2F),
          surface: Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
        ),
      ),
      home: const MainPage(),
    );
  }
}
