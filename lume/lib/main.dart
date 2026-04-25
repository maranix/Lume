import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lume/counter_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: CounterText()),
        floatingActionButton: Column(
          spacing: 4,
          mainAxisAlignment: .end,
          children: [CountIncrementButton(), CountDecrementButton()],
        ),
      ),
    );
  }
}

class CounterText extends ConsumerWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Text("$count", style: Theme.of(context).textTheme.displayLarge);
  }
}

class CountIncrementButton extends ConsumerWidget {
  const CountIncrementButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton.filled(
      icon: Icon(Icons.add),
      onPressed: ref.read(counterProvider.notifier).increment,
    );
  }
}

class CountDecrementButton extends ConsumerWidget {
  const CountDecrementButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton.filled(
      icon: Icon(Icons.remove),
      onPressed: ref.read(counterProvider.notifier).decrement,
    );
  }
}
