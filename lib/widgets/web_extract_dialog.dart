import 'package:flutter/material.dart';

class WebExtractDialog extends StatefulWidget {
  const WebExtractDialog({super.key});

  @override
  State<WebExtractDialog> createState() => _WebExtractDialogState();
}

class _WebExtractDialogState extends State<WebExtractDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Extracting Data'),
      titleTextStyle: Theme.of(context).textTheme.bodyMedium,
      // icon: Icon(Icons.upload),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        // height: MediaQuery.of(context).size.width * 0.1,
        child: LinearProgressIndicator(value: 0.3),
      ),
    );
  }
}
