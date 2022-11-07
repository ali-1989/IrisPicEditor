import 'dart:async';

class FireOnLastCall {
  Function? actionFn;
  Function? firstStartFn;
  late Duration delay;
  Timer? timer;

  FireOnLastCall(Duration timeDelay, {this.actionFn, this.firstStartFn}) : delay = timeDelay;

  void changeDelay(Duration timeDelay) {
    delay = timeDelay;
  }

  void setFirstStartAction(Function onStartFn) {
    this.firstStartFn = onStartFn;
  }

  void setAction(Function doFn) {
    this.actionFn = doFn;
  }

  Timer? getTimer(){
    return timer;
  }

  void fire() {
    if (timer == null || !timer!.isActive){
      this.firstStartFn?.call();
    }

    timer?.cancel();

    timer = Timer(delay, () {
      this.actionFn?.call();
    });
  }

  void fireBy({Function? fn, Function? startFn}) {
    this.firstStartFn = startFn?? this.firstStartFn;
    this.actionFn = fn?? this.actionFn;

    fire();
  }
}
///================================================================================================
class OnceCallLimit {
  static Map<String, OnceCallLimit> _holder = {};
  Function? doFn;
  DateTime? _calledTime;
  late Duration delay;
  bool _isPurge = false;

  OnceCallLimit._init(this.delay, {this.doFn});

  factory OnceCallLimit(String name, Duration delay, {Function? doFn}){
    if(_holder.containsKey(name))
      return _holder[name]!;

    OnceCallLimit res = OnceCallLimit._init(delay, doFn: doFn);
    _holder[name] = res;

    return res;
  }

  void changeDelay(Duration delay) {
    this.delay = delay;
  }

  void setAction(Function doFn) {
    this.doFn ??= doFn;
  }

  void call() {
    if (_isPurge)
      throw Exception("this OnceCallLimit is purge.");

    if (_calledTime == null) {
      _calledTime = DateTime.now();
      this.doFn?.call();
      return;
    }

    if (_calledTime!.add(delay).isBefore(DateTime.now())) {
      this.doFn?.call();
      _calledTime = DateTime.now();
    }
  }

  void purge(){
    _holder.removeWhere((name, caller) => caller == this);
    this.doFn = null;
    _isPurge = true;
  }
}
///================================================================================================