# Mobil Oyun Projesi

Android için 2D, gerçek zamanlı çok oyunculu arena oyunu (agar.io/slither.io tarzı).

## Mimari

- **client/** — Godot 4 projesi (Android export). Oyuncu girdisini sunucuya yollar, sunucudan gelen state'i render eder. Client-side prediction yok (ilk MVP).
- **server/** — Go ile yazılmış authoritative gerçek zamanlı sunucu. WebSocket (`/ws`) üzerinden 30Hz'de oyun durumunu yayınlar. Hareket, yiyecek toplama ve oyuncu çarpışma/yeme mantığı sunucuda hesaplanır.

## Sunucuyu çalıştırma

```bash
cd server
go run .
# :7777 üzerinde dinler, endpoint: ws://<host>:7777/ws
```

VPS'e deploy ederken `server` klasörünü derleyip (`go build`) çalıştırman yeterli; harici bağımlılık yok (statik binary).

## İstemciyi açma

1. Godot 4.3+ Editor ile `client/` klasörünü aç.
2. `client/scripts/NetworkManager.gd` içindeki `SERVER_URL` sabitini kendi VPS IP/domain'in ile güncelle (`ws://VPS_IP:7777/ws`).
3. Android export preset'i (`export_presets.cfg`) repoda zaten tanımlı (INTERNET izni dahil). Godot Editor'de Project > Export açtığında "Android" preset'ini hazır görürsün.

### Android export için gerekenler (ilk kurulum)

- **Android Build Template**: Project > Install Android Build Template (bir kerelik)
- **Android SDK + JDK 17**: Editor > Editor Settings > Export > Android altında SDK ve `adb`/`jarsigner` yollarını ayarla. Android Studio kuruluysa SDK Manager üzerinden komut satırı araçlarını indirebilirsin.
- **Debug keystore**: ilk testler için Godot otomatik debug keystore oluşturur, ek ayar gerekmez.
- **Release imzalama**: Play Store'a yüklemeden önce kendi keystore'unu oluşturup (`keytool -genkey -v -keystore release.keystore ...`) preset'e eklemen gerekir — bu dosyayı repoya **eklemeyiz** (gizli tutulmalı).

Kurulum tamamlandıktan sonra Project > Export > Android > Export Project ile APK üretebilirsin.

## Yapılacaklar (sıradaki adımlar)

- Client-side prediction / interpolation (gecikmeyi gizlemek için)
- TLS (wss://) — VPS'e domain + sertifika eklenince
- Skor tablosu / oda listesi
- Görsel iyileştirme (isim etiketleri, renkler, skin sistemi)
