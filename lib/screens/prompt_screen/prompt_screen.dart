import 'package:flutter/material.dart';
import 'package:linkage/screens/prompt_screen/types.dart';
import 'package:linkage/screens/table_screen/table_screen.dart';
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

  Future<List<PastQuery>> _fetchPastQueries() async {
    if (supabase.auth.currentUser == null) {
      return []; // No user, no queries
    }
    try {
      final response = await supabase
          .from('Query')
          .select('uuid, title, created_at')
          .eq('user_uuid', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false) // Show newest first
          .limit(20); // Limit the number of past queries shown

      final List<PastQuery> queries =
          (response as List<dynamic>)
              .map(
                (data) => PastQuery(
                  uuid: data['uuid'] as String,
                  title: data['title'] as String? ?? 'Untitled Query',
                  createdAt: DateTime.parse(data['created_at'] as String),
                ),
              )
              .toList();
      return queries;
    } catch (e) {
      debugPrint('Error fetching past queries: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                supabase.auth.currentUser?.email ?? "User email",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              accountEmail: Text(
                "Logged in",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                supabase.auth
                    .signOut()
                    .then((_) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    })
                    .catchError((error) {
                      debugPrint('Error signing out: $error');
                      // Optionally show a snackbar or dialog on error
                    });
              },
            ),
            const Divider(),
            const ListTile(
              title: Text(
                'Past Queries',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<PastQuery>>(
              future: _fetchPastQueries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('Error loading queries'),
                    subtitle: Text(snapshot.error.toString()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const ListTile(title: Text('No past queries found.'));
                }
                final queries = snapshot.data!;
                return Column(
                  children:
                      queries.map((query) {
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(query.title),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close the drawer
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        TableScreen(queryUuid: query.uuid),
                              ),
                            );
                          },
                        );
                      }).toList(),
                );
              },
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
              Padding(
                padding: const EdgeInsets.only(top: 48.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 250,
                    maxHeight: 250,
                  ),
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/logo_dark.png'
                        : 'assets/logo_light.png',
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => Text(error.toString()),
                  ),
                ),
              ),
              SizedBox(height: 24),
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
