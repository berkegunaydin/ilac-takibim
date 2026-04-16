import 'ilac.dart';

class Profil {
  String isim;
  String emoji;
  List<Ilac> ilaclar;

  Profil({
    required this.isim,
    required this.emoji,
    List<Ilac>? ilaclar,
  }) : ilaclar = ilaclar ?? [];

  Map<String, dynamic> toJson() => {
    'isim': isim,
    'emoji': emoji,
    'ilaclar': ilaclar.map((e) => e.toJson()).toList(),
  };

  factory Profil.fromJson(Map<String, dynamic> json) => Profil(
    isim: json['isim'],
    emoji: json['emoji'],
    ilaclar: (json['ilaclar'] as List?)
        ?.map((e) => Ilac.fromJson(e))
        .toList() ?? [],
  );
}