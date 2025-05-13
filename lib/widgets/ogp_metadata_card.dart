import 'package:flutter/material.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:url_launcher/url_launcher.dart';

class OGPMetadataCard extends StatelessWidget {
  const OGPMetadataCard({super.key, required this.ogpData});

  final OgpData? ogpData;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 10,
      ), // Removed horizontal margin
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ogpData!.image != null)
                Image.network(
                  ogpData!.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  if (ogpData?.url != null) {
                    final Uri url = Uri.parse(ogpData!.url!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      debugPrint('Could not launch ${ogpData!.url!}');
                    }
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  ogpData!.title ?? 'No Title',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ogpData!.description ?? 'No Description',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (ogpData!.siteName != null) ...[
                const SizedBox(height: 4),
                Text(
                  ogpData!.siteName!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
