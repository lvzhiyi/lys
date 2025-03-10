import 'dart:async';

import 'package:lys/rps.dart';
import 'package:lys/src/cli/cli.dart';
import 'package:lys/src/cli/cli_options/cli_option.dart';
import 'package:lys/src/utils/rps_package.dart';

class HelpOption extends CliOption {
  final Console console;
  final RpsPackage package;

  HelpOption({
    required this.console,
    required this.package,
  });

  @override
  String get description => 'Prints help.';

  @override
  String get name => 'help';

  @override
  String get short => 'h';

  @override
  Future<void> run(Cli cli, Console console, List<String> arguments) async {
    console
      ..writeln(
          '${bold('Run Pubspec Script')} (${boldGreen('rps')}) ${bold("v${package.version}")}')
      ..writeln();
    // ..writeln('${bold('Options')}:')
    // ..writeln('  -v, --version - prints version.')
    // ..writeln('  -h, --help    - prints help.')
    // ..writeln('  -u, --upgrade - upgrades rps package.');

    final options = cli.options;
    if (options.isNotEmpty) {
      console.writeln('${bold('Options')}:');
      for (final option in options) {
        final short = option.short;

        if (short != null) {
          console.writeln(
              '  -${option.short}, --${option.name} - ${option.description}');
        } else {
          console.writeln('      --${option.name} - ${option.description}');
        }
      }
    }

    final commands = cli.commands;
    if (commands.isNotEmpty) {
      console.writeln('${bold('Commands')}:');
      for (final command in commands) {
        console.writeln(
            '  ${command.tooltip ?? command.name} - ${command.description}');
      }
    }

    console.writeln();
  }
}
