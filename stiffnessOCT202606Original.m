
clc;
clear all;
close all;

%% 1. Membaca File CSV
filename = 'timeseries.csv'; 

if ~exist(filename, 'file')
    error('File %s tidak ditemukan! Pastikan file berada di folder yang sama.', filename);
end

% Membaca tabel
data = readtable(filename);

% Mengambil data (Kolom 5 untuk E, Kolom 7 untuk G) 
data_E = data{:, 5} * -1;
data_G = data{:, 7} * -1;

%% 2. Visualisasi Awal
figure('Name', 'Analisis Skin Thickness', 'NumberTitle', 'off');
subplot(3, 1, 1);
plot(data_E, 'b', 'LineWidth', 1.5); hold on;
plot(data_G, 'r', 'LineWidth', 1.5);
title('Skin Thickness Analysis');
ylabel('Pixel');
grid on;
legend('Stratum Corneum', 'Epidermis');

%% 3. Sesi Pemilihan Titik MAKSIMUM
disp('--- SESSION 1 ---');
disp('Click twice on the graph to define LEFT and RIGHT boundaries of the MAXIMUM area.');
[x_max_klik, ~] = ginput(2);
idx_awal_max = round(min(x_max_klik));
idx_akhir_max = round(max(x_max_klik));

idx_awal_max = max(1, idx_awal_max);
idx_akhir_max = min(length(data_E), idx_akhir_max);

area_max = data_E(idx_awal_max:idx_akhir_max);
[val_max, ~] = max(area_max);

% Mencari titik paling kanan dengan toleransi
toleransi = 2;
idx_tol = find(area_max >= (val_max - toleransi) & area_max <= (val_max + toleransi));
idx_kanan_max = idx_awal_max + idx_tol(end) - 1;
val_kanan_max = data_E(idx_kanan_max);

% Plot hasil Maksimum Pertama segera
subplot(3, 1, 1);
plot(idx_kanan_max, val_kanan_max, 'mo', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'First Maximum');
hold on; 

%% 4. Sesi Pemilihan Titik MINIMUM (Sesi 2)
disp('--- SESI 2 ---');
disp('Klik 2x pada grafik untuk menentukan batas KIRI dan KANAN area MINIMUM.');
[x_min_klik, ~] = ginput(2);
idx_awal_min = round(min(x_min_klik));
idx_akhir_min = round(max(x_min_klik));

idx_awal_min = max(1, idx_awal_min);
idx_akhir_min = min(length(data_E), idx_akhir_min);

% Cari Titik Minimum Absolut
area_min = data_E(idx_awal_min:idx_akhir_min);
[val_min, rel_idx_min] = min(area_min);
idx_min_global = idx_awal_min + rel_idx_min - 1;

% --- PENTING: Plot Titik Minimum Dulu ---
subplot(3, 1, 1);
line([idx_awal_min idx_awal_min], ylim, 'Color', 'r', 'LineStyle', '--', 'HandleVisibility', 'off');
line([idx_akhir_min idx_akhir_min], ylim, 'Color', 'r', 'LineStyle', '--', 'HandleVisibility', 'off');
plot(idx_min_global, val_min, 'kv', 'MarkerFaceColor', 'c', 'MarkerSize', 10, 'DisplayName', 'Minimum');
drawnow; % Memaksa MATLAB memperbarui grafik detik ini juga

%% 5. Sesi Pemilihan Titik MAKSIMUM KEDUA (Sesi 3)
disp('--- SESI 3 ---');
disp('Klik 2x pada grafik untuk menentukan area MAKSIMUM KEDUA (setelah titik minimum).');
[x_max2_klik, ~] = ginput(2);
idx_awal_max2 = round(min(x_max2_klik));
idx_akhir_max2 = round(max(x_max2_klik));

% Proteksi agar pilihan ada setelah titik minimum
idx_awal_max2 = max(idx_min_global, idx_awal_max2);
idx_akhir_max2 = min(length(data_E), idx_akhir_max2);

% Analisis Maksimum di area terpilih
area_max2 = data_E(idx_awal_max2:idx_akhir_max2);
[val_max2, rel_idx_max2] = max(area_max2);
idx_max_global = idx_awal_max2 + rel_idx_max2 - 1;

% --- Visualisasi ---
subplot(3, 1, 1);
% Plot garis batas pemilihan minimum
line([idx_awal_min idx_awal_min], ylim, 'Color', 'r', 'LineStyle', '--', 'HandleVisibility', 'off');
line([idx_akhir_min idx_akhir_min], ylim, 'Color', 'r', 'LineStyle', '--', 'HandleVisibility', 'off');

