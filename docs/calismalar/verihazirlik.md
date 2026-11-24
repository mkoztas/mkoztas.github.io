---
search:
  exclude: true
meta:
  - name: robots
    content: noindex, nofollow, noarchive, noimageindex
  - name: googlebot
    content: noindex, nofollow, noarchive
  - name: bingbot
    content: noindex, nofollow, noarchive
---
<meta name="robots" content="noindex, nofollow, noarchive, noimageindex">
<meta name="googlebot" content="noindex, nofollow, noarchive">

# Verilerin Hazırlanması ve Kalite Kontrolü (QA/QC)

Bu bölümde, Meteoroloji Genel Müdürlüğü'nden (MGM) temin edilen ham gözlem verilerinin iklim değişikliği trend analizlerine (Homojenlik, TFPW-MK ve SQMK) hazır hale getirilmesi için uygulanan **Kalite Güvencesi ve Kalite Kontrolü (QA/QC)** adımları ile Python veri işleme akışı yer almaktadır.

---

## 1. Veri Yapısı ve Girdi Dosyalarının Tanımlanması

Analiz hattında iki farklı zaman ölçeğinde ve formatta ham veri seti kullanılmaktadır. GitHub deposu üzerinden veya yerel çalışma dizininden (`./data/`) kod çalıştırılırken her aşamada hangi dosyanın çağrıldığı aşağıda tanımlanmıştır:

| Veri Seti Türü | Dosya Formatı | Gerekli Dosya İçeriği ve Sütun Yapısı | Kullanım Amacı |
| :--- | :---: | :--- | :--- |
| **Standart Süreli Maksimum Yağışlar** | `.xlsx` | MGM `TABLO` sayfası formatı. İlk sütunda **Gözlem Yılı**, devam eden 14 sütunda **5, 10, 15, 30 dk** ve **1, 2, 3, 4, 5, 6, 8, 12, 18, 24 saatlik** maksimum yağış değerleri ($\text{mm}$). | Kısa ve orta süreli ekstrem yağış şiddeti (IDF) ve konvektif yağış trendlerinin analizi. |
| **Günlük Sıcaklık ve Toplam Yağış Zaman Serileri** | `.txt` | MGM boru (`|`) ayraçlı metin dosyası (`cp1254` veya `UTF-8`). Sütunlar: `İstasyon No | Yıl | Ay | Gün | Parametre Değeri` ($T_{\text{ort}}, T_{\max}, T_{\min}$ [$^\circ\text{C}$] veya Toplam Yağış [$\text{mm}$]). | Çok günlük yağış ($Rx1day, Rx5day$), kuraklık ($CDD$), sıcaklık indeksleri ($WSDI, SU, TR$) ve mevsimsel/yıllık ortalamaların türetilmesi. |
| **İstasyon Üstveri (Metadata) Dosyası** | `.txt` / `.csv` | `İstasyon No | İstasyon Adı | İl | İlçe | Enlem | Boylam | Rakım` bilgilerini içeren referans tablosu. | Mekânsal haritalama (QGIS/Matplotlib) ve istasyon tarihçesi (yer/cihaz değişikliği) kontrolü. |

> **Önemli Metodolojik Not:** İklim değişikliği trend analizlerinde yağış ve sıcaklık zaman serileri istatistiksel olarak birbirinden **bağımsız (tek değişkenli)** şekilde analiz edilir. Bir istasyonun analize dahil edilebilmesi için hem sıcaklık hem yağış verisinin aynı anda bulunması zorunlu değildir; her parametre kendi istasyon havuzunda WMO kriterlerine göre değerlendirilir.

---

## 2. Uluslararası QA/QC Kriterleri ve Bilimsel Dayanaklar

Ham meteorolojik veriler istatistiksel testlere sokulmadan önce aşağıdaki 4 temel eleme kuralından geçirilir:

1. **Minimum Gözlem Süresi ($N \ge 30$ Yıl):** Dünya Meteoroloji Örgütü (**WMO-No. 1203**, *Guidelines on the Calculation of Climate Normals*) uyarınca atmosferik doğal salınımların (NAO, ENSO vb.) uzun dönemli iklim trendiyle karışmaması için en az 30 yıllık veri şarttır. *(Örn: $N=10$ yıllık İstanbul-Kartal istasyonu bu aşamada elenir).*
2. **Eksik Veri Toleransı ($<\%10$ Kuralı):** **WMO-No. 100** (*Guide to Climatological Practices*) ve **Klein Tank vd. (2002)** standartlarına göre:
   * Yıllık serilerde eksik yıl oranı **%10'un altında** olmalıdır.
   * Günlük zaman serilerinde bir ayda **5 günden fazla** eksik veri varsa o ay geçersiz (`NaN`) sayılır; bir yılda geçerli gün sayısı **330 günün altındaysa** o yıl yıllık/mevsimlik indeks hesabına dahil edilmez.
3. **Fiziksel ve İç Tutarlılık:**
   * Yağış serilerinde negatif değer ($P < 0$) bulunamaz ve kısa süreli maksimum yağış, kendisinden uzun süreli maksimum yağıştan büyük olamaz ($P_{5\text{dk}} \le P_{10\text{dk}} \le \dots \le P_{24\text{sa}}$).
   * Günlük sıcaklık serilerinde $T_{\max} \ge T_{\text{ort}} \ge T_{\min}$ eşitsizliği sağlanmalıdır.
4. **Uç Değer (Outlier) Kontrolü:** $Q_3 + 3 \times \text{IQR}$ eşiğini aşan gözlemler otomatik olarak silinmez (**ETCCDI / Zhang & Yang, 2004**); komşu istasyonlar ve sinoptik kayıtlarla doğrulanarak gerçek ekstrem sağanak/sıcak hava dalgası olup olmadığı teyit edilir ve parametrik olmayan testlerle korunur.

---

## 3. Adım Adım Python QA/QC İş Akışı

### Adım 3.1: Kütüphanelerin Yüklenmesi ve Dizin Tanımı

```python
import glob
import os
import numpy as np
import pandas as pd

# GitHub reposu veya yerel çalışma ortamındaki ham veri klasörleri
EXCEL_KLASORU = "data/standart_sureli_yagis/"   # İstasyon bazlı .xlsx dosyaları
GUNLUK_KLASORU = "data/gunluk_zaman_serileri/" # Sıcaklık ve günlük yağış .txt dosyaları
