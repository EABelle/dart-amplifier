import 'dart:html';
import 'dart:web_audio';
import 'dart:math';

import './controls.dart';

void main() {
  Element visualizer = querySelector('#visualizer')!;

  // Set up Web Audio API.
  AudioContext context = new AudioContext();
  VolumeControl volume = new VolumeControl(context, 'volume');
  Element gain = getGainControl(context);
  Element bass = getBassControl(context);
  Element mid = getMidControl(context);
  Element treble = getTrebleControl(context);
//  Element muteButton = getMuteButton(context);

  GainNode makeUpGain = new GainNode(context, {'gain': 50});
  ConvolverNode overdriveConvolver = new ConvolverNode(context);
  ConvolverNode reverb = new ConvolverNode(context);
  AnalyserNode analyserNode = new AnalyserNode(context, {'fftSize': 1024});
}
