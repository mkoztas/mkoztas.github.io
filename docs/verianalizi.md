# 💻 Veri Analizi, Kodlar ve Hesaplama Ortamları

Bu sayfa; hidro-meteorolojik zaman serilerinin analizi, otokorelasyon arındırma (TFPW), rejim kırılmaları (SQMK) ve Sen's Slope eğim hesaplamaları için geliştirilen Python ve MATLAB kodlamalarının merkezi indeksidir.

---

## 🛠️ Analiz Modülleri ve Çalıştırılabilir Ortamlar

### 1. Metodolojik Kod Sayfaları
* **[📈 Trend ve Kırılma Analizi](kodlar/trend-analizi.md):** Sen's Slope, Mann-Kendall ve SQMK analiz metodolojisi ve sekmeli (Python/MATLAB) kod blokları.
* **[🔄 Pre-Whitening (TFPW)](kodlar/pre-whitening.md):** Zaman serilerinde 1. derece otokorelasyonun ($r_1$) temizlenmesi ve Type-I hataların önlenmesi için TFPW algoritması.

---

### 2. Etkileşimli ve Canlı Kodlama Alanları

| Platform | Açıklama | Bağlantı / Çalıştır |
| :--- | :--- | :---: |
| **🐍 Google Colab Notebook** | LaTeX formülleri, adım adım açıklamaları ve Python kod bloğu içeren Colab Defteri. | [🚀 Colab'da Aç](kodlar/trend_analysis.ipynb) |
| **📐 MathWorks MATLAB** | Yerel bilgisayar ve MATLAB Online ile tam uyumlu esnek veri okumalı `.m` scripti. | [💻 MATLAB Online'da Aç](kodlar/trend_analysis_matlab.m) |

---

### ⚙️ Hesaplama Akışı ve Metodolojik Sıralama

[MGM Excel Verisi] ➔ [Sen's Slope (β)] ➔ [TFPW Pre-Whitening (r1)] ➔ [SQMK (UF / UB Kırılma Yılları)]

1. **Veri Ön İşleme:** MGM Excel çıktılarının güvenli tip dönüşümleri ve yıllık ekstrem dizilerin çekilmesi.
2. **Eğim Hesabı:** Değişim oranının ($\beta$) parametrik olmayan yoldan bulunması.
3. **Otokorelasyon Temizleme:** $r_1$ otokorelasyonunun sökülmesi ve eğimin geri eklenmesi.
4. **SQMK Kırılma Analizi:** Rejim değişim yıllarının $UF$ ve $UB$ kesişim çizgileriyle belirlenmesi.
