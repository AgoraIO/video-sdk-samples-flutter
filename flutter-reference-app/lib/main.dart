import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:flutter_reference_app/audio-and-voice-effects/audio_voice_effects_ui.dart';
import 'package:flutter_reference_app/cloud_proxy/cloud_proxy_ui.dart';
import 'package:flutter_reference_app/custom-video-and-audio/custom_video_audio_ui.dart';
import 'package:flutter_reference_app/geofencing/geofencing_ui.dart';
import 'package:flutter_reference_app/media-stream-encryption/media_stream_encryption_ui.dart';
import 'package:flutter_reference_app/play-media/play_media_ui.dart';
import 'package:flutter_reference_app/product-workflow/product_workflow_ui.dart';
import 'package:flutter_reference_app/sdk-quickstart/sdk_quickstart_ui.dart';
import 'package:flutter_reference_app/authentication-workflow/authentication_workflow_ui.dart';
import 'package:flutter_reference_app/ensure-channel-quality/call_quality_ui.dart';
import 'package:flutter_reference_app/spatial-audio/spatial_audio_ui.dart';
import 'package:flutter_reference_app/stream-raw-video-and-audio/raw_video_audio_ui.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class Example {
  final String name;
  final String category;
  final String id;

  Example({required this.name, required this.category, required this.id});
}

class MyAppState extends State<MyApp> with UiHelper {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  ProductName selectedProduct = ProductName.videoCalling;
  final List<Example> examples = [
    Example(name: 'SDK quickstart', category: 'GET STARTED', id: 'sdk_quickstart'),
    Example(name: 'Secure authentication with tokens', category: 'GET STARTED', id: 'authentication_workflow'),
    // Develop
    Example(name: 'Call quality best practice', category: 'DEVELOP', id: 'call_quality'),
    Example(name: 'Stream media to a channel', category: 'DEVELOP', id: 'stream_media'),
    Example(name: 'Screen share, volume control, and mute', category: 'DEVELOP', id: 'product_workflow'),
    Example(name: 'Cloud proxy', category: 'DEVELOP', id: 'cloud_proxy'),
    Example(name: 'Media stream encryption', category: 'DEVELOP', id: 'secure_channel_encryption'),
    Example(name: 'Custom video and audio', category: 'DEVELOP', id: 'custom_video_audio'),
    Example(name: 'Stream raw video and audio', category: 'DEVELOP', id: 'raw_video_audio'),
    //Example(name: 'Live streaming over multiple channels', category: 'DEVELOP', id: 'multiple_channels'),
    // Integrate features
    Example(name: 'Audio and voice effects', category: 'INTEGRATE FEATURES', id: 'audio_voice_effects'),
    Example(name: '3D Spatial audio', category: 'INTEGRATE FEATURES', id: 'spatial_audio'),
    Example(name: 'Geofencing', category: 'INTEGRATE FEATURES', id: 'geofencing'),
    //Example(name: 'Virtual background', category: 'INTEGRATE FEATURES', id: 'virtual_background'),
    //Example(name: 'AI noise suppression', category: 'INTEGRATE FEATURES', id: 'ai_noise_suppression'),
  ];

  Map<ProductName, String> productFriendlyNames = {
    ProductName.videoCalling: 'Video Calling',
    ProductName.voiceCalling: 'Voice Calling',
    ProductName.interactiveLiveStreaming: 'Interactive Live Streaming',
    ProductName.broadcastStreaming: 'Broadcast Streaming',
  };

  // Build UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Reference App'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agora Video SDK Samples',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Product:',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: productDropDown()),
                    ],
                  ),
                ],
              ),
            ),
            exampleList(),
          ],
        ),
      ),
    );
  }

  void onItemClicked(String exampleId) {
    switch (exampleId) {
      case 'sdk_quickstart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SDKQuickstartScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'authentication_workflow':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AuthenticationWorkflowScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'call_quality':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CallQualityScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'cloud_proxy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CloudProxyScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'secure_channel_encryption':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MediaStreamEncryptionScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'stream_media':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlayMediaScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'geofencing':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GeofencingScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'spatial_audio':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SpatialAudioScreen(selectedProduct: selectedProduct)),
      );
      break;
      case 'product_workflow':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductWorkflowScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'audio_voice_effects':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AudioVoiceEffectsScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'custom_video_audio':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomVideoAudioScreen(selectedProduct: selectedProduct)),
        );
        break;
      case 'raw_video_audio':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RawVideoAudioScreen(selectedProduct: selectedProduct)),
        );
        break;
      default:
        // not implemented yet
    }
  }

  Widget exampleList() {
    return Expanded(
      child: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0 ||
                    examples[index - 1].category != example.category)
                  ListTile(
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: Text(
                      example.category,
                      style: const TextStyle(fontSize: 15),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(18, 6, 12, 0),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10,
                      vertical: 2), // Add vertical space
                  child: ListTile(
                    tileColor: Colors.grey[300],
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(example.name),
                        const Icon(Icons.arrow_right),
                      ],
                    ),
                    onTap: () {
                      onItemClicked(example.id);
                    },
                  ),
                ),
              ]);
        },
      ),
    );
  }

  Widget productDropDown() {
    return DropdownButton<ProductName>(
      value: selectedProduct,
      onChanged: (newValue) {
        setState(() {
          selectedProduct = newValue!;
        });
      },
      items: ProductName.values.map<DropdownMenuItem<ProductName>>(
        (ProductName value) {
          return DropdownMenuItem<ProductName>(
            value: value,
            child: Text(productFriendlyNames[value]!),
          );
        },
      ).toList(),
    );
  }
}
