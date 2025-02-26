// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ramautomention/main.dart';
import 'package:ramautomention/services/notification_manager.dart';
import 'package:ramautomention/services/notification.dart';
import 'package:ramautomention/services/database.dart';

// 创建模拟对象
class MockNotificationManager extends Mock implements NotificationManager {}
class MockNotificationService extends Mock implements NotificationService {}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  testWidgets('Schedule app smoke test', (WidgetTester tester) async {
    // 创建模拟的NotificationManager
    final mockNotificationService = MockNotificationService();
    final mockDatabaseService = MockDatabaseService();
    final mockNotificationManager = NotificationManager(
      notificationService: mockNotificationService,
      databaseService: mockDatabaseService,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(RAMautoMention(notificationManager: mockNotificationManager));

    // 验证应用已成功启动
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 验证底部导航栏存在
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // 验证课程表选项卡初始显示
    expect(find.text('课程表'), findsOneWidget);
    expect(find.text('导入'), findsOneWidget);
  });
}