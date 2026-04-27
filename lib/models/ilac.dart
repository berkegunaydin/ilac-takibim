class Ilac {
  final int bildirimId;
  final String isim;
  final String doz;
  final String saat;
  final String emoji;
  final List<int> gunler;
  final String eklemeTarihi;
  final int bildirimOnce; // dakika: 0=zamanında, 5/15/30/60=önce
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
    this.bildirimOnce = 0,
    this.alindi = false,
    this.sonAlinmaTarihi = '',
    Map<String, bool>? gecmis,
    this.stok = 0,
    this.stokUyariEsigi = 5,
    // Her ilaca 20 slotluk aralık → 7 ana + 7 takip + 1 stok = 15 slot
  })  : bildirimId = bildirimId ??
            (DateTime.now().microsecondsSinceEpoch.abs() % 100000000) * 20,
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
        'bildirimOnce': bildirimOnce,
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
        bildirimOnce: json['bildirimOnce'] as int? ?? 0,
        alindi: json['alindi'] ?? false,
        sonAlinmaTarihi: json['sonAlinmaTarihi'] ?? '',
        gecmis: json['gecmis'] != null
            ? Map<String, bool>.from(json['gecmis'])
            : {},
        stok: json['stok'] ?? 0,
        stokUyariEsigi: json['stokUyariEsigi'] ?? 5,
      );
}
