import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

class WebScrapingScreen extends StatefulWidget {
  const WebScrapingScreen({super.key, required this.url});

  final String url;

  @override
  State<WebScrapingScreen> createState() => _WebScrapingScreenState();
}

class _WebScrapingScreenState extends State<WebScrapingScreen> {
  HeadlessInAppWebView? headlessWebView;

  int _progress = 0;

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
      onLoadStop: (controller, url) async {},
    );
  }

  @override
  void dispose() {
    super.dispose();
    headlessWebView?.dispose();
  }

  Future<void> createPdf(InAppWebViewController controller) async {
    Uint8List? pdf = await headlessWebView?.webViewController?.createPdf();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await headlessWebView?.dispose();
                await headlessWebView?.run();
              },
              child: const Text("Run HeadlessInAppWebView"),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                if (headlessWebView?.isRunning() ?? false) {
                  await headlessWebView?.webViewController?.evaluateJavascript(
                    source: "console.log('Here is the message!');",
                  );
                } else {
                  const snackBar = SnackBar(
                    content: Text(
                      'HeadlessInAppWebView is not running. Click on "Run HeadlessInAppWebView"!',
                    ),
                    duration: Duration(milliseconds: 1500),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: const Text("Send console.log message"),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                headlessWebView?.dispose();
                setState(() {
                  // url = '';
                });
              },
              child: const Text("Dispose HeadlessInAppWebView"),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              // onPressed: () async {
              //   // Size screenSize = MediaQuery.of(context).size;

              //   String? html =
              //       await headlessWebView?.webViewController?.getHtml();

              //   final String dir =
              //       (await getApplicationDocumentsDirectory()).path;
              //   final String path = '$dir/example.pdf';
              //   final String htmlPath = '$dir/index.html';

              //   final File file = File(path);
              //   final File htmlFile = File(htmlPath);
              //   if (pdf != null && html != null) {
              //     await file.writeAsBytes(pdf);
              //     await htmlFile.writeAsString(html);

              //     print(file.path);
              //     print(dir);
              //   } else {
              //     const snackBar = SnackBar(
              //       content: Text('Failed to generate PDF.'),
              //       duration: Duration(seconds: 1),
              //     );
              //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
              //   }

              //   // Uint8List? capturedImage = await headlessWebView
              //   //     ?.webViewController
              //   //     ?.takeScreenshot(
              //   //       screenshotConfiguration: ScreenshotConfiguration(
              //   //         rect: InAppWebViewRect(
              //   //           x: 0,
              //   //           y: 0,
              //   //           width: screenSize.width,
              //   //           height:
              //   //               (contentHeight?.toDouble()) ?? screenSize.height,
              //   //         ),
              //   //       ),
              //   //     );

              //   // showDialog(
              //   //   context: context,
              //   //   builder: (BuildContext context) {
              //   //     return AlertDialog(
              //   //       content:
              //   //           capturedImage != null
              //   //               ? Image.memory(capturedImage)
              //   //               : Text("No Captured Image3"),
              //   //       actions: [
              //   //         TextButton(
              //   //           onPressed: () {
              //   //             Navigator.of(context).pop();
              //   //           },
              //   //           child: const Text('Close'),
              //   //         ),
              //   //       ],
              //   //     );
              //   //   },
              //   // );
              // },
              child: const Text("Capture Screenshot"),
            ),
          ),
        ],
      ),
    );
  }
}
