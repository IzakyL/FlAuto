import 'package:flutter/material.dart';
import '../services/web_scraper.dart';
import '../services/database.dart';
import '../models/event.dart';

class ImportScheduleScreen extends StatefulWidget {
  const ImportScheduleScreen({super.key});

  @override
  _ImportScheduleScreenState createState() => _ImportScheduleScreenState();
}

class _ImportScheduleScreenState extends State<ImportScheduleScreen> {
  final WebScraperService _webScraperService = WebScraperService();
  final DatabaseService _databaseService = DatabaseService();
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
            Text(
              '从教务系统导入课程表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _importFromWebsite('jw.ustc.edu.cn'),
              child:
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('jw.ustc.edu.cn'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _launchBrowser(),
              child: Text('打开浏览器登录'),
            ),
            SizedBox(height: 24),
            Text(
              '已导入的课程: ${_importedEvents.length}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _importedEvents.length,
                itemBuilder: (context, index) {
                  final event = _importedEvents[index];
                  return ListTile(
                    title: Text(event.name),
                    subtitle: Text('${event.description} | ${event.location}'),
                    trailing: Text(
                      '${event.startTime}-${event.endTime}节',
                    ),
                  );
                },
              ),
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
