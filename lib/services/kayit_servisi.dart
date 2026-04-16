import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profil.dart';

class KayitServisi {
  static Future<List<Profil>> profilleriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('profiller') ?? [];
    final bugun = DateTime.now().toIso8601String().substring(0, 10);

    if (jsonList.isEmpty) {
      return [Profil(isim: 'Ben', emoji: '👤')];
    }

    return jsonList.map((e) {
      final profil = Profil.fromJson(jsonDecode(e));
      for (final ilac in profil.ilaclar) {
        if (ilac.sonAlinmaTarihi != bugun) {
          ilac.alindi = false;
        }
      }
      return profil;
    }).toList();
  }

  static Future<void> profilleriKaydet(List<Profil> profiller) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = profiller.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('profiller', jsonList);
  }

}