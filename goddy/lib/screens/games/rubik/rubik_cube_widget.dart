import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class RubikCubeWidget extends StatefulWidget {
  final VoidCallback? onMoveExecuted;
  final Function(String move)? onMoveName;
  final double size;

  const RubikCubeWidget({
    super.key,
    this.onMoveExecuted,
    this.onMoveName,
    this.size = 210.0,
  });

  @override
  State<RubikCubeWidget> createState() => RubikCubeWidgetState();
}

class RubikCubeWidgetState extends State<RubikCubeWidget> with SingleTickerProviderStateMixin {
  // Góc nhìn phối cảnh không gian 3 chiều Isometric mặc định (nhìn thấy 3 mặt: Trên, Trái, Phải)
  double _rotX = -0.55;
  double _rotY = 0.65;

  late AnimationController _turnController;
  Timer? _activeMoveTimer;
  String _activeMove = '';

  // 6 mặt Rubik: 0=Trên (Trắng), 1=Đáy (Vàng), 2=Trước (Xanh lá), 3=Sau (Xanh dương), 4=Phải (Đỏ), 5=Trái (Cam)
  late List<List<Color>> _faces;

  // Bảng màu thi đấu Rubik chính thức theo tiêu chuẩn thế giới WCA
  static const Color cWhite = Color(0xFFF8FAFC);  // Trắng (Mặt trên - Up)
  static const Color cYellow = Color(0xFFFFD500); // Vàng (Mặt đáy - Down)
  static const Color cGreen = Color(0xFF009B48);  // Xanh lá (Mặt trước - Front)
  static const Color cBlue = Color(0xFF0046AD);   // Xanh dương (Mặt sau - Back)
  static const Color cRed = Color(0xFFB71234);    // Đỏ Rubik (Mặt phải - Right)
  static const Color cOrange = Color(0xFFFF5800); // Cam rực rỡ (Mặt trái - Left)

  @override
  void initState() {
    super.initState();
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    resetCube();
  }

  @override
  void dispose() {
    _activeMoveTimer?.cancel();
    _turnController.dispose();
    super.dispose();
  }

  void resetCube() {
    setState(() {
      _faces = [
        List.filled(9, cWhite),  // 0 Up
        List.filled(9, cYellow), // 1 Down
        List.filled(9, cGreen),  // 2 Front
        List.filled(9, cBlue),   // 3 Back
        List.filled(9, cRed),    // 4 Right
        List.filled(9, cOrange), // 5 Left
      ];
    });
  }

  List<List<Color>> get faces => _faces;

  void resetCameraView() {
    setState(() {
      _rotX = -0.55;
      _rotY = 0.65;
    });
  }

