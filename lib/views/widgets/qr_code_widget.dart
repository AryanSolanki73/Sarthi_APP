import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Self-contained, pure Dart QR Code widget conforming to ISO/IEC 18004.
/// Generates and paints camera-readable QR code matrices without external packages.
class QrCodeWidget extends StatelessWidget {
  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 180.0,
    this.foregroundColor = const Color(0xFF18181B),
    this.backgroundColor = Colors.white,
    this.showCenterBadge = false,
  });

  /// The string payload to encode (e.g. 'TKT-884129').
  final String data;

  /// The dimension (width and height) of the rendered QR code widget.
  final double size;

  /// Color of the QR modules (black).
  final Color foregroundColor;

  /// Color of the background (white).
  final Color backgroundColor;

  /// Whether to render a small transit icon in the center.
  final bool showCenterBadge;

  @override
  Widget build(BuildContext context) {
    final matrix = _QrEncoder.encode(data);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size * 0.9, size * 0.9),
            painter: _QrPainter(
              matrix: matrix,
              color: foregroundColor,
            ),
          ),
          if (showCenterBadge)
            Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: foregroundColor, width: 2),
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                size: size * 0.12,
                color: const Color(0xFF009B6A),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter that draws the QR code grid modules onto the canvas.
class _QrPainter extends CustomPainter {
  const _QrPainter({
    required this.matrix,
    required this.color,
  });

  final List<List<int>> matrix;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final n = matrix.length;
    if (n == 0) return;

    final cellSize = size.width / n;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (matrix[r][c] == 1) {
          final rect = Rect.fromLTWH(
            c * cellSize,
            r * cellSize,
            cellSize + 0.1, // slight overlap to prevent subpixel hairline gaps
            cellSize + 0.1,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.matrix != matrix || oldDelegate.color != color;
  }
}

/// Pure Dart standard QR Code Matrix Encoder (Version 1 & 2, Byte Mode, EC Level M).
class _QrEncoder {
  static final List<int> _exp = List<int>.filled(512, 0);
  static final List<int> _log = List<int>.filled(256, 0);
  static bool _tablesInitialized = false;

  static void _initTables() {
    if (_tablesInitialized) return;
    int x = 1;
    for (int i = 0; i < 255; i++) {
      _exp[i] = x;
      _exp[i + 255] = x;
      _log[x] = i;
      x = x << 1;
      if ((x & 256) != 0) {
        x ^= 285; // primitive polynomial x^8 + x^4 + x^3 + x^2 + 1
      }
    }
    _tablesInitialized = true;
  }

  static int _gmul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _exp[(_log[a] + _log[b]) % 255];
  }

  static List<int> _rsEncode(List<int> data, int nEc) {
    _initTables();
    List<int> gen = [1];
    for (int i = 0; i < nEc; i++) {
      final nxt = List<int>.filled(gen.length + 1, 0);
      for (int j = 0; j < gen.length; j++) {
        nxt[j] ^= gen[j];
        nxt[j + 1] ^= _gmul(gen[j], _exp[i]);
      }
      gen = nxt;
    }

    final res = List<int>.from(data)..addAll(List<int>.filled(nEc, 0));
    for (int i = 0; i < data.length; i++) {
      final lead = res[i];
      if (lead != 0) {
        for (int j = 0; j < gen.length; j++) {
          res[i + j] ^= _gmul(lead, gen[j]);
        }
      }
    }
    return res.sublist(data.length);
  }

  /// Encodes data into a 2D integer matrix (1 = black, 0 = white).
  static List<List<int>> encode(String text) {
    _initTables();
    final rawBytes = text.codeUnits;

    // Use Version 1 (21x21, max 14 bytes in M) or Version 2 (25x25, max 26 bytes in M)
    final isVersion1 = rawBytes.length <= 14;
    final version = isVersion1 ? 1 : 2;
    final n = version == 1 ? 21 : 25;
    final totalDataCodewords = version == 1 ? 16 : 28;
    final totalEcCodewords = version == 1 ? 10 : 16;

    // Build bitstream: 0100 (Byte mode) + 8-bit length + data + 0000 terminator
    final bits = <int>[0, 1, 0, 0];
    final lenStr = rawBytes.length.toRadixString(2).padLeft(8, '0');
    for (int i = 0; i < 8; i++) {
      bits.add(lenStr.codeUnitAt(i) - 48);
    }
    for (final b in rawBytes) {
      final bStr = b.toRadixString(2).padLeft(8, '0');
      for (int i = 0; i < 8; i++) {
        bits.add(bStr.codeUnitAt(i) - 48);
      }
    }

    // Add terminator
    final maxBits = totalDataCodewords * 8;
    final termLen = math.min(4, maxBits - bits.length);
    for (int i = 0; i < termLen; i++) {
      bits.add(0);
    }

    // Pad to byte boundary
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    // Convert to bytes & append alternating pad codewords 0xEC, 0x11
    final codewords = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int val = 0;
      for (int j = 0; j < 8; j++) {
        val = (val << 1) | bits[i + j];
      }
      codewords.add(val);
    }

