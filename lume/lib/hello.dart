import 'dart:ffi';

const _helloAssetId = 'package:lume/plugins/hello/hello.dart';

@Native<Int64 Function(Int64, Int64)>(symbol: 'add', assetId: _helloAssetId)
external int _nativeAdd(int left, int right);

int helloAdd(int previous, int next) => _nativeAdd(previous, next);
