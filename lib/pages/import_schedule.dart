import 'package:flutter/material.dart';
import '../components/event_list.dart';
import '../components/import_buttons.dart';
import '../components/import_header.dart';
import '../services/web_scraper.dart';
import '../models/event.dart';

class ImportSchedulePage extends StatefulWidget {
  const ImportSchedulePage({super.key});

  @override
  _ImportSchedulePageState createState() => _ImportSchedulePageState();
}

class _ImportSchedulePageState extends State<ImportSchedulePage> {
  final WebScraperService _webScraperService = WebScraperService();
  bool _isLoading = false;
  List<Event> _importedEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('导入课程表')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImportHeader(),
            ImportButtons(
              isLoading: _isLoading,
              onImportFromWebsite: _importFromWebsite,
              onLaunchBrowser: _launchBrowser,
            ),
            Expanded(
              child: EventList(events: _importedEvents),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromWebsite(String schoolSystem) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _webScraperService.fetchEventsWithWebView(
        context,
        schoolSystem,
      );
      setState(() {
        _importedEvents = events;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchBrowser() async {
    try {
      await _webScraperService.openBrowserForLogin(
        'https://jw.ustc.edu.cn/for-std/course-table/get-data',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请在浏览器中登录教务系统')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开浏览器失败: ${e.toString()}')));
    }
  }
}