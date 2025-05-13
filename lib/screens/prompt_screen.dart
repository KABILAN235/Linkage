import 'package:flutter/material.dart';
import 'package:linkage/widgets/ogp_metadata_card.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final TextEditingController linkController = TextEditingController();
  OgpData? ogpData;

  String lastURL = "";

  bool loadingMetadata = false;

  @override
  void dispose() {
    linkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    linkController.addListener(_onLinkChanged);
  }

  void _onLinkChanged() {
    final url = linkController.text;

    if (url == lastURL) return;

    setState(() {
      lastURL = url;
    });
    // Add your logic here to handle the text change
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (!uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
          print('Invalid URL format');
          return;
        }

        _fetchMetadata(url);
      } catch (e) {
        print('Invalid URL: $e');
      }
    } else {
      setState(() {
        ogpData = null;
      });
    }
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => loadingMetadata = true);
    final recievedOgpData = await OgpDataExtract.execute(
      url,
    ).timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (recievedOgpData != null) {
      setState(() {
        loadingMetadata = false;
        ogpData = recievedOgpData;
      });
    } else {
      setState(() {
        loadingMetadata = false;
        ogpData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.07,
          vertical: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: <Widget>[
            TextField(
              controller: linkController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter or Paste Link',
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
            Skeletonizer(
              enabled: loadingMetadata,
              child:
                  ogpData != null
                      ? OGPMetadataCard(ogpData: ogpData)
                      : const SizedBox.shrink(),
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'What do you want from this Page',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(onPressed: () {}, icon: Icon(Icons.search)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
