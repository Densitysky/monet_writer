import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/models/chapter.dart';
import 'package:path/path.dart' as p;

class EpubBuilder {
  /// 生成 EPUB 文件二进制数据
  /// 【关键修复】方法名改为 build，适配 ExportService 的调用
  static List<int> build(Book book, List<Chapter> chapters) {
    final archive = Archive();

    // 1. mimetype (必须是第一个文件)
    const mimetypeData = 'application/epub+zip';
    // archive 4.x 写法：直接添加，不设置 compress 属性
    archive.addFile(ArchiveFile('mimetype', mimetypeData.length, utf8.encode(mimetypeData)));

    // 2. META-INF/container.xml
    const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    // 3. OEBPS 目录内容
    // 3.1 封面图片 (如果有)
    String? coverFileName;
    if (book.coverPath != null) {
      final coverFile = File(book.coverPath!);
      if (coverFile.existsSync()) {
        final coverBytes = coverFile.readAsBytesSync();
        coverFileName = 'cover${p.extension(book.coverPath!)}';
        archive.addFile(ArchiveFile('OEBPS/images/$coverFileName', coverBytes.length, coverBytes));
      }
    }

    // 3.2 章节内容 (XHTML)
    final manifestItems = <String>[];
    final spineItems = <String>[];

    // 添加封面页
    if (coverFileName != null) {
      final coverPage = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Cover</title></head>
<body><div style="text-align: center; padding: 0pt; margin: 0pt;"><img src="images/$coverFileName" style="height: 100%;" /></div></body>
</html>''';
      archive.addFile(ArchiveFile('OEBPS/cover.xhtml', coverPage.length, utf8.encode(coverPage)));
      manifestItems.add('<item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>');
      manifestItems.add('<item id="cover-image" href="images/$coverFileName" media-type="image/jpeg"/>');
      spineItems.add('<itemref idref="cover"/>');
    }

    // 添加章节
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterFileName = 'chapter_$i.xhtml';
      // 简单的 HTML 处理，处理换行
      final contentHtml = chapter.content.split('\n').map((line) => line.trim().isNotEmpty ? '<p>$line</p>' : '').join('');

      final xhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${chapter.title}</title></head>
<body>
<h1>${chapter.title}</h1>
$contentHtml
</body>
</html>''';

      archive.addFile(ArchiveFile('OEBPS/$chapterFileName', xhtml.length, utf8.encode(xhtml)));
      manifestItems.add('<item id="chap$i" href="$chapterFileName" media-type="application/xhtml+xml"/>');
      spineItems.add('<itemref idref="chap$i"/>');
    }

    // 3.3 content.opf
    final opfContent = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>${book.title}</dc:title>
    <dc:language>zh-CN</dc:language>
    <meta name="cover" content="cover-image" />
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    ${manifestItems.join('\n    ')}
  </manifest>
  <spine toc="ncx">
    ${spineItems.join('\n    ')}
  </spine>
</package>''';
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfContent.length, utf8.encode(opfContent)));

    // 3.4 toc.ncx (目录)
    final navPoints = List.generate(chapters.length, (i) {
      return '''<navPoint id="navPoint-${i + 1}" playOrder="${i + 1}">
      <navLabel><text>${chapters[i].title}</text></navLabel>
      <content src="chapter_$i.xhtml"/>
    </navPoint>''';
    }).join('\n    ');

    final ncxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="urn:uuid:12345"/></head>
  <docTitle><text>${book.title}</text></docTitle>
  <navMap>
    $navPoints
  </navMap>
</ncx>''';
    archive.addFile(ArchiveFile('OEBPS/toc.ncx', ncxContent.length, utf8.encode(ncxContent)));

    // 4. 打包
    final encoder = ZipEncoder();
    return encoder.encode(archive)!;
  }
}