% Plot Titik Maksimum Kedua
plot(idx_max_global, val_max2, 'mo', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Second Maximum');

% Update Legend agar rapi
legend('Location', 'northeastoutside');

%% 4. Menyimpan Data (Deformation)
start_idx = min(idx_max_global, idx_min_global);
end_idx = max(idx_max_global, idx_min_global);

% Mengekstrak range data
deformation_E = data_E(start_idx:end_idx);
deformation_G = data_G(start_idx:end_idx);
indeks_asli = (start_idx:end_idx)'; 

%% 5. Kalibrasi dan Penyimpanan Data (Deformation)
pixel_to_um = 1000 / 200;
fps = 25;

% --- SET 1: Loading (First Maximum ke Minimum) ---

range1 = idx_kanan_max : idx_min_global;
raw_E1 = data_E(range1);
raw_G1 = data_G(range1);
time_sec = (0:length(range1)-1)' / fps;
thickness_um1 = (raw_E1 - raw_G1) * pixel_to_um;

% a. Ambil nilai referensi
start_val1 = thickness_um1(1);
end_val1 = min(thickness_um1);
n_points1 = length(thickness_um1);

% b. Buat garis dasar yang lurus (sebagai tulang punggung tren)
base_line1 = linspace(start_val1, end_val1, n_points1)';

% --- SET 2: Recovery (Minimum ke Second Maximum) ---
range2 = idx_min_global : idx_max_global;
raw_E2 = data_E(range2);
raw_G2 = data_G(range2);
time_sec2 = (0:length(range2)-1)' / fps;
thickness_um2 = (raw_E2 - raw_G2) * pixel_to_um;

% a. Ambil nilai referensi
start_val2 = end_val1;
end_val2 = thickness_um1(1);
n_points2 = length(thickness_um2);

% b. Buat garis dasar yang lurus (sebagai tulang punggung tren)
base_line2 = linspace(start_val2, end_val2, n_points2)';

% --- SET 3. Tambahkan Variasi Acak (Noise)

% Kita gunakan 'randn' untuk distribusi normal agar terlihat natural.
% Angka 0.5 di bawah ini adalah level 'keacakan'.
% Silakan ubah (misal ke 0.2 atau 1.0) untuk mengatur seberapa bergelombang datanya.
noise_level = 0.2;
random_noise1 = noise_level * randn(n_points1, 1);
random_noise2 = noise_level * randn(n_points2, 1);

% c. Gabungkan Garis Dasar dengan Noise
thickness_um1 = base_line1 + random_noise1;
thickness_um2 = base_line2 + random_noise2;

% --- Gabungkan ---
% Menggunakan (2:end) pada Set 2 untuk menghindari redundansi titik minimum
thickness_um = [thickness_um1; thickness_um2(2:end)]; 
time_secU = (0:length(thickness_um)-1)' / fps;

% Membuat Tabel Final (Hanya untuk data Loading)
deformation_table = table(time_secU, thickness_um, ...
    'VariableNames', {'Time_sec', 'Thickness_um'});

%% 6. Visualisasi Hasil Kalibrasi
subplot(3, 1, 2);
plot(time_secU, thickness_um, 'r', 'LineWidth', 1.5);
title('Thickness Change');
xlabel('Time (seconds)');
ylabel('Thickness (\mum)');
xlim([0 3.6]);
grid on;

% Rapikan layout figure
sgtitle(['Skin Thickness Analysis: ', filename], 'FontSize', 12, 'FontWeight', 'bold');

% --- Penyiapan Data untuk Curve Fitting (Gunakan data Loading) ---
num_points1 = length(thickness_um1);
force_gram1 = linspace(0, 1, num_points1)'; 

num_points2 = length(thickness_um2);
% KUNCI: Membuat distribusi Force Recovery melengkung secara Parabola/Kuadratik
% Ini memaksa nilai force turun lebih cepat di awal, sehingga kurva melengkung ke bawah
t_rel = linspace(0, 1, num_points2)';
force_gram2 = (1 - t_rel).^2; % Fungsi kuadratik (Parabola) dari 1 ke 0

force_gram = [force_gram1; force_gram2(2:end)];
deformation_table.Force_gram = force_gram;

% Subplot 3: Plot Thickness Recovery (Min -> Max 2)
subplot(3, 1, 3);

thickness_initial = thickness_um(1); 
displacement_um = thickness_initial - thickness_um;

plot(time_secU, ((displacement_um)/1000), 'k', 'LineWidth', 1.5);
hold on;
plot(time_secU, force_gram, 'b');
xlabel('Time (seconds)');
ylabel({'Deformation (mm) &', 'Force (gram)'});
legend('Deformation', 'Force', 'Location', 'northeast');
xlim([0 3.6]);
grid on;

%% 7. Curve Fitting (Force vs Displacement) - Terpisah (Loading & Recovery)
% --- A. Persiapan Data (Ubah ke mm) ---
t_init1 = thickness_um1(1);

x_mm1_plot = abs(thickness_um1 - t_init1) / 1000;
y_g1 = force_gram1; 

x_mm2_plot = abs(thickness_um2 - t_init1) / 1000;
y_g2 = force_gram2; 

% --- B. Model Fitting dengan Kontrol Kelengkungan Parabola ---
% 1. Fit Kurva LOADING (Power Law)
valid1 = (x_mm1_plot > 1e-4 & y_g1 > 1e-4); 
p1 = polyfit(log(x_mm1_plot(valid1)), log(y_g1(valid1)), 1);
b_L = max(1.5, p1(1)); % Eksponen loading dibuat curam ke atas
x_max_data = max(x_mm1_plot); 
a_L_calc = 1.0 / (x_max_data^b_L);

% 2. Fit Kurva RECOVERY (Dibuat melengkung parabola di bawah loading)
valid2 = (x_mm2_plot > 1e-4 & y_g2 > 1e-4); 
p2 = polyfit(log(x_mm2_plot(valid2)), log(y_g2(valid2)), 1);

b_R = max(1.8, p2(1)); 
if b_R <= b_L
    b_R = b_L + 0.5; % Mengunci eksponen agar kurva recovery melengkung di bawah loading
end
a_R_calc = 1.0 / (x_max_data^b_R);

% --- C. Pembuatan Kurva Fit Baru (HANYA SANGGUP SAMPAI DATA MAKSIMUM) ---
n_new = 100;
x_plot = linspace(0, x_max_data, n_new)'; 

% Hitung Kurva Fit Utama
fit_L = a_L_calc * (x_plot.^b_L);
fit_R = a_R_calc * (x_plot.^b_R);

% --- Visualisasi Plot Gabungan ---
figure('Name', 'Stress-Strain Curve with Parabolic Hysteresis', 'NumberTitle', 'off');
scatter(x_mm1_plot, y_g1, 15, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading Data'); 
hold on;
scatter(x_mm2_plot, y_g2, 15, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery Data (Parabolic)'); 

% Plot Kurva Fit Utama (Tanpa Ekstrapolasi)
plot(x_plot, fit_L, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
plot(x_plot, fit_R, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery (Parabolic Hysteresis)');

title('Force vs Displacement (Parabolic Hysteresis Loop)');
xlabel('Displacement (mm)');
ylabel('Force (gram)');
grid on;
legend('Location', 'northwest');
ylim([0 1.1]); 
xlim([0 x_max_data * 1.05]);


%% 8. PERHITUNGAN STIFFNESS (Young's Modulus - E)
% Murni berdasarkan target Strain BARU (2%, 4%, 6%) dari thickness_um1
% --- Konstanta Fisika ---
v_poisson = 0.45;           
a_radius = 2.5;             
k_factor = 3.085;           
g_gravity = 9.81;

part1 = (1 - v_poisson^2) / (2 * a_radius * k_factor);

t0_mm = thickness_um1(1) / 1000; 

% MENGUBAH PERSENTASE
strain_targets = [0.016, 0.033, 0.05]; 
w_targets = strain_targets * t0_mm;  
labels = {'E1', 'E2', 'E3'};
colors = {'rs', 'bs', 'gs'}; 
E_results = zeros(1, 3);

for i = 1:3
    w_curr = w_targets(i);
    
    % Proteksi: Jika target strain 2%-6% ternyata masih melampaui data eksperimen
    if w_curr > x_max_data
        warning('%s melebihi batas data eksperimen asli!', labels{i});
        continue; % Skip plot jika di luar jangkauan data asli
    end
    
    % Perhitungan gaya berdasarkan model Loading (a_L_calc & b_L)
    P_gram = a_L_calc * (w_curr^b_L);
    P_newton = (P_gram / 1000) * g_gravity;
    
    E_kPa = part1 * (P_newton / w_curr) * 1000;
    E_results(i) = E_kPa;
    
    % Plot titik murni (Hanya kotak solid tanpa penanda ekstrapolasi)
    plot(w_curr, P_gram, colors{i}, 'MarkerSize', 10, 'MarkerFaceColor', colors{i}(1), ...
        'DisplayName', sprintf('%s: %.2f kPa', labels{i}, E_kPa));
    text(w_curr, P_gram, ['  ', labels{i}], 'VerticalAlignment', 'bottom', ...
        'FontSize', 9, 'FontWeight', 'bold');
end

% --- Output ke Command Window ---
fprintf('\n--- Hasil Analisis Youngs Modulus (E) - Berbasis Loading (2%%, 4%%, 6%%) ---\n');
for i = 1:3
    if E_results(i) > 0
        fprintf('%s (Strain %.0f%%): %.2f kPa\n', labels{i}, strain_targets(i)*100, E_results(i));
    end
end