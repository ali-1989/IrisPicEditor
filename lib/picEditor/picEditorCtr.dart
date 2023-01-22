import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iris_pic_editor/picEditor/croper.dart';
import 'package:iris_pic_editor/picEditor/inOutParam.dart';
import 'package:iris_pic_editor/picEditor/lazyCallAction.dart';
import 'package:iris_pic_editor/picEditor/models/edit_options.dart';
import 'package:iris_pic_editor/picEditor/models/editor_state.dart';
import 'package:iris_pic_editor/picEditor/picEditor.dart';
import 'package:iris_pic_editor/picEditor/enums.dart';
import 'package:image_editor/image_editor.dart';

class PicEditorCtr {
  late PicEditorState state;
  late EditOptions editOptions;
  late EditorState editorState;
  EditorActions currentAction = EditorActions.CROP;
  late OutputFormat outputFormat;
  RenderBox? renderBox;
  double brightnessValue = 0.0;
  double contrastValue = 0.0;
  double colorValue = 0.0;
  bool mustShowLoadingProgress = true;
  bool mustShowOperationProgress = false;
  late FireOnLastCall brightnessActionT;
  late FireOnLastCall contrastActionT;
  late FireOnLastCall colorActionT;

  PicEditorCtr();

  void onInitState(State s){
    state = s as PicEditorState;

    editOptions = state.widget.editOptions;

    brightnessActionT = FireOnLastCall(Duration(milliseconds: 800));
    contrastActionT = FireOnLastCall(Duration(milliseconds: 800));
    colorActionT = FireOnLastCall(Duration(milliseconds: 800));

    editorState = EditorState();
    editorState.editOptions = editOptions;
    editorState.cropArea = CropArea();
    editorState.cropAreaTouchHandler = CropAreaTouchHandler(cropArea: editorState.cropArea);
    editorState.cropArea.canResizeBox = editOptions.canResizeBox;

    if (editOptions.outFormat == OutFormat.PNG)
      outputFormat = OutputFormat.png(editOptions.quality);
    else
      outputFormat = OutputFormat.jpeg(editOptions.quality);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      //renderBox = state.context.findRenderObject() as RenderBox;
      InOutParam outer = InOutParam();

      if (editOptions.imageBytes == null) {
        editOptions.imageBytes = PicEditor.readImageBytes(editOptions.imagePath!);
      }

      editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, outer);
      editOptions.originalSizeChanged = outer.originalSizeChanged!;

      if (editOptions.originalSizeChanged) {
        editOptions.imageBytes = await PicEditor.imageToPngBytes(editOptions.image!);
      }

      mustShowLoadingProgress = false;
      state.stateController.updateHead();
    });
  }

  void onBuild(){
    editorState.cropArea.canResizeBox = editOptions.canResizeBox;
  }

  void onDispose(){}

  void onPanUpdate(PointerEvent event) {
    editorState.oldTouchPosition = editorState.currentTouchPosition;
    editorState.currentTouchPosition = renderBox!.globalToLocal(event.position);

    if (editorState.oldTouchPosition == null) {
      editorState.cropAreaTouchHandler.startTouch(editorState.currentTouchPosition!);
    }
    else {
      editorState.cropAreaTouchHandler.updateTouch(editorState.currentTouchPosition!);
    }

    state.stateController.updateHead();
  }

  void onPanEnd(PointerEvent event) {
    editorState.oldTouchPosition = null;
    editorState.currentTouchPosition = null;

    state.stateController.updateHead();
  }

  void showProgress() {
    mustShowOperationProgress = true;
    state.stateController.updateGroup(state.id$state$progress);
  }

  bool canSelectOperator() {
    return editOptions.imageBytes != null &&
        !mustShowLoadingProgress && !mustShowOperationProgress;
  }

  num cleanValue(num val, num limit) {
    return min(limit, max(-limit, val));
  }
  ///==================================================================================================
  void cropAction() async {
    if (!canSelectOperator())
      return;

    currentAction = EditorActions.CROP;
    state.stateController.updateHead();
  }

  void cropImage() async {
    if (!canSelectOperator())
      return;

    mustShowOperationProgress = true;
    state.stateController.updateAssist(state.id$state$progress);

    Rect rect = getCropRect();

    ImageEditorOption option = ImageEditorOption();
    option.addOption(ClipOption.fromRect(rect));
    option.outputFormat = outputFormat;

    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, InOutParam());

    /// for prepare crop square again
    editorState.cropArea.invalidateRect();

    mustShowOperationProgress = false;
    state.stateController.updateHead();
  }

  Rect getCropRect() {
    //Future<ui.Image>
    final yOffset = (editorState.editorSize.height -
        editorState.fittedImageSize.destination.height) /
        2.0;
    final xOffset = (editorState.editorSize.width -
        editorState.fittedImageSize.destination.width) /
        2.0;
    final fittedCropRect = Rect.fromCenter(
      center: Offset(
        editorState.cropArea.cropRect!.center.dx - xOffset,
        editorState.cropArea.cropRect!.center.dy - yOffset,
      ),
      width: editorState.cropArea.cropRect!.width,
      height: editorState.cropArea.cropRect!.height,
    );

    final scale =
        editorState.imageSize.width / editorState.fittedImageSize.destination.width;
    final imageCropRect = Rect.fromLTRB(
        fittedCropRect.left * scale,
        fittedCropRect.top * scale,
        fittedCropRect.right * scale,
        fittedCropRect.bottom * scale);

    return imageCropRect;
    /*final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawImage(_editState.editOptions._image, Offset(-imageCropRect.left, -imageCropRect.top), Paint(),);

  final picture = recorder.endRecording();
  final croppedImage = await picture.toImage(imageCropRect.width.toInt(), imageCropRect.height.toInt(),);

  picture.dispose();

  return croppedImage;*/
  }
  ///==================================================================================================
  void rotateAction() async {
    if (!canSelectOperator()) {
      return;
    }

    currentAction = EditorActions.ROTATE;
    //state.stateController.updateHead();
  }

  void rotateToRight() async {
    if (!canSelectOperator()) {
      return;
    }

    mustShowOperationProgress = true;
    state.stateController.updateGroup(state.id$state$progress);

    ImageEditorOption option = ImageEditorOption();
    option.addOption(RotateOption(90));
    option.outputFormat = outputFormat;

    //editOptions.imageBytes = await ImageEditor.editImage(image: editOptions.imageBytes!, imageEditorOption: option);
    //editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    /*state.editOptions._image = await ImageHelper.rotateByCanvas(state.editOptions._image, 90);
  state.editOptions.imageBytes = await PicEditorState.imageToBytes(state.editOptions._image);*/

    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }

  void rotateToLeft() async {
    if (!canSelectOperator())
      return;

    mustShowOperationProgress = true;
    state.stateController.updateGroup(state.id$state$progress);

    ImageEditorOption option = ImageEditorOption();
    option.addOption(RotateOption(-90));
    option.outputFormat = outputFormat;

    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }
  ///==================================================================================================
  void flipAction() async {
    if (!canSelectOperator())
      return;

    currentAction = EditorActions.FLIP;
    state.stateController.updateHead();
  }

  void flipHImage() async {
    if (!canSelectOperator())
      return;

    mustShowOperationProgress = true;
    state.stateController.updateGroup(state.id$state$progress);

    ImageEditorOption option = ImageEditorOption();
    option.addOption(FlipOption(horizontal: true, vertical: false));
    option.outputFormat = outputFormat;

    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }

  void flipVImage() async {
    if (!canSelectOperator())
      return;

    mustShowOperationProgress = true;
    state.stateController.updateGroup(state.id$state$progress);

    ImageEditorOption option = ImageEditorOption();
    option.addOption(FlipOption(vertical: true, horizontal: false));
    option.outputFormat = outputFormat;

    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }
  ///==================================================================================================
  void brightnessAction() async {
    if (!canSelectOperator())
      return;

    currentAction = EditorActions.BRIGHTNESS;
    state.stateController.updateHead();
  }

  void addBrightness() async {
    ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(1 + brightnessValue));
    option.addOption(ColorOption.contrast(1));
    option.addOption(ColorOption.saturation(1));
    option.outputFormat = outputFormat;
    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    brightnessValue = 0;
    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }

  void minusBrightness() async {
    ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(1 - brightnessValue));
    option.addOption(ColorOption.contrast(1));
    option.addOption(ColorOption.saturation(1));
    option.outputFormat = outputFormat;
    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image =
    await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    brightnessValue = 0;
    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }
  ///==================================================================================================
  void contrastAction() async {
    if (!canSelectOperator())
      return;

    currentAction = EditorActions.CONTRAST;
    state.stateController.updateHead();
  }

  void addContrast() async {
    ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(1));
    option.addOption(ColorOption.contrast(1 + contrastValue));
    option.addOption(ColorOption.saturation(1));
    option.outputFormat = outputFormat;
    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    contrastValue = 0;
    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }

  void minusContrast() async {
    ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(1));
    option.addOption(ColorOption.contrast(1 - contrastValue));
    option.addOption(ColorOption.saturation(1));
    option.outputFormat = outputFormat;
    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    contrastValue = 0;
    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }
  ///==================================================================================================
  void colorAction() async {
    if (!canSelectOperator())
      return;

    currentAction = EditorActions.COLOR;
    state.stateController.updateHead();
  }

  void addColor() async {
    ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(1));
    option.addOption(ColorOption.contrast(1));
    option.addOption(ColorOption.saturation(1 + colorValue));
    option.outputFormat = outputFormat;
    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image =
    await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    colorValue = 0;
    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }

  void minusColor() async {
    ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(1));
    option.addOption(ColorOption.contrast(1));
    option.addOption(ColorOption.saturation(1 - colorValue));
    option.outputFormat = outputFormat;
    editOptions.imageBytes = await ImageEditor.editImage(
        image: editOptions.imageBytes!, imageEditorOption: option);
    editOptions.image = await PicEditor.bytesToImage(editOptions.imageBytes!, null);

    colorValue = 0;
    mustShowOperationProgress = false;
    state.stateController.updateGroup(state.id$state$progress);
  }
  ///==================================================================================================
  void drawAction(PicEditorState state) async {
    if (!canSelectOperator())
      return;

    currentAction = EditorActions.DRAW;
    state.stateController.updateHead();
  }
  ///==================================================================================================
  bool isNearHue(Color base, Color dif, {num deg = 10}) {
    HSLColor baseHsl = HSLColor.fromColor(base);
    HSLColor difHsl = HSLColor.fromColor(dif);

    if (deg > 250) deg = 250;

    bool wb = baseHsl.hue < 5.0 && difHsl.hue < 5.0;

    if (!wb) {
      num hueDif = (baseHsl.hue - difHsl.hue).abs();
      return hueDif < deg;
    }

    num briDif = (baseHsl.lightness - difHsl.lightness).abs();
    return briDif < 0.45;
  }

  Color inverseColor(Color color) {
    int newR = 255 - color.red;
    int newG = 255 - color.green;
    int newB = 255 - color.blue;

    return Color.fromARGB(color.alpha, newR, newG, newB);
  }
}