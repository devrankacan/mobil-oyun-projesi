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
3. Android export presetlerini Godot'tan ayarla (Project > Export > Android), APK/AAB üret.

## Yapılacaklar (sıradaki adımlar)

- Client-side prediction / interpolation (gecikmeyi gizlemek için)
- TLS (wss://) — VPS'e domain + sertifika eklenince
- Skor tablosu / oda listesi
- Görsel iyileştirme (isim etiketleri, renkler, skin sistemi)
