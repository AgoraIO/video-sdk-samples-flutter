import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_manager/agora_manager.dart';
import 'package:agora_manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

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
    Example(name: 'SDK quickstart', category: 'GET STARTED', id: '1'),
    Example(name: 'Secure authentication with tokens', category: 'GET STARTED', id: '2'),
    Example(name: 'Call quality best practice', category: 'DEVELOP', id: '3'),
    //Example(name: 'Task 2', category: 'DEVELOP', id: '4'),
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
            Expanded(
              child: ListView.builder(
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  final task = examples[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0 || examples[index - 1].category != task.category)
                        ListTile(
                          title: Text(
                            task.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ListTile(
                        title: Text(task.name),
                        tileColor: Colors.grey[300],
                        contentPadding: const EdgeInsets.symmetric(vertical: -8),
                        onTap: () {
                          onTaskClicked(task.id);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  void onTaskClicked(String taskId) {
    // Handle task clicked
    print('Task clicked: $taskId');
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}
