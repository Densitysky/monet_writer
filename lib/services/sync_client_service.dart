import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:monet_writer/services/database_service.dart';

class SyncClientService {

  static Map<String, String> parseQrCode(String qrData) {
    if (!qrData.startsWith('monetsync://')) throw Exception('这似乎不是 Monet Writer 的专属同步二维码');
    final uri = Uri.parse(qrData);
    final ip = uri.host;
    final port = uri.port.toString();
    final pin = uri.queryParameters['pin'];

    if (ip.isEmpty || port == '0' || pin == null) throw Exception('二维码数据包损坏或无法解析');
    return {'ip': ip, 'port': port, 'pin': pin};
  }

  static Future<void> pullData(String ip, String port, String pin) async {
    final targetUrl = Uri.parse('http://$ip:$port/api/sync/pull');
    // 【修改】：使用流式客户端处理接收，防止拉取过大 ZIP 时手机内存爆炸
    final request = http.Request('GET', targetUrl);
    request.headers['authorization'] = 'Bearer $pin';

    final streamedResponse = await http.Client().send(request)
        .timeout(const Duration(seconds: 60), onTimeout: () => throw Exception('连接桌面端超时（打包可能需要较长时间）'));

    if (streamedResponse.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/monet_sync_pull_${DateTime.now().millisecondsSinceEpoch}.zip');

      // 像水管一样一点点写入本地文件
      final sink = tempFile.openWrite();
      await streamedResponse.stream.pipe(sink);

      await DatabaseService().importDataFromZip(tempFile.path);
      if (await tempFile.exists()) await tempFile.delete();
    } else if (streamedResponse.statusCode == 403) {
      throw Exception('安全码 (PIN) 校验失败或已过期');
    } else {
      throw Exception('桌面端服务器异常 (状态码: ${streamedResponse.statusCode})');
    }
  }

  static Future<void> pushData(String ip, String port, String pin) async {
    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/monet_sync_push_${DateTime.now().millisecondsSinceEpoch}.zip');

    // 1. 将手机数据打包
    await DatabaseService().exportAllDataToZip(tempFile.path);

    // 2. 发送给电脑
    final targetUrl = Uri.parse('http://$ip:$port/api/sync/push');

    // 【核心修复】：放弃内存堆叠，改用 StreamedRequest 流式上传！
    final request = http.StreamedRequest('POST', targetUrl);
    request.headers['authorization'] = 'Bearer $pin';
    request.headers['Content-Type'] = 'application/zip';
    // 提前通报文件大小，防止 Windows 防火墙拦截
    request.contentLength = await tempFile.length();

    // 打开文件流，像水管一样接到网络发送口
    tempFile.openRead().listen(
          (chunk) => request.sink.add(chunk),
      onDone: () => request.sink.close(),
      onError: (e) => request.sink.addError(e),
    );

    final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('推送数据超时，可能是因为包含大量图片，请保持网络畅通')
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (await tempFile.exists()) await tempFile.delete();

    if (response.statusCode != 200) {
      if (response.statusCode == 403) throw Exception('安全码 (PIN) 校验失败或已过期');
      throw Exception('桌面端服务器异常 (状态码: ${response.statusCode})');
    }
  }
}