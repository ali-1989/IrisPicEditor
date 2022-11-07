import 'dart:async';
import 'package:flutter/material.dart';

typedef StateBuilder<T> = Widget Function(BuildContext context, StateManagerController controller, dynamic sendData);
typedef NotifyUpdate = void Function(dynamic sendData);
///===================================================================================================
class StateManager extends StatefulWidget {
  final StateManagerController? controller;
  final String? id;
  final String? group;
  final bool isMain;
  final bool isSubMain;
  final StateBuilder builder;

  StateManager({
    Key? key,
    this.id,
    this.group,
    this.isMain = false,
    this.isSubMain = false,
    this.controller,
    required this.builder,
  }): assert(id != null || (isSubMain || isMain)), super(key : key);

  @override
  State<StatefulWidget> createState() {
    return _StateManagerState();
  }
}
///===================================================================================================
class _StateManagerState extends IStateX<StateManager> {
  late StateManagerController _controller;
  dynamic _data;

  dynamic get lastData => _data;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller?? StateManagerController();
    _controller._add(this);
  }

  @override
  void didUpdateWidget(StateManager oldWidget) {
    //_controller = oldWidget.controller;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(context, _controller, _data);
  }

  @override
  void dispose() {
    _controller._widgetIsDisposed(this);
    super.dispose();
  }

  void update(dynamic data) {
    _data = data;

    if(mounted) {
      setState(() {});
    }
  }

  void disposeWidget() {
    dispose();
  }
}
///===================================================================================================
abstract class IStateX<w extends StatefulWidget> extends State<w> {
  void update(dynamic data);
  void disposeWidget();
}
///===================================================================================================
class StateManagerController {
  static const state$normal = 'Normal';
  static const state$error = 'Error';
  static const state$emptyData = 'EmptyData';
  static const state$loading = 'Loading';
  static const state$serverNotResponse = 'ServerNotResponse';
  static const state$netDisconnect = 'NetDisconnect';
  static List<StateManagerController> _allControllers = [];

  List<StateXGroup> _groupHolderList = [];
  List<_StateManagerState> _xStateList = [];
  Set<NotifyUpdate> _notifyMainStateUpdate = {};
  Set<NotifyUpdate> _notifySubMainStateUpdate = {};
  StateDataManager _stateDataManager = StateDataManager();
  _StateManagerState? _main;
  _StateManagerState? _subMain;
  var _objects = <String, dynamic>{};
  String mainState = state$normal;
  String subMainState = state$normal;

  StateManagerController(){
    _allControllers.add(this);
  }

  void mainStateAndUpdate(String state, {data}){
    mainState = state;
    updateMain(stateData: data);
  }

  void subMainStateAndUpdate(String state, {data}){
    subMainState = state;
    updateSubMain(stateData: data);
  }

  void addMainStateListener(NotifyUpdate fn){
    _notifyMainStateUpdate.add(fn);
  }

  void addSubMainStateListener(NotifyUpdate fn){
    _notifySubMainStateUpdate.add(fn);
  }

  void _add(_StateManagerState state){
    if(!_xStateList.contains(state)){
      _xStateList.add(state);
    }

    if(state.widget.isMain){
      if(_main != null){
        throw Exception("one 'isMain' can use");
      }

      _main = state;
    }
    else if(state.widget.isSubMain){
      if(_subMain != null){
        throw Exception("one 'isSubMain' can use");
      }

      _subMain = state;
    }

    bool addToGroup = false;

    if(state.widget.group != null) {
      for (var g in _groupHolderList) {
        if (g.groupId == state.widget.group) {
          g.stateList.add(state);
          addToGroup = true;
          break;
        }
      }

      if(!addToGroup){
        _groupHolderList.add(StateXGroup.fill(state.widget.group!, state));
      }
    }
  }

  void updateMain({dynamic stateData, Duration? delay}) {
    void fn(){
      _main?.update(stateData);//?? _main!._data

      for(var fn in _notifyMainStateUpdate){
        try {
          fn.call(stateData);
        }
        catch (e){}
      }
    }

    if(delay == null)
      fn();
    else
      Timer(delay, (){fn();});
  }

  void updateSubMain({dynamic stateData, Duration? delay}) {
    void fn(){
      _subMain?.update(stateData);

      for(var fn in _notifySubMainStateUpdate){
        try {
          fn.call(stateData);
        }
        catch (e){}
      }
    }

    if(delay == null)
      fn();
    else
      Timer(delay, (){fn();});
  }

  void update(String id, {dynamic stateData, Duration? delay}){
    void fn(){
      for(var s in _xStateList){
        if(s.widget.id == id){
          s.update(stateData);
        }
      }
    }

    if(delay == null)
      fn();
    else
      Timer(delay, (){fn();});
  }

  void updateAll({dynamic stateData, Duration? delay}){
    void fn(){
      for(var s in _xStateList){
        s.update(stateData);//?? s._data
      }
    }

    if(delay == null)
      fn();
    else
      Timer(delay, (){fn();});
  }

