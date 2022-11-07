import 'dart:async';
import 'package:flutter/material.dart';

typedef RefreshBuilder<T> = Widget Function(BuildContext context, RefreshController controller);
///=======================================================================================================
abstract class RefreshStateApi<w extends StatefulWidget> extends State<w> {
	void update();
	void disposeWidget();
}
///=======================================================================================================
class Updater extends StatefulWidget {
	final RefreshBuilder childBuilder;
	final RefreshController controller;

	Updater({Key? key, required this.controller, required this.childBuilder,}): super(key : key);

	@override
  State<StatefulWidget> createState() {
    /*var rs = RefreshState();
    controller._state = rs;*/
    return _RefreshState();
  }
}
///=======================================================================================================
class _RefreshState extends RefreshStateApi<Updater> {
	late RefreshController _controller;

	@override
	void initState() {
		super.initState();

		_controller = widget.controller;
		_controller._state = this;
	}

	/// call before any build() if parent rebuild
	@override
	void didUpdateWidget(Updater oldWidget) {
		if(widget.controller != oldWidget.controller){
			_controller = widget.controller;
			_controller._state = this;

			//oldWidget.controller.dispose(); maybe no need
		}

		super.didUpdateWidget(oldWidget);
	}

	/// this is call any time, like: init, screen on/off, rotation, ...
	/// call after [createState]
	/// no call in back route
  @override
  Widget build(BuildContext context) {
    return widget.childBuilder.call(context, _controller);
  }

  @override
	void dispose() {
		_controller._disposeFromWidget();
		super.dispose();
	}

	void update() {
		setState(() {});
	}

	void disposeWidget() {
		dispose();
	}
}
///=======================================================================================================
class RefreshController {
	late RefreshStateApi? _state;
	Map<String, dynamic> objects = {};
	dynamic _attach;
	bool errorOccurred = false;
	bool showPrimaryView = true;
	String? _primaryTag;
	String? _extraTag;
	List<Sink> _chainUpdate = [];
	Map<Stream, StreamSubscription> _streamListeners = {};
	StreamController? _streamCtr;
	Function? _onData;
	Function? _onError;

	void update({Duration? delay, dynamic event}){
		if(_state != null && _state!.mounted){
			if(delay == null)
				_state!.update();
			else
				Timer(delay, (){_state!.update();});
		}

		for(Sink s in _chainUpdate) {
			try {
				s.add(event?? this);
			}
			catch(e){}
		}
	}

	Widget? get widget => _state?.widget;
	BuildContext? get context => _state?.context;

	bool isPrimaryTag(String tag) => _primaryTag != null && _primaryTag == tag;
	bool isExtraTag(String tag) => _extraTag != null && _extraTag == tag;

	void setPrimaryTag(String val){
		_primaryTag = val;
	}

	String? getPrimaryTag(){
		return _primaryTag;
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

	T attachment<T>(){
		return _attach;
	}

	void attach(dynamic val){
		_attach = val;
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

	void onData(void Function(dynamic event, RefreshController controller) fun){
		_onData = fun;
	}

	void onError(void Function(Object event, RefreshController controller) fun){
		_onError = fun;
	}

	void handlerOnData(event) {
		if(_onData != null)
			_onData!(event, this);
	}

	void handlerOnError(Object err) {
		if(_onError != null)
			_onError!(err, this);
	}

	StreamSubscription listenTo(Stream stream) {
		if(_streamListeners.containsKey(stream))
			return _streamListeners[stream]!;

		StreamSubscription sc = stream.listen(handlerOnData, onError: handlerOnError);

		_streamListeners[stream] = sc;
		return sc;
	}

	void unListenTo(Stream stream) {
		_streamListeners.remove(stream)?.cancel();
	}

	void _disposeFromWidget() {
	}

	void dispose([bool disposeWidget = false]) {
		_streamListeners.forEach((key, value) {
			try {
				value.cancel();
			}
			catch(e) {}
			});

		_streamListeners.clear();
		_chainUpdate.clear();
		_streamCtr?.close();
		objects.clear();

		if(disposeWidget && _state != null)
			_state!.disposeWidget();

		_state = null;
	}

	void chainUpdate(Sink sink){
		_chainUpdate.add(sink);
	}

	void unChainUpdate(Sink sink){
		_chainUpdate.remove(sink);
	}

	void _checkSink(){
		if(_streamCtr == null){
			_streamCtr = StreamController();

			_streamCtr!.stream.listen((event) {update();});
		}
	}

	Sink getSink(){
		_checkSink();

		return _streamCtr!.sink;
	}
}