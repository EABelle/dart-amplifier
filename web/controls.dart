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
  double? value;

  VolumeControl(AudioContext context, String id, { defaultRotation: 300 }) {
    this.context = context;
    this.id = id;
    this.element = querySelector('#$id');
    this.value = 0.5;
    this.node = new GainNode(context, {'gain': this.value});
    this.element?.addEventListener('input', (e) {
      InputElement input = e.target as InputElement;
      this.value = double.parse(input.value!);
      this.node?.gain?.setTargetAtTime(
        this.value!,
        this.context!.currentTime!,
        0.01
      );
    });
    setRotation(id, defaultRotation);
  }

  GainNode? get getNode {
    return node;
  }

  Element? get getElement {
    return element;
  }

  double? get getValue {
    return value;
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

class MuteControl {

  AudioContext? context;
  GainNode? gainNode;
  Element? element;
  String? id;
  VolumeControl? volumeControl;

  bool muted = false;

  MuteControl(AudioContext context, String id, VolumeControl volumeControl) {
    this.context = context;
    this.volumeControl = volumeControl;
    this.gainNode = volumeControl.getNode;
    this.id = id;
    this.element = querySelector('#$id');
    this.element?.addEventListener('click', (e) {
      this.muted = !muted;
      if(this.muted) {
          this.gainNode?.gain?.setTargetAtTime(.0, this.context!.currentTime!, 0.01);
          this.element?.classes?.add('muted');
      } else {
          this.gainNode?.gain?.setTargetAtTime(this.volumeControl!.getValue!, this.context!.currentTime!, 0.01);
          this.element?.classes?.remove('muted');
      }
      print(this.muted);
    });
  }

  bool get getMuted {
    return muted;
  }

  void set setMuted(bool muted) {
    this.muted = muted;
  }
}
