import 'package:lys/rps.dart';
import 'package:lys/src/cli/commands/command.dart';
import 'package:lys/src/cli/cli_options/cli_option.dart';
import 'package:collection/collection.dart';
import 'package:lys/src/cli/exceptions/cli_exception.dart';
import 'package:lys/src/utils/rps_package.dart';

class Cli {
  final RpsPackage package;
  final Console console;
  final List<Command> commands;
  final List<CliOption> options;
  final CliOption? fallback;

  Cli({
    required this.package,
    required this.console,
    required this.commands,
    required this.options,
    required this.fallback,
  });

  Future<void> run(List<String> arguments) async {
    try {
      final option =
          options.firstWhereOrNull((option) => option.match(arguments));
      if (option != null) {
        return option.run(this, console, arguments);
      }
      final command =
          commands.firstWhereOrNull((command) => command.match(arguments));
      if (command != null) {
        return command.run(console, arguments);
      }

      if (fallback != null) {
        console
          ..writeln('${bold(yellow('Warning!'))} No command has been matched.')
          ..writeln();
        fallback!.run(this, console, arguments);
      } else {
        throw CliException('No command has been matched.');
      }
    } catch (_) {
      await console.flush();
      rethrow;
    }
  }
}
