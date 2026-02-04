# ⚡ Vexel Control Script

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Lua](https://img.shields.io/badge/language-Lua-000080.svg)
![Platform](https://img.shields.io/badge/platform-Roblox-red.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**Vexel Control**, Roblox oyuncuları ve geliştiricileri için tasarlanmış, modern bir kullanıcı arayüzüne (UI) sahip, kapsamlı bir yönetim ve yardımcı araç scriptidir. Gelişmiş hedef takip sistemi, görsel yardımcılar (ESP/Chams) ve karakter kontrol özellikleri ile oyun deneyimini bir üst seviyeye taşır.

---

## 🌟 Özellikler (Features)

### 🖥️ Kullanıcı Arayüzü (UI)
* **Modern Tasarım:** Karanlık tema (Dark Mode) ve yumuşak geçiş efektleri.
* **Draggable Frames:** Menü, Chat Log ve Hedef Monitörü ekranın istenilen yerine taşınabilir.
* **Minimize Modu:** Ekranı kaplamaması için küçültülebilir arayüz.

### 👁️ Görsel & ESP
* **Player ESP:** Oyuncuların isimlerini ve mesafelerini duvar arkasından gösterir.
* **Chams:** Oyuncuları parlak bir materyal ile vurgular (Duvar arkası görünürlük).
* **Target Monitor:** Hedeflenen oyuncunun Can (HP), Mesafe ve elindeki Eşya (Tool) bilgisini canlı gösterir.

### 🚀 Hareket & Karakter
* **Fly (Uçuş):** `F` tuşu ile aktifleşir, tamamen kontrol edilebilir uçuş modu.
* **Noclip:** Duvarlardan ve engellerden geçme özelliği.
* **Freecam:** `P` tuşu ile kamerayı karakterden bağımsız hareket ettirme (Spectator modu).
* **Infinite Zoom:** Kamera uzaklaştırma sınırını kaldırır.
* **Anti-Ragdoll:** Karakterin yere düşmesini veya sersemlemesini engeller.

### 🎯 Hedef & Etkileşim
* **Target Selector:** İsim ile oyuncu seçimi (Kısaltmalar desteklenir).
* **Teleport (TP):** Seçilen hedefin yanına ışınlanma.
* **Loop Follow:** Hedefi sürekli takip etme.
* **Spectate:** Hedefi izleme modu.
* **Fling:** Hedefi fizik motorunu kullanarak fırlatma (Troll).
* **Click TP:** `CTRL + Tık` ile haritada tıklanan yere ışınlanma.
* **Click Delete:** `CTRL + Tık` ile nesneleri silme.

### 🛠️ Diğer Araçlar
* **Chat Logger:** Oyun içi sohbeti kaydeden ve filtreleyen özel panel.
* **Server Hop:** Dolu olmayan başka bir sunucuya hızlı geçiş.
* **Rejoin:** Aynı sunucuya hızlıca tekrar bağlanma.

---

## 📸 Ekran Görüntüleri (Screenshots)

*(Buraya scriptin menüsünün ekran görüntülerini ekleyebilirsin)*

| Ana Menü | ESP & Monitor |
| :---: | :---: |
| ![Menu Preview]([https://imgur.com/a/sPoLHLR)) | ![ESP Preview]([https://imgur.com/a/YHo1Dob)) |

---

## 🎮 Kontroller (Keybinds)

Script içerisindeki varsayılan tuş atamaları aşağıdadır:

| Tuş | İşlev | Açıklama |
| :--- | :--- | :--- |
| **F1** | Menü Aç/Kapat | Arayüzü gizler veya gösterir. |
| **F** | Fly (Uçuş) | Uçuş modunu açar veya kapatır. |
| **P** | Freecam | Serbest kamera moduna geçer. |
| **CTRL + Click** | Işınlanma (TP) | Mouse ile tıklanan yere ışınlanır (Ayar açıksa). |
| **CTRL + Click** | Silme (Delete) | Tıklanan nesneyi siler (Ayar açıksa). |
| **WASD** | Freecam/Fly Yön | Uçuş veya kamera modunda yönlendirme. |

---

## 📥 Kurulum (Installation)

1. Bir Roblox "Script Executor" (Örn: Synapse X, Krnl, Fluxus vb.) indirin.
2. Aşağıdaki kodu kopyalayın veya `Source.lua` dosyasını açın.
3. Executor'a yapıştırın ve **Execute** butonuna basın.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/SabanGnc/vexelcontrolmenu/refs/heads/main/control.lua"))()

