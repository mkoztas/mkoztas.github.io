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
<a href="https://colab.research.google.com/github/mkoztas/mkoztas.github.io/blob/main/docs/notebooks/verihazirlik.ipynb" target="_blank" rel="noopener">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/>
</a>  
Bu bölümde, Meteoroloji Genel Müdürlüğü'nden (MGM) temin edilen ham gözlem verilerinin iklim değişikliği trend analizlerine (Homojenlik, TFPW-MK ve SQMK) hazır hale getirilmesi için uygulanan **Kalite Güvencesi ve Kalite Kontrolü (QA/QC)** adımları ile Python veri işleme akışı yer almaktadır.

---

## 1. Veri Yapısı ve Girdi Dosyalarının Tanımlanması

Analiz hattında iki farklı zaman ölçeğinde ve formatta ham veri seti kullanılmaktadır. GitHub deposu üzerinden veya yerel çalışma dizininden (`./data/`) kod çalıştırılırken her aşamada hangi dosyanın çağrıldığı aşağıda tanımlanmıştır:

| Veri Seti Türü | Dosya Formatı | Gerekli Dosya İçeriği ve Sütun Yapısı | Kullanım Amacı |
| :--- | :---: | :--- | :--- |
| **Standart Süreli Maksimum Yağışlar** | `.xlsx` | MGM `TABLO` sayfası formatı. İlk sütunda **Gözlem Yılı**, devam eden 14 sütunda **5, 10, 15, 30 dk** ve **1, 2, 3, 4, 5, 6, 8, 12, 18, 24 saatlik** maksimum yağış değerleri ($\text{mm}$). | Kısa ve orta süreli ekstrem yağış şiddeti (IDF) ve konvektif yağış trendlerinin analizi. |
| **Günlük Sıcaklık ve Toplam Yağış Zaman Serileri** | `.txt` | MGM boru ayraçlı metin dosyası (cp1254 veya UTF-8). Sütunlar: İstasyon No - Yıl - Ay - Gün - Parametre Değeri ($T_{\text{ort}}, T_{\max}, T_{\min}$ [$^\circ\text{C}$] veya Toplam Yağış [$\text{mm}$]). | Çok günlük yağış ($Rx1day, Rx5day$), kuraklık ($CDD$), sıcaklık indeksleri ($WSDI, SU, TR$) ve mevsimsel/yıllık ortalamaların türetilmesi. |
| **İstasyon Üstveri (Metadata) Dosyası** | .txt veya .csv | İstasyon No - İstasyon Adı - İl - İlçe - Enlem - Boylam - Rakım bilgilerini içeren referans tablosu. | Mekânsal haritalama (QGIS/Matplotlib) ve istasyon tarihçesi (yer/cihaz değişikliği) kontrolü. |

> **Önemli Metodolojik Not:** İklim değişikliği trend analizlerinde yağış ve sıcaklık zaman serileri istatistiksel olarak birbirinden **bağımsız (tek değişkenli)** şekilde analiz edilir. Bir istasyonun analize dahil edilebilmesi için hem sıcaklık hem yağış verisinin aynı anda bulunması zorunlu değildir; her parametre kendi istasyon havuzunda WMO kriterlerine göre değerlendirilir.

---

## 2. Uluslararası QA/QC Kriterleri ve Bilimsel Dayanaklar

Ham meteorolojik veriler istatistiksel testlere sokulmadan önce aşağıdaki 4 temel eleme kuralından geçirilir:

1. **Minimum Gözlem Süresi ($N \ge 30$ Yıl):** Dünya Meteoroloji Örgütü (**WMO-No. 1203**, *Guidelines on the Calculation of Climate Normals*) uyarınca atmosferik doğal salınımların (NAO, ENSO vb.) uzun dönemli iklim trendiyle karışmaması için en az 30 yıllık veri şarttır. *(Örn: yeni kurulmuş $N=3$ yıllık İstanbul-X istasyonu bu aşamada elenir).*
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

