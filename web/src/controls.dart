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

abstract class AmpControl {

  Element? element;
  String? id;
  AudioContext? context;
  dynamic? node;
  double? value;

  void set setElement(Element element) {
    this.element = element;
  }
  void addEventListener(String event, dynamic Function(Event) callback) {
    this.element?.addEventListener(event, callback);
  }
}

class VolumeControl extends AmpControl {

  VolumeControl(AudioContext context, String id, { defaultRotation: 300 }) {
    this.context = context;
    this.id = id;
    this.element = querySelector('#$id');
    this.value = 0;
    this.node = new GainNode(context, {'gain': this.value});
    this.element?.addEventListener('input', (e) {
      InputElement input = e.target as InputElement;
      this.value = double.parse(input.value!);
      this.node?.gain?.setTargetAtTime(
        this.value!,
        this.context!.currentTime!,
        0.01
      );
      if (this.context!.state == 'suspended') {
        context.resume();
      }
    });
    setRotation(id, defaultRotation);
  }
}

class OverdriveControl extends AmpControl {

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

class EQControl extends AmpControl {

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

class MuteControl extends AmpControl {

  GainNode? gainNode;
  VolumeControl? volumeControl;
  bool muted = false;

  MuteControl(AudioContext context, String id, VolumeControl volumeControl) {
    this.context = context;
    this.volumeControl = volumeControl;
    this.gainNode = volumeControl.node;
    this.id = id;
    this.element = querySelector('#$id');
    this.element?.addEventListener('click', (e) {
      this.muted = !muted;
      if(this.muted) {
          this.gainNode?.gain?.setTargetAtTime(.0, this.context!.currentTime!, 0.01);
          this.element?.classes?.add('muted');
      } else {
          this.gainNode?.gain?.setTargetAtTime(this.volumeControl!.value!, this.context!.currentTime!, 0.01);
          this.element?.classes?.remove('muted');
      }
    });
  }
}
