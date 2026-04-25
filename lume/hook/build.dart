import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const _pluginName = 'hello';
const _assetName = 'plugins/hello/hello.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final pluginRoot = Directory.fromUri(
      input.packageRoot.resolve('plugins/$_pluginName/'),
    );
    final cargoTargetDir = Directory.fromUri(
      input.outputDirectoryShared.resolve('cargo/$_pluginName/'),
    )..createSync(recursive: true);

    final target = _rustTargetTriple(
      os: input.config.code.targetOS,
      architecture: input.config.code.targetArchitecture,
    );
    final libraryFileName = input.config.code.targetOS.dylibFileName(
      _pluginName,
    );
    await _ensureRustTargetInstalled(target);

    final buildResult = await Process.run(
      'cargo',
      ['build', '--release', '--target', target],
      workingDirectory: pluginRoot.path,
      environment: {'CARGO_TARGET_DIR': cargoTargetDir.path},
    );

    if (buildResult.exitCode != 0) {
      throw ProcessException(
        'cargo',
        ['build', '--release', '--target', target],
        '${buildResult.stdout}\n${buildResult.stderr}',
        buildResult.exitCode,
      );
    }

    final compiledLibrary = File.fromUri(
      cargoTargetDir.uri.resolve('$target/release/$libraryFileName'),
    );
    if (!compiledLibrary.existsSync()) {
      throw StateError(
        'Expected compiled library at ${compiledLibrary.path}, but it was not produced.',
      );
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: compiledLibrary.absolute.uri,
      ),
    );
  });
}

String _rustTargetTriple({
  required OS os,
  required Architecture architecture,
}) {
  return switch ((os, architecture)) {
    (OS.android, Architecture.arm) => 'armv7-linux-androideabi',
    (OS.android, Architecture.arm64) => 'aarch64-linux-android',
    (OS.android, Architecture.ia32) => 'i686-linux-android',
    (OS.android, Architecture.x64) => 'x86_64-linux-android',
    (OS.iOS, Architecture.arm64) => 'aarch64-apple-ios',
    (OS.iOS, Architecture.x64) => 'x86_64-apple-ios',
    (OS.linux, Architecture.arm) => 'armv7-unknown-linux-gnueabihf',
    (OS.linux, Architecture.arm64) => 'aarch64-unknown-linux-gnu',
    (OS.linux, Architecture.ia32) => 'i686-unknown-linux-gnu',
    (OS.linux, Architecture.riscv64) => 'riscv64gc-unknown-linux-gnu',
    (OS.linux, Architecture.x64) => 'x86_64-unknown-linux-gnu',
    (OS.macOS, Architecture.arm64) => 'aarch64-apple-darwin',
    (OS.macOS, Architecture.x64) => 'x86_64-apple-darwin',
    (OS.windows, Architecture.arm64) => 'aarch64-pc-windows-msvc',
    (OS.windows, Architecture.ia32) => 'i686-pc-windows-msvc',
    (OS.windows, Architecture.x64) => 'x86_64-pc-windows-msvc',
    _ => throw UnsupportedError(
      'Rust build is not configured for ${os.name}/${architecture.name}.',
    ),
  };
}

Future<void> _ensureRustTargetInstalled(String target) async {
  final installedTargets = await Process.run('rustup', [
    'target',
    'list',
    '--installed',
  ]);

  if (installedTargets.exitCode != 0) {
    throw ProcessException(
      'rustup',
      ['target', 'list', '--installed'],
      '${installedTargets.stdout}\n${installedTargets.stderr}',
      installedTargets.exitCode,
    );
  }

  final installed = (installedTargets.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toSet();

  if (installed.contains(target)) {
    return;
  }

  final activeToolchain = await Process.run('rustup', [
    'show',
    'active-toolchain',
  ]);
  final toolchainDescription = activeToolchain.exitCode == 0
      ? (activeToolchain.stdout as String).trim()
      : 'unknown';

  throw StateError(
    'Rust target "$target" is required for plugin "$_pluginName", but it is not installed.\n'
    'Active toolchain: $toolchainDescription\n'
    'Installed targets: ${installed.toList()..sort()}\n'
    'Install it with: rustup target add $target',
  );
}
