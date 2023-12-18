import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';

class AgoraManagerVirtualBackground extends AgoraManagerAuthentication {
  AgoraManagerVirtualBackground({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerVirtualBackground
  }

  static Future<AgoraManagerVirtualBackground> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerVirtualBackground(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  Future<bool> isFeatureAvailable() {
    return agoraEngine!.isFeatureAvailableOnDevice(FeatureType.videoVirtualBackground);
  }

  void setBlurBackground() {
    VirtualBackgroundSource virtualBackgroundSource;

    // Set the type of virtual background
    virtualBackgroundSource = const VirtualBackgroundSource(
    backgroundSourceType: BackgroundSourceType.backgroundBlur,
    blurDegree: BackgroundBlurDegree.blurDegreeHigh);

    setBackground(virtualBackgroundSource);
  }

  void setBackground(VirtualBackgroundSource virtualBackgroundSource) {
    // Set processing properties for background
    SegmentationProperty segmentationProperty = const SegmentationProperty(
        modelType: SegModelType.segModelAi, // Use segModelGreen if you have a green background
        greenCapacity: 0.5 // Accuracy for identifying green colors (range 0-1)
    );

    // Enable or disable virtual background
    agoraEngine?.enableVirtualBackground(
        enabled: true,
        backgroundSource: virtualBackgroundSource,
        segproperty: segmentationProperty);
  }

  void setSolidBackground() {
    VirtualBackgroundSource virtualBackgroundSource;

    // Set a solid background color
    virtualBackgroundSource = const VirtualBackgroundSource(
        backgroundSourceType: BackgroundSourceType.backgroundColor,
        color: 0x0000FF); // Blue

    setBackground(virtualBackgroundSource);
  }

  void setImageBackground() {
    VirtualBackgroundSource virtualBackgroundSource;

    // Set a background image
    virtualBackgroundSource = const VirtualBackgroundSource(
      backgroundSourceType: BackgroundSourceType.backgroundImg,
      source: "<The local absolute path of the image file>"); // use .png or .jpg

    setBackground(virtualBackgroundSource);
  }

  void removeBackground() {
    // Disable virtual background
    agoraEngine!.enableVirtualBackground(
      enabled: false,
      backgroundSource: const VirtualBackgroundSource(),
      segproperty: const SegmentationProperty()
    );
  }

}
