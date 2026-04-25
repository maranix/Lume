// import 'dart:io';

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

final class PluginMetadata {
  const PluginMetadata({
    required this.name,
    required this.os,
    required this.arch,
    required this.target,
    required this.dir,
  });

  final String name;
  final OS os;
  final Architecture arch;
  final String target;
  final Directory dir;

  String get libraryName => os.dylibFileName(name);

  @override
  String toString() =>
      "PluginMetadata(name: $name, os: ${os.name}, arch: ${arch.name}, target: $target, dir: $dir)";
}

void main(List<String> args) async {
  await build(
    args,
    (input, output) async {
      if (!input.config.buildCodeAssets) {
        return;
      }

      final os = input.config.code.targetOS;
      final arch = input.config.code.targetArchitecture;
      final target = _rustCompilationTarget(os: os, architecture: arch);

      final pluginOutDir = Directory.fromUri(
        input.packageRoot.resolve("assets/plugins"),
      )..createSync(recursive: true);

      final metadatas =
          Directory.fromUri(
                input.packageRoot.resolve("plugins"),
              )
              .listSync()
              .where((e) => e.statSync().type == .directory)
              .map((e) => Directory.fromUri(e.uri))
              .map<PluginMetadata>(
                (d) => .new(
                  name: d.uri.pathSegments[d.uri.pathSegments.length - 2],
                  os: os,
                  arch: arch,
                  target: target,
                  dir: d,
                ),
              );

      for (final metadata in metadatas) {
        try {
          final buildDir = Directory.fromUri(
            input.outputDirectoryShared.resolve("plugins/${metadata.name}"),
          )..createSync(recursive: true);

          final outDir = Directory.fromUri(
            pluginOutDir.uri.resolve(
              "${metadata.name}/${os.name}/",
            ),
          )..createSync(recursive: true);

          final result = await Process.run(
            "cargo",
            ["build", "--release", "--target", metadata.target],
            workingDirectory: metadata.dir.path,
            environment: {
              "CARGO_TARGET_DIR": buildDir.path,
            },
          );

          if (result.exitCode != 0) {
            throw ProcessException(
              'cargo',
              ['build', '--release', '--target', target],
              '${result.stdout}\n${result.stderr}',
              result.exitCode,
            );
          }

          final plugin = File.fromUri(
            buildDir.uri.resolve(
              "${metadata.target}/release/${metadata.libraryName}",
            ),
          );

          if (!plugin.existsSync()) {
            throw StateError(
              'Expected compiled library at ${plugin.path}, but it was not produced.',
            );
          }

          final dest = File.fromUri(
            outDir.uri.resolve(metadata.libraryName),
          );

          if (dest.existsSync()) {
            dest.deleteSync();
          }

          dest.parent.createSync(recursive: true);

          plugin.copySync(dest.path);
        } catch (e) {
          throw ProcessException(
            'cargo',
            ['build', '--release', '--target', target],
            "${metadata.name}\n${e.toString()}",
          );
        }
      }
    },
  );
}

String _rustCompilationTarget({
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
