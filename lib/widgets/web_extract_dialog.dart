import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebExtractDialog extends StatefulWidget {
  final String url;
  final String queryUuid;

  const WebExtractDialog({
    super.key,
    required this.url,
    required this.queryUuid,
  });

  @override
  State<WebExtractDialog> createState() => _WebExtractDialogState();
}

class _WebExtractDialogState extends State<WebExtractDialog> {
  final supabase = Supabase.instance.client;

  HeadlessInAppWebView? headlessWebView;

  int _progress = 0;

  Future<void> createPdf(InAppWebViewController controller) async {
    Uint8List? pdf = await headlessWebView?.webViewController?.createPdf();

    supabase.functions.invoke(
      'scraper',
      body: pdf,
      queryParameters: {'queryUuid': widget.queryUuid},
    );

    // final String dir = (await getApplicationDocumentsDirectory()).path;
    // final String path = '$dir/example.pdf';

    // final File file = File(path);
    // if (pdf != null) {
    //   await file.writeAsBytes(pdf);

    //   print(file.path);
    //   print(dir);
    // } else {}
  }

  @override
  void initState() {
    super.initState();

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: InAppWebViewSettings(isInspectable: kDebugMode),
      onWebViewCreated: (controller) {},
      onConsoleMessage: (controller, consoleMessage) {},
      onProgressChanged: (controller, progress) {
        setState(() {
          _progress = progress;
        });
      },
      onLoadStart: (controller, url) async {},
      onLoadStop: (controller, url) async {
        await Future.delayed(const Duration(seconds: 10));
        createPdf(controller);
      },
    );

    headlessWebView?.run();
  }

  @override
  void dispose() {
    super.dispose();
    headlessWebView?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Extracting Data'),
        titleTextStyle: Theme.of(context).textTheme.bodyMedium,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: LinearProgressIndicator(value: _progress * 0.09),
        ),
      ),
    );
  }
}
