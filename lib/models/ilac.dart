class Ilac {
  final int bildirimId; // Stabil, kalıcı bildirim kimliği
  final String isim;
  final String doz;
  final String saat;
  final String emoji;
  final List<int> gunler;
  final String eklemeTarihi; // 'YYYY-MM-DD' — takvimde bu tarihten önce gösterilmez
  bool alindi;
  String sonAlinmaTarihi;
  Map<String, bool> gecmis;
  int stok;
  int stokUyariEsigi;

  Ilac({
    int? bildirimId,
    required this.isim,
    required this.doz,
    required this.saat,
    required this.emoji,
    this.gunler = const [1, 2, 3, 4, 5, 6, 7],
    String? eklemeTarihi,
    this.alindi = false,
    this.sonAlinmaTarihi = '',
    Map<String, bool>? gecmis,
    this.stok = 0,
    this.stokUyariEsigi = 5,
    // Her ilaca 30 slotluk aralık → 28 bildirim + 1 stok asla çakışmaz
  })  : bildirimId = bildirimId ??
            (DateTime.now().microsecondsSinceEpoch.abs() % 60000000) * 30,
        eklemeTarihi =
            eklemeTarihi ?? DateTime.now().toIso8601String().substring(0, 10),
        gecmis = gecmis ?? {};

  Map<String, dynamic> toJson() => {
        'bildirimId': bildirimId,
        'isim': isim,
        'doz': doz,
        'saat': saat,
        'emoji': emoji,
        'gunler': gunler,
        'eklemeTarihi': eklemeTarihi,
        'alindi': alindi,
        'sonAlinmaTarihi': sonAlinmaTarihi,
        'gecmis': gecmis,
        'stok': stok,
        'stokUyariEsigi': stokUyariEsigi,
      };

  factory Ilac.fromJson(Map<String, dynamic> json) => Ilac(
        bildirimId: json['bildirimId'] as int?,
        isim: json['isim'],
        doz: json['doz'],
        saat: json['saat'],
        emoji: json['emoji'],
        gunler: List<int>.from(json['gunler'] ?? [1, 2, 3, 4, 5, 6, 7]),
        eklemeTarihi: json['eklemeTarihi'] as String?,
        alindi: json['alindi'] ?? false,
        sonAlinmaTarihi: json['sonAlinmaTarihi'] ?? '',
        gecmis: json['gecmis'] != null
            ? Map<String, bool>.from(json['gecmis'])
            : {},
        stok: json['stok'] ?? 0,
        stokUyariEsigi: json['stokUyariEsigi'] ?? 5,
      );
}