    final padCodewords = [0xEC, 0x11];
    int padIdx = 0;
    while (codewords.length < totalDataCodewords) {
      codewords.add(padCodewords[padIdx % 2]);
      padIdx++;
    }

    // Reed-Solomon Error Correction
    final ecBytes = _rsEncode(codewords, totalEcCodewords);
    final allBytes = [...codewords, ...ecBytes];

    final allBits = <int>[];
    for (final byteVal in allBytes) {
      final s = byteVal.toRadixString(2).padLeft(8, '0');
      for (int i = 0; i < 8; i++) {
        allBits.add(s.codeUnitAt(i) - 48);
      }
    }

    // Construct QR Grid
    final grid = List.generate(n, (_) => List<int>.filled(n, 0));
    final reserved = List.generate(n, (_) => List<bool>.filled(n, false));

    void addFinder(int r0, int c0) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isBlack = (r == 0 || r == 6 || c == 0 || c == 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4));
          grid[r0 + r][c0 + c] = isBlack ? 1 : 0;
          reserved[r0 + r][c0 + c] = true;
        }
      }
      for (int r = -1; r <= 7; r++) {
        for (int c = -1; c <= 7; c++) {
          if (r == -1 || r == 7 || c == -1 || c == 7) {
            final rr = r0 + r;
            final cc = c0 + c;
            if (rr >= 0 && rr < n && cc >= 0 && cc < n) {
              grid[rr][cc] = 0;
              reserved[rr][cc] = true;
            }
          }
        }
      }
    }

    addFinder(0, 0);
    addFinder(0, n - 7);
    addFinder(n - 7, 0);

    // Alignment pattern for Version 2 (at center (18, 18))
    if (version == 2) {
      const cr = 18;
      const cc = 18;
      for (int r = -2; r <= 2; r++) {
        for (int c = -2; c <= 2; c++) {
          final isBlack = (r.abs() == 2 || c.abs() == 2 || (r == 0 && c == 0));
          grid[cr + r][cc + c] = isBlack ? 1 : 0;
          reserved[cr + r][cc + c] = true;
        }
      }
    }

    // Timing Patterns
    for (int i = 8; i < n - 8; i++) {
      grid[6][i] = (i % 2 == 0) ? 1 : 0;
      reserved[6][i] = true;
      grid[i][6] = (i % 2 == 0) ? 1 : 0;
      reserved[i][6] = true;
    }

    // Dark Module
    final darkR = 4 * version + 9;
    grid[darkR][8] = 1;
    reserved[darkR][8] = true;

    // Reserve Format Information areas
    for (int i = 0; i <= 8; i++) {
      reserved[8][i] = true;
      reserved[i][8] = true;
    }
    for (int i = 0; i < 8; i++) {
      reserved[8][n - 1 - i] = true;
      reserved[n - 1 - i][8] = true;
    }

    // Data placement in 2-column bands with Mask Pattern 0: (row + col) % 2 == 0
    int bitIdx = 0;
    bool up = true;
    int col = n - 1;

    while (col > 0) {
      if (col == 6) col--; // skip vertical timing column
      final rows = up ? List.generate(n, (i) => n - 1 - i) : List.generate(n, (i) => i);

      for (final r in rows) {
        for (final c in [col, col - 1]) {
          if (!reserved[r][c]) {
            int b = (bitIdx < allBits.length) ? allBits[bitIdx] : 0;
            bitIdx++;
            // Apply Mask 0
            if ((r + c) % 2 == 0) {
              b ^= 1;
            }
            grid[r][c] = b;
          }
        }
      }
      up = !up;
      col -= 2;
    }

    // Format Information (EC Level M = 00, Mask 0 = 000 -> 0x5412)
    const fb = 0x5412;
    final fbStr = fb.toRadixString(2).padLeft(15, '0');
    final fbBits = List.generate(15, (i) => fbStr.codeUnitAt(i) - 48);

    // Top-left
    grid[8][0] = fbBits[0];
    grid[8][1] = fbBits[1];
    grid[8][2] = fbBits[2];
    grid[8][3] = fbBits[3];
    grid[8][4] = fbBits[4];
    grid[8][5] = fbBits[5];
    grid[8][7] = fbBits[6];
    grid[8][8] = fbBits[7];
    grid[7][8] = fbBits[8];
    grid[5][8] = fbBits[9];
    grid[4][8] = fbBits[10];
    grid[3][8] = fbBits[11];
    grid[2][8] = fbBits[12];
    grid[1][8] = fbBits[13];
    grid[0][8] = fbBits[14];

    // Bottom-left & Top-right
    for (int i = 0; i < 7; i++) {
      grid[n - 1 - i][8] = fbBits[i];
    }
    for (int i = 0; i < 8; i++) {
      grid[8][n - 8 + i] = fbBits[7 + i];
    }

    return grid;
  }
}

