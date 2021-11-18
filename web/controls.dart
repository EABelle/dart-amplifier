import 'dart:html';
import 'dart:web_audio';
import 'dart:typed_data';
import 'dart:math';

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

void setRotation(String id, double multiplier, { int angleOffset = 0 }) {
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

class VolumeControl {
  Element? element;
  GainNode? node;
  AudioContext? context;
  String? id;
  VolumeControl(AudioContext context, String id, { defaultRotation: 300 }) {
    this.context = context;
    this.id = id;
    this.element = querySelector('#$id');
    this.node = new GainNode(context, {'gain': this.element?.nodeValue});
    this.element?.addEventListener('input', (e) {
      InputElement input = e.target as InputElement;
      this.node?.gain?.setTargetAtTime(double.parse(input.value!), this.context!.currentTime!, 0.01);
    });
    setRotation(id, defaultRotation);
  }
}

class OverdriveControl {
  Element? element;
  WaveShaperNode? node;
  AudioContext? context;
  String? id;
  OverdriveControl(AudioContext context, String id, { defaultRotation: 15 }) {
    this.context = context;
    this.id = id;
    this.element = querySelector('#$id');
    String overdriveValue = '0';
    if (this.element?.nodeValue != null) {
      overdriveValue = this.element?.nodeValue as String;
    }
    this.node = new WaveShaperNode(context, {
      'curve': makeOverdriveCurve(double.parse(overdriveValue) * 10),
      'oversample': '4x'
    });
    this.element?.addEventListener('input', (e) {
      InputElement input = e.target as InputElement;
      double value = double.parse(input.value!) * 5;
      this.node?.curve = makeOverdriveCurve(value);
    });
    setRotation(id, defaultRotation);
  }
}

class EQControl {
  Element? element;
  BiquadFilterNode? node;
  AudioContext? context;
  String? id;
  EQControl(AudioContext context, String id, Map filterOptions, { angleOffset: 150, defaultRotation: 15 }) {
    this.context = context;
    this.id = id;
    this.element = querySelector('#$id');
    filterOptions['gain'] = this.element?.nodeValue;
    this.node = new BiquadFilterNode(context, filterOptions);
    this.element?.addEventListener('input', (e) {
      InputElement input = e.target as InputElement;
      this.node?.gain?.setTargetAtTime(double.parse(input.value!), this.context!.currentTime!, 0.01);
    });
    setRotation(id, defaultRotation, angleOffset: angleOffset);
  }
}


/*
Element getMuteButton(AudioContext context, GainNode gainNode, Element volumeControl) {
  Element muteButton = querySelector('#mute')!;
  bool muted = false;
  muteButton.addEventListener('click', () {
    muted = !muted;
    if(muted) {
        gainNode.gain.setTargetAtTime(.0, context.currentTime, 0.01);
        muteButton.classList.add('muted');
    } else {
        gainNode.gain.setTargetAtTime(parseFloat(volume.value), context.currentTime, 0.01);
        muteButton.classList.remove('muted');
    }
  });
  return muteButton;
}
*/