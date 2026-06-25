import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:monet_writer/services/sync_client_service.dart';

class MobileScannerPage extends StatefulWidget {
  const MobileScannerPage({super.key});

  @override
  State<MobileScannerPage> createState() => _MobileScannerPageState();
}

class _MobileScannerPageState extends State<MobileScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || !rawValue.startsWith('monetsync://')) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    try {
      final qrInfo = SyncClientService.parseQrCode(rawValue);

      // 弹出选择方向对话框
      final choice = await _showDirectionDialog();

      if (choice == null) {
        // 用户取消，恢复扫描
        setState(() => _isProcessing = false);
        _scannerController.start();
        return;
      }

      // 弹出加载框
      _showLoadingDialog(choice == 'pull' ? '正在拉取电脑数据...' : '正在将手机数据推送至电脑...');

      // 执行同步
      if (choice == 'pull') {
        await SyncClientService.pullData(qrInfo['ip']!, qrInfo['port']!, qrInfo['pin']!);
      } else {
        await SyncClientService.pushData(qrInfo['ip']!, qrInfo['port']!, qrInfo['pin']!);
      }

      if (!mounted) return;
      Navigator.pop(context); // 关加载框

      // 成功提示
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('✅ 同步成功', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(choice == 'pull' ? '已成功将电脑数据覆盖至手机！' : '已成功将手机数据推送至电脑！\n\n请在电脑端重新启动应用以加载最新数据。'),
          actions: [
            FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('完成')),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context); // 关加载框

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent), SizedBox(width: 8), Text('同步失败')]),
          content: Text(e.toString()),
          actions: [
            TextButton(
                onPressed: () { Navigator.pop(ctx); setState(() => _isProcessing = false); _scannerController.start(); },
                child: const Text('重试')
            ),
          ],
        ),
      );
    }
  }

  Future<String?> _showDirectionDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('发现桌面端设备', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('请选择您要执行的数据同步方向：\n\n⚠️ 注意：被覆盖方的数据将被彻底清空。'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                icon: const Icon(CupertinoIcons.cloud_download),
                label: const Text('拉取电脑数据 (覆盖手机)'),
                onPressed: () => Navigator.pop(ctx, 'pull'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(CupertinoIcons.cloud_upload),
                label: const Text('推送手机数据 (覆盖电脑)'),
                onPressed: () => Navigator.pop(ctx, 'push'),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('取消', style: TextStyle(color: Colors.grey))),
            ],
          )
        ],
      ),
    );
  }

  void _showLoadingDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(text),
            const SizedBox(height: 8),
            const Text('请勿锁屏或切换应用', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text('局域网同步', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off: return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on: return const Icon(Icons.flash_on, color: Colors.amber);
                }
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _handleBarcode),
          Positioned.fill(
            child: Container(decoration: ShapeDecoration(shape: _ScannerOverlayShape(borderColor: Theme.of(context).colorScheme.primary, borderWidth: 4.0))),
          ),
          const Positioned(
            bottom: 60, left: 0, right: 0,
            child: Center(child: Text('对准桌面端左下角生成的专属二维码', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5))),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  const _ScannerOverlayShape({required this.borderColor, required this.borderWidth});
  @override EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);
  @override Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();
  @override Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path();
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final scanArea = width * 0.7;
    final rectArea = Rect.fromLTWH((width - scanArea) / 2, (height - scanArea) / 2, scanArea, scanArea);
    final backgroundPaint = Paint()..color = Colors.black54;
    final backgroundPath = Path()..addRect(rect);
    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(rectArea, const Radius.circular(16)));
    canvas.drawPath(Path.combine(PathOperation.difference, backgroundPath, cutoutPath), backgroundPaint);
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth..strokeCap = StrokeCap.round;
    final length = scanArea * 0.15;
    final r = rectArea;
    canvas.drawLine(r.topLeft, r.topLeft + Offset(length, 0), borderPaint);
    canvas.drawLine(r.topLeft, r.topLeft + Offset(0, length), borderPaint);
    canvas.drawLine(r.topRight, r.topRight + Offset(-length, 0), borderPaint);
    canvas.drawLine(r.topRight, r.topRight + Offset(0, length), borderPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(length, 0), borderPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(0, -length), borderPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(-length, 0), borderPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(0, -length), borderPaint);
  }
  @override ShapeBorder scale(double t) => this;
}