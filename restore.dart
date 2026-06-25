import 'dart:io';

// 您的源文件名
const String sourceFileName = 'all_code.txt';

void main() async {
  final file = File(sourceFileName);

  if (!await file.exists()) {
    print('❌ 错误：在当前目录下找不到 "$sourceFileName"');
    return;
  }

  print('🚀 开始读取代码库...');
  final lines = await file.readAsLines();

  // 匹配文件名行，例如: --- FILE: lib/main.dart ---
  final headerPattern = RegExp(r'--- FILE: (.+) ---');

  String? currentPath;
  List<String> currentContent = [];

  for (var line in lines) {
    // 忽略纯装饰线 (比如全是 = 号的行)
    if (line.trim().startsWith('=====')) continue;

    final match = headerPattern.firstMatch(line);

    if (match != null) {
      // 1. 保存上一个文件
      if (currentPath != null) {
        await _saveFile(currentPath!, currentContent);
        currentContent = [];
      }

      // 2. 获取新文件路径
      String rawPath = match.group(1)!.trim();
      // 兼容 Windows 反斜杠
      currentPath = rawPath.replaceAll('\\', '/');
      print('📄 正在解析: $currentPath');
    } else {
      // 3. 记录文件内容
      if (currentPath != null) {
        currentContent.add(line);
      }
    }
  }

  // 保存最后一个文件
  if (currentPath != null) {
    await _saveFile(currentPath!, currentContent);
  }

  print('\n✅ 还原完成！所有文件已重新生成。');
}

Future<void> _saveFile(String path, List<String> content) async {
  final file = File(path);
  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }
  await file.writeAsString(content.join('\n'));
}