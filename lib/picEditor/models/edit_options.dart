import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:iris_pic_editor/picEditor/enums.dart';

class EditOptions {
  EditOptions.byPath(this.imagePath) : assert(imagePath != null);
  EditOptions.byBytes(this.imageBytes) : assert(imageBytes != null);

  String? imagePath;
  Uint8List? imageBytes;
  ui.Image? image;
  Color backgroundColor = Colors.black;
  Color iconsColor = Colors.white;
  Color cropBoxColor = Colors.white30;
  Color cropBoxCornerColor = Colors.grey[300]!;
  Size cropBoxInitSize = Size(130, 200);
  bool canResizeBox = true;
  bool fillBoxRect = true;
  bool showButtonText = true;
  bool hasResult = false;
  bool originalSizeChanged = false;
  double cropCornerSize = 12;
  double cropBoxLineSize = 2;
  OutFormat outFormat = OutFormat.JPG;
  int quality = 100;
  Function(EditOptions eo)? callOnResult;
  Function(EditOptions eo)? callOnCancel;
}