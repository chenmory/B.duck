import 'package:flutter/material.dart';

import '../models/conversation_record.dart';
import '../pages/child_profile_page.dart';
import '../pages/conversation_detail_page.dart';
import '../pages/conversation_records_page.dart';
import '../pages/device_page.dart';
import '../pages/feedback_page.dart';
import '../pages/legal_page.dart';
import '../pages/login_page.dart';
import '../pages/main_shell_page.dart';
import '../pages/splash_page.dart';
import '../pages/usage_time_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const conversations = '/conversations';
  static const conversationDetail = '/conversation-detail';
  static const usage = '/usage';
  static const device = '/device';
  static const childProfile = '/child-profile';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const feedback = '/feedback';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case splash:
        page = const SplashPage();
        break;
      case login:
        page = const LoginPage();
        break;
      case home:
        page = const MainShellPage();
        break;
      case conversations:
        page = const ConversationRecordsPage(showAppBar: true);
        break;
      case conversationDetail:
        final record = settings.arguments as ConversationRecord?;
        page = ConversationDetailPage(record: record);
        break;
      case usage:
        page = const UsageTimePage();
        break;
      case device:
        page = const DevicePage();
        break;
      case childProfile:
        page = const ChildProfilePage();
        break;
      case privacy:
        page = const LegalPage(type: LegalType.privacy);
        break;
      case terms:
        page = const LegalPage(type: LegalType.terms);
        break;
      case feedback:
        page = const FeedbackPage();
        break;
      default:
        page = const LoginPage();
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
