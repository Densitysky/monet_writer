import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:monet_writer/services/database_service.dart';

class SyncServerService {
  static final SyncServerService _instance = SyncServerService._internal();
  factory SyncServerService() => _instance;
  SyncServerService._internal();

  HttpServer? _server;
  String? _localIp;
  final int _port = 9527;
  String _currentPin = '';

  String get ip => _localIp ?? '127.0.0.1';
  int get port => _port;
  String get pin => _currentPin;
  bool get isRunning => _server != null;

  Future<bool> startServer() async {
    if (_server != null) return true;

    try {
      _localIp = await NetworkInfo().getWifiIP();
      if (_localIp == null && !kIsWeb) {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              _localIp = addr.address;
              break;
            }
          }
        }
      }

      _currentPin = (Random().nextInt(900000) + 100000).toString();

      final router = Router();
      router.get('/api/ping', (Request request) => Response.ok('pong'));
      router.get('/api/sync/pull', _handlePullData);
      router.post('/api/sync/push', _handlePushData);

      final handler = const Pipeline()
          .addMiddleware(_authMiddleware())
          .addHandler(router.call);

      _server = await io.serve(handler, InternetAddress.anyIPv4, _port);
      debugPrint('🚀 服务已启动: http://$ip:$_port (PIN: $_currentPin)');
      return true;
    } catch (e) {
      debugPrint('❌ 启动失败: $e');
      return false;
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  Middleware _authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.url.path == 'api/ping') return await innerHandler(request);
        final authHeader = request.headers['authorization'];
        if (authHeader != 'Bearer $_currentPin') {
          return Response.forbidden(jsonEncode({'error': 'PIN码不正确或已过期'}));
        }
        return await innerHandler(request);
      };
    };
  }

  Future<Response> _handlePullData(Request request) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempZipPath = '${dir.path}/monet_sync_pull_server_${DateTime.now().millisecondsSinceEpoch}.zip';

      await DatabaseService().exportAllDataToZip(tempZipPath);

      final file = File(tempZipPath);
      if (!await file.exists()) throw Exception('Zip 数据打包失败');

      // 【核心修复】：不再将其读入内存，而是直接将 File 的流挂载到响应体上！
      return Response.ok(
        file.openRead(), // 直接传输水管
        headers: {
          'Content-Type': 'application/zip',
          'Content-Disposition': 'attachment; filename="monet_backup.zip"',
          'Content-Length': (await file.length()).toString(),
        },
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _handlePushData(Request request) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempZipPath = '${dir.path}/monet_sync_receive_${DateTime.now().millisecondsSinceEpoch}.zip';
      final tempFile = File(tempZipPath);

      // 【核心修复】：放弃极其占用内存的 BytesBuilder！
      // 建立直接通往硬盘的管道，接住手机端冲过来的网络流
      final sink = tempFile.openWrite();
      await request.read().pipe(sink); // 管道对齐，瞬间完成，不占一丝内存！

      // 覆盖电脑本地数据库
      await DatabaseService().importDataFromZip(tempZipPath);

      if (await tempFile.exists()) await tempFile.delete();
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
}