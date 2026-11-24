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

```python
import glob
import os
import numpy as np
import pandas as pd

# GitHub reposu veya yerel çalışma ortamındaki ham veri klasörleri
EXCEL_KLASORU = "data/standart_sureli_yagis/"   # İstasyon bazlı .xlsx dosyaları
GUNLUK_KLASORU = "data/gunluk_zaman_serileri/" # Sıcaklık ve günlük yağış .txt dosyaları
```
Adım 3.2: Standart Süreli Yağış Tablolarının (.xlsx) Doğrulanması
Bu adımda klasördeki tüm .xlsx dosyaları okunur; gözlem yılı aralığı, eksik yıl oranı, negatif değer ve süre monotonluğu denetlenerek WMO şartını sağlayan istasyonlar temiz_yagis_serileri sözlüğünde toplanır.

```python
SURELER = ['5dk', '10dk', '15dk', '30dk', '1sa', '2sa', '3sa', '4sa', '5sa', '6sa', '8sa', '12sa', '18sa', '24sa']

def standart_sureli_qaqc(dosya_yolu):
    df_ham = pd.read_excel(dosya_yolu, sheet_name='TABLO', header=None)
    istasyon_adi = str(df_ham.iloc[1, 0]).replace('METEOROLOJİ İSTASYONU', '').strip()
    
    # Gözlem yıllarını ve 14 standart süre sütununu ayıkla
    satirlar = []
    for idx in range(5, len(df_ham)):
        try:
            yil = int(float(df_ham.iloc[idx, 0]))
            if 1900 <= yil <= 2030:
                degerler = pd.to_numeric(df_ham.iloc[idx, 1:15], errors='coerce').values
                satirlar.append([yil] + list(degerler))
        except (ValueError, TypeError):
            break
            
    df = pd.DataFrame(satirlar, columns=['Yil'] + SURELER).sort_values('Yil').reset_index(drop=True)
    
    # WMO 30 yıl ve %10 eksiklik kontrolü
    baslangic, bitis = df['Yil'].min(), df['Yil'].max()
    beklenen_yil = bitis - baslangic + 1
    mevcut_yil = len(df)
    eksik_yillar = sorted(list(set(range(baslangic, bitis + 1)) - set(df['Yil'])))
    eksik_oran = (len(eksik_yillar) / beklenen_yil) * 100
    
    # Fiziksel tutarlılık: Negatif değer ve Monotonluk (P_i <= P_{i+1})
    negatif_hata = int((df[SURELER] < 0).sum().sum())
    monotonluk_hatasi = sum(
        1 for _, satir in df.iterrows() if np.any(np.diff(satir[SURELER].values) < -1e-6)
    )
    
    # Aşırı uç değer tespiti (Q3 + 3*IQR)
    uc_deger_sayisi = 0
    for s in SURELER:
        q1, q3 = np.percentile(df[s].dropna(), [25, 75])
        uc_deger_sayisi += int((df[s] > q3 + 3 * (q3 - q1)).sum())
        
    karar = "KABUL" if (mevcut_yil >= 30 and eksik_oran < 10.0) else "RED"
        
    ozet = {
        "Istasyon": istasyon_adi,
        "Periyot": f"{baslangic}-{bitis}",
        "N_Yil": mevcut_yil,
        "Eksik_Yil": len(eksik_yillar),
        "Eksik_Oran_%": round(eksik_oran, 2),
        "Negatif_Hata": negatif_hata,
        "Monotonluk_Hatasi": monotonluk_hatasi,
        "Uc_Deger": uc_deger_sayisi,
        "WMO_Karar": karar
    }
    return ozet, df

qaqc_listesi = []
temiz_yagis_serileri = {}

for dosya in sorted(glob.glob(os.path.join(EXCEL_KLASORU, "*.xlsx"))):
    ozet, temiz_df = standart_sureli_qaqc(dosya)
    qaqc_listesi.append(ozet)
    if ozet["WMO_Karar"] == "KABUL":
        temiz_yagis_serileri[ozet["Istasyon"]] = temiz_df

df_qaqc_rapor = pd.DataFrame(qaqc_listesi)
display(df_qaqc_rapor)
```
Adım 3.3: Günlük Sıcaklık ve Yağış Zaman Serilerinin (.txt) İşlenmesi
Bu aşamada sisteme günlük zaman serisi .txt dosyası yüklenir. Kod, aylık ve yıllık eksiklik eşiklerini uygulayarak yalnızca WMO standartlarını sağlayan yılları bırakır ve bir sonraki aşama (ETCCDI indeksleri ve yıllık/mevsimlik seriler) için temiz zaman serisi üretir.

```python
def gunluk_zaman_serisi_qaqc(txt_yolu, parametre="sicaklik"):
    """
    Girdi: MGM günlük gözlem .txt dosyası (İstasyon No | Yıl | Ay | Gün | Değer)
    parametre: 'sicaklik' veya 'yagis'
    """
    df = pd.read_csv(txt_yolu, sep="|", encoding="cp1254")
    df.columns = [c.strip() for c in df.columns]
    
    df['Tarih'] = pd.to_datetime(df[['Yıl', 'Ay', 'Gün']].rename(
        columns={'Yıl': 'year', 'Ay': 'month', 'Gün': 'day'}
    ))
    
    deger_kolonu = df.columns[-1]
    df['Deger'] = pd.to_numeric(df[deger_kolonu], errors='coerce')
    
    # Fiziksel sınır kontrolü
    if parametre == "yagis":
        df.loc[(df['Deger'] < 0) | (df['Deger'] > 500), 'Deger'] = np.nan
    elif parametre == "sicaklik":
        df.loc[(df['Deger'] < -45) | (df['Deger'] > 55), 'Deger'] = np.nan
        
    # WMO-No. 100 Aylık Kural: Bir ayda > 5 gün eksik varsa o ayı geçersiz say
    aylik_eksik = df.groupby(['Yıl', 'Ay'])['Deger'].apply(lambda x: x.isna().sum())
    for (yil, ay) in aylik_eksik[aylik_eksik > 5].index:
        df.loc[(df['Yıl'] == yil) & (df['Ay'] == ay), 'Deger'] = np.nan
        
    # WMO-No. 100 Yıllık Kural: Yılda en az 330 gün geçerli gözlem şartı (<%10 eksik)
    yillik_gecerli = df.groupby('Yıl')['Deger'].count()
    gecerli_yillar = yillik_gecerli[yillik_gecerli >= 330].index.tolist()
    
    df_temiz = df[df['Yıl'].isin(gecerli_yillar)].copy()
    
    # Minimum 30 yıl kontrolü
    if len(gecerli_yillar) < 30:
        print(f"UYARI: {os.path.basename(txt_yolu)} geçerli yıl sayısı ({len(gecerli_yillar)}) < 30 yıl!")
    else:
        print(f"BAŞARILI: {os.path.basename(txt_yolu)} -> {len(gecerli_yillar)} geçerli yıl analize hazır.")
        
    return df_temiz
```

4. Bir Sonraki Aşamaya (Homojenlik ve TFPW-MK) Aktarım Kuralı
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




