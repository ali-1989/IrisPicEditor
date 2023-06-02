import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iris_pic_editor/picEditor/enums.dart';

class CropAreaTouchHandler {
  final CropArea cropArea;
  late Offset activeAreaDelta;
  late CropTouchCorner activeArea;

  CropAreaTouchHandler({required CropArea cropArea}) : cropArea = cropArea;

  void startTouch(Offset touchPosition) {
    activeArea = cropArea.getActionArea(touchPosition);
    activeAreaDelta = cropArea.getActionAreaDelta(touchPosition, activeArea);
  }

  void updateTouch(Offset touchPosition) {
    cropArea.moveOrResize(touchPosition, activeAreaDelta, activeArea);
  }

  void endTouch() {
    //activeArea = null;
    //activeAreaDelta = null;
  }
}
///==================================================================================================
class CropArea {
  double _sizeOfCornerTouch = 40;
  bool canResizeBox = true;
  late Rect imageBounds;
  Rect? _cropSquare;
  late Rect _topLeftCorner;
  late Rect _topRightCorner;
  late Rect _bottomRightCorner;
  late Rect _bottomLeftCorner;

  CropArea();

  Rect? get cropRect => _cropSquare;

  void invalidateRect(){
    _cropSquare = null;
  }

  void setValues({
    required Offset center,
    required double width,
    required double height,
    required Rect bounds,
    double? cornerTouchSize
  }) {
    if (cornerTouchSize != null) {
      _sizeOfCornerTouch = cornerTouchSize;
    }

    // bounds is image size
    imageBounds = bounds;
    //width & height set by user
    //center is center of imageDim
    _cropSquare = Rect.fromCenter(center: center, width: width, height: height);

    _updateCorners();
  }

  void _updateCorners() {
    _topLeftCorner = Rect.fromCenter(
      center: _cropSquare!.topLeft,
      width: _sizeOfCornerTouch,
      height: _sizeOfCornerTouch,
    );

    _topRightCorner = Rect.fromCenter(
      center: _cropSquare!.topRight,
      width: _sizeOfCornerTouch,
      height: _sizeOfCornerTouch,
    );

    _bottomRightCorner = Rect.fromCenter(
      center: _cropSquare!.bottomRight,
      width: _sizeOfCornerTouch,
      height: _sizeOfCornerTouch,
    );

    _bottomLeftCorner = Rect.fromCenter(
      center: _cropSquare!.bottomLeft,
      width: _sizeOfCornerTouch,
      height: _sizeOfCornerTouch,
    );
  }

  /*bool contains(Offset position) {
    return _cropRect.contains(position) ||
        _topLeftCorner.contains(position) ||
        _topRightCorner.contains(position) ||
        _bottomRightCorner.contains(position) ||
        _bottomLeftCorner.contains(position);
  }*/

  void moveArea(Offset newCenter) {
    final newRect = Rect.fromCenter(
      center: newCenter,
      width: _cropSquare!.width,
      height: _cropSquare!.height,
    );

    var offset = Offset(0.0, 0.0);

    if (newRect.left < imageBounds.left) {
      offset = offset.translate(imageBounds.left - newRect.left, 0.0);
    }

    if (newRect.top < imageBounds.top) {
      offset = offset.translate(0.0, imageBounds.top - newRect.top);
    }

    if (newRect.right > imageBounds.right) {
      offset = offset.translate(imageBounds.right - newRect.right, 0.0);
    }

    if (newRect.bottom > imageBounds.bottom) {
      offset = offset.translate(0.0, imageBounds.bottom - newRect.bottom);
    }

    _cropSquare = newRect.shift(offset);
    _updateCorners();
  }

  double _applyLeftBounds(double left) {
    var boundedLeft = max(left, imageBounds.left); // left bound
    boundedLeft = min(boundedLeft, _cropSquare!.right - _sizeOfCornerTouch); // right bound

    return boundedLeft;
  }

  double _applyTopBounds(double top) {
    var boundedTop = max(top, imageBounds.top); // top bound
    boundedTop = min(boundedTop, _cropSquare!.bottom - _sizeOfCornerTouch); // bottom bound

    return boundedTop;
  }

