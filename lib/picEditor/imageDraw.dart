/*
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_pro/modules/all_emojies.dart';
import 'package:image_editor_pro/modules/bottombar_container.dart';
import 'package:image_editor_pro/modules/colors_picker.dart';
import 'package:image_editor_pro/modules/emoji.dart';
import 'package:image_editor_pro/modules/text.dart';
import 'package:image_editor_pro/modules/textview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:signature/signature.dart';

TextEditingController heightController = TextEditingController();
TextEditingController widthController = TextEditingController();
SignatureController _signatureController = SignatureController(penStrokeWidth: 5, penColor: Colors.green);
num width = 300;
num height = 300;
num widgetsCount = 0;
num opacity = 0.0;
num slider = 0.0;
List fontSizes = [];
List multiWidgets = [];
Color currentColor = Colors.deepOrange;

class ImageDraw extends StatefulWidget {
  final Color appBarColor;
  final Color bottomBarColor;

  ImageDraw({this.appBarColor, this.bottomBarColor});

  @override
  _ImageDrawState createState() => _ImageDrawState();
}
///--------------------------------------------------------------------------------------------------------------
class _ImageDrawState extends State<ImageDraw> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey containerKey = GlobalKey();
  final GlobalKey repaintKey = new GlobalKey();
  ScreenshotController screenshotController = ScreenshotController();
  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);
  List<Offset> offsets = [];
  Offset offset1 = Offset.zero;
  Offset offset2 = Offset.zero;
  bool isBottomSheetOpen = false;
  List<Offset> _points = <Offset>[];
  List types = [];
  List alignments = [];
  File _image;
  Timer updateTimer;

  @override
  void initState() {
    super.initState();

    startUpdateTimer();
    _signatureController.clear();
    types.clear();
    fontSizes.clear();
    offsets.clear();
    multiWidgets.clear();
    widgetsCount = 0;
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
    var points = _signatureController.points;
    _signatureController = SignatureController(penStrokeWidth: 5, penColor: color, points: points);
  }

  void startUpdateTimer() {
    Timer.periodic(Duration(milliseconds: 10), (tim) {
      setState(() {});
      updateTimer = tim;
    });
  }

  @override
  void dispose() {
    updateTimer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey,
        key: scaffoldKey,
        appBar: new AppBar(
          actions: <Widget>[
            new IconButton(
                icon: Icon(FontAwesomeIcons.boxes),
                onPressed: () {
                  showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: new Text("Select Height Width"),
                          actions: <Widget>[
                            FlatButton(
                                onPressed: () {
                                  setState(() {
                                    height = int.parse(heightController.text);
                                    width = int.parse(widthController.text);
                                  });
                                  heightController.clear();
                                  widthController.clear();
                                  Navigator.pop(context);
                                },
                                child: new Text("Done"))
                          ],
                          content: new SingleChildScrollView(
                            child: new Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Text("Define Height"),
                                new SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    controller: heightController,
                                    keyboardType:
                                    TextInputType.numberWithOptions(),
                                    decoration: InputDecoration(
                                        hintText: 'Height',
                                        contentPadding:
                                        EdgeInsets.only(left: 10),
                                        border: OutlineInputBorder())),
                                new SizedBox(
                                  height: 10,
                                ),
                                new Text("Define Width"),
                                new SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    controller: widthController,
                                    keyboardType:
                                    TextInputType.numberWithOptions(),
                                    decoration: InputDecoration(
                                        hintText: 'Width',
                                        contentPadding:
                                        EdgeInsets.only(left: 10),
                                        border: OutlineInputBorder())),
                              ],
                            ),
                          ),
                        );
                      });
                }),

            ///---- clear
            IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _signatureController.points.clear();
                  setState(() {});
                }),

            ///---- camera
            IconButton(
                icon: Icon(Icons.camera),
                onPressed: () {
                  bottomSheets();
                }),

            ///---- Done
            FlatButton(
                child: new Text("Done"),
                textColor: Colors.red,
                onPressed: () {
                  File _imageFile;
                  _imageFile = null;
                  screenshotController
                      .capture(
                      delay: Duration(milliseconds: 500), pixelRatio: 1.5)
                      .then((File imageFile) async {
                    //Settings.logger.logToScreen("Capture Done");
                    setState(() {
                      _imageFile = imageFile;
                    });

                    final paths = await getExternalStorageDirectory();
                    imageFile.copy(paths.path + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '.png');
                    Navigator.pop(context, imageFile);
                  }).catchError((onError) {
                    Settings.logger.logToScreen(onError);
                  });
                }),
          ],
          backgroundColor: widget.appBarColor,
        ),

        ///---- body
        body: Center(
          child: Screenshot(
            controller: screenshotController,
            child: Container(
              margin: EdgeInsets.all(20),
              color: Colors.blue,
              width: width.toDouble(),
              height: height.toDouble(),
              child: RepaintBoundary(
                  key: repaintKey,
                  child: Stack(
                    children: <Widget>[
                      _image != null ? Image.file(
                        _image,
                        height: height.toDouble(),
                        width: width.toDouble(),
                        fit: BoxFit.cover,
                      ) : SizedBox.expand(),

                      Container(
                        child: GestureDetector(
                            onPanUpdate: (DragUpdateDetails details) {
                              setState(() {
                                RenderBox object = context.findRenderObject();
                                Offset _localPosition = object.globalToLocal(details.globalPosition);
                                _points = new List.from(_points)..add(_localPosition);
                              });
                            },
                            onPanEnd: (DragEndDetails details) {
                              _points.add(null);
                            },
                            child: Signat()),
                      ),
                      Stack(
                        children: multiWidgets.asMap().entries.map((f) {
                          return types[f.key] == 1
                              ? EmojiView(
                            left: offsets[f.key].dx,
                            top: offsets[f.key].dy,
                            ontap: () {
                              scaffoldKey.currentState.showBottomSheet((context) {
                                return Sliders(
                                  size: f.key,
                                  sizeValue: fontSizes[f.key].toDouble(),
                                );
                              });
                            },
                            onpanupdate: (details) {
                              setState(() {
                                offsets[f.key] = Offset(
                                    offsets[f.key].dx + details.delta.dx,
                                    offsets[f.key].dy + details.delta.dy);
                              });
                            },
                            value: f.value.toString(),
                            fontsize: fontSizes[f.key].toDouble(),
                            align: TextAlign.center,
                          )
                              : types[f.key] == 2
                              ? TextView(
                            left: offsets[f.key].dx,
                            top: offsets[f.key].dy,
                            ontap: () {
                              scaffoldKey.currentState
                                  .showBottomSheet((context) {
                                return Sliders(
                                  size: f.key,
                                  sizeValue:
                                  fontSizes[f.key].toDouble(),
                                );
                              });
                            },
                            onpanupdate: (details) {
                              setState(() {
                                offsets[f.key] = Offset(
                                    offsets[f.key].dx +
                                        details.delta.dx,
                                    offsets[f.key].dy +
                                        details.delta.dy);
                              });
                            },
                            value: f.value.toString(),
                            fontsize: fontSizes[f.key].toDouble(),
                            align: TextAlign.center,
                          )
                              : new Container();
                        }).toList(),
                      )
                    ],
                  )),
            ),
          ),
        ),
        bottomNavigationBar: isBottomSheetOpen ? SizedBox()
            : Container(
          decoration: BoxDecoration(
              color: widget.bottomBarColor,
              boxShadow: [BoxShadow(blurRadius: 10.9)]),
          height: 70,
          child: new ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              BottomBarContainer(
                colors: widget.bottomBarColor,
                icons: FontAwesomeIcons.brush,
                ontap: () {
                  // raise the [showDialog] widget
                  showDialog(
                      context: context,
                      child: AlertDialog(
                        title: const Text('Pick a color!'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: pickerColor,
                            onColorChanged: changeColor,
                            showLabel: true,
                            pickerAreaHeightPercent: 0.8,
                          ),
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: const Text('Got it'),
                            onPressed: () {
                              setState(() => currentColor = pickerColor);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ));
                },
                title: 'Brush',
              ),
              BottomBarContainer(
                icons: Icons.text_fields,
                title: 'Text',
                ontap: () async {
                  final value = await Navigator.push(context, MaterialPageRoute(builder: (context) => TextEditor()));
                  if (value == null || value.toString().isEmpty) {
                    Settings.logger.logToScreen("text null");
                  }
                  else {
                    types.add(2);
                    fontSizes.add(20);
                    offsets.add(Offset.zero);
                    multiWidgets.add(value);
                    widgetsCount++;
                  }
                },
              ),

              BottomBarContainer(
                icons: FontAwesomeIcons.eraser,
                title: 'Eraser',
                ontap: () {
                  _signatureController.clear();
                  types.clear();
                  fontSizes.clear();
                  offsets.clear();
                  multiWidgets.clear();
                  widgetsCount = 0;
                },
              ),

              BottomBarContainer(
                icons: Icons.photo,
                title: 'Filter',
                ontap: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return ColorPickersSlider();
                      });
                },
              ),

              BottomBarContainer(
                icons: FontAwesomeIcons.smile,
                title: 'Emoji',
                ontap: () {
                  Future getEmojis = showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Emojies();
                      });
                  getEmojis.then((value) {
                    if (value != null) {
                      types.add(1);
                      fontSizes.add(20);
                      offsets.add(Offset.zero);
                      multiWidgets.add(value);
                      widgetsCount++;
                    }
                  });
                },
              ),
            ],
          ),
        ));
  }

  void bottomSheets() {
    isBottomSheetOpen = true;
    setState(() {});
    final picker = ImagePicker();

    Future<void> future = showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return new Container(
          decoration: BoxDecoration(color: Colors.indigo, boxShadow: [
            BoxShadow(blurRadius: 10.9, color: Colors.grey[400])
          ]),
          height: 170,
          child: new Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: new Text("Select Image Options"),
              ),
              Divider(
                height: 1,
              ),
              new Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: InkWell(
                        onTap: () {},
                        child: Container(
                          child: Column(
                            children: <Widget>[
                              IconButton(
                                  icon: Icon(Icons.photo_library),
                                  onPressed: () async {
                                    PickedFile image = await picker.getImage(source: ImageSource.gallery);
                                    var decodedImage = await decodeImageFromList(await image.readAsBytes());

                                    setState(() {
                                      height = decodedImage.height;
                                      width = decodedImage.width;
                                      _image = File(image.path);
                                    });
                                    setState(() => _signatureController.clear());
                                    Navigator.pop(context);
                                  }),
                              SizedBox(width: 10),
                              Text("Open Gallery")
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: () async {
                                  var image = await ImagePicker.pickImage(
                                      source: ImageSource.camera);
                                  var decodedImage = await decodeImageFromList(
                                      image.readAsBytesSync());

                                  setState(() {
                                    height = decodedImage.height;
                                    width = decodedImage.width;
                                    _image = image;
                                  });
                                  setState(() => _signatureController.clear());
                                  Navigator.pop(context);
                                }),
                            SizedBox(width: 10),
                            Text("Open Camera")
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );

    future.then((void value) => _closeModal(value));
  }

  void _closeModal(void value) {
    isBottomSheetOpen = false;
    setState(() {});
  }
}
///===============================================================================================================
class Signat extends StatefulWidget {
  @override
  _SignatState createState() => _SignatState();
}

class _SignatState extends State<Signat> {
  @override
  void initState() {
    super.initState();
    _signatureController.addListener(() => Settings.logger.logToScreen("Value changed"));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: <Widget>[
          Signature(
              controller: _signatureController,
              height: height.toDouble(),
              width: width.toDouble(),
              backgroundColor: Colors.transparent),
        ],
      );
  }
}
///==============================================================================================================
class Sliders extends StatefulWidget {
  final int size;
  final sizeValue;

  const Sliders({Key key, this.size, this.sizeValue}) : super(key: key);

  @override
  _SlidersState createState() => _SlidersState();
}

class _SlidersState extends State<Sliders> {
  @override
  void initState() {
    slider = widget.sizeValue;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 120,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: new Text("Slider Size"),
            ),
            Divider(
              height: 1,
            ),
            new Slider(
                value: slider,
                min: 0.0,
                max: 100.0,
                onChangeEnd: (v) {
                  setState(() {
                    fontSizes[widget.size] = v.toInt();
                  });
                },
                onChanged: (v) {
                  setState(() {
                    slider = v;
                    Settings.logger.logToScreen(v.toInt());
                    fontSizes[widget.size] = v.toInt();
                  });
                }),
          ],
        ));
  }
}
///================================================================================================================
class ColorPickersSlider extends StatefulWidget {
  @override
  _ColorPickersSliderState createState() => _ColorPickersSliderState();
}

class _ColorPickersSliderState extends State<ColorPickersSlider> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      height: 260,
      color: Colors.greenAccent,
      child: new Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: new Text("Slider Filter Color"),
          ),
          Divider(
            height: 1,
          ),
          SizedBox(height: 20),
          new Text("Slider Color"),
          SizedBox(height: 10),
          BarColorPicker(
              width: 300,
              thumbColor: Colors.deepPurple,
              cornerRadius: 10,
              pickMode: PickMode.Color,
              colorListener: (int value) {
                setState(() {
                  //  currentColor = Color(value);
                });
              }),
          SizedBox(height: 20),
          Text("Slider Opacity"),
          SizedBox(height: 10),
          Slider(value: 0.1, min: 0.0, max: 1.0, onChanged: (v) {})
        ],
      ),
    );
  }
}
*/