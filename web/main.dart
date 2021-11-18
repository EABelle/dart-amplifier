import 'dart:html';
import 'dart:web_audio';
import 'dart:math';

import './controls.dart';

void main() {
  Element visualizer = querySelector('#visualizer')!;

  // Set up Web Audio API.
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
//  Element muteButton = getMuteButton(context);

  GainNode makeUpGain = new GainNode(context, {'gain': 50});
  ConvolverNode overdriveConvolver = new ConvolverNode(context);
  ConvolverNode reverb = new ConvolverNode(context);
  AnalyserNode analyserNode = new AnalyserNode(context, {'fftSize': 1024});
}