  double _applyRightBounds(double right) {
    var boundedRight = min(right, imageBounds.right); // right bound
    boundedRight = max(boundedRight, _cropSquare!.left + _sizeOfCornerTouch); // left bound

    return boundedRight;
  }

  double _applyBottomBounds(double bottom) {
    var boundedBottom = min(bottom, imageBounds.bottom); // bottom bound
    boundedBottom = max(boundedBottom, _cropSquare!.top + _sizeOfCornerTouch); // top bound

    return boundedBottom;
  }

  void moveTopLeftCorner(Offset newPosition) {
    _cropSquare = Rect.fromLTRB(
      _applyLeftBounds(newPosition.dx),
      _applyTopBounds(newPosition.dy),
      _cropSquare!.right,
      _cropSquare!.bottom,
    );

    _updateCorners();
  }

  void moveTopRightCorner(Offset newPosition) {
    _cropSquare = Rect.fromLTRB(
      _cropSquare!.left,
      _applyTopBounds(newPosition.dy),
      _applyRightBounds(newPosition.dx),
      _cropSquare!.bottom,
    );

    _updateCorners();
  }

  void moveBottomRightCorner(Offset newPosition) {
    _cropSquare = Rect.fromLTRB(
      _cropSquare!.left,
      _cropSquare!.top,
      _applyRightBounds(newPosition.dx),
      _applyBottomBounds(newPosition.dy),
    );

    _updateCorners();
  }

  void moveBottomLeftCorner(Offset newPosition) {
    _cropSquare = Rect.fromLTRB(
      _applyLeftBounds(newPosition.dx),
      _cropSquare!.top,
      _cropSquare!.right,
      _applyBottomBounds(newPosition.dy),
    );

    _updateCorners();
  }

  Offset _getTopLeftDelta(Offset position) {
    return _topLeftCorner.center - position;
  }

  Offset _getTopRightDelta(Offset position) {
    return _topRightCorner.center - position;
  }

  Offset _getBottomRightDelta(Offset position) {
    return _bottomRightCorner.center - position;
  }

  Offset _getBottomLeftDelta(Offset position) {
    return _bottomLeftCorner.center - position;
  }

  Offset _getCenterDelta(Offset position) {
    return _cropSquare!.center - position;
  }

  CropTouchCorner getActionArea(Offset position) {
    if (_topLeftCorner.contains(position)) {
      return CropTouchCorner.top_left;
    }

    if (_topRightCorner.contains(position)) {
      return CropTouchCorner.top_right;
    }

    if (_bottomLeftCorner.contains(position)) {
      return CropTouchCorner.bottom_left;
    }

    if (_bottomRightCorner.contains(position)) {
      return CropTouchCorner.bottom_right;
    }

    if (_cropSquare!.contains(position)) {
      return CropTouchCorner.center;
    }

    return CropTouchCorner.none;
  }

  Offset getActionAreaDelta(Offset position, CropTouchCorner activeArea) {
    switch (activeArea) {
      case CropTouchCorner.top_left:
        return _getTopLeftDelta(position);
      case CropTouchCorner.top_right:
        return _getTopRightDelta(position);
      case CropTouchCorner.bottom_right:
        return _getBottomRightDelta(position);
      case CropTouchCorner.bottom_left:
        return _getBottomLeftDelta(position);
      case CropTouchCorner.center:
        return _getCenterDelta(position);
      default:
        return Offset.zero;
    }
  }

  void moveOrResize(Offset position, Offset delta, CropTouchCorner actionArea) {
    if (!canResizeBox) {
      if (actionArea == CropTouchCorner.center) {
        moveArea(position + delta);
      }

      return;
    }

    switch (actionArea) {
      case CropTouchCorner.top_left:
        moveTopLeftCorner(position + delta);
        break;
      case CropTouchCorner.top_right:
        moveTopRightCorner(position + delta);
        break;
      case CropTouchCorner.bottom_right:
        moveBottomRightCorner(position + delta);
        break;
      case CropTouchCorner.bottom_left:
        moveBottomLeftCorner(position + delta);
        break;
      case CropTouchCorner.center:
        moveArea(position + delta);
        break;
      default:
    }
  }
}
