import 'dart:async';
import 'package:flutter/material.dart';

typedef SwitchBuilder<T> = Widget Function(BuildContext context, dynamic item, SwitchController controller);

class SwitchRefresh extends StatefulWidget {
  final SwitchBuilder switchBuilder;
  final SwitchController controller;

  SwitchRefresh({Key? key, required this.controller, required this.switchBuilder,}): super(key : key);

  @override
  State<StatefulWidget> createState() {
    var rs = _SwitchRefreshState();
    controller._state = rs;
    return rs;
  }
}
///==============================================================================================
class _SwitchRefreshState extends SwitchViewStateApi<SwitchRefresh> {
  late SwitchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  void didUpdateWidget(SwitchRefresh oldWidget) {
    //_controller = oldWidget.controller;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.switchBuilder.call(context, _controller.item, _controller);
  }

  @override
  void dispose() {
    _controller._disposeFromWidget();
    super.dispose();
  }

  void update() {
    setState(() {
    });
  }

  void disposeWidget() {
    dispose();
  }
}
///==============================================================================================
abstract class SwitchViewStateApi<w extends StatefulWidget> extends State<w> {
  void update();
  void disposeWidget();
}
///==============================================================================================
class SwitchController {
  SwitchViewStateApi? _state;
  Map<String, dynamic> objects = {};
  dynamic item;
  bool errorOccurred = false;
  String? _ownerTag;
  String? _extraTag;

  SwitchController(dynamic initItem){
    item = initItem;
  }

  void update({Duration? delay}){
    if(_state != null && _state!.mounted) {
      if(delay == null)
        _state!.update();
      else
        Timer(delay, (){_state!.update();});
    }
  }

  Widget? get widget => _state?.widget;
  BuildContext? get context => _state?.context;

  bool isOwnerTag(String tag) => _ownerTag != null && _ownerTag == tag;
  bool isExtraTag(String tag) => _extraTag != null && _extraTag == tag;

  void setOwnerTag(String val){
    _ownerTag = val;
  }

  String? getOwnerTag(){
    return _ownerTag;
  }

  void setExtraTag(String val){
    _extraTag = val;
  }

  String? getExtraTag(){
    return _extraTag;
  }

  void set(String key, dynamic val){
    objects[key] = val;
  }

  void addIfNotExist(String key, dynamic val){
    if(objects[key] == null)
      objects[key] = val;
  }

  T getItem<T>(){
    return item;
  }

  void setItem(dynamic val){
    item = val;
  }

  void setItemAndUpdate(dynamic val){
    item = val;
    update();
  }

  T get<T>(String key){
    return objects[key];
  }

  T getOrDefault<T>(String key, T defaultVal){
    return objects[key]?? defaultVal;
  }

  bool exist(String key){
    return objects[key] != null;
  }

  void _disposeFromWidget() {
  }

  void dispose([bool disposeWidget = false]) {
    objects.clear();

    if(disposeWidget && _state != null)
      _state!.disposeWidget();
  }
}