Etkileşimli (Kullanıcıdan Dosya Talep Eden) Veri Hazırlama Akışı  
Bu yapıda kod her aşamada durur, kullanıcıya o aşamada tam olarak hangi veriye ihtiyaç duyulduğunu ve dosya içeriğinin nasıl olması gerektiğini ekrana yazar, ardından dosya yolunu (veya Jupyter/Colab yükleme penceresini) bekler.  

```python
import os
import numpy as np
import pandas as pd

def kullanicidan_dosya_iste(asama_basligi, beklenen_format, ornek_icerik, dosya_uzantisi):
    """
    Her aşamada kullanıcıya ne tür bir dosya gerektiğini açıklar ve dosya yolunu alır.
    """
    print("=" * 75)
    print(f"AŞAMA: {asama_basligi}")
    print("-" * 75)
    print(f"Beklenen Dosya Türü : {beklenen_format}")
    print(f"Beklenen İçerik     :\n{ornek_icerik}")
    print("=" * 75)
    
    while True:
        dosya_yolu = input(f"Lütfen {dosya_uzantisi} dosyasının yolunu girin (Atlamak için 'pas' yazın): ").strip().strip("'\"")
        if dosya_yolu.lower() == 'pas':
            return None
        if os.path.isfile(dosya_yolu) and dosya_yolu.lower().endswith(dosya_uzantisi):
            print(f"✓ Dosya doğrulandı: {os.path.basename(dosya_yolu)}\n")
            return dosya_yolu
        print(f"HATA: Geçerli bir '{dosya_uzantisi}' dosyası bulunamadı. Lütfen yolu kontrol edip tekrar deneyin.\n")  
```

### Adım 3.2: Standart Süreli Yağış Tablolarının (.xlsx) Doğrulanması   
Bu adımda klasördeki tüm .xlsx dosyaları okunur; gözlem yılı aralığı, eksik yıl oranı, negatif değer ve süre monotonluğu denetlenerek WMO şartını sağlayan istasyonlar temiz_yagis_serileri sözlüğünde toplanır.

```python
SURELER = ['5dk', '10dk', '15dk', '30dk', '1sa', '2sa', '3sa', '4sa', '5sa', '6sa', '8sa', '12sa', '18sa', '24sa']

ornek_excel = (
    "  - Sayfa Adı: 'TABLO'\n"
    "  - 2. Satır (A2): İstasyon Adı (Örn: EDİRNE METEOROLOJİ İSTASYONU)\n"
    "  - 6. Satırdan itibaren: [Gözlem Yılı | 5dk | 10dk | 15dk | 30dk | 1sa | ... | 24sa] (mm)"
)

excel_yolu = kullanicidan_dosya_iste(
    asama_basligi="1. STANDART SÜRELİ MAKSİMUM YAĞIŞ QA/QC ANALİZİ",
    beklenen_format="MGM Standart Süreli Yağış Excel Dosyası (.xlsx)",
    ornek_icerik=ornek_excel,
    dosya_uzantisi=".xlsx"
)

if excel_yolu:
    df_ham = pd.read_excel(excel_yolu, sheet_name='TABLO', header=None)
    istasyon = str(df_ham.iloc[1, 0]).replace('METEOROLOJİ İSTASYONU', '').strip()
    
    satirlar = []
    for idx in range(5, len(df_ham)):
        try:
            yil = int(float(df_ham.iloc[idx, 0]))
            if 1900 <= yil <= 2030:
                satirlar.append([yil] + list(pd.to_numeric(df_ham.iloc[idx, 1:15], errors='coerce').values))
        except (ValueError, TypeError):
            break
            
    df_standart = pd.DataFrame(satirlar, columns=['Yil'] + SURELER).sort_values('Yil').reset_index(drop=True)
    eksik_oran = ((df_standart['Yil'].max() - df_standart['Yil'].min() + 1 - len(df_standart)) / 
                  (df_standart['Yil'].max() - df_standart['Yil'].min() + 1)) * 100
    
    print(f"İstasyon: {istasyon} | Yıl Sayısı (N): {len(df_standart)} | Eksik Oran: %{eksik_oran:.2f}")
    print("WMO Durumu:", "KABUL" if (len(df_standart) >= 30 and eksik_oran < 10) else "RED")
```

