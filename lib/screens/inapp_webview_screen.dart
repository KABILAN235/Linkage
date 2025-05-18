import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

class WebView extends StatefulWidget {
  const WebView({super.key});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  HeadlessInAppWebView? headlessWebView;
  String url = "";

  @override
  void initState() {
    super.initState();

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          "https://www.woolworths.com.au/shop/search/products?searchTerm=Oreo",
        ),
      ),
      initialSettings: InAppWebViewSettings(isInspectable: kDebugMode),
      onWebViewCreated: (controller) {
        const snackBar = SnackBar(
          content: Text('HeadlessInAppWebView created!'),
          duration: Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      onConsoleMessage: (controller, consoleMessage) {
        final snackBar = SnackBar(
          content: Text('Console Message: ${consoleMessage.message}'),
          duration: const Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      onLoadStart: (controller, url) async {
        final snackBar = SnackBar(
          content: Text('onLoadStart $url'),
          duration: const Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        setState(() {
          this.url = url?.toString() ?? '';
        });
      },
      onLoadStop: (controller, url) async {
        final snackBar = SnackBar(
          content: Text('onLoadStop $url'),
          duration: const Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        setState(() {
          this.url = url?.toString() ?? '';
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    headlessWebView?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "URL: ${(url.length > 50) ? "${url.substring(0, 50)}..." : url}",
            ),
          ),
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
                  url = '';
                });
              },
              child: const Text("Dispose HeadlessInAppWebView"),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                // Size screenSize = MediaQuery.of(context).size;
                Uint8List? pdf =
                    await headlessWebView?.webViewController?.createPdf();

                String? html =
                    await headlessWebView?.webViewController?.getHtml();

                final String dir =
                    (await getApplicationDocumentsDirectory()).path;
                final String path = '$dir/example.pdf';
                final String HTMLpath = '$dir/index.html';

                final File file = File(path);
                final File htmlFile = File(HTMLpath);
                if (pdf != null && html != null) {
                  await file.writeAsBytes(pdf);
                  await htmlFile.writeAsString(html);

                  print(file.path);
                  print(dir);
                } else {
                  const snackBar = SnackBar(
                    content: Text('Failed to generate PDF.'),
                    duration: Duration(seconds: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }

                // Uint8List? capturedImage = await headlessWebView
                //     ?.webViewController
                //     ?.takeScreenshot(
                //       screenshotConfiguration: ScreenshotConfiguration(
                //         rect: InAppWebViewRect(
                //           x: 0,
                //           y: 0,
                //           width: screenSize.width,
                //           height:
                //               (contentHeight?.toDouble()) ?? screenSize.height,
                //         ),
                //       ),
                //     );

                // showDialog(
                //   context: context,
                //   builder: (BuildContext context) {
                //     return AlertDialog(
                //       content:
                //           capturedImage != null
                //               ? Image.memory(capturedImage)
                //               : Text("No Captured Image3"),
                //       actions: [
                //         TextButton(
                //           onPressed: () {
                //             Navigator.of(context).pop();
                //           },
                //           child: const Text('Close'),
                //         ),
                //       ],
                //     );
                //   },
                // );
              },
              child: const Text("Capture Screenshot"),
            ),
          ),
        ],
      ),
    );
  }
}
