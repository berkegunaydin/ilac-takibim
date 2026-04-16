import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  const green = 0xFF1D9E75;
  const white = 0xFFFFFFFF;
  const transparent = 0x00000000;

  // --- 1. Tam ikon (yeşil arka plan + ilaç kapsülü) ---
  final full = img.Image(width: size, height: size);
  img.fill(full, color: img.ColorRgba8(0, 0, 0, 0));

  // Yuvarlak yeşil arka plan
  _fillCircle(full, size ~/ 2, size ~/ 2, size ~/ 2, green);

  // İlaç kapsülü (yatay hap şekli)
  _drawPill(full, size, white, green);

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(full));
  // ignore: avoid_print
  print('✓ assets/icon/icon.png oluşturuldu');

  // --- 2. Adaptif ikon ön plan (şeffaf arka plan + beyaz kapsül) ---
  final fg = img.Image(width: size, height: size);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  _drawPill(fg, size, white, transparent);

  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));
  // ignore: avoid_print
  print('✓ assets/icon/icon_foreground.png oluşturuldu');
}

void _drawPill(img.Image image, int size, int pillColor, int dividerColor) {
  // Kapsül boyutları: 520x220, ortada
  const pillW = 520;
  const pillH = 220;
  final cx = size ~/ 2;
  final cy = size ~/ 2;
  final r = pillH ~/ 2;
  final left = cx - pillW ~/ 2;
  final right = cx + pillW ~/ 2;
  final top = cy - r;
  final bottom = cy + r;

  // Sol yarım daire
  _fillCircle(image, left + r, cy, r, pillColor);
  // Sağ yarım daire
  _fillCircle(image, right - r, cy, r, pillColor);
  // Orta dikdörtgen
  _fillRect(image, left + r, top, right - r, bottom, pillColor);

  // Orta çizgi (kapsülü ikiye böler)
  if (dividerColor != 0x00000000) {
    _fillRect(image, cx - 6, top, cx + 6, bottom, dividerColor);
  }
}

void _fillCircle(img.Image image, int cx, int cy, int r, int colorHex) {
  final color = img.ColorRgba8(
    (colorHex >> 16) & 0xFF,
    (colorHex >> 8) & 0xFF,
    colorHex & 0xFF,
    (colorHex >> 24) & 0xFF,
  );
  for (int y = cy - r; y <= cy + r; y++) {
    for (int x = cx - r; x <= cx + r; x++) {
      if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r) {
        if (x >= 0 && y >= 0 && x < image.width && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

void _fillRect(img.Image image, int x1, int y1, int x2, int y2, int colorHex) {
  final color = img.ColorRgba8(
    (colorHex >> 16) & 0xFF,
    (colorHex >> 8) & 0xFF,
    colorHex & 0xFF,
    (colorHex >> 24) & 0xFF,
  );
  for (int y = y1; y <= y2; y++) {
    for (int x = x1; x <= x2; x++) {
      if (x >= 0 && y >= 0 && x < image.width && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }
}