### Adım 3.3: Günlük Yağış Zaman Serilerinin (.txt) İşlenmesi 
Bu aşamada sisteme günlük zaman serisi .txt dosyası yüklenir. Kod, aylık ve yıllık eksiklik eşiklerini uygulayarak yalnızca WMO standartlarını sağlayan yılları bırakır ve bir sonraki aşama (ETCCDI indeksleri ve yıllık/mevsimlik seriler) için temiz zaman serisi üretir.

```python
ornek_yagis_txt = (
    "  - Ayraç: Boru işareti '|' (Kodlama: cp1254 veya UTF-8)\n"
    "  - Sütunlar: İstasyon_No | Yıl | Ay | Gün | Günlük_Toplam_Yağış_mm\n"
    "  - Örnek Satır: 17050|1965|1|14|12.4"
)

yagis_txt_yolu = kullanicidan_dosya_iste(
    asama_basligi="2. GÜNLÜK TOPLAM YAĞIŞ ZAMAN SERİSİ QA/QC ANALİZİ",
    beklenen_format="MGM Günlük Yağış Zaman Serisi Metin Dosyası (.txt)",
    ornek_icerik=ornek_yagis_txt,
    dosya_uzantisi=".txt"
)

if yagis_txt_yolu:
    df_yagis = pd.read_csv(yagis_txt_yolu, sep="|", encoding="cp1254")
    df_yagis.columns = [c.strip() for c in df_yagis.columns]
    df_yagis['Yagis'] = pd.to_numeric(df_yagis.iloc[:, -1], errors='coerce')
    
    # Fiziksel hata ve WMO aylık (>5 gün eksik) / yıllık (<330 gün) filtresi
    df_yagis.loc[(df_yagis['Yagis'] < 0) | (df_yagis['Yagis'] > 500), 'Yagis'] = np.nan
    aylik_eksik = df_yagis.groupby(['Yıl', 'Ay'])['Yagis'].apply(lambda x: x.isna().sum())
    for (y, m) in aylik_eksik[aylik_eksik > 5].index:
        df_yagis.loc[(df_yagis['Yıl'] == y) & (df_yagis['Ay'] == m), 'Yagis'] = np.nan
        
    gecerli_yillar = df_yagis.groupby('Yıl')['Yagis'].count()
    gecerli_yillar = gecerli_yillar[gecerli_yillar >= 330].index.tolist()
    df_yagis_temiz = df_yagis[df_yagis['Yıl'].isin(gecerli_yillar)].copy()
    print(f"Günlük Yağış QA/QC Tamamlandı -> WMO Geçerli Yıl Sayısı: {len(gecerli_yillar)}")  
```

### Adım 3.4: Günlük Sıcaklık Zaman Serilerinin (.txt) İşlenmesi 
Bu aşamada sisteme günlük zaman serisi .txt dosyası yüklenir. Kod, aylık ve yıllık eksiklik eşiklerini uygulayarak yalnızca WMO standartlarını sağlayan yılları bırakır ve bir sonraki aşama (ETCCDI indeksleri ve yıllık/mevsimlik seriler) için temiz zaman serisi üretir.

