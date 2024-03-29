import 'dart:async';
import 'dart:math';

import 'package:sensors/sensors.dart';
import 'package:synchronized/synchronized.dart';

class Motion {
  final double x;
  final double y;
  final double z;
  final double mag;
  final int timestamp;

  Motion(this.timestamp, this.x, this.y, this.z, this.mag);

  @override
  String toString() => "Motion($x, $y, $z)";
}

class ShakeDetector extends Stream<Motion> {
  static ShakeDetector _instance;
  static Lock _lock = Lock();

  static Future<ShakeDetector> getInstance() async {
    if (_instance == null) {
      await _lock.synchronized(() async {
        if (_instance == null) {
          // keep local instance till it is fully initialized
          var newInstance = ShakeDetector._();
          await newInstance._init();
          _instance = newInstance;
        }
      });
    }
    return _instance;
  }

  ShakeDetector._();

  double _threshold = 5.0;
  double _prodThreshold = -25.0;
  static const _timeSpan = 800;
  static const _countPerShake = 3;

  Motion lastShake;

  int shakeTimestamp = 0;
  int shakeCount = 0;

  void setShakeThreshold(double value) {
    _threshold = value;
    _prodThreshold = -(value * value);
  }

  StreamSubscription<UserAccelerometerEvent> _listener;

  StreamController<Motion> _controller;

  Future _init() async {
    _listener = userAccelerometerEvents.listen(_handleEvent);
    _controller = StreamController<Motion>();
    reset();
  }

  void dispose() {
    stopCaptureSensor();
  }

  void startCaptureSensor() {
    if (_listener != null) {
      _listener.resume();
    } else {
      _listener = userAccelerometerEvents.listen(_handleEvent);
    }
  }

  void stopCaptureSensor() {
    if (_listener != null) {
      _listener.pause();
      _listener.cancel();
      _listener = null;
    }
  }

  void reset() {
    lastShake = null;
    shakeTimestamp = 0;
    shakeCount = 0;
  }

  void _handleEvent(UserAccelerometerEvent event) {
    Motion shake = detectShake(event);
    if (shake != null) {
      // print("Shake Detected:  $shake");
      if (lastShake != null) {
        final product = shake.x * lastShake.x +
            shake.y * lastShake.y +
            shake.z * lastShake.z;
        // final cos0 = product / (shake.mag * lastShake.mag);
        // print("product:  $product");

        if (product < _prodThreshold) {
          if (shake.timestamp - shakeTimestamp < _timeSpan) {
            shakeCount++;
          } else {
            shakeCount = 1;
          }
          shakeTimestamp = shake.timestamp;
        }
      }
      lastShake = shake;

      if (shakeCount >= _countPerShake) {
        if (!_controller.isPaused) {
          _controller.add(shake);
        }
        reset();
      }
    }
  }

  Motion detectShake(UserAccelerometerEvent accl) {
    final x = accl.x, y = accl.y, z = accl.z;

    Motion result;

    final magnitude = sqrt(x * x + y * y + z * z);
    if (magnitude > _threshold) {
      result =
          Motion(DateTime.now().millisecondsSinceEpoch, x, y, z, magnitude);
    }

    return result;
  }

  @override
  StreamSubscription<Motion> listen(void Function(Motion event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
