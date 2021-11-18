import 'dart:html';
import 'dart:web_audio';
import 'dart:math';
import 'dart:typed_data';

Float32List makeOverdriveCurve(double amount) {
  var k = amount is double || amount is int ? amount : 0,
      n_samples = 44100,
      curve = Float32List(n_samples),
      deg = pi / 180,
      i = 0,
      x;
  for (; i < n_samples; ++i) {
    x = i * 2 / n_samples - 1;
    curve[i] = (3 + k) * x * 30 * deg / (pi + k * x.abs());
  }
  return curve;
}

void main() {
  Element volume = querySelector('#volume')!;
  Element range = querySelector('#overdrive')!;
  Element bass = querySelector('#bass')!;
  Element mid = querySelector('#mid')!;
  Element treble = querySelector('#treble')!;
  Element visualizer = querySelector('#visualizer')!;
  Element muteButton = querySelector('#mute')!;

  // Set up Web Audio API.
  AudioContext context = new AudioContext();
  GainNode gainNode = new GainNode(context, {'gain': volume.nodeValue});
  GainNode makeUpGain = new GainNode(context, {'gain': 50});
  BiquadFilterNode bassEQ = new BiquadFilterNode(
      context, {'type': 'lowshelf', 'frequency': 600, 'gain': bass.nodeValue});
  BiquadFilterNode middleEQ = new BiquadFilterNode(context, {
    'peaking': 'peaking',
    'frequency': 2000,
    'gain': mid.nodeValue,
    'Q': sqrt1_2
  });
  BiquadFilterNode trebleEQ = new BiquadFilterNode(context,
      {'type': 'highshelf', 'frequency': 4000, 'gain': treble.nodeValue});
  String overdriveValue = '0';
  if (range.nodeValue != null) {
    overdriveValue = range.nodeValue as String;
  }
  WaveShaperNode overdriveNode = new WaveShaperNode(context, {
    'curve': makeOverdriveCurve(int.parse(overdriveValue) * 10),
    'oversample': '4x'
  });
  ConvolverNode overdriveConvolver = new ConvolverNode(context);
  ConvolverNode reverb = new ConvolverNode(context);
  AnalyserNode analyserNode = new AnalyserNode(context, {'fftSize': 1024});

  bool muted = false;

  volume.addEventListener('input', (e) {
    InputElement input = e.target as InputElement;
    gainNode.gain?.setTargetAtTime(double.parse(input.value!), context.currentTime!, 0.01);
  });
  setRotation(String id, double multiplier, { angleOffset: 0 }) {
    rotate(angle) {
      Element knob = document.querySelector('.control-$id')!;
      knob.style.transform = "rotate(" + (angle - 150).toString() + "deg)";
    }
    InputElement input = document.querySelector('#$id') as InputElement;
    var initialAngle = double.parse(input.value!) * multiplier + angleOffset;
 
    rotate(initialAngle);

    input.addEventListener('input', (e) {
      InputElement input = e.target as InputElement;
      var newAngle = double.parse(input.value!) * multiplier + angleOffset;
      rotate(newAngle);
    });
  }
  setRotation('volume', 300);
}