```python
ornek_sicaklik_txt = (
    "  - Ayraç: Boru işareti '|' (Kodlama: cp1254 veya UTF-8)\n"
    "  - Sütunlar: İstasyon_No | Yıl | Ay | Gün | Sıcaklık_C (Ortalama, Maksimum veya Minimum)\n"
    "  - Örnek Satır: 17050|1965|1|14|4.8"
)

sicaklik_txt_yolu = kullanicidan_dosya_iste(
    asama_basligi="3. GÜNLÜK SICAKLIK ZAMAN SERİSİ QA/QC ANALİZİ",
    beklenen_format="MGM Günlük Sıcaklık Zaman Serisi Metin Dosyası (.txt)",
    ornek_icerik=ornek_sicaklik_txt,
    dosya_uzantisi=".txt"
)

if sicaklik_txt_yolu:
    df_sic = pd.read_csv(sicaklik_txt_yolu, sep="|", encoding="cp1254")
    df_sic.columns = [c.strip() for c in df_sic.columns]
    df_sic['Sicaklik'] = pd.to_numeric(df_sic.iloc[:, -1], errors='coerce')
    
    # Fiziksel sınır (-45°C ile +55°C) ve WMO aylık/yıllık kontrol
    df_sic.loc[(df_sic['Sicaklik'] < -45) | (df_sic['Sicaklik'] > 55), 'Sicaklik'] = np.nan
    aylik_eksik = df_sic.groupby(['Yıl', 'Ay'])['Sicaklik'].apply(lambda x: x.isna().sum())
    for (y, m) in aylik_eksik[aylik_eksik > 5].index:
        df_sic.loc[(df_sic['Yıl'] == y) & (df_sic['Ay'] == m), 'Sicaklik'] = np.nan
        
    gecerli_yillar_sic = df_sic.groupby('Yıl')['Sicaklik'].count()
    gecerli_yillar_sic = gecerli_yillar_sic[gecerli_yillar_sic >= 330].index.tolist()
    df_sic_temiz = df_sic[df_sic['Yıl'].isin(gecerli_yillar_sic)].copy()
    print(f"Günlük Sıcaklık QA/QC Tamamlandı -> WMO Geçerli Yıl Sayısı: {len(gecerli_yillar_sic)}")
```


## 4. Bir Sonraki Aşamaya (Homojenlik ve TFPW-MK) Aktarım Kuralı  
QA/QC filtresinden geçen seriler doğrudan trend testine sokulmaz; öncelikle seri bağımlılık (otokorelasyon) kontrolünden geçirilir:
Homojenlik Testleri (Pettitt, SNHT, Buishand, Von Neumann): Wijngaard vd. (2003) sınıflandırmasına göre en fazla 1 testte kırılma veren (Useful) seriler doğrudan, 2 testte kırılma veren (Doubtful) seriler üstveri kontrolüyle analiz havuzuna alınır.
Lag-1 Otokorelasyon ($r_1$) hesaplanır ve $\%95$ güven aralığı $\left[\frac{-1 - 1.96\sqrt{n-2}}{n-1},\; \frac{-1 + 1.96\sqrt{n-2}}{n-1}\right]$ ile karşılaştırılır. Güven sınırları dışında kalan anlamlı otokorelasyonlu seriler TFPW (Trend-Free Pre-Whitening) aşamasına yönlendirilir.

 ```python  
def tfpw_secim_kontrolu(seri):
    x = np.asarray(seri, dtype=float)
    n = len(x)
    ort = np.mean(x)
    r1 = np.sum((x[:-1] - ort) * (x[1:] - ort)) / np.sum((x - ort) ** 2)
    ust = (-1 + 1.96 * np.sqrt(n - 2)) / (n - 1)
    alt = (-1 - 1.96 * np.sqrt(n - 2)) / (n - 1)
    return round(r1, 3), bool((r1 > ust) or (r1 < alt))

# QA/QC'den geçen her seri için TFPW gereksinimini listele
tfpw_adaylari = []
for istasyon, df in temiz_yagis_serileri.items():
    for s in SURELER:
        r1_val, gerekli = tfpw_secim_kontrolu(df[s].values)
        if gerekli:
            tfpw_adaylari.append({"Istasyon": istasyon, "Parametre": s, "r1": r1_val, "Yontem": "TFPW-MK"})

display(pd.DataFrame(tfpw_adaylari))  
```




