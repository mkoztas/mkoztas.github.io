%% ========================================================================
%  İKLİM DEĞİŞİKLİĞİ TREND, PRE-WHITENING (TFPW) VE SQMK KIRILMA ANALİZİ
%  ========================================================================
%  Yazar: Mustafa Kerem Öztaş
%  Kurum: Pamukkale Üniversitesi Fen Bilimleri Enstitüsü 
%         İnşaat Mühendisliği A.D. (Hidrolik Bilim Dalı)
%  Tanım: MGM Excel verisi üzerinden TFPW Pre-Whitening, Sen's Slope ve
%         Sequential Mann-Kendall (SQMK) analizlerini yürütür.
%  Çalışma Ortamı: MATLAB R2016b+ / MATLAB Online
%  ========================================================================

clear; clc; close all;

%% 1. VERİ İTHALİ VE ÖN İŞLEME
filename = '20181225BC0F-Aylık Maksimum Sıcaklık (°C).xlsx';

if ~exist(filename, 'file')
    error('HATA: %s dosyası bulunamadı. Lütfen dosya yolunu kontrol edin.', filename);
end

% Excel dosyasından ham veriyi okuma
opts = detectImportOptions(filename);
raw_data = readcell(filename);

% Acıpayam İstasyonu verilerini ayıklama (2003-2018, 16 yıl)
% MGM Excel yapısında 6-21 arası satırlar Acıpayam istasyonuna aittir
years = cell2mat(raw_data(6:21, 2));          % Yıllar
monthly_temps = cell2mat(raw_data(6:21, 3:14)); % 12 aylık maksimumlar

% Yıllık ekstrem (maksimum) sıcaklık serisi
temp_series = max(monthly_temps, [], 2);
n = length(temp_series);

fprintf('=== VERİ SETİ ÖZETİ ===\n');
fprintf('Zaman Aralığı : %d - %d (%d Yıl)\n', years(1), years(end), n);

%% 2. ADIM: SEN'IN EĞİM TESTİ (SEN'S SLOPE)
% Neden Yapılıyor? Serideki parametrik olmayan yıllık Değişim Oranını (beta) bulmak için.
beta = calc_sens_slope(temp_series);
fprintf('Sen''s Slope Eğimi (beta) : %.4f °C/yıl\n', beta);

%% 3. ADIM: TREND-FREE PRE-WHITENING (TFPW)
% Neden Yapılıyor? Otokorelasyonun (r1) Mann-Kendall testinde sanal trend üretmesini engellemek için.
[tfpw_series, r1] = tfpw_prewhitening(temp_series, beta);
fprintf('Lag-1 Otokorelasyon (r1)  : %.4f\n', r1);

%% 4. ADIM: SEQUENTIAL MANN-KENDALL (SQMK) ANALİZİ
% Neden Yapılıyor? İklimsel kırılma (rejim değişimi) yıllarını tespit etmek için.
[uf, ub] = sequential_mk(tfpw_series);

% TFPW işlemi nedeniyle 1 yıl azalan zaman dizisini hizalama
years_tfpw = years(2:end);

%% 5. SONUÇLARIN GÖRSELLEŞTİRİLMESİ
figure('Color', 'w', 'Position', [100, 100, 850, 450]);

% UF (İleri) ve UB (Geri) İstatistik Eğrileri
plot(years_tfpw, uf, 'r-o', 'LineWidth', 1.8, 'MarkerFaceColor', 'r', 'DisplayName', 'UF (İleri İstatistik)');
hold on;
plot(years_tfpw, ub, 'b--s', 'LineWidth', 1.8, 'MarkerFaceColor', 'b', 'DisplayName', 'UB (Geri İstatistik)');

% %95 Güven Sınırları (Z = ±1.96)
yline(1.96, 'k--', 'LineWidth', 1.2, 'DisplayName', '+1.96 (%95 Güven Sınırı)');
yline(-1.96, 'k--', 'LineWidth', 1.2, 'DisplayName', '-1.96 (%95 Güven Sınırı)');
yline(0, 'Color', [0.5 0.5 0.5], 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');

grid on;
xlabel('Yıllar', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Z İstatistiği u(t)', 'FontSize', 11, 'FontWeight', 'bold');
title('Acıpayam İstasyonu Yıllık Maks. Sıcaklık SQMK Kırılma Analizi', 'FontSize', 12);
legend('Location', 'best');
xlim([years_tfpw(1) years_tfpw(end)]);

fprintf('\nAnaliz başarıyla tamamlandı.\n');

%% ========================================================================
%  YARDIMCI FONKSİYONLAR (SUBFUNCTIONS)
%  ========================================================================

% 1. Sen's Slope Fonksiyonu
function beta = calc_sens_slope(x)
    n = length(x);
    slopes = [];
    for i = 1:n-1
        for j = i+1:n
            slopes(end+1) = (x(j) - x(i)) / (j - i); %#ok<AGROW>
        end
    end
    beta = median(slopes);
end

% 2. Trend-Free Pre-Whitening (TFPW) Fonksiyonu
function [x_tfpw, r1] = tfpw_prewhitening(x, beta)
    n = length(x);
    t = (1:n)';
    x = x(:);
    
    % 1. Eğimi Sökme (Detrending)
    y = x - beta * t;
    
    % 2. Lag-1 Otokorelasyon Hesabı
    y_mean = mean(y);
    r1 = sum((y(1:n-1) - y_mean) .* (y(2:n) - y_mean)) / sum((y - y_mean).^2);
    
    % 3. AR(1) Temizleme ve Eğimi Geri Ekleme
    y_prime = y(2:n) - r1 * y(1:n-1);
    x_tfpw = y_prime + beta * t(2:n);
end

% 3. Sequential Mann-Kendall (SQMK) Fonksiyonu
function [uf, ub] = sequential_mk(x)
    n = length(x);
    x = x(:);
    
    % İleri İstatistik (UF)
    uf = zeros(n, 1);
    t_stat = 0;
    for k = 2:n
        n_k = sum(x(1:k-1) < x(k));
        t_stat = t_stat + n_k;
        E_t = k * (k - 1) / 4;
        Var_t = k * (k - 1) * (2*k + 5) / 72;
        uf(k) = (t_stat - E_t) / sqrt(Var_t);
    end
    
    % Geri İstatistik (UB)
    x_rev = flipud(x);
    ub_rev = zeros(n, 1);
    t_stat_rev = 0;
    for k = 2:n
        n_k = sum(x_rev(1:k-1) < x_rev(k));
        t_stat_rev = t_stat_rev + n_k;
        E_t = k * (k - 1) / 4;
        Var_t = k * (k - 1) * (2*k + 5) / 72;
        ub_rev(k) = (t_stat_rev - E_t) / sqrt(Var_t);
    end
    
    ub = -flipud(ub_rev);
end
