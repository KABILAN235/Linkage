import 'package:flutter/material.dart';
import 'package:linkage/widgets/ogp_metadata_card.dart';
import 'package:linkage/widgets/web_extract_dialog.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final TextEditingController linkController = TextEditingController();
  final TextEditingController promptController = TextEditingController();
  OgpData? ogpData;

  String lastURL = "";

  bool loadingMetadata = false;

  @override
  void dispose() {
    linkController.dispose();
    promptController.dispose();
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

  final supabase = Supabase.instance.client;

  Future<String> _createQuery(String url) async {
    final response = await supabase
        .from('Query')
        .insert([
          {
            'title': ogpData?.title ?? url,
            'user_uuid': supabase.auth.currentUser?.id,
            'url': url,
            'prompt': promptController.text,
          },
        ])
        .select("uuid");

    final String queryUuid = response[0]['uuid'];

    return queryUuid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Text(supabase.auth.currentUser?.email ?? "User"),
              trailing: IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  supabase.auth
                      .signOut()
                      .then((_) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      })
                      .catchError((error) {
                        debugPrint('Error signing out: $error');
                      });
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.07,
            vertical: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
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
                controller: promptController,
                minLines: 1,
                maxLines: 6, // Allows unlimited lines
                keyboardType:
                    TextInputType.multiline, // Enables multiline input
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'What do you want from this Page',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
              ),
              SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () async {
                  final queryText = linkController.text;
                  final promptText = promptController.text;
                  final queryUuid = await _createQuery(linkController.text);

                  showDialog(
                    context: context,
                    builder:
                        (ctx) => WebExtractDialog(
                          url: queryText,
                          queryUuid: queryUuid,
                          additionalPrompt: promptText,
                        ),
                  );
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
                child: Text(
                  "Go!",

                  // style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
