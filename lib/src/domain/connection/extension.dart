import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/subjects.dart';

const dataChannelId = 1;
const dataChannelLabel = 'wtc-dc1';

enum ExtensionConnectionStatus {
  idle,
  began,
  responded,
  confirmed,
  error,
  done
}

enum RTCSessionDescriptionType {
  offer('offer'),
  answer('answer');

  const RTCSessionDescriptionType(this.value);
  final String value;

  @override
  String toString() => value;
}

@lazySingleton
class ExtensionConnection {
  RTCPeerConnection? _peerConnection;
  late RTCDataChannel _sendDataChannel;
  late RTCDataChannel _extensionDataChannel;

  final _status = BehaviorSubject.seeded(ExtensionConnectionStatus.idle);
  ExtensionConnectionStatus get status => _status.value;
  Stream<ExtensionConnectionStatus> get status$ => _status.stream;

  Future<
      ({
        RTCSessionDescription offer,
        List<RTCIceCandidate> iceCandidates,
      })> beginConnection() async {
    _status.value = ExtensionConnectionStatus.began;
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

  Future<void> confirmConnection(String serializedAnswer) async {
    assert(_peerConnection != null);
    _status.value = ExtensionConnectionStatus.responded;
    final (answer, iceCandidates) = deserialize(serializedAnswer);
    _peerConnection!.onConnectionState =
        (RTCPeerConnectionState connectionState) {
      if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _status.value = ExtensionConnectionStatus.confirmed;
      }
    };
    await _peerConnection!.setRemoteDescription(answer);
    await Future.delayed(const Duration(seconds: 1));
    for (final iceCandidate in iceCandidates) {
      // Firefox is trying to be compliant with the spec
      // and sends an empty candidate to indicate trickle ICE end.
      // MacOSes WebRTC implementation does not like that and crashes
      // the app if it founds this candidate, so we need to filter it out
      // manually. It does not affect the connection routine.
      if (iceCandidate.candidate?.isNotEmpty ?? false) {
        await _peerConnection!.addCandidate(iceCandidate);
      }
    }
  }

  Future<void> send(String text) async {
    await _sendDataChannel.send(RTCDataChannelMessage(text));
  }

  Future<void> sendBinary(Uint8List binary) async {
    await _sendDataChannel.send(RTCDataChannelMessage.fromBinary(binary));
  }

  Future<void> close() async {
    _status.value = ExtensionConnectionStatus.done;
    _sendDataChannel.close();
    _peerConnection?.close();
    _status.value = ExtensionConnectionStatus.idle;
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

  (RTCSessionDescription answer, List<RTCIceCandidate> iceCandidates)
      deserialize(String input) {
    final json = jsonDecode(
      Uri.decodeComponent(String.fromCharCodes(base64Decode(input))),
    );
    return (
      RTCSessionDescription(
        json['answer']['sdp'] as String,
        json['answer']['type'] as String,
      ),
      (json['iceCandidates'] as List<dynamic>)
          .map<RTCIceCandidate>(
            (serializedCandidate) => RTCIceCandidate(
              serializedCandidate['candidate'] as String,
              serializedCandidate['sdpMid'] as String,
              serializedCandidate['sdpMLineIndex'] as int,
            ),
          )
          .toList(),
    );
  }
}