  void updateGroup(String groupId, {dynamic stateData, Duration? delay}){
    void fn(){
      var list = getGroup(groupId);

      for(var s in list){
        var nS = s as _StateManagerState;
        nS.update(stateData);//?? nS._data
      }
    }

    if(delay == null)
      fn();
    else
      Timer(delay, (){fn();});
  }

  Set<State> getGroup(String groupId){
    for(var m in _groupHolderList){
      if(m.groupId == groupId){
        return m.stateList;
      }
    }

    return {};
  }
  //..............................................................................
  void setObject(String key, dynamic val){
    _objects[key] = val;
  }

  void setObjectIfNotExist(String key, dynamic val){
    if(_objects[key] == null)
      _objects[key] = val;
  }

  T object<T>(String key){
    return _objects[key];
  }

  T objectOrDefault<T>(String key, T defaultVal){
    return _objects[key]?? defaultVal;
  }

  bool existObject(String key){
    return _objects[key] != null;
  }

  void clearObjects(){
    return _objects.clear();
  }
  //..............................................................................
  void setStateData(String key, dynamic value){
    _stateDataManager.set(key, value);
  }

  T stateData<T>(String key){
    return _stateDataManager.state(key);
  }

  T stateDataOrDefault<T>(String key, T defaultVal){
    return _stateDataManager.state(key)?? defaultVal;
  }

  bool existStateData(String key){
    return _stateDataManager.existKey(key);
  }
  //..............................................................................
  void dispose() {
    _allControllers.remove(this);

    /*no need: for(var s in _stateList){
      if(s.mounted) {
        s.disposeWidget();
      }
    }*/

    _xStateList.clear();
    _objects.clear();
    _groupHolderList.clear();
    _stateDataManager.clear();
    _notifyMainStateUpdate.clear();
    _notifySubMainStateUpdate.clear();
    _main = null;
    _subMain = null;
  }

  void _widgetIsDisposed(IStateX state){
    List temp = [];

    for(var s in _xStateList){
      if(s == state){
        temp.add(s);
      }
    }

    for(var x in temp){
      _xStateList.remove(x);
    }

    temp.clear();

    /// means this controller is empty and no control any.
    if(_xStateList.isEmpty){
      _allControllers.remove(this);
      _groupHolderList.clear();
      _objects.clear();
      _stateDataManager.clear();
      _notifyMainStateUpdate.clear();
      _notifySubMainStateUpdate.clear();
      _main = null;
      _subMain = null;
      return;
    }

    List gTemp = [];
    for(var g in _groupHolderList){
      for(var s in g.stateList){
        if(s == state) {
          temp.add(s);
          break;
        }
      }

      for(var x in temp){
        g.stateList.remove(x);
      }

      temp.clear();

      if(g.stateList.isEmpty){
        gTemp.add(g);
      }
    }

    for(var x in gTemp){
      _groupHolderList.remove(x);
    }
  }

  static void globalUpdateMains({dynamic stateData, Duration? delay}){
    for(var c in _allControllers){
      c.updateMain(stateData: stateData, delay: delay);
    }
  }

  static void globalUpdate(String id, {dynamic stateData, Duration? delay}){
    for(var c in _allControllers){
      c.update(id, stateData: stateData, delay: delay);
    }
  }

  static void globalUpdateAll({dynamic stateData, Duration? delay}){
    for(var c in _allControllers){
      c.updateAll(stateData: stateData, delay: delay);
    }
  }

  static void globalUpdateGroup(String groupId, {dynamic stateData, Duration? delay}){
    for(var c in _allControllers){
      c.updateGroup(groupId, stateData: stateData, delay: delay);
    }
  }
}
///===================================================================================================
class StateXGroup {
  late String groupId;
  Set<IStateX> stateList = {};

  StateXGroup();

  StateXGroup.fill(String id, IStateX state){
    this.groupId = id;
    stateList.add(state);
  }
}
///===================================================================================================
class StateDataManager {
  Set<MapEntry> _stateList = {};

  StateDataManager();

  StateDataManager.add(String key, dynamic value){
    _stateList.add(MapEntry(key, value));
  }

  void set(String key, dynamic value){
    remove(key);
    _stateList.add(MapEntry(key, value));
  }

  bool setIfAbsent(String key, dynamic value){
    if(!existKey(key)) {
      _stateList.add(MapEntry(key, value));
      return true;
    }

    return false;
  }

  bool existKey(String key){
    for(var e in _stateList){
      if(e.key == key){
        return true;
      }
    }

    return false;
  }

  bool remove(String key){
    var find;

    for(var e in _stateList){
      if(e.key == key){
        find = e;
        break;
      }
    }

    if(find != null){
      return _stateList.remove(find);
    }

    return false;
  }

  dynamic state(String key){
    for(var e in _stateList){
      if(e.key == key){
        return e.value;
      }
    }

    return null;
  }

  void clear(){
    _stateList.clear();
  }
}