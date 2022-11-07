import 'package:flutter/gestures.dart';

typedef OnPanStart = Function(PointerEvent);
typedef OnPanMove = Function(PointerEvent);
typedef OnPanEnd = Function(PointerEvent);

class PanGestureRecognizer extends OneSequenceGestureRecognizer {
  final OnPanStart onPanStart;
  final OnPanMove onPanMove;
  final OnPanEnd onPanEnd;

  PanGestureRecognizer({required this.onPanStart, required this.onPanMove, required this.onPanEnd});

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      onPanStart(event);
    }
    else if (event is PointerMoveEvent) {
      onPanMove(event);
    }
    else if (event is PointerUpEvent) {
      onPanEnd(event);
      stopTrackingPointer(event.pointer);
    }
  }

 @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'PicEdit_PanGestureRecognizer';
}