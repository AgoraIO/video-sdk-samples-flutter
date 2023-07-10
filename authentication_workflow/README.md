# Secure authentication with tokens

Authentication is the act of validating the identity of each user before they access a system. Agora uses digital tokens to authenticate users and their privileges before they access Agora SD-RTN™ to join a channel. Each token is valid for a limited period and works only for a specific channel. For example, you cannot use a token generated for a channel named `AgoraChannel` to join the `AppTest` channel.

This project shows you the authentication workflow required to connect securely to a specific Video SDK channel. To quickly set up an authentication token server for use with this project, see [Create and run a token server](https://docs.agora.io/en/video-calling/get-started/authentication-workflow?platform=flutter#create-and-run-a-token-server). To develop your own token generator and integrate it into your production IAM system, read [Token generators](https://docs.agora.io/en/video-calling/develop/integrate-token-generation).

## Understand the code

For context on this sample, and a full explanation of the essential code snippets used in this project, read the following guides:

* [Secure authentication with tokens for Video calling](https://docs.agora.io/en/video-calling/get-started/authentication-workflow?platform=flutter)
* [Secure authentication with tokens for Voice calling](https://docs.agora.io/en/voice-calling/get-started/authentication-workflow?platform=flutter)
* [Secure authentication with tokens for Interactive live Streaming](https://docs.agora.io/en/interactive-live-streaming/get-started/authentication-workflow?platform=flutter)
* [Secure authentication with tokens for Broadcast streaming](https://docs.agora.io/en/broadcast-streaming/get-started/authentication-workflow?platform=flutter)


## How to run this project

To see how to run this project, refer to the [README](../README.md) in the root folder or one of the complete product guides.
