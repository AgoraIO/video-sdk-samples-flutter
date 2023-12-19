# Agora Video SDK reference app for Flutter

This repository holds the complete code examples presented in the [Agora Video SDK for Flutter](https://docs.agora.io/en/video-calling/overview/product-overview?platform=flutter) documentation. The reference app demonstrates use of Agora Video SDK for real-time audio and video communication. It is a robust and comprehensive documentation reference app, designed to enhance your productivity and understanding. It's built to be flexible, easily extensible, and beginner-friendly.

## Prerequisites

Before getting started with this example app, please ensure you have the following set up:

* An Agora [account](https://docs.agora.io/en/video-calling/reference/manage-agora-account#create-an-agora-account) and [project](https://docs.agora.io/en/video-calling/reference/manage-agora-account#create-an-agora-project).
* Flutter 2.0.0 or higher
* Dart 2.15.1 or higher
* Android Studio, IntelliJ, VS Code, or any other IDE that supports Flutter, see [Set up an editor](https://docs.flutter.dev/get-started/editor).
* If your target platform is Android:
  * Android Studio on macOS or Windows (latest version recommended)
  * An Android emulator or a physical Android device.
* If your target platform is iOS:
  * Xcode on macOS (latest version recommended)
  * A physical iOS device
  * iOS version 12.0 or later
* If you are developing a desktop application for Windows, macOS or Linux, make sure your development device meets the requirements specified in [Desktop support for Flutter](https://docs.flutter.dev/development/platform-integration/desktop).


## Run the App

1. Clone the repository

    To clone the repository to your local machine, open Terminal and navigate to the directory where you want to clone the repository. Then, use the following command:

    ```sh
    git clone https://github.com/AgoraIO/video-sdk-samples-flutter.git
    ```

1. Open the project

    Launch Android Studio. From the **File** menu, select **Open...** and navigate to the [flutter-reference-app](flutter-reference-app) folder. Start Gradle sync to automatically install all project dependencies.

1. Modify `config.json`

   The app loads connection parameters from the [`config.json`](flutter=reference-app/assets/config/config.json) file. Ensure that the file is populated with the required parameter values before running the application.

    - `uid`: The user ID associated with the application.
    - `appId`: (Required) The unique ID for the application obtained from [Agora Console](https://console.agora.io). 
    - `channelName`: The default name of the channel to join.
    - `rtcToken`: An RTC (Real-Time Communication) token generated for the `channelName`. You can generate a temporary token using Agora Console.
    - `serverUrl`: The URL for the token generator. See [Secure authentication with tokens](authentication-workflow) for information on how to set up a token server.
    - `tokenExpiryTime`: The time in seconds after which a token expires.

    If a valid `serverUrl` is specified, all examples use the token server to obtain a token except the **SDK quickstart** project that uses the `rtcToken`. If a `serverUrl` is not specified, all examples except **Secure authentication with tokens** use the `rtcToken` from `config.json`.

1. Launch Android Studio or the IDE of your choice. From the **File** menu, select **Open...** then choose the `flutter_reference_app` folder. 

1. Run the following command to install the project's dependencies:

    ```bash
    flutter pub get
    ```

1. Connect an Android device to your development machine.

1. In the IDE, click **Run app** or run the following command: 

    ```bash
    flutter run
    ```

    A moment later, you see the project installed on your device.

1. From the main app screen, choose and launch an example.

## Examples

This reference app includes several examples that illustrate the functionality and features of Agora Video/Voice SDK. Each example is self-contained and the relevant code can be found in its own folder in the [`lib`](flutter-reference-app/lib) directory. For more information about each example, see the README file within the directory.

- [SDK quickstart](flutter-reference-app/lib/agora-manager)
- [Secure authentication with tokens](flutter-reference-app/lib/authentication-workflow)
- [Call quality best practice](flutter-reference-app/lib/ensure-channel-quality)


## Contact

If you have any questions, issues, or suggestions, please file an issue in our [GitHub Issue Tracker](https://github.com/AgoraIO/video-sdk-samples-flutter/issues).

