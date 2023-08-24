import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:flutter_reference_app/sdk-quickstart/sdk_quickstart_ui.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

enum AgoraProduct {
  VIDEO_CALLING,
  VOICE_CALLING,
  INTERACTIVE_LIVE_STREAMING,
  BROADCAST_STREAMING,
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
  AgoraProduct selectedProduct = AgoraProduct.VIDEO_CALLING;
  final List<Example> examples = [
    Example(name: 'SDK quickstart', category: 'GET STARTED', id: 'sdk_quickstart'),
    Example(name: 'Secure authentication with tokens', category: 'GET STARTED', id: 'authentication_workflow'),
    Example(name: 'Call quality best practice', category: 'DEVELOP', id: 'call_quality'),
  ];

  Map<AgoraProduct, String> productFriendlyNames = {
    AgoraProduct.VIDEO_CALLING: 'Video Calling',
    AgoraProduct.VOICE_CALLING: 'Voice Calling',
    AgoraProduct.INTERACTIVE_LIVE_STREAMING: 'Interactive Live Streaming',
    AgoraProduct.BROADCAST_STREAMING: 'Broadcast Streaming',
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
    print('ExampleId clicked: $exampleId');

    switch (exampleId) {
      case 'sdk_quickstart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SDKQuickstartScreen()),
        );
        break;
      case 'authentication_workflow':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SDKQuickstartScreen()),
        );
        break;
      case 'call_quality':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SDKQuickstartScreen()),
        );
        break;
      default:
        print("Invalid day");
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
    return DropdownButton<AgoraProduct>(
      value: selectedProduct,
      onChanged: (newValue) {
        setState(() {
          selectedProduct = newValue!;
        });
      },
      items: AgoraProduct.values.map<DropdownMenuItem<AgoraProduct>>(
        (AgoraProduct value) {
          return DropdownMenuItem<AgoraProduct>(
            value: value,
            child: Text(productFriendlyNames[value]!),
          );
        },
      ).toList(),
    );
  }
}
