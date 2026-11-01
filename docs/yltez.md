# MARMARA BÖLGESİ’NDE İKLİM DEĞİŞİKLİĞİ TRENDLERİNİN VE EKSTREM HİDRO-METEOROLOJİK OLAYLARIN ANALİZİ

---

## ÖZET

İklim değişikliği, küresel ölçekte hidro-meteorolojik döngülerin dengesini bozarak ekstrem hava olaylarının sıklığında, şiddetinde ve mekânsal dağılımında belirgin değişimlere yol açmaktadır. Türkiye'nin nüfus yoğunluğu, sanayi üretimi ve tarımsal faaliyetler açısından en kritik bölgesi olan Marmara Bölgesi, yarı kurak iklim kuşağından Akdeniz geçiş iklimine uzanan hassas ekosistemiyle iklim değişikliğinin olumsuz etkilerine karşı oldukça kırılgan bir yapıdır. 

Bu tez çalışmasında, Marmara Bölgesi genelinde yer alan uzun yıllar hidro-meteorolojik gözlem istasyonlarına ait sıcaklık (minimum, maksimum, ortalama) ve yağış verileri incelenmiştir. Veri serilerindeki doğrusal ve doğrusal olmayan eğilimlerin belirlenmesi amacıyla non-parametrik testlerden **Sen’s Slope (Eğim) Estimator**, **Trend-Free Pre-Whitening (TFPW)** entegreli **Mann-Kendall** testi, **Modified Mann-Kendall (MMK)** ve **Yenilikçi Şen Yöntemi (ITA)** uygulanmıştır. Ekstrem rejim kırılmalarını ve rejim değişim yıllarını tespit etmek amacıyla **Sequential Mann-Kendall (SQMK)** analizi yürütülmüş, kuraklık ve aşırı yağış ekstremleri ise **SPEI (Standardized Precipitation Evapotranspiration Index)** ve **GEV (Generalized Extreme Value)** dağılımları ile değerlendirilmiştir.

Elde edilen bulgular, bölge genelinde özellikle gece sıcaklıklarında (minimum sıcaklıklar) ve yaz dönemi maksimum sıcaklıklarında istatistiksel olarak %95 ve %99 güven düzeyinde belirgin bir artış eğilimi (küresel ısınma sinyali) olduğunu göstermektedir. Yağış dizilerinde ise toplam miktar bazında hafif bir düşüş eğilimi gözlenirken, kısa süreli şiddetli yağış ekstremlerinde ve kurak dönem sürelerinde artış saptanmıştır. Bu çalışma, Marmara Bölgesi'nin gelecekteki su kaynakları yönetimi, kentsel taşkın dirençliliği ve tarımsal su bütçesi planlaması için güvenilir istatistiksel ve metodolojik bir altlık sunmaktadır.

**Anahtar Kelimeler:** İklim Değişikliği, Marmara Bölgesi, TFPW, Sequential Mann-Kendall (SQMK), Sen's Slope, SPEI, Hidro-Meteoroloji.

---

## 1. GİRİŞ

### 1.1. Çalışmanın Konusu ve Önemi
İklim sistemi, küresel ölçekte gerçekleşen insan kaynaklı (antropojenik) sera gazı salımları ve arazi kullanımı değişiklikleri nedeniyle tarihsel süreçteki doğal değişkenlik sınırlarının ötesine geçmiştir. Hükümetlerarası İklim Değişikliği Paneli (IPCC) Altıncı Değerlendirme Raporu (AR6), Akdeniz Havzası'nı iklim değişikliğinin en hızlı gerçekleştiği "sıcak noktalar" (hotspots) arasında sınıflandırmaktadır. Akdeniz geçiş iklimi kuşağında yer alan Türkiye ve özellikle Marmara Bölgesi, yükselen sıcaklıklar, düzensizleşen yağış rejimleri, artan kuraklık frekansı ve kentsel taşkın riskleri ile karşı karşıyadır.

Marmara Bölgesi; Türkiye nüfusunun üçte birinden fazlasını barındırması, sanayi üretiminin kalbi olması ve kısıtlı su havzalarına sahip bulunması nedeniyle iklimsel ekstremlere karşı en yüksek sosyo-ekonomik hassasiyete sahip bölgedir. Bölgedeki su potansiyelinin sürdürülebilir yönetimi, tarımsal üretimin korunması ve kentsel altyapı dirençliliğinin artırılması; geçmişten günümüze uzanan hidro-meteorolojik verilerin doğru, tarafsız ve otokorelasyondan arındırılmış yöntemlerle analiz edilmesine bağlıdır.

### 1.2. Çalışmanın Amacı ve Kapsamı
Bu tez çalışmasının temel amacı, Marmara Bölgesi’ndeki meteorolojik gözlem istasyonlarının uzun yıllık zaman serilerini kullanarak:
1. Sıcaklık ve yağış parametrelerindeki uzun dönemli eğilimleri (trendleri) belirlemek,
2. Seri içi otokorelasyon (lag-1) etkisini sönümleyen **TFPW (Trend-Free Pre-Whitening)** yöntemini uygulayarak "yanlış pozitif" trend tespitlerini engellemek,
3. **Sequential Mann-Kendall (SQMK)** yöntemiyle iklimsel rejim kırılmalarının gerçekleştiği belirleyici yılları tespit etmek,
4. İklim değişikliğinin havza ölçeğindeki etkilerini değerlendirmek için açık kaynaklı ve tekrarlanabilir (Python/MATLAB) bir analiz altyapısı sunmaktır.

### 1.3. Metodolojik Çerçeve
Tez kapsamında izlenen metodolojik sıralama ve işlem adımları aşağıda özetlenmiştir:
