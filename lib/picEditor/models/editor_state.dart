import 'package:flutter/material.dart';
import 'package:iris_pic_editor/picEditor/croper.dart';
import 'package:iris_pic_editor/picEditor/models/edit_options.dart';

class EditorState {
  late EditOptions editOptions;
  late FittedSizes fittedImageSize;
  late CropArea cropArea;
  late CropAreaTouchHandler cropAreaTouchHandler;
  late Rect imageContainingRect;
  Offset? currentTouchPosition;
  Offset? oldTouchPosition;
  Size editorSize = Size.zero;
  Size imageSize = Size.zero;
  double horizontalGap = 0;
  double verticalGap = 0;
}