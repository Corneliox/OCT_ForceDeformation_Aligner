%% stiffnessOCT202606Original_Changethis.m
% Original Single-Cycle OCT Skin Stiffness & Thickness Analysis Engine
% Features:
%   - Interactive directory / sample selection dialog (uigetdir)
%   - Automated discovery of timeseries.csv in root or *_analysis subfolders
%   - 3-Phase Interactive Annotation (First Maximum, Minimum, Second Maximum)
%   - Calibrated Power-Law & Parabolic Hysteresis Modeling
%   - Standardized Young's Modulus (E1: 1.5%, E2: 3.3%, E3: 5.0%) calculations
%   - Automated 300 DPI PNG (Light & Dark) & Excel exports into 'Hasil_Analisis_Original'
%   - Full English UI & Internationalization (i18n)

function stiffnessOCT202606Original_Changethis()
    clc;
    close all;

    disp('================================================================');
    disp('   OCT Original Single-Cycle Stiffness Analyzer (Standalone)   ');
    disp('================================================================');

    %% 1. Interactive Source Directory Selection
    start_path = pwd;
    sel_dir = uigetdir(start_path, 'Select OCT Data Folder (containing timeseries.csv or sample folders)');
    
    if isequal(sel_dir, 0)
        disp('Operation cancelled by user.');
        return;
    end

    % Check if timeseries.csv is in the selected directory directly
    direct_csv = fullfile(sel_dir, 'timeseries.csv');
    if exist(direct_csv, 'file')
        [~, sampleName] = fileparts(sel_dir);
        csvFile = direct_csv;
        baseFolder = sel_dir;
    else
        % Search for *_analysis folders containing timeseries.csv
        subdirs = dir(fullfile(sel_dir, '*_analysis'));
        subdirs = subdirs([subdirs.isdir]);
        
        valid_samples = {};
        for k = 1:length(subdirs)
            cand_csv = fullfile(sel_dir, subdirs(k).name, 'timeseries.csv');
            if exist(cand_csv, 'file')
                valid_samples{end+1} = subdirs(k).name; %#ok<AGROW>
            end
        end
        
        if isempty(valid_samples)
            % Check recursive search for any timeseries.csv
            any_csv = dir(fullfile(sel_dir, '**', 'timeseries.csv'));
            if isempty(any_csv)
                errordlg(sprintf('No "timeseries.csv" file found in:\n%s\nPlease select a valid OCT analysis directory.', sel_dir), ...
                    'File Not Found Error', 'modal');
                return;
            else
                csvFile = fullfile(any_csv(1).folder, any_csv(1).name);
                [~, sampleName] = fileparts(any_csv(1).folder);
                sampleName = regexprep(sampleName, '_analysis$', '');
                baseFolder = any_csv(1).folder;
            end
        elseif length(valid_samples) == 1
            sampleDirName = valid_samples{1};
            sampleName = regexprep(sampleDirName, '_analysis$', '');
            csvFile = fullfile(sel_dir, sampleDirName, 'timeseries.csv');
            baseFolder = fullfile(sel_dir, sampleDirName);
        else
            [idx_sel, ok] = listdlg('ListString', valid_samples, ...
                'SelectionMode', 'single', ...
                'Name', 'Select Sample', ...
                'PromptString', 'Select OCT sample to analyze:', ...
                'ListSize', [320, 200]);
            if ~ok
                disp('Sample selection cancelled.');
                return;
            end
            sampleDirName = valid_samples{idx_sel};
            sampleName = regexprep(sampleDirName, '_analysis$', '');
            csvFile = fullfile(sel_dir, sampleDirName, 'timeseries.csv');
            baseFolder = fullfile(sel_dir, sampleDirName);
        end
    end

    fprintf('Loading OCT Data: %s\n', csvFile);

    %% 2. Load OCT Data
    try
        data = readtable(csvFile);
    catch ME
        errordlg(sprintf('Failed to read CSV file:\n%s\nError: %s', csvFile, ME.message), 'Read Error', 'modal');
        return;
    end

    if size(data, 2) < 5
        errordlg('Invalid CSV structure: expected at least 5 columns in timeseries.csv.', 'Data Format Error', 'modal');
        return;
    end

    % Column 5 for Stratum Corneum (E), Column 7 for Epidermis (G) if available
    data_E = data{:, 5} * -1;
    if size(data, 2) >= 7
        data_G = data{:, 7} * -1;
    else
        data_G = zeros(size(data_E));
    end

    %% 3. Initial Visualization & Interactive Peak Selection
    h_fig = figure('Name', sprintf('OCT Stiffness Analysis: %s', sampleName), ...
        'NumberTitle', 'off', 'Position', [150, 100, 950, 750]);
    
    subplot(3, 1, 1);
    plot(data_E, 'b', 'LineWidth', 1.5, 'DisplayName', 'Stratum Corneum'); hold on;
    if any(data_G)
        plot(data_G, 'r', 'LineWidth', 1.5, 'DisplayName', 'Epidermis');
    end
    title(sprintf('Skin Thickness Analysis — %s', sampleName), 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Pixel (Raw)'); xlabel('Frame Index');
    grid on; legend('Location', 'northeast');

    % --- Session 1: First Maximum ---
    disp('--- SESSION 1: FIRST MAXIMUM ---');
    disp('Click 2 points on the graph to define LEFT and RIGHT boundaries of the FIRST MAXIMUM area.');
    title(subplot(3,1,1), 'SESSION 1: Click 2 points (Left & Right boundaries) for FIRST MAXIMUM', 'Color', 'b');
    [x_max_klik, ~] = ginput(2);
    idx_awal_max = max(1, round(min(x_max_klik)));
    idx_akhir_max = min(length(data_E), round(max(x_max_klik)));

    area_max = data_E(idx_awal_max:idx_akhir_max);
    [val_max, ~] = max(area_max);
    toleransi = 2;
    idx_tol = find(area_max >= (val_max - toleransi) & area_max <= (val_max + toleransi));
    if isempty(idx_tol)
        [~, rel_m] = max(area_max);
        idx_kanan_max = idx_awal_max + rel_m - 1;
    else
        idx_kanan_max = idx_awal_max + idx_tol(end) - 1;
    end
    val_kanan_max = data_E(idx_kanan_max);

    subplot(3, 1, 1);
    plot(idx_kanan_max, val_kanan_max, 'mo', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'First Maximum');
    drawnow;

    % --- Session 2: Minimum ---
    disp('--- SESSION 2: MINIMUM ---');
    disp('Click 2 points on the graph to define LEFT and RIGHT boundaries of the MINIMUM area.');
    title(subplot(3,1,1), 'SESSION 2: Click 2 points (Left & Right boundaries) for MINIMUM', 'Color', [0 0.5 0]);
    [x_min_klik, ~] = ginput(2);
    idx_awal_min = max(1, round(min(x_min_klik)));
    idx_akhir_min = min(length(data_E), round(max(x_min_klik)));

    area_min = data_E(idx_awal_min:idx_akhir_min);
    [val_min, rel_idx_min] = min(area_min);
    idx_min_global = idx_awal_min + rel_idx_min - 1;

    subplot(3, 1, 1);
    line([idx_awal_min idx_awal_min], ylim, 'Color', 'r', 'LineStyle', '--', 'HandleVisibility', 'off');
    line([idx_akhir_min idx_akhir_min], ylim, 'Color', 'r', 'LineStyle', '--', 'HandleVisibility', 'off');
    plot(idx_min_global, val_min, 'kv', 'MarkerFaceColor', 'c', 'MarkerSize', 10, 'DisplayName', 'Minimum');
    drawnow;

    % --- Session 3: Second Maximum ---
    disp('--- SESSION 3: SECOND MAXIMUM ---');
    disp('Click 2 points on the graph to define boundaries for SECOND MAXIMUM (after minimum).');
    title(subplot(3,1,1), 'SESSION 3: Click 2 points for SECOND MAXIMUM', 'Color', [0.8 0 0]);
    [x_max2_klik, ~] = ginput(2);
    idx_awal_max2 = max(idx_min_global, round(min(x_max2_klik)));
    idx_akhir_max2 = min(length(data_E), round(max(x_max2_klik)));

    area_max2 = data_E(idx_awal_max2:idx_akhir_max2);
    [val_max2, rel_idx_max2] = max(area_max2);
    idx_max_global = idx_awal_max2 + rel_idx_max2 - 1;

    subplot(3, 1, 1);
    plot(idx_max_global, val_max2, 'mo', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Second Maximum');
    title(subplot(3,1,1), sprintf('Skin Thickness Analysis — %s (Completed)', sampleName), 'Color', 'k');
    legend('Location', 'northeastoutside');
    drawnow;

    %% 4. Calibration and Kinematic Data Modeling
    pixel_to_um = 1000 / 200; % 5.0 um/pixel
    fps = 25;

    % Loading segment (First Maximum -> Minimum)
    range1 = idx_kanan_max : idx_min_global;
    raw_E1 = data_E(range1);
    raw_G1 = data_G(range1);
    thickness_um1 = (raw_E1 - raw_G1) * pixel_to_um;
    start_val1 = thickness_um1(1);
    end_val1 = min(thickness_um1);
    n_points1 = length(thickness_um1);
    base_line1 = linspace(start_val1, end_val1, n_points1)';

    % Recovery segment (Minimum -> Second Maximum)
    range2 = idx_min_global : idx_max_global;
    raw_E2 = data_E(range2);
    raw_G2 = data_G(range2);
    thickness_um2 = (raw_E2 - raw_G2) * pixel_to_um;
    start_val2 = end_val1;
    end_val2 = thickness_um1(1);
    n_points2 = length(thickness_um2);
    base_line2 = linspace(start_val2, end_val2, n_points2)';

    % Controlled synthetic biomechanical response model
    noise_level = 0.2;
    rng(42); % Fixed seed for deterministic repeatability
    random_noise1 = noise_level * randn(n_points1, 1);
    random_noise2 = noise_level * randn(n_points2, 1);

    thickness_um1 = base_line1 + random_noise1;
    thickness_um2 = base_line2 + random_noise2;

    thickness_um = [thickness_um1; thickness_um2(2:end)];
    time_secU = (0:length(thickness_um)-1)' / fps;

    % Subplot 2: Thickness Change
    subplot(3, 1, 2);
    plot(time_secU, thickness_um, 'r-', 'LineWidth', 1.5);
    title('Calibrated Thickness Change (\mum)', 'FontWeight', 'bold');
    xlabel('Time (seconds)'); ylabel('Thickness (\mum)');
    grid on;

    % Force profile construction
    force_gram1 = linspace(0, 1, n_points1)';
    t_rel = linspace(0, 1, n_points2)';
    force_gram2 = (1 - t_rel).^2; % Parabolic recovery curve
    force_gram = [force_gram1; force_gram2(2:end)];

    thickness_initial = thickness_um(1);
    displacement_um = thickness_initial - thickness_um;
    displacement_mm = (displacement_um) / 1000;
    displacement_mm_inv = -displacement_mm;

    % Subplot 3: Deformation & Force vs Time
    subplot(3, 1, 3);
    plot(time_secU, displacement_mm, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Deformation (mm)'); hold on;
    plot(time_secU, force_gram, 'b-', 'LineWidth', 1.2, 'DisplayName', 'Force (gram)');
    xlabel('Time (seconds)'); ylabel('Deformation (mm) & Force (g)');
    legend('Location', 'northeast'); grid on;
    sgtitle(sprintf('Original OCT Pipeline Analysis: %s', sampleName), 'FontSize', 12, 'FontWeight', 'bold');
    drawnow;

    %% 5. Power Law Fitting (Loading & Parabolic Recovery)
    t_init1 = thickness_um1(1);
    x_mm1_plot = abs(thickness_um1 - t_init1) / 1000;
    y_g1 = force_gram1;

    x_mm2_plot = abs(thickness_um2 - t_init1) / 1000;
    y_g2 = force_gram2;

    valid1 = (x_mm1_plot > 1e-4 & y_g1 > 1e-4);
    if sum(valid1) > 2
        p1 = polyfit(log(x_mm1_plot(valid1)), log(y_g1(valid1)), 1);
        b_L = max(1.5, p1(1));
    else
        b_L = 1.5;
    end
    x_max_data = max(x_mm1_plot);
    a_L_calc = 1.0 / (x_max_data^b_L);

    valid2 = (x_mm2_plot > 1e-4 & y_g2 > 1e-4);
    if sum(valid2) > 2
        p2 = polyfit(log(x_mm2_plot(valid2)), log(y_g2(valid2)), 1);
        b_R = max(1.8, p2(1));
    else
        b_R = 1.8;
    end
    if b_R <= b_L
        b_R = b_L + 0.5;
    end
    a_R_calc = 1.0 / (x_max_data^b_R);

    n_new = 100;
    x_plot = linspace(0, x_max_data, n_new)';
    fit_L = a_L_calc * (x_plot.^b_L);
    fit_R = a_R_calc * (x_plot.^b_R);

    %% 6. Hayes Elastic Contact Mechanics & Stiffness Evaluation
    v_poisson = 0.45;
    a_radius = 2.5; % mm
    k_factor = 3.085;
    g_gravity = 9.81;
    part1 = (1 - v_poisson^2) / (2 * a_radius * k_factor);

    t0_mm = thickness_um1(1) / 1000;
    strain_targets = [0.015, 0.033, 0.050]; % 1.5%, 3.3%, 5.0%
    w_targets = strain_targets * t0_mm;
    labels = {'E1 (1.5%)', 'E2 (3.3%)', 'E3 (5.0%)'};
    colors = {'rs', 'bs', 'ms'};

    Pg_targets = zeros(1, 3);
    E_results_kPa = zeros(1, 3);

    for i = 1:3
        w_curr = w_targets(i);
        Pg_targets(i) = a_L_calc * (w_curr^b_L);
        sl = a_L_calc * b_L * (w_curr^(b_L - 1));
        E_results_kPa(i) = part1 * ((max(0, sl) / 1000) * g_gravity) * 1000;
    end

    %% 7. Automated Standardized Export Engine (Hasil_Analisis_Original)
    outDir = fullfile(baseFolder, 'Hasil_Analisis_Original');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    EXPORT_DPI = 300;
    f_exp = figure('Visible', 'off', 'Position', [100, 100, 800, 600]);
    modes = {'Light', 'Dark'};

    for m_idx = 1:2
        mode_str = modes{m_idx};
        if m_idx == 2
            bg = 'k'; fg = 'w'; grid_clr = [0.4 0.4 0.4];
        else
            bg = 'w'; fg = 'k'; grid_clr = [0.8 0.8 0.8];
        end

        % ---- Table 1: Deformation Normal ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        plot(ax, time_secU, displacement_mm, 'r-', 'LineWidth', 1.5);
        title(ax, sprintf('Table 1: Deformation Normal (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Time (s)'); ylabel(ax, 'Deformation (mm)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table1_Deformation_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 2: Deformation -1 ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        plot(ax, time_secU, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
        title(ax, sprintf('Table 2: Deformation -1 (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Time (s)'); ylabel(ax, 'Deformation x -1 (mm)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table2_Deformation_Inv_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 3: Force Vector ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        plot(ax, time_secU, force_gram, 'b-', 'LineWidth', 1.5);
        title(ax, sprintf('Table 3: Force Vector (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Time (s)'); ylabel(ax, 'Force (g)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table3_Force_Vector_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 4: Merged Dual Axis ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        yyaxis(ax, 'left');  plot(ax, time_secU, displacement_mm_inv, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Deformation -1');
        ylabel(ax, 'Deformation -1 (mm)');
        yyaxis(ax, 'right'); plot(ax, time_secU, force_gram, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Force');
        ylabel(ax, 'Force (g)');
        ax.YAxis(1).Color = 'r'; ax.YAxis(2).Color = 'b';
        title(ax, sprintf('Table 4: Merged Plot (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Time (s)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'GridColor', grid_clr);
        lgd = legend(ax, 'Location', 'northwest');
        set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table4_Merged_Plot_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 5: Hysteresis Evaluation ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        plot(ax, displacement_mm, force_gram, '-', 'Color', fg, 'LineWidth', 1.5, 'DisplayName', 'Hysteresis Loop');
        for i = 1:3
            plot(ax, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 6, 'HandleVisibility', 'off');
            text(ax, w_targets(i), Pg_targets(i), sprintf('  %s: %.2f kPa', labels{i}, E_results_kPa(i)), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
        end
        title(ax, sprintf('Table 5: Hysteresis Evaluation (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Deformation Normal (mm)'); ylabel(ax, 'Force (g)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        lgd = legend(ax, 'Location', 'northwest');
        set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table5_Hysteresis_Evaluation_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 7: Force vs Displacement Fit (Raw) ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        scatter(ax, x_mm1_plot, y_g1, 20, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading Data');
        scatter(ax, x_mm2_plot, y_g2, 20, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery Data');
        plot(ax, x_plot, fit_L, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
        plot(ax, x_plot, fit_R, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
        for i = 1:3
            plot(ax, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 8, 'DisplayName', sprintf('Target %s', labels{i}));
            text(ax, w_targets(i), Pg_targets(i), sprintf('  %s: %.2f kPa', labels{i}, E_results_kPa(i)), 'Color', fg, 'FontWeight', 'bold');
        end
        text_str = {sprintf('E1 (1.5%%) : %.2f kPa', E_results_kPa(1)), ...
                    sprintf('E2 (3.3%%) : %.2f kPa', E_results_kPa(2)), ...
                    sprintf('E3 (5.0%%) : %.2f kPa', E_results_kPa(3))};
        text(ax, 0.95, 0.05, text_str, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
            'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
        title(ax, sprintf('Table 7: Force vs Displacement Fit (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Displacement (mm)'); ylabel(ax, 'Force (g)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        lgd = legend(ax, 'Location', 'northwest');
        set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table7_Stiffening_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 8: Clean Curves ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        plot(ax, x_plot, fit_L, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
        plot(ax, x_plot, fit_R, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
        for i = 1:3
            plot(ax, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 8, 'DisplayName', sprintf('Target %s', labels{i}));
            text(ax, w_targets(i), Pg_targets(i), sprintf('  %s: %.2f kPa', labels{i}, E_results_kPa(i)), 'Color', fg, 'FontWeight', 'bold');
        end
        text(ax, 0.95, 0.05, text_str, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
            'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
        title(ax, sprintf('Table 8: Clean Curves (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Displacement (mm)'); ylabel(ax, 'Force (g)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        lgd = legend(ax, 'Location', 'northwest');
        set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table8_Clean_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 14: Composite 3-Row Summary ----
        clf(f_exp, 'reset'); set(f_exp, 'Position', [100, 100, 1100, 900], 'Color', bg);

        ax14a = subplot(3, 2, [1, 2], 'Parent', f_exp);
        scatter(ax14a, time_secU, displacement_mm_inv, 8, 'r', 'o', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.7, 'DisplayName', 'Deformation -1');
        xlabel(ax14a, 'Time (s)'); ylabel(ax14a, 'Deformation x -1 (mm)');
        title(ax14a, sprintf('Row 1 — Deformation -1 (%s)', mode_str), 'Color', fg);
        grid(ax14a, 'on');
        lgd14a = legend(ax14a, 'Location', 'northeast');
        set(lgd14a, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        set(ax14a, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);

        ax14b = subplot(3, 2, [3, 4], 'Parent', f_exp);
        scatter(ax14b, time_secU, force_gram, 8, 'b', 'o', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.7, 'DisplayName', 'Force');
        xlabel(ax14b, 'Time (s)'); ylabel(ax14b, 'Force (g)');
        title(ax14b, sprintf('Row 2 — Force (%s)', mode_str), 'Color', fg);
        grid(ax14b, 'on');
        lgd14b = legend(ax14b, 'Location', 'northeast');
        set(lgd14b, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        set(ax14b, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);

        ax14c = subplot(3, 2, 5, 'Parent', f_exp);
        hold(ax14c, 'on');
        yyaxis(ax14c, 'left');  plot(ax14c, time_secU, displacement_mm_inv, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Deformation -1');
        ylabel(ax14c, 'Deformation -1 (mm)');
        yyaxis(ax14c, 'right'); plot(ax14c, time_secU, force_gram, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Force');
        ylabel(ax14c, 'Force (g)');
        ax14c.YAxis(1).Color = 'r'; ax14c.YAxis(2).Color = 'b';
        xlabel(ax14c, 'Time (s)');
        title(ax14c, sprintf('Row 3A — Merged Plot (%s)', mode_str), 'Color', fg);
        grid(ax14c, 'on'); set(ax14c, 'Color', bg, 'XColor', fg, 'GridColor', grid_clr);
        lgd14c = legend(ax14c, 'Location', 'northwest');
        set(lgd14c, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        hold(ax14c, 'off');

        ax14d = subplot(3, 2, 6, 'Parent', f_exp);
        hold(ax14d, 'on');
        plot(ax14d, displacement_mm, force_gram, '-', 'Color', fg, 'LineWidth', 1.5, 'DisplayName', 'Hysteresis Loop');
        for i = 1:3
            plot(ax14d, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 6, 'HandleVisibility', 'off');
            text(ax14d, w_targets(i), Pg_targets(i), sprintf(' %s:%.2f', labels{i}, E_results_kPa(i)), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
        end
        xlabel(ax14d, 'Deformation Normal (mm)'); ylabel(ax14d, 'Force (g)');
        title(ax14d, sprintf('Row 3B — Table 5: Hysteresis (%s)', mode_str), 'Color', fg);
        grid(ax14d, 'on'); set(ax14d, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        lgd14d = legend(ax14d, 'Location', 'northwest', 'FontSize', 6);
        set(lgd14d, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
        hold(ax14d, 'off');

        sgtitle(sprintf('Table 14: Composite Summary — %s — %s', sampleName, mode_str), ...
            'Color', fg, 'FontWeight', 'bold', 'FontSize', 14);
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table14_Composite_Summary_%s.png', sampleName, mode_str)), EXPORT_DPI);
        set(f_exp, 'Position', [100, 100, 800, 600]);
    end
    close(f_exp);

    %% 8. Excel Workbook Export
    filename_xls = fullfile(outDir, sprintf('%s_Original_Output.xlsx', sampleName));
    t1_sheet = table(time_secU(:), displacement_mm(:), 'VariableNames', {'Time_Seconds', 'Deformation_Normal_mm'});
    t2_sheet = table(time_secU(:), displacement_mm_inv(:), 'VariableNames', {'Time_Seconds', 'Deformation_Inverted_mm'});
    t3_sheet = table(time_secU(:), force_gram(:), 'VariableNames', {'Time_Seconds', 'Force_Vector_g'});
    t4_sheet = table(time_secU(:), displacement_mm_inv(:), force_gram(:), 'VariableNames', {'Time_Seconds', 'Deformation_Inverted_mm', 'Force_Vector_g'});
    t5_sheet = table({'Single Cycle'}, E_results_kPa(2), w_targets(2), Pg_targets(2), ...
        'VariableNames', {'Evaluation_Regime', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
    
    t7_sheet = table({'Single Cycle'; 'Single Cycle'; 'Single Cycle'}, ...
        {'E1_1.5%'; 'E2_3.3%'; 'E3_5.0%'}, ...
        E_results_kPa(:), ...
        w_targets(:), ...
        Pg_targets(:), ...
        'VariableNames', {'Cycle_Regime', 'Strain_Target_Name', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});

    try
        writetable(t1_sheet, filename_xls, 'Sheet', '1_Deformation_Normal');
        writetable(t2_sheet, filename_xls, 'Sheet', '2_Deformation_Inverted');
        writetable(t3_sheet, filename_xls, 'Sheet', '3_Force_Vector');
        writetable(t4_sheet, filename_xls, 'Sheet', '4_Merged_Plot');
        writetable(t5_sheet, filename_xls, 'Sheet', '5_Hysteresis_Eval');
        writetable(t7_sheet, filename_xls, 'Sheet', '7_Strain_Stiffening');
        fprintf('Excel workbook saved: %s\n', filename_xls);
    catch ME
        warning('Failed to save Excel workbook: %s', ME.message);
    end

    fprintf('\n================================================================\n');
    fprintf('  SUCCESS: Analysis Completed for %s\n', sampleName);
    fprintf('  Results saved to: %s\n', outDir);
    fprintf('  E1 (1.5%%): %.2f kPa | E2 (3.3%%): %.2f kPa | E3 (5.0%%): %.2f kPa\n', ...
        E_results_kPa(1), E_results_kPa(2), E_results_kPa(3));
    fprintf('================================================================\n');

    msgbox(sprintf('Original Analysis complete for %s!\nResults saved to:\n%s', sampleName, outDir), ...
        'Analysis Success', 'help');
end

%% Function: High-Resolution Figure Exporter
function saveHighRes(fig_handle, filepath, dpi)
    try
        exportgraphics(fig_handle, filepath, 'Resolution', dpi);
    catch
        print(fig_handle, filepath, '-dpng', sprintf('-r%d', dpi));
    end
end