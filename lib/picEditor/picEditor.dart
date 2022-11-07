import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:iris_pic_editor/picEditor/enums.dart';
import 'package:iris_pic_editor/picEditor/iconText.dart';
import 'package:iris_pic_editor/picEditor/models/edit_options.dart';

import 'package:flutter/material.dart';

import 'package:iris_pic_editor/picEditor/inOutParam.dart';
import 'package:iris_pic_editor/picEditor/models/editor_state.dart';
import 'package:iris_pic_editor/picEditor/state_manager.dart';
import 'package:iris_pic_editor/picEditor/panGestureRecognizer.dart';
import 'package:iris_pic_editor/picEditor/picEditorCtr.dart';
//import 'imageDraw.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';

///==================================================================================================
class PicEditor extends StatefulWidget {
  final EditOptions editOptions;

  PicEditor(this.editOptions);

  @override
  State<StatefulWidget> createState() {
    return PicEditorState();
  }

  static Future<Uint8List> readImageAsBytes(String filePath) async {
    File file = File(filePath);
    return file.readAsBytes();
  }

  static Uint8List readImageBytes(String filePath) {
    File file = File(filePath);
    return file.readAsBytesSync();
  }

  static Future<ui.Image> bytesToImage(
      Uint8List imgBytes, InOutParam? fnResult) async {
    ui.Codec codec = await ui.instantiateImageCodec(imgBytes);
    ui.FrameInfo frame = await codec.getNextFrame();

    bool isLandscape = frame.image.width >= frame.image.height;
    bool hasNormalSize = hasNormalDimension(
        Point(frame.image.width, frame.image.height), 1000, 800);

    fnResult?.originalSizeChanged = false;

    if (hasNormalSize)
      return frame.image;

    fnResult?.originalSizeChanged = true;
    Point<int> xy = getScaledDimensionByRate(
        Point<int>(frame.image.width, frame.image.height),
        Point<int>(1000, 800));

    if (!isLandscape)
      xy = getScaledDimensionByRate(
          Point<int>(frame.image.width, frame.image.height),
          Point<int>(800, 1000));

    codec = await ui.instantiateImageCodec(imgBytes,
        targetWidth: xy.x, targetHeight: xy.y);
    frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<Uint8List> imageToPngBytes(ui.Image img) async {
    ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static bool hasNormalDimension(
      Point imageSize, int maxWinLandscape, int maxHinLandscape) {
    bool isLandscape = imageSize.x >= imageSize.y;
    return isLandscape
        ? (imageSize.x <= maxWinLandscape && imageSize.y <= maxHinLandscape)
        : (imageSize.x <= maxHinLandscape && imageSize.y <= maxWinLandscape);
  }

  static Point<int> getScaledDimension(
      Point<int> imgSize, Point<int> boundary) {
    int originalWidth = imgSize.x;
    int originalHeight = imgSize.y;
    int boundWidth = boundary.x;
    int boundHeight = boundary.y;
    int newWidth = originalWidth;
    int newHeight = originalHeight;

    if (originalWidth > boundWidth) {
      newWidth = boundWidth;
      newHeight = ((newWidth * originalHeight) ~/ originalWidth);
    }

    // then check if we need to scale even with the new height
    if (newHeight > boundHeight) {
      newHeight = boundHeight;
      newWidth = ((newHeight * originalWidth) ~/ originalHeight);
    }

    return new Point<int>(newWidth, newHeight);
  }

  static Point<int> getScaledDimensionByRate(
      Point<int> imageSize, Point<int> boundary) {
    double widthRatio = boundary.x / imageSize.x;
    double heightRatio = boundary.y / imageSize.y;
    double ratio = min(widthRatio, heightRatio);

    return Point<int>(
        (imageSize.x * ratio).toInt(), (imageSize.y * ratio).toInt());
  }
}
///==================================================================================================
class PicEditorState extends State<PicEditor> {
  var stateController = StateManagerController();
  var controller = PicEditorCtr();
  late ThemeData theme;
  late SliderThemeData sliderTheme;
  var toolbarRefreshKey = 'toolBarRefresher';
  var progressRefresherKey = 'progressRefresher';
  var imageRefresherKey = 'imageHolderRefresher';


  PicEditorState();

  @override
  void initState() {
    super.initState();
    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    controller.onBuild();

    theme = Theme.of(context);
    sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 4.0,
      trackShape: RectangularSliderTrackShape(),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 25.0),
      tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 1.5),
      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
      thumbColor: theme.primaryColor,
      overlayColor: theme.primaryColor,
      activeTrackColor: theme.primaryColor,
      inactiveTrackColor: theme.primaryColor,
      activeTickMarkColor: theme.colorScheme.secondary,
      inactiveTickMarkColor: theme.colorScheme.secondary,
      valueIndicatorColor: theme.primaryColor,
      showValueIndicator: ShowValueIndicator.always,
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
      ),
    );

    return StateManager(
      isMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        return Scaffold(
          appBar: getAppbar(),
          body: getBody(),
          bottomNavigationBar: getNavBar(),
        );
      }
    );
  }

  @override
  void dispose() {
    controller.onDispose();
    stateController.dispose();

    super.dispose();
  }

  void update() {
    setState(() {});
  }

  PreferredSizeWidget getAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      actions: <Widget>[
        Material(
          clipBehavior: Clip.antiAlias,
          type: MaterialType.circle,
          color: Colors.transparent,
          child: IconButton(
            iconSize: 20,
            onPressed: () {
              controller.editOptions.hasResult = false;
              Navigator.of(context).pop();
              controller.editOptions.callOnCancel?.call(controller.editOptions);
            },
            splashColor: Colors.white,
            icon: Icon(
              Icons.clear,
              color: theme.appBarTheme.iconTheme!.color,
            ),
          ),
        ),
        VerticalDivider(
          indent: 8,
          endIndent: 8,
        ),
        Material(
          clipBehavior: Clip.antiAlias,
          type: MaterialType.circle,
          color: Colors.transparent,
          child: IconButton(
            iconSize: 20,
            onPressed: () {
              controller.editOptions.hasResult = true;
              Navigator.of(context).pop();
              controller.editOptions.callOnResult?.call(controller.editOptions);
            },
            splashColor: Colors.white,
            icon: Icon(
              Icons.check,
              color: theme.appBarTheme.iconTheme!.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget getNavBar() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ColoredBox(
        color: theme.appBarTheme.backgroundColor!,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: false,
              children: <Widget>[
                generateNavBarButton(
                    Icons.crop,
                    EditorActions.CROP,
                    controller.cropAction
                ),
                generateNavBarButton(
                    Icons.rotate_right,
                    EditorActions.ROTATE,
                    controller.rotateAction
                ),
                generateNavBarButton(
                    Icons.flip,
                    EditorActions.FLIP,
                    controller.flipAction
                ),
                generateNavBarButton(
                    Icons.brightness_7,
                    EditorActions.BRIGHTNESS,
                    controller.brightnessAction
                ),
                generateNavBarButton(
                    Icons.brightness_6,
                    EditorActions.CONTRAST,
                    controller.contrastAction
                ),
                generateNavBarButton(
                    Icons.color_lens,
                    EditorActions.COLOR,
                    controller.colorAction
                ),
                //getActionBtnView(state, FontAwesomeIcons.brush, currentAction, Actions.DRAW, (){drawAction(state);}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getBody() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ///--- background
        Positioned.fill(
            child: ColoredBox(
          color: controller.editOptions.backgroundColor,
          ),
        ),

        ///--- src image
        Positioned.fill(
          child: StateManager(
            id: imageRefresherKey,
            controller: stateController,
            builder: (ctx, ctr, data) {
              if (controller.mustShowLoadingProgress)
                return Center(
                    child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator()
                    )
                );

              return CustomPaint(
                painter: _ImagePainter(controller.editorState),
                foregroundPainter: controller.currentAction == EditorActions.CROP
                    ? _CropBoxPainter(controller.editorState)
                    : null,
                child: Builder(
                  builder: (ctx) {
                    if (controller.currentAction != EditorActions.CROP) {
                      return SizedBox();
                    }

                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      controller.renderBox = ctx.findRenderObject() as RenderBox;
                    });

                    return RawGestureDetector(
                      gestures: {
                        PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                          () => PanGestureRecognizer(
                            onPanStart: controller.onPanUpdate,
                            onPanMove: controller.onPanUpdate,
                            onPanEnd: controller.onPanEnd,
                          ),
                          (recognizer) {},
                        )
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),

        ///---- tools
        Positioned(
          bottom: 40,
          left: 18,
          right: 18,
          height: 60,
          child: StateManager(
            id: toolbarRefreshKey,
            controller: stateController,
            builder: (ctx, ctr, data) {
              switch (controller.currentAction) {
                case EditorActions.CROP:
                  return Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Material(
                            clipBehavior: Clip.antiAlias,
                            shape: CircleBorder(),
                            color: theme.backgroundColor,
                            type: MaterialType.button,
                            child: InkWell(
                                onTap: () {
                                  controller.cropImage();
                                },
                                splashColor: Colors.white,
                                child: Icon(
                                  Icons.crop,
                                ))),
                      ));

                ///---- ROTATE
                case EditorActions.ROTATE:
                  return Align(
                      alignment: Alignment.bottomRight,
                      child: Wrap(children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.rotateToRight();
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.rotate_right,
                                  ))),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.rotateToLeft();
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.rotate_left,
                                  ))),
                        ),
                      ]));

                ///---- FLIP
                case EditorActions.FLIP:
                  return Align(
                      alignment: Alignment.bottomRight,
                      child: Wrap(children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.flipHImage();
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.flip,
                                  ))),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.flipVImage();
                                  },
                                  splashColor: Colors.white,
                                  child: Transform.rotate(
                                      angle: 1.58,
                                      child: Icon(
                                        Icons.flip,
                                      )))),
                        ),
                      ]));

                ///---- BRIGHTNESS
                case EditorActions.BRIGHTNESS:
                  return Align(
                      alignment: Alignment.bottomCenter,
                      child: Wrap(children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.brightnessValue += 0.3;
                                    controller.brightnessActionT.setFirstStartAction(() {
                                      controller.showProgress();
                                    });
                                    controller.brightnessActionT.fireBy(fn: () {
                                      controller.addBrightness();
                                    });
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                  ))),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.brightnessValue += 0.1;
                                    controller.brightnessActionT.setFirstStartAction(() {
                                      controller.showProgress();
                                    });
                                    controller.brightnessActionT.fireBy(fn: () {
                                      controller.minusBrightness();
                                    });
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.remove,
                                  ))),
                        ),
                      ]));

                ///---- CONTRAST
                case EditorActions.CONTRAST:
                  return Align(
                      alignment: Alignment.bottomCenter,
                      child: Wrap(children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.contrastValue += 0.3;
                                    controller.contrastActionT.setFirstStartAction(() {
                                      controller.showProgress();
                                    });
                                    controller.contrastActionT.fireBy(fn: () {
                                      controller.addContrast();
                                    });
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                  ))),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.contrastValue += 0.1;
                                    controller.contrastActionT.setFirstStartAction(() {
                                      controller.showProgress();
                                    });
                                    controller.contrastActionT.fireBy(fn: () {
                                      controller.minusContrast();
                                    });
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.remove,
                                  ))),
                        ),
                      ]));

                ///---- COLOR
                case EditorActions.COLOR:
                  return Align(
                      alignment: Alignment.bottomCenter,
                      child: Wrap(children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.colorValue += 0.3;
                                    controller.colorActionT.setFirstStartAction(() {
                                      controller.showProgress();
                                    });
                                    controller..colorActionT.fireBy(fn: () {
                                      controller.addColor();
                                    });
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                  ))),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                              clipBehavior: Clip.antiAlias,
                              shape: CircleBorder(),
                              color: theme.backgroundColor,
                              type: MaterialType.button,
                              child: InkWell(
                                  onTap: () {
                                    controller.colorValue += 0.1;
                                    controller.colorActionT.setFirstStartAction(() {
                                      controller.showProgress();
                                    });
                                    controller.colorActionT.fireBy(fn: () {
                                      controller.minusColor();
                                    });
                                  },
                                  splashColor: Colors.white,
                                  child: Icon(
                                    Icons.remove,
                                  ))),
                        ),
                      ]));

                ///---- DRAW
                case EditorActions.DRAW:
                  /*Timer(Duration(milliseconds: 500), () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return ImageDraw(
                        appBarColor: Colors.blue,
                        bottomBarColor: Colors.blue,
                      );
                    }));
                  });*/
                  return SizedBox();
              }
            },
          ),
        ),

        ///---- progress
        Positioned.fill(
          child: StateManager(
            id: progressRefresherKey,
            controller: stateController,
            builder: (ctx, ctr, data) {
              if (controller.mustShowOperationProgress)
                return Center(
                    child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator())
                );

              return SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget generateNavBarButton(
      IconData icon,
      EditorActions actions,
      Function() action
      ) {
    bool isActive = controller.currentAction == actions;
    Color color = controller.editOptions.iconsColor;

    if (controller.isNearHue(theme.appBarTheme.backgroundColor!, color)) {
      color = controller.inverseColor(color);
    }

    color = isActive ? color : color.withAlpha(130);

    return IconTextBtn(
        width: 50,
        backColor: theme.appBarTheme.backgroundColor!,
        textColor: color,
        iconColor: color,
        icon: icon,
        title: controller.editOptions.showButtonText
            ? actions.toString().replaceFirst(RegExp(r'EditorActions.'), '').substring(0, 4)
            : " ",
        onTap: action);
  }
}
///==================================================================================================
class _ImagePainter extends CustomPainter {
  final EditorState editorState;

  _ImagePainter(this.editorState);

  @override
  void paint(ui.Canvas canvas, ui.Size paintSize) {
    editorState.editorSize = paintSize;

    Rect displayRect = Rect.fromLTWH(0.0, 0.0, paintSize.width, paintSize.height);

    paintImage(
      canvas: canvas,
      image: editorState.editOptions.image!,
      rect: displayRect,
      fit: BoxFit.contain,
    );

    editorState.imageSize = Size(
      editorState.editOptions.image!.width.toDouble(),
      editorState.editOptions.image!.height.toDouble(),
    );

    editorState.fittedImageSize = applyBoxFit(
      BoxFit.contain,
      editorState.imageSize,
      paintSize,
    );

    editorState.horizontalGap = (paintSize.width - editorState.fittedImageSize.destination.width) / 2;
    editorState.verticalGap = (paintSize.height - editorState.fittedImageSize.destination.height) / 2;
    editorState.imageContainingRect = Rect.fromLTWH(
        editorState.horizontalGap,
        editorState.verticalGap,
        editorState.fittedImageSize.destination.width,
        editorState.fittedImageSize.destination.height);
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    //return editState.editOptions._image != oldDelegate.editState.editOptions._image; both reference to one
    return true;
  }
}
///==================================================================================================
class _CropBoxPainter extends CustomPainter {
  final EditorState editorState;
  final paintCorner = Paint();
  final paintBox = Paint();

  _CropBoxPainter(this.editorState) {
    paintCorner.strokeWidth = editorState.editOptions.cropCornerSize;
    paintCorner.strokeCap = StrokeCap.round;
    paintCorner.color = editorState.editOptions.cropBoxCornerColor;

    paintBox.color = editorState.editOptions.cropBoxColor;
    paintBox.strokeWidth = editorState.editOptions.cropBoxLineSize;

    if (!editorState.editOptions.fillBoxRect) {
      paintBox.style = PaintingStyle.stroke;
    }
  }

  @override
  void paint(Canvas canvas, Size paintSize) {
    if (editorState.cropArea.cropRect == null) {
      editorState.cropArea.setValues(
        bounds: editorState.imageContainingRect,
        center: Offset(paintSize.width / 2, paintSize.height / 2),
        width: min(editorState.editOptions.cropBoxInitSize.width, // cropBoxInitSize.width: user width
            editorState.imageContainingRect.width),
        height: min(editorState.editOptions.cropBoxInitSize.height,
            editorState.imageContainingRect.height),
      );
    }

    canvas.drawRect(editorState.cropArea.cropRect!, paintBox);

    final points = <Offset>[
      editorState.cropArea.cropRect!.topLeft,
      editorState.cropArea.cropRect!.topRight,
      editorState.cropArea.cropRect!.bottomLeft,
      editorState.cropArea.cropRect!.bottomRight
    ];

    canvas.drawPoints(ui.PointMode.points, points, paintCorner);
  }

  @override
  bool shouldRepaint(_CropBoxPainter oldDelegate) {
    return editorState.cropArea != oldDelegate.editorState.cropArea;
  }
}
