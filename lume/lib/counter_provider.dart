import 'package:lume/hello.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
final class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state = helloAdd(state, 1);
  void decrement() => state = helloAdd(state, -1);
}
