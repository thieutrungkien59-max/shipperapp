import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';
import 'camera_capture_screen.dart';

class CameraProofScreen extends StatefulWidget {
  final bool isDeliveryPhase;
  final String maDh;
  final String phoneNumber; // SĐT để gọi (người nhận nếu pha giao, người gửi nếu pha lấy)

  const CameraProofScreen({
    Key? key,
    required this.isDeliveryPhase,
    required this.maDh,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<CameraProofScreen> createState() => _CameraProofScreenState();
}

class _CameraProofScreenState extends State<CameraProofScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _successGreen = const Color(0xFF198754);

  // ----- MINH CHỨNG 1: ẢNH GÓI HÀNG (chụp thật, live preview trong app) -----
  Uint8List? _photoBytes; // Ảnh thật đã chụp (bytes), null nếu chưa chụp
  bool _isCapturingPhoto = false;
  bool get _hasPhoto => _photoBytes != null;

  // ----- MINH CHỨNG 2: CHỮ KÝ — vẽ tay thật trên bảng trắng, "Lưu" sẽ chụp thành ảnh -----
  // Dùng RepaintBoundary để "chụp" đúng những gì đang vẽ trên canvas thành ảnh PNG,
  // giống hệt cơ chế chụp ảnh gói hàng — chỉ khác nguồn ảnh là canvas vẽ tay thay vì camera.
  final GlobalKey _signatureBoundaryKey = GlobalKey();
  final List<Offset?> _signaturePoints = []; // null = ngắt nét (nhấc bút/tay lên)
  Uint8List? _signatureBytes; // Ảnh chữ ký đã "Lưu", null nếu chưa lưu
  bool _isSavingSignature = false;
  bool get _hasSignature => _signatureBytes != null;

  // Khi đang vẽ (ngón tay/chuột còn nhấn), KHOÁ cuộn của trang cha (SingleChildScrollView)
  // -> tránh việc cuộn trang "giành" mất cử chỉ kéo giữa chừng, khiến nét vẽ bị cắt ngang
  // chỉ còn 1 đoạn ngắn. Mở khoá lại ngay khi nhấc tay/bút lên.
  bool _isDrawingSignature = false;

  late TextEditingController _nameController;

  bool _isUploading = false;
  late final OrderRepository _orderRepository;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
    _nameController = TextEditingController(
      text: widget.isDeliveryPhase ? 'Nguyễn Văn A' : 'Trần Văn B',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Đủ điều kiện xác thực hay chưa (chỉ còn Chữ ký, không còn OTP)
  bool get _isAuthComplete => _hasSignature;

  // ----- CHỤP ẢNH: MỞ MÀN HÌNH CAMERA LIVE PREVIEW TRONG APP -----
  Future<void> _pickPhoto() async {
    setState(() => _isCapturingPhoto = true);
    try {
      final Uint8List? bytes = await Navigator.push<Uint8List?>(
        context,
        MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
      );
      if (bytes == null) return; // Người dùng bấm huỷ, không chụp ảnh nào cả

      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở camera: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
  }

  // Chuyển bytes ảnh thành chuỗi base64 dạng data URI để gửi vào field kiểu String của API.
  // LƯU Ý: đây là giải pháp TẠM THỜI trong lúc Backend chưa có endpoint upload ảnh riêng.
  // Khi có endpoint upload ảnh (trả về URL thật), cần đổi lại: upload file trước, lấy URL, rồi mới
  // gọi uploadDeliveryProof với URL đó thay vì base64.
  String _buildImageDataUri(Uint8List bytes) {
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  // ----- CHỮ KÝ: XỬ LÝ VẼ TAY TRÊN BẢNG TRẮNG (dùng sự kiện con trỏ thô, không qua Scrollable) -----
  void _handleSignaturePointerDown(PointerDownEvent event) {
    setState(() {
      _isDrawingSignature = true; // Khoá cuộn trang trong lúc vẽ
      _signaturePoints.add(event.localPosition);
    });
  }

  void _handleSignaturePointerMove(PointerMoveEvent event) {
    setState(() {
      _signaturePoints.add(event.localPosition);
    });
  }

  void _handleSignaturePointerUp(PointerUpEvent event) {
    setState(() {
      _signaturePoints.add(null); // Ngắt nét khi nhấc tay/bút lên
      _isDrawingSignature = false; // Mở khoá cuộn trang trở lại
    });
  }

  void _handleSignaturePointerCancel(PointerCancelEvent event) {
    setState(() {
      _signaturePoints.add(null);
      _isDrawingSignature = false;
    });
  }

  void _clearSignatureDrawing() {
    setState(() {
      _signaturePoints.clear();
    });
  }

  // Vẽ lại từ đầu: xoá luôn ảnh đã lưu (nếu có) để cho ký lại
  void _redoSignature() {
    setState(() {
      _signatureBytes = null;
      _signaturePoints.clear();
    });
  }

  // "Chụp" đúng những gì đang hiển thị trên bảng vẽ (RepaintBoundary) thành ảnh PNG thật,
  // giống hệt cơ chế lưu ảnh chụp gói hàng.
  Future<void> _handleSaveSignature() async {
    if (_signaturePoints.isEmpty) return;

    setState(() => _isSavingSignature = true);
    try {
      final boundary = _signatureBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Không thể lưu ảnh chữ ký, vui lòng thử lại.');

      if (!mounted) return;
      setState(() {
        _signatureBytes = byteData.buffer.asUint8List();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu chữ ký: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSignature = false);
    }
  }

  // ----- GỌI ĐIỆN THẬT: mở app Điện thoại với SĐT đã điền sẵn -----
  Future<void> _handleCall() async {
    if (widget.phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có số điện thoại để gọi.'), backgroundColor: Colors.red),
      );
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: widget.phoneNumber.trim());
    try {
      final launched = await launchUrl(telUri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng gọi điện trên thiết bị này.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gọi điện: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // Khoá cuộn trang trong lúc đang vẽ chữ ký -> đảm bảo trang không "giành" mất
              // cử chỉ kéo giữa chừng, cho phép vẽ nét dài/nhiều nét thoải mái đến khi xong.
              physics: _isDrawingSignature ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningBanner(),
                  const SizedBox(height: 16),
                  _buildCallButton(),
                  const SizedBox(height: 24),

                  const Text(
                    'Minh chứng 1 — Ảnh gói hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoProofSection(),
                  const SizedBox(height: 24),

                  const Text(
                    'Minh chứng 2 — Chữ ký',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSignatureSection(),

                  const SizedBox(height: 24),
                  Text(
                    widget.isDeliveryPhase ? 'Tên người nhận thực tế' : 'Tên người gửi thực tế',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _buildNameInput(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isDeliveryPhase ? 'Xác nhận giao hàng' : 'Xác nhận lấy hàng',
            style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            widget.maDh,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E9),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: 'Đơn hàng '),
                  TextSpan(text: '≥ 1.000.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' — cần đủ 2 minh chứng'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _handleCall,
        icon: const Icon(Icons.call_outlined, size: 18),
        label: Text(
          widget.isDeliveryPhase ? 'Gọi cho người nhận' : 'Gọi cho người gửi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryRed,
          side: BorderSide(color: _primaryRed),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildPhotoProofSection() {
    return GestureDetector(
      onTap: _isCapturingPhoto ? null : _pickPhoto,
      child: Container(
        height: 200,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasPhoto ? Colors.transparent : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: _isCapturingPhoto
            ? const Center(child: CircularProgressIndicator())
            : _hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_photoBytes!, fit: BoxFit.cover),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: _successGreen, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Đã chụp', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.refresh, color: Colors.black87, size: 24),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Nhấn để chụp ảnh gói hàng', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
      ),
    );
  }

  // --- GIAO DIỆN CHỮ KÝ THẬT: bảng trắng cho vẽ tay, "Lưu" sẽ chụp thành ảnh ---
  Widget _buildSignatureSection() {
    // Đã lưu chữ ký thành ảnh -> hiển thị ảnh xem lại, giống hệt kiểu preview ảnh gói hàng
    if (_hasSignature) {
      return Container(
        height: 220,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_signatureBytes!, fit: BoxFit.contain),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _successGreen, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Đã ký', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _redoSignature,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.refresh, color: Colors.black87, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Chưa lưu -> hiển thị bảng trắng cho vẽ tay
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: RepaintBoundary(
            key: _signatureBoundaryKey,
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.white, // Nền trắng thật sự -> ảnh chụp ra cũng có nền trắng
              child: Stack(
                children: [
                  if (_signaturePoints.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw_outlined, size: 32, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Ký tên vào đây', style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _handleSignaturePointerDown,
                    onPointerMove: _handleSignaturePointerMove,
                    onPointerUp: _handleSignaturePointerUp,
                    onPointerCancel: _handleSignaturePointerCancel,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _SignaturePainter(points: _signaturePoints),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _signaturePoints.isEmpty ? null : _clearSignatureDrawing,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Xoá'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: (_signaturePoints.isEmpty || _isSavingSignature) ? null : _handleSaveSignature,
                icon: _isSavingSignature
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryRed),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Lưu chữ ký'),
                style: TextButton.styleFrom(foregroundColor: _primaryRed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryRed)),
      ),
    );
  }

  Future<void> _handleCompleteProof() async {
    if (_photoBytes == null || _signatureBytes == null) return; // An toàn: nút chỉ bật khi đã đủ 2 minh chứng

    setState(() => _isUploading = true);

    try {
      await _orderRepository.uploadDeliveryProof(
        maDonHang: widget.maDh,
        hinhAnhUrl: _buildImageDataUri(_photoBytes!),
        chuKyOtp: _buildImageDataUri(_signatureBytes!), // Ảnh chữ ký, base64 giống ảnh gói hàng
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu minh chứng: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildBottomAction() {
    // ĐIỀU KIỆN ĐỂ NÚT HOÀN THÀNH SÁNG LÊN
    bool isFormValid = _hasPhoto && _isAuthComplete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Column(
          children: [
            const Text('Nút sẽ được kích hoạt khi đã đủ minh chứng bắt buộc', style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                // Nếu chưa đủ điều kiện hoặc đang gửi -> onPressed = null (nút tự động bị mờ/disable)
                onPressed: (isFormValid && !_isUploading) ? _handleCompleteProof : null,
                style: ElevatedButton.styleFrom(
                  // Thay đổi màu nền tùy theo trạng thái hợp lệ
                  backgroundColor: isFormValid ? _primaryRed : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300, // Màu khi bị disable
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Hoàn thành',
                        style: TextStyle(
                          color: isFormValid ? Colors.white : Colors.grey.shade500, // Đổi màu chữ tương ứng
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Ảnh được tự động nén để tối ưu dung lượng (max 2MB)', style: TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

// Vẽ lại nét chữ ký từ danh sách điểm đã ghi nhận (null = ngắt nét khi nhấc tay/bút)
class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}