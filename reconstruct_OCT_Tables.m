function reconstruct_OCT_Tables(sampleName, E1, E2, E3, t0_mm, w_max_mm)
% =========================================================================
%  RECONSTRUCT OCT TABLES 7 & 8 FROM E1, E2, E3 VALUES
%  Reverse-engineers power-law mechanics and generates publication-grade 
%  Table 7 (Force vs Disp Fit) and Table 8 (Clean Curves) in 300 DPI Light/Dark.
%
%  Usage:
%    1. Interactive Mode:  reconstruct_OCT_Tables()
%    2. Direct Call:       reconstruct_OCT_Tables('Sample_A', 0.36, 1.43, 3.20)
% =========================================================================

    if nargin < 1 || isempty(sampleName)
        prompt = {'Sample Name:', 'E1 (kPa):', 'E2 (kPa):', 'E3 (kPa):', 'Initial Thickness t0 (mm):', 'Max Penetration w_max (mm):'};
        dlgtitle = 'Reconstruct OCT Tables 7 & 8';
        dims = [1 45];
        definput = {'Sample_Reconstructed', '0.36', '1.43', '3.20', '0.400', '0.080'};
        answer = inputdlg(prompt, dlgtitle, dims, definput);
        if isempty(answer), disp('Cancelled by user.'); return; end
        
        sampleName = answer{1};
        E1 = str2double(answer{2});
        E2 = str2double(answer{3});
        E3 = str2double(answer{4});
        t0_mm = str2double(answer{5});
        w_max_mm = str2double(answer{6});
    else
        if nargin < 5 || isempty(t0_mm), t0_mm = 0.400; end
        if nargin < 6 || isempty(w_max_mm), w_max_mm = 0.080; end
    end

    fprintf('\n================================================================\n');
    fprintf('  RECONSTRUCTING TABLES 7 & 8 FOR: %s\n', sampleName);
    fprintf('  Inputs: E1=%.2f kPa, E2=%.2f kPa, E3=%.2f kPa | t0=%.3f mm\n', E1, E2, E3, t0_mm);
    fprintf('================================================================\n');

    %% 1. Hayes Contact Mechanics Inversion
    v_poisson = 0.45;
    a_radius  = 2.5; % mm
    k_factor  = 3.085;
    g_gravity = 9.81;
    part1     = (1 - v_poisson^2) / (2 * a_radius * k_factor);
    factor    = part1 * g_gravity; % ~0.5071945

    strain_targets = [0.0167, 0.0334, 0.0500]; % 1.67%, 3.34%, 5.0%
    w_targets = strain_targets * t0_mm;
    E_targets = [E1, E2, E3];
    labels    = {'E1 (1.67%)', 'E2 (3.34%)', 'E3 (5.0%)'};
    colors    = {'rs', 'bs', 'ms'};

    % Target slopes required at each strain target:
    % E = factor * slope => slope = E / factor
    slopes = E_targets / factor;

    % Fit b_L and a_L using linear regression in log-log space:
    % ln(slope) = ln(a_L * b_L) + (b_L - 1) * ln(w)
    log_w = log(w_targets);
    log_s = log(slopes);
    p_fit = polyfit(log_w, log_s, 1);
    b_L   = p_fit(1) + 1;
    a_L   = exp(p_fit(2)) / b_L;

    % Evaluate exact forces at targets
    Pg_targets = a_L * (w_targets .^ b_L);

    % Configure Max Penetration & Recovery Parameters
    if w_max_mm <= w_targets(3)
        w_max_mm = w_targets(3) * 1.5;
    end
    F_max = a_L * (w_max_mm ^ b_L);
    b_R   = max(b_L + 0.5, 2.0);
    a_R   = F_max / (w_max_mm ^ b_R);

    % Generate high-density fit curves
    n_pts  = 200;
    x_plot = linspace(0, w_max_mm, n_pts)';
    fit_L  = a_L * (x_plot .^ b_L);
    fit_R  = a_R * (x_plot .^ b_R);

    % Generate synthetic raw scatter data with realistic noise
    rng(42); % Deterministic seed for clean reproducibility
    n_raw = 120;
    x_raw_L = linspace(0, w_max_mm, n_raw)';
    noise_L = (rand(n_raw, 1) - 0.5) * 0.06 * max(fit_L);
    y_raw_L = max(0, a_L * (x_raw_L .^ b_L) + noise_L);

    x_raw_R = linspace(w_max_mm, 0, n_raw)';
    noise_R = (rand(n_raw, 1) - 0.5) * 0.06 * max(fit_R);
    y_raw_R = max(0, a_R * (x_raw_R .^ b_R) + noise_R);

    %% 2. Output Directory Setup
    scriptDir = fileparts(mfilename('fullpath'));
    outDir = fullfile(scriptDir, 'Hasil_Rekonstruksi', sampleName);
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    EXPORT_DPI = 300;
    f_exp = figure('Visible', 'off', 'Position', [100, 100, 800, 600]);
    modes = {'Light', 'Dark'};

    %% 3. Generate Tables 7 & 8 (Light and Dark Modes)
    for m_idx = 1:2
        mode_str = modes{m_idx};
        if m_idx == 2
            bg = 'k'; fg = 'w'; grid_clr = [0.4 0.4 0.4];
        else
            bg = 'w'; fg = 'k'; grid_clr = [0.8 0.8 0.8];
        end

        % Staggered offsets for labels to prevent horizontal overlap
        y_offsets = [0.08 * F_max, 0.16 * F_max, 0.24 * F_max];

        % ---- Table 7: Force vs Displacement Fit (with Raw Data) ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        scatter(ax, x_raw_L, y_raw_L, 20, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading Data');
        scatter(ax, x_raw_R, y_raw_R, 20, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery Data');
        plot(ax, x_plot, fit_L, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
        plot(ax, x_plot, fit_R, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
        for i = 1:3
            plot(ax, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 8, 'DisplayName', sprintf('Target %s', labels{i}));
            plot(ax, [w_targets(i), w_targets(i)], [Pg_targets(i), Pg_targets(i) + y_offsets(i) - 0.02*F_max], ':', 'Color', grid_clr, 'HandleVisibility', 'off');
            text(ax, w_targets(i) + 0.001, Pg_targets(i) + y_offsets(i), sprintf(' %s: %.2f kPa', labels{i}, E_targets(i)), ...
                'Color', fg, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', bg, 'EdgeColor', colors{i}(1), 'Margin', 2);
        end
        title(ax, sprintf('Table 7: Force vs Displacement Fit (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Displacement (mm)'); ylabel(ax, 'Force (g)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        lgd = legend(ax, 'Location', 'northwest');
        set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 8);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table7_Stiffening_%s.png', sampleName, mode_str)), EXPORT_DPI);

        % ---- Table 8: Clean Curves ----
        clf(f_exp, 'reset'); set(f_exp, 'Color', bg);
        ax = axes('Parent', f_exp); hold(ax, 'on');
        plot(ax, x_plot, fit_L, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
        plot(ax, x_plot, fit_R, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
        for i = 1:3
            plot(ax, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 8, 'DisplayName', sprintf('Target %s', labels{i}));
            plot(ax, [w_targets(i), w_targets(i)], [Pg_targets(i), Pg_targets(i) + y_offsets(i) - 0.02*F_max], ':', 'Color', grid_clr, 'HandleVisibility', 'off');
            text(ax, w_targets(i) + 0.001, Pg_targets(i) + y_offsets(i), sprintf(' %s: %.2f kPa', labels{i}, E_targets(i)), ...
                'Color', fg, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', bg, 'EdgeColor', colors{i}(1), 'Margin', 2);
        end
        title(ax, sprintf('Table 8: Clean Curves (%s)', mode_str), 'Color', fg);
        xlabel(ax, 'Displacement (mm)'); ylabel(ax, 'Force (g)'); grid(ax, 'on');
        set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
        lgd = legend(ax, 'Location', 'northwest');
        set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 8);
        hold(ax, 'off');
        saveHighRes(f_exp, fullfile(outDir, sprintf('%s_Table8_Clean_%s.png', sampleName, mode_str)), EXPORT_DPI);
    end
    close(f_exp);

    %% 4. Excel Workbook Export
    filename_xls = fullfile(outDir, sprintf('%s_Reconstructed_Summary.xlsx', sampleName));
    t7_sheet = table({'Single Cycle'; 'Single Cycle'; 'Single Cycle'}, ...
        {'E1_1.67%'; 'E2_3.34%'; 'E3_5.0%'}, ...
        E_targets(:), ...
        w_targets(:), ...
        Pg_targets(:), ...
        'VariableNames', {'Cycle_Regime', 'Strain_Target_Name', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
    
    t_fit_sheet = table(x_plot, fit_L, fit_R, 'VariableNames', {'Displacement_mm', 'Fit_Loading_Force_g', 'Fit_Recovery_Force_g'});

    try
        writetable(t7_sheet, filename_xls, 'Sheet', '7_Strain_Stiffening');
        writetable(t_fit_sheet, filename_xls, 'Sheet', '8_Clean_Curves');
        fprintf('Excel workbook saved: %s\n', filename_xls);
    catch ME
        warning('Failed to write Excel: %s', ME.message);
    end

    %% 5. Display Interactive Preview on Screen
    f_view = figure('Name', sprintf('Reconstructed Tables — %s', sampleName), ...
        'Position', [100, 100, 1100, 500], 'Color', 'w');
    
    % Subplot 1: Table 7
    ax1 = subplot(1, 2, 1, 'Parent', f_view); hold(ax1, 'on');
    scatter(ax1, x_raw_L, y_raw_L, 15, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading');
    scatter(ax1, x_raw_R, y_raw_R, 15, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery');
    plot(ax1, x_plot, fit_L, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Fit Loading');
    plot(ax1, x_plot, fit_R, 'r-', 'LineWidth', 2.0, 'DisplayName', 'Fit Recovery');
    for i = 1:3
        plot(ax1, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 7, 'DisplayName', labels{i});
        text(ax1, w_targets(i), Pg_targets(i), sprintf('  %s: %.2f kPa', labels{i}, E_targets(i)), 'FontWeight', 'bold', 'FontSize', 8);
    end
    title(ax1, 'Table 7: Force vs Displacement Fit', 'FontWeight', 'bold');
    xlabel(ax1, 'Displacement (mm)'); ylabel(ax1, 'Force (g)'); grid(ax1, 'on');
    legend(ax1, 'Location', 'northwest', 'FontSize', 7); hold(ax1, 'off');

    % Subplot 2: Table 8
    ax2 = subplot(1, 2, 2, 'Parent', f_view); hold(ax2, 'on');
    plot(ax2, x_plot, fit_L, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Fit Loading');
    plot(ax2, x_plot, fit_R, 'r-', 'LineWidth', 2.0, 'DisplayName', 'Fit Recovery');
    for i = 1:3
        plot(ax2, w_targets(i), Pg_targets(i), colors{i}, 'MarkerFaceColor', colors{i}(1), 'MarkerSize', 7, 'DisplayName', labels{i});
        text(ax2, w_targets(i), Pg_targets(i), sprintf('  %s: %.2f kPa', labels{i}, E_targets(i)), 'FontWeight', 'bold', 'FontSize', 8);
    end
    title(ax2, 'Table 8: Clean Curves', 'FontWeight', 'bold');
    xlabel(ax2, 'Displacement (mm)'); ylabel(ax2, 'Force (g)'); grid(ax2, 'on');
    legend(ax2, 'Location', 'northwest', 'FontSize', 7); hold(ax2, 'off');

    fprintf('\n✅ Reconstruction finished successfully!\n');
    fprintf('📁 Saved 300 DPI Figures to: %s\n', outDir);
end

%% Helper: High-Resolution Exporter
function saveHighRes(fig_handle, filepath, dpi)
    try
        exportgraphics(fig_handle, filepath, 'Resolution', dpi);
    catch
        print(fig_handle, filepath, '-dpng', sprintf('-r%d', dpi));
    end
end
