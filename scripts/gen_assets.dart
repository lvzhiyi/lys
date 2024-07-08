import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io';

String? baseAbsDir;

String calcRelPath(String base, String dst) {
  var rtv = '';
  if (dst.startsWith(base)) {
    rtv = dst.substring(base.length);
    if (rtv.startsWith('/')) rtv = rtv.substring(1);
    return rtv;
  }
  var ba = base.split('/');
  var da = dst.split('/');

  while (ba.isNotEmpty && da.isNotEmpty) {
    if (ba[0] != da[0]) break;
    ba.removeAt(0);
    da.removeAt(0);
  }

  for (int i = 0; i < ba.length; i++) {
    rtv += '../';
  }
  for (int i = 0; i < da.length; i++) {
    rtv += '${da[i]}/';
  }
  if (rtv.endsWith('/')) rtv = rtv.substring(0, rtv.length - 1);

  return rtv;
}

Future<bool> sortImports(File f) async {
  log('sort imports: ${f.path}');

  var allLines = <String>[];
  var lines = <String>[];
  var dimports = <String>[];
  var pimports = <String>[];
  var cimports = <String>[];
  var regexImport = RegExp(r"^\s*import\s+['" "].*");
  var regexLib = RegExp(r"^\s*library\s+.*");

  await f
      .openRead()
      .map(utf8.decode)
      .transform(const LineSplitter())
      .forEach((ln) {
    if (regexLib.firstMatch(ln) != null) {
      allLines.add(ln);
      allLines.add('');
      return;
    }

    var m = regexImport.firstMatch(ln);
    if (m != null) {
      var imp = m.group(0);
      if (imp!.contains(r"'dart:")) {
        dimports.add(imp);
      } else if (imp.contains(r"'package:")) {
        pimports.add(imp);
      } else {
        cimports.add(imp);
      }
    } else {
      lines.add(ln);
    }
  });

  if (dimports.isNotEmpty) {
    dimports.sort();
    allLines.addAll(dimports);
  }

  if (pimports.isNotEmpty) {
    pimports.sort();
    allLines.addAll(pimports);
  }

  if (cimports.isNotEmpty) {
    cimports.sort();
    allLines.addAll(cimports);
  }

  // splite imports and code
  if (allLines.isNotEmpty && allLines[allLines.length - 1] == '') {
    allLines.add('');
  }

  // ignore: avoid_function_literals_in_foreach_calls
  lines.forEach((l) {
    if (allLines.isNotEmpty && allLines[allLines.length - 1] == '' && l == '') {
      return;
    }

    allLines.add(l);
  });

  f.openWrite()
    ..writeAll(allLines, '\n')
    ..close();

  return true;
}

main() async {
  const defKey = '__def__';
  var bd = Directory.fromUri(Uri.directory('./assets'));
  baseAbsDir = bd.absolute.path;
  if (baseAbsDir!.endsWith('/')) {
    baseAbsDir = baseAbsDir!.substring(0, baseAbsDir!.length - 1);
  }
  var rootAbsDir = baseAbsDir!.substring(0, baseAbsDir!.length - 6);

  var isNumber = RegExp(r"^\d+$");
  var isUpper = RegExp(r"[A-Z]+");
  var errors = <String>[];
  var assets = <String, Map<String, String>>{};

  await bd.list(recursive: true, followLinks: false).forEach((fse) async {
    if (fse is! File) return;
    var f = fse;
    if (f.path.contains('.DS_Store')) {
      return;
    }
    var bundleKey = defKey;
    var assetKey = '';
    var assfn = f.absolute.path.substring(rootAbsDir.length);
    var basefn = f.absolute.path.substring(baseAbsDir!.length);
    if (basefn.startsWith(Platform.pathSeparator)) basefn = basefn.substring(1);
    if (basefn.startsWith('.')) return;

    if (isUpper.hasMatch(basefn)) {
      log('Filename is Upper: $basefn');
    }

    var ss = basefn.split(Platform.pathSeparator);
    if (ss.length > 1) {
      bundleKey = ss[0];
      assetKey = basefn.substring(bundleKey.length);
      if (assetKey.startsWith('/')) assetKey = assetKey.substring(1);
    } else {
      assetKey = basefn;
    }

    var lastIdx = assetKey.lastIndexOf('.');
    if (lastIdx > -1) assetKey = assetKey.substring(0, lastIdx);
    assetKey = assetKey.toUpperCase();
    assetKey = assetKey.replaceAll(RegExp(r"\/"), '_');
    assetKey = assetKey.replaceAll(RegExp(r"\."), '_');

    if (isNumber.hasMatch(assetKey)) assetKey = 'Num$assetKey';

    var bundle = assets.putIfAbsent(
      bundleKey,
      () => <String, String>{},
    );

    if (bundle.containsKey(assetKey)) {
      errors.add('assetKey dup: $assfn => ${bundle[assetKey]} => $assetKey');
      return;
    }

    bundle[assetKey] = assfn;
  });

  if (errors.isNotEmpty) {
    for (var e = 0; e < errors.length; e++) {
      log(e.toString());
    }
    return;
  }

  assets.forEach((k, v) async {
    var lines = <String>[];
    var fn = 'lib/static/$k.dart';
    var className = 'Assets${k.substring(0, 1).toUpperCase()}${k.substring(1)}';

    lines.add(
        '// ignore_for_file: directives_ordering, constant_identifier_names');
    lines.add('');

    if (k == defKey) {
      fn = 'lib/static/assets.dart';
      className = 'Assets';

      assets.forEach((kk, vv) {
        if (kk == defKey) return;

        lines.add('export \'$kk.dart\';');
      });
      if (lines.isNotEmpty) lines.add('');
    }

    lines.add('class $className {');
    v.keys.toList()
      ..sort()
      ..forEach((kk) => lines.add('  static const $kk = \'${v[kk]}\';'));
    lines.add('}');
    lines.add('');

    log('generate $fn');

    var f = File.fromUri(Uri.parse('$rootAbsDir$fn'));

    var sink = f.openWrite();
    sink.writeAll(lines, '\n');
    await sink.close();
  });
}
