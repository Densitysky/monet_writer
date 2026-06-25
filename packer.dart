import 'dart:io';

void main() async {
  // 设置：每个生成的文本文件最大字符数（约 1万5 到 2万字符适合一次性发给 AI）
  const int maxCharsPerFile = 20000;

  final dir = Directory('lib');
  // 获取所有 dart 文件
  final files = dir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int partIndex = 1;
  StringBuffer buffer = StringBuffer();
  int currentLength = 0;

  print('开始打包...');

  for (var file in files) {
    String content = await file.readAsString();
    // 添加文件名头，方便 AI 识别
    String header = "\n\n" + ("=" * 40) + "\nFILE: ${file.path}\n" + ("=" * 40) + "\n\n";

    // 检查如果加上这个文件是否会超标
    if (currentLength + header.length + content.length > maxCharsPerFile && buffer.isNotEmpty) {
      // 保存当前 buffer 到文件
      await _saveFile(partIndex, buffer.toString());
      partIndex++;
      buffer.clear();
      currentLength = 0;
    }

    buffer.write(header);
    buffer.write(content);
    currentLength += header.length + content.length;
  }

  // 保存剩下的部分
  if (buffer.isNotEmpty) {
    await _saveFile(partIndex, buffer.toString());
  }

  print('✅ 打包完成！请查看项目根目录下的 code_part_x.txt 文件。');
}

Future<void> _saveFile(int index, String content) async {
  final fileName = 'code_part_$index.txt';
  await File(fileName).writeAsString(content);
  print('-> 生成文件: $fileName (${content.length} 字符)');
}