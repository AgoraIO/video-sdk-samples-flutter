library agora_manager;
import 'dart:convert';
import 'package:flutter/services.dart';

class AgoraManager {
  
   Future<void> readConfig() async {
    try {
      String configString = await rootBundle.loadString('config.json');
      Map<String, dynamic> configData = jsonDecode(configString);
      
      String appId = configData['appId'];
      String token = configData['token'];
    } catch (e) {
      // Handle any errors that occur during the reading or parsing of the config file
    }
  }
}
