import 'dart:developer';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    log('Usage: dart create_page.dart <component_name>');
    return;
  }

  String templateFolderPath = 'scripts/pageTemplate';
  String componentName = capitalize(arguments[0]);
  String pageFileName = arguments[0];
  print('componentName $componentName');
  print('pageFileName $pageFileName');
  Directory templateFolder = Directory(templateFolderPath);
  if (!templateFolder.existsSync()) {
    log('Template folder does not exist.');
    return;
  }

  List<File> templateFiles = _getTemplateFiles(templateFolder);
  if (templateFiles.isEmpty) {
    log('No template files found in the specified folder.');
    return;
  }

  String outputFolderPath = path.join('lib', 'pages', pageFileName);
  Directory outputFolder = Directory(outputFolderPath);
  if (!outputFolder.existsSync()) {
    outputFolder.createSync(recursive: true);
  }

  for (var templateFile in templateFiles) {
    String templateContent = templateFile.readAsStringSync();
    String replacedContent =
        templateContent.replaceAll('{{pageName}}', componentName);
    replacedContent = replacedContent.replaceAll('{{fileName}}', pageFileName);
    String relativePath =
        path.relative(templateFile.path, from: templateFolderPath);
    String outputFilePath =
        path.join(outputFolderPath, relativePath.replaceAll('.template', ''));
    File outputFile = File(outputFilePath);
    outputFile.createSync(recursive: true);
    outputFile.writeAsStringSync(replacedContent);
  }

  log('Component templates generated successfully in $outputFolderPath.');
}

// 判断首字母是否为大写
bool isFirstLetterUpperCase(String input) {
  if (input.isEmpty) {
    return false;
  }
  String firstLetter = input.substring(0, 1);
  return firstLetter.toUpperCase() == firstLetter;
}

String capitalize(String input) {
  if (input.isEmpty) {
    return input;
  }
  return input[0].toUpperCase() + input.substring(1);
}

// 驼峰转小写加下滑线拼接
String convertToSnakeCase(String input) {
  String snakeCase = '';
  for (int i = 0; i < input.length; i++) {
    if (input[i].toUpperCase() == input[i] && i != 0) {
      snakeCase += '_${input[i].toLowerCase()}';
    } else {
      snakeCase += input[i].toLowerCase();
    }
  }
  return snakeCase;
}

List<File> _getTemplateFiles(Directory directory) {
  List<File> templateFiles = [];
  List<FileSystemEntity> entities = directory.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.template')) {
      templateFiles.add(entity);
    }
  }
  return templateFiles;
}
