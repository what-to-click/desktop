import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart';

const dataChannelId = 1;
const dataChannelLabel = 'wtc-dc1';

enum ExtensionConnectionStatus { idle, begin, confirmed, active, error, done }

enum RTCSessionDescriptionType {
  offer('offer'),
  answer('answer');

  const RTCSessionDescriptionType(this.value);
  final String value;

  @override
  String toString() => value;
}

class ExtensionConnection {
  RTCPeerConnection? _peerConnection;
  late RTCDataChannel _sendDataChannel;
  late RTCDataChannel _extensionDataChannel;

  ExtensionConnectionStatus status = ExtensionConnectionStatus.idle;

  Future<
      ({
        RTCSessionDescription offer,
        List<RTCIceCandidate> iceCandidates,
      })> beginConnection() async {
    status = ExtensionConnectionStatus.begin;
    final iceCandidatesCompleter = Completer<List<RTCIceCandidate>>();
    final iceCandidates = <RTCIceCandidate>[];
    _peerConnection = await createPeerConnection({'iceServers': []});
    _peerConnection!.onIceCandidate = (candidate) {
      iceCandidates.add(candidate);
    };
    _peerConnection!.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        iceCandidatesCompleter.complete(iceCandidates);
      }
    };
    _sendDataChannel = await _peerConnection!.createDataChannel(
      dataChannelLabel,
      RTCDataChannelInit()..id = dataChannelId,
    );
    _peerConnection!.onDataChannel = (RTCDataChannel dataChannel) {
      _extensionDataChannel = dataChannel;
      _extensionDataChannel.onMessage = (message) {
        log('Received message: $message');
      };
    };

    final offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    return (
      offer: offer,
      iceCandidates: await iceCandidatesCompleter.future,
    );
  }

  Future<void> confirmConnection(String sdp) async {
    assert(_peerConnection != null);
    _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        sdp,
        RTCSessionDescriptionType.answer.toString(),
      ),
    );
    status = ExtensionConnectionStatus.confirmed;
  }

  Future<void> send() async {
    assert(status == ExtensionConnectionStatus.confirmed);
    status = ExtensionConnectionStatus.active;
    _sendDataChannel.send(RTCDataChannelMessage('hello from desktop'));
    status = ExtensionConnectionStatus.done;
  }
}

extension SerializeConnectionOffer on ExtensionConnection {
  String _serialize(
    ({
      RTCSessionDescription offer,
      List<RTCIceCandidate> iceCandidates,
    }) input,
  ) =>
      json.encode({
        'offer': {
          'type': input.offer.type,
          'sdp': input.offer.sdp,
        },
        'iceCandidates': input.iceCandidates
            .map<Map>(
              (element) => {
                'candidate': element.candidate,
                'sdpMid': element.sdpMid,
                'sdpMLineIndex': element.sdpMLineIndex,
              },
            )
            .toList(),
      });

  Future<String> serializedOffer() async {
    final offerMap = _serialize(await beginConnection());
    return base64Encode(offerMap.codeUnits);
  }
}
