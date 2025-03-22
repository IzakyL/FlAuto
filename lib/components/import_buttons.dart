import 'package:flutter/material.dart';

class ImportButtons extends StatelessWidget {
  final bool isLoading;
  final Function(String) onImportFromWebsite;
  final VoidCallback onLaunchBrowser;

  const ImportButtons({
    super.key,
    required this.isLoading,
    required this.onImportFromWebsite,
    required this.onLaunchBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : () => onImportFromWebsite('jw.ustc.edu.cn'),
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text('jw.ustc.edu.cn'),
        ),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: isLoading ? null : onLaunchBrowser,
          child: Text('打开浏览器登录'),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}