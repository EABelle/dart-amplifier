import 'dart:html';
import 'dart:web_audio';
import 'dart:math';
import 'dart:async';

import 'src/controls.dart';

Future<ConvolverNode> decodeImpulse(String url, AudioContext context, ConvolverNode convolverNode) async {
  var response = await HttpRequest.request(url, responseType: "arraybuffer");
  var audioData = await context.decodeAudioData(response.response);
  convolverNode.buffer = audioData;
  return convolverNode;
}

Future<MediaStream> getGuitar() {
    return window.navigator.mediaDevices!.getUserMedia({
      'audio': {
        'latency': 0,
        'echoCancellation': false,
        'noiseSuppression': false,
        'autoGainControl': false,
      }
    });
}

MediaStreamAudioSourceNode connectAudioNodes(AudioContext context, MediaStream stream, List audioNodes) {
  MediaStreamAudioSourceNode source = context.createMediaStreamSource(stream);
  source.connectNode(audioNodes[0]);
  if (audioNodes.length > 1) {
    for (int i = 1; i < audioNodes.length; i++) {
      audioNodes[i - 1].connectNode(audioNodes[i]);
    }
  }
  audioNodes[audioNodes.length - 1].connectNode(context.destination as AudioNode);
  return source;
}

Future<MediaStreamAudioSourceNode> setupContext() async {
  AudioContext context = new AudioContext();
  VolumeControl volume = new VolumeControl(context, 'volume');
  OverdriveControl gain = new OverdriveControl(context, 'overdrive');
  EQControl bass = new EQControl(context, 'bass', {'type': 'lowshelf', 'frequency': 600});
  EQControl mid = new EQControl(context, 'mid', {
    'peaking': 'peaking',
    'frequency': 2000,
    'Q': sqrt1_2
  });
  EQControl treble = new EQControl(context, 'treble', {'type': 'highshelf', 'frequency': 4000});
  MuteControl mute = new MuteControl(context, 'mute', volume);
  GainNode makeUpGain = new GainNode(context, {'gain': 50});
  MediaStream guitar = await getGuitar();
  ConvolverNode overdriveConvolver = new ConvolverNode(context);
  ConvolverNode reverb = new ConvolverNode(context);
  await decodeImpulse('./assets/impulses/overdrive.wav', context, overdriveConvolver);
  await decodeImpulse('./assets/impulses/reverb.wav', context, reverb);
  
  return connectAudioNodes(context, guitar, [
    overdriveConvolver,
    reverb,
    makeUpGain,
    bass.node!,
    mid.node!,
    treble.node!,
    volume.node!,
    gain.node!,
  ]);
}

void setup() {
  bool contextReady = false;
  querySelector('.amp')?.onMouseOver?.listen((e) async {
    if (!contextReady) {
      contextReady = true;
      await setupContext();
    }
  });
}

void main() {
  setup();
}