  bool isSolved() {
    for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
      final base = _faces[faceIdx][0];
      for (int i = 1; i < 9; i++) {
        if (_faces[faceIdx][i] != base) return false;
      }
    }
    return true;
  }

  void scramble() {
    final rand = Random();
    final moves = ['U', "U'", 'D', "D'", 'R', "R'", 'L', "L'", 'F', "F'", 'B', "B'", 'M', "M'", 'E', "E'"];
    for (int i = 0; i < 20; i++) {
      _applyMoveLogic(moves[rand.nextInt(moves.length)]);
    }
    setState(() {});
  }

  void executeMove(String move, {bool animate = true}) {
    _activeMove = move;
    _applyMoveLogic(move);
    widget.onMoveExecuted?.call();
    widget.onMoveName?.call(move);
    setState(() {});

    _activeMoveTimer?.cancel();
    _activeMoveTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted && _activeMove == move) {
        setState(() {
          _activeMove = '';
        });
      }
    });
  }

  void _applyMoveLogic(String move) {
    switch (move) {
      // Hàng ngang trên (Top Layer)
      case 'U':
        _rotateFaceClockwise(0);
        _cycleEdges([2, 5, 3, 4], [0, 1, 2], [0, 1, 2], [0, 1, 2], [0, 1, 2]);
        break;
      case "U'":
        _rotateFaceCounterClockwise(0);
        _cycleEdges([2, 4, 3, 5], [0, 1, 2], [0, 1, 2], [0, 1, 2], [0, 1, 2]);
        break;

      // Hàng ngang giữa (Equator Layer)
      case 'E':
        _cycleEdges([2, 4, 3, 5], [3, 4, 5], [3, 4, 5], [3, 4, 5], [3, 4, 5]);
        break;
      case "E'":
        _cycleEdges([2, 5, 3, 4], [3, 4, 5], [3, 4, 5], [3, 4, 5], [3, 4, 5]);
        break;

      // Hàng ngang dưới (Bottom Layer)
      case 'D':
        _rotateFaceClockwise(1);
        _cycleEdges([2, 4, 3, 5], [6, 7, 8], [6, 7, 8], [6, 7, 8], [6, 7, 8]);
        break;
      case "D'":
        _rotateFaceCounterClockwise(1);
        _cycleEdges([2, 5, 3, 4], [6, 7, 8], [6, 7, 8], [6, 7, 8], [6, 7, 8]);
        break;

      // Cột dọc phải (Right Column)
      case 'R':
        _rotateFaceClockwise(4);
        _cycleEdges([0, 3, 1, 2], [2, 5, 8], [6, 3, 0], [2, 5, 8], [2, 5, 8]);
        break;
      case "R'":
        _rotateFaceCounterClockwise(4);
        _cycleEdges([2, 1, 3, 0], [2, 5, 8], [2, 5, 8], [6, 3, 0], [2, 5, 8]);
        break;

      // Cột dọc giữa (Middle Column)
      case 'M':
        _cycleEdges([0, 2, 1, 3], [1, 4, 7], [1, 4, 7], [1, 4, 7], [7, 4, 1]);
        break;
      case "M'":
        _cycleEdges([3, 1, 2, 0], [7, 4, 1], [1, 4, 7], [1, 4, 7], [1, 4, 7]);
        break;

      // Cột dọc trái (Left Column)
      case 'L':
        _rotateFaceClockwise(5);
        _cycleEdges([0, 2, 1, 3], [0, 3, 6], [0, 3, 6], [0, 3, 6], [8, 5, 2]);
        break;
      case "L'":
        _rotateFaceCounterClockwise(5);
        _cycleEdges([3, 1, 2, 0], [8, 5, 2], [0, 3, 6], [0, 3, 6], [0, 3, 6]);
        break;

      // Mặt trước (Front Face)
      case 'F':
        _rotateFaceClockwise(2);
        _cycleEdges([0, 4, 1, 5], [6, 7, 8], [0, 3, 6], [2, 1, 0], [8, 5, 2]);
        break;
      case "F'":
        _rotateFaceCounterClockwise(2);
        _cycleEdges([5, 1, 4, 0], [8, 5, 2], [2, 1, 0], [0, 3, 6], [6, 7, 8]);
        break;

      // Mặt sau (Back Face)
      case 'B':
        _rotateFaceClockwise(3);
        _cycleEdges([0, 5, 1, 4], [2, 1, 0], [0, 3, 6], [6, 7, 8], [8, 5, 2]);
        break;
      case "B'":
        _rotateFaceCounterClockwise(3);
        _cycleEdges([4, 1, 5, 0], [8, 5, 2], [6, 7, 8], [0, 3, 6], [2, 1, 0]);
        break;

      default:
        _rotateFaceClockwise(0);
        break;
    }
  }

  void _rotateFaceClockwise(int faceIdx) {
    final f = List<Color>.from(_faces[faceIdx]);
    _faces[faceIdx][0] = f[6];
    _faces[faceIdx][1] = f[3];
    _faces[faceIdx][2] = f[0];
    _faces[faceIdx][3] = f[7];
    _faces[faceIdx][4] = f[4];
    _faces[faceIdx][5] = f[1];
    _faces[faceIdx][6] = f[8];
    _faces[faceIdx][7] = f[5];
    _faces[faceIdx][8] = f[2];
  }

  void _rotateFaceCounterClockwise(int faceIdx) {
    final f = List<Color>.from(_faces[faceIdx]);
    _faces[faceIdx][0] = f[2];
    _faces[faceIdx][1] = f[5];
    _faces[faceIdx][2] = f[8];
    _faces[faceIdx][3] = f[1];
    _faces[faceIdx][4] = f[4];
    _faces[faceIdx][5] = f[7];
    _faces[faceIdx][6] = f[0];
    _faces[faceIdx][7] = f[3];
    _faces[faceIdx][8] = f[6];
  }

  void _cycleEdges(List<int> faces, List<int> p1, List<int> p2, List<int> p3, List<int> p4) {
    final c1 = [for (var i in p1) _faces[faces[0]][i]];
    final c2 = [for (var i in p2) _faces[faces[1]][i]];
    final c3 = [for (var i in p3) _faces[faces[2]][i]];
    final c4 = [for (var i in p4) _faces[faces[3]][i]];

    for (int i = 0; i < 3; i++) {
      _faces[faces[1]][p2[i]] = c1[i];
      _faces[faces[2]][p3[i]] = c2[i];
      _faces[faces[3]][p4[i]] = c3[i];
      _faces[faces[0]][p1[i]] = c4[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotY += details.delta.dx * 0.015;
          _rotX -= details.delta.dy * 0.015;
        });
      },
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Khung vẽ đồ họa 3D khối Rubik đặc nguyên khối chân thực
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RealisticRubik3dPainter(
                  rotX: _rotX,
                  rotY: _rotY,
                  faces: _faces,
                  cubeSize: widget.size,
                ),
              ),

              // Huy hiệu hiển thị nước xoay đang thực hiện
              if (_activeMove.isNotEmpty)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: GoddyTheme.glowBox(
                      borderColor: GoddyTheme.neonCyan,
                      bgColor: GoddyTheme.bgDark.withValues(alpha: 0.9),
                      radius: 8,
                    ),
                    child: Text(
                      'XOAY: $_activeMove',
                      style: const TextStyle(
                        color: GoddyTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vector3d {
  final double x;
  final double y;
  final double z;

  const _Vector3d(this.x, this.y, this.z);

  _Vector3d operator +(_Vector3d other) => _Vector3d(x + other.x, y + other.y, z + other.z);
  _Vector3d operator -(_Vector3d other) => _Vector3d(x - other.x, y - other.y, z - other.z);
  _Vector3d operator *(double scalar) => _Vector3d(x * scalar, y * scalar, z * scalar);

  double dot(_Vector3d other) => x * other.x + y * other.y + z * other.z;

  _Vector3d rotateY(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return _Vector3d(x * cosA + z * sinA, y, -x * sinA + z * cosA);
  }

  _Vector3d rotateX(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return _Vector3d(x, y * cosA - z * sinA, y * sinA + z * cosA);
  }

  Offset project(Offset center, double fov) {
    final k = fov / (fov - z);
    return Offset(center.dx + x * k, center.dy + y * k);
  }
}

class _VisibleFaceData {
  final int faceIndex;
  final double centerZ;
  final double diffuse;

  _VisibleFaceData({
    required this.faceIndex,
    required this.centerZ,
    required this.diffuse,
  });
}

class _RealisticRubik3dPainter extends CustomPainter {
  final double rotX;
  final double rotY;
  final List<List<Color>> faces;
  final double cubeSize;

  static const _Vector3d lightDir = _Vector3d(-0.4, -0.6, 0.69);

  const _RealisticRubik3dPainter({
    required this.rotX,
    required this.rotY,
    required this.faces,
    this.cubeSize = 210.0,
  });

  double get L => cubeSize * (72.0 / 280.0);
  double get fov => cubeSize * (460.0 / 280.0);

  _Vector3d _transform(_Vector3d v) {
    return v.rotateY(rotY).rotateX(rotX);
  }

  Path _buildRoundedQuad(List<Offset> pts, double r) {
    final path = Path();
    final p0In = Offset.lerp(pts[0], pts[3], r)!;
    final p0Out = Offset.lerp(pts[0], pts[1], r)!;
    final p1In = Offset.lerp(pts[1], pts[0], r)!;
    final p1Out = Offset.lerp(pts[1], pts[2], r)!;
    final p2In = Offset.lerp(pts[2], pts[1], r)!;
    final p2Out = Offset.lerp(pts[2], pts[3], r)!;
    final p3In = Offset.lerp(pts[3], pts[2], r)!;
    final p3Out = Offset.lerp(pts[3], pts[0], r)!;

    path.moveTo(p0Out.dx, p0Out.dy);
    path.lineTo(p1In.dx, p1In.dy);
    path.quadraticBezierTo(pts[1].dx, pts[1].dy, p1Out.dx, p1Out.dy);
    path.lineTo(p2In.dx, p2In.dy);
    path.quadraticBezierTo(pts[2].dx, pts[2].dy, p2Out.dx, p2Out.dy);
    path.lineTo(p3In.dx, p3In.dy);
    path.quadraticBezierTo(pts[3].dx, pts[3].dy, p3Out.dx, p3Out.dy);
    path.lineTo(p0In.dx, p0In.dy);
    path.quadraticBezierTo(pts[0].dx, pts[0].dy, p0Out.dx, p0Out.dy);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 8);

    // 1. Hiệu ứng đổ bóng 3D mềm mại trên mặt bàn phía dưới khối Rubik
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.65),
          Colors.black.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(center.dx, center.dy + L * 1.55),
        width: L * 3.4,
        height: L * 0.9,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + L * 1.55),
        width: L * 3.4,
        height: L * 0.9,
      ),
      shadowPaint,
    );

    // Định nghĩa hình học 6 mặt Rubik: (tâm mặt, trục u, trục v, vector pháp tuyến)
    final faceDefs = [
      // 0: Mặt Trên - Up (Trắng, Y = -L)
      (_Vector3d(0, -L, 0), const _Vector3d(1, 0, 0), const _Vector3d(0, 0, 1), const _Vector3d(0, -1, 0)),
      // 1: Mặt Đáy - Down (Vàng, Y = +L)
      (_Vector3d(0, L, 0), const _Vector3d(1, 0, 0), const _Vector3d(0, 0, -1), const _Vector3d(0, 1, 0)),
      // 2: Mặt Trước - Front (Xanh lá, Z = +L)
      (_Vector3d(0, 0, L), const _Vector3d(1, 0, 0), const _Vector3d(0, 1, 0), const _Vector3d(0, 0, 1)),
      // 3: Mặt Sau - Back (Xanh dương, Z = -L)
      (_Vector3d(0, 0, -L), const _Vector3d(-1, 0, 0), const _Vector3d(0, 1, 0), const _Vector3d(0, 0, -1)),
      // 4: Mặt Phải - Right (Đỏ, X = +L)
      (_Vector3d(L, 0, 0), const _Vector3d(0, 0, -1), const _Vector3d(0, 1, 0), const _Vector3d(1, 0, 0)),
      // 5: Mặt Trái - Left (Cam, X = -L)
      (_Vector3d(-L, 0, 0), const _Vector3d(0, 0, 1), const _Vector3d(0, 1, 0), const _Vector3d(-1, 0, 0)),
    ];

    final visibleFaces = <_VisibleFaceData>[];

    for (int i = 0; i < 6; i++) {
      final normal = _transform(faceDefs[i].$4);
      // Mặt chỉ hiển thị khi góc pháp tuyến normal.z > 0 (hướng về phía màn hình camera)
      if (normal.z > 0.001) {
        final faceCenter = _transform(faceDefs[i].$1);
        final diffuse = (normal.dot(lightDir)).clamp(0.0, 1.0);
        visibleFaces.add(_VisibleFaceData(
          faceIndex: i,
          centerZ: faceCenter.z,
          diffuse: diffuse,
        ));
      }
    }

    // Sắp xếp các mặt theo độ sâu trục Z để vẽ từ xa đến gần (Z-sorting painter algorithm)
    visibleFaces.sort((a, b) => a.centerZ.compareTo(b.centerZ));

    final blackBodyPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;

    final outerChamferPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final stickerBorderPaint = Paint()
      ..color = const Color(0xFF161B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Vẽ các mặt đang nhìn thấy
    for (final vf in visibleFaces) {
      final fIdx = vf.faceIndex;
      final def = faceDefs[fIdx];
      final fCenter = def.$1;
      final uAxis = def.$2;
      final vAxis = def.$3;

      // 1. Thân lõi nhựa màu đen của khối Rubik (Chassis không khe hở)
      final cTL = _transform(fCenter - uAxis * L - vAxis * L).project(center, fov);
      final cTR = _transform(fCenter + uAxis * L - vAxis * L).project(center, fov);
      final cBR = _transform(fCenter + uAxis * L + vAxis * L).project(center, fov);
      final cBL = _transform(fCenter - uAxis * L + vAxis * L).project(center, fov);

      final faceBasePath = Path()
        ..moveTo(cTL.dx, cTL.dy)
        ..lineTo(cTR.dx, cTR.dy)
        ..lineTo(cBR.dx, cBR.dy)
        ..lineTo(cBL.dx, cBL.dy)
        ..close();
      canvas.drawPath(faceBasePath, blackBodyPaint);
      canvas.drawPath(faceBasePath, outerChamferPaint);

      // 2. Vẽ 9 miếng dán decal bo góc 3D (lưới ma trận 3x3)
      final double step = (2 * L) / 3.0;
      final double pad = 3.2 * (cubeSize / 280.0); // Rãnh đen giữa các viên rubik

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final stickerIdx = row * 3 + col;
          final color = faces[fIdx][stickerIdx];

          final u0 = -L + col * step + pad;
          final u1 = -L + (col + 1) * step - pad;
          final v0 = -L + row * step + pad;
          final v1 = -L + (row + 1) * step - pad;

          final p0 = _transform(fCenter + uAxis * u0 + vAxis * v0).project(center, fov);
          final p1 = _transform(fCenter + uAxis * u1 + vAxis * v0).project(center, fov);
          final p2 = _transform(fCenter + uAxis * u1 + vAxis * v1).project(center, fov);
          final p3 = _transform(fCenter + uAxis * u0 + vAxis * v1).project(center, fov);

          // Tạo hình đa giác decal bo viền mềm chân thực trong không gian 3D
          final stickerPath = _buildRoundedQuad([p0, p1, p2, p3], 0.16);

          // Đổ bóng 3D chân thực với độ đậm nét 100%
          final brightness = (0.78 + 0.22 * vf.diffuse).clamp(0.0, 1.0);
          final baseShaded = Color.fromARGB(
            255,
            (color.r * 255 * brightness).clamp(0, 255).toInt(),
            (color.g * 255 * brightness).clamp(0, 255).toInt(),
            (color.b * 255 * brightness).clamp(0, 255).toInt(),
          );

          // Ánh sáng phản chiếu bóng gương (Specular Highlight giống khối Rubik thật)
          final stickerRect = stickerPath.getBounds();
          final fillPaint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(baseShaded, Colors.white, 0.28)!,
                baseShaded,
                Color.lerp(baseShaded, Colors.black, 0.15)!,
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(stickerRect)
            ..style = PaintingStyle.fill;

          canvas.drawPath(stickerPath, fillPaint);
          canvas.drawPath(stickerPath, stickerBorderPaint);

          // 3. Logo thương hiệu Rubik chính hãng trên nhãn tâm màu trắng
          if (fIdx == 0 && stickerIdx == 4) {
            final centerPoint = Offset(
              (p0.dx + p1.dx + p2.dx + p3.dx) / 4,
              (p0.dy + p1.dy + p2.dy + p3.dy) / 4,
            );
            // Huy hiệu biểu tượng logo
            final badgePaint = Paint()
              ..color = const Color(0xFF1E293B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4;
            canvas.drawCircle(centerPoint, 8.0, Paint()..color = Colors.white.withValues(alpha: 0.9));
            canvas.drawCircle(centerPoint, 8.0, badgePaint);

            // Mô hình Rubik 3D thu nhỏ trên logo
            final logoPaint = Paint()..style = PaintingStyle.fill;
            logoPaint.color = RubikCubeWidgetState.cRed;
            canvas.drawCircle(centerPoint + const Offset(-2, -2), 2.0, logoPaint);
            logoPaint.color = RubikCubeWidgetState.cGreen;
            canvas.drawCircle(centerPoint + const Offset(2, -2), 2.0, logoPaint);
            logoPaint.color = RubikCubeWidgetState.cBlue;
            canvas.drawCircle(centerPoint + const Offset(0, 2), 2.0, logoPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticRubik3dPainter oldDelegate) {
    return oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.faces != faces ||
        oldDelegate.cubeSize != cubeSize;
  }
}
