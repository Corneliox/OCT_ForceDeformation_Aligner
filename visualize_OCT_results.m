function visualize_OCT_results()
% =========================================================================
%  STANDALONE VISUALIZATION VIEWER — OCT Biomechanical Analysis Results
%  Open this file in MATLAB and run it to view previously processed outputs.
%
%  Usage:
%    1. Run this script: visualize_OCT_results()
%    2. Browse to a sample's output folder (e.g., Hasil_Analisis/YourSample/)
%    3. The viewer will load the Excel data and display all plots.
% =========================================================================

    % --- 1. SELECT OUTPUT FOLDER ---
    outDir = uigetdir('', 'Select Sample Output Folder (e.g., Analysis_Output/SampleName)');
    if outDir == 0
        disp('Cancelled by user.'); return;
    end

    % --- 2. FIND EXCEL FILE ---
    xlsFiles = dir(fullfile(outDir, '*_Standardized_6Table_Output.xlsx'));
    if isempty(xlsFiles)
        errordlg('No standardized Excel output file found in this folder!', 'Error'); return;
    end
    xlsPath = fullfile(outDir, xlsFiles(1).name);
    sampleName = strrep(xlsFiles(1).name, '_Standardized_6Table_Output.xlsx', '');
    fprintf('Loading sample data: %s\n', sampleName);

    % --- 3. LOAD ALL SHEETS ---
    try
        T1 = readtable(xlsPath, 'Sheet', '1_Deformation_Normal');
        T2 = readtable(xlsPath, 'Sheet', '2_Deformation_Inverted');
        T3 = readtable(xlsPath, 'Sheet', '3_Force_Vector');
        T4 = readtable(xlsPath, 'Sheet', '4_Merged_Plot');
        T5 = readtable(xlsPath, 'Sheet', '5_Hysteresis_Eval');
        T6 = readtable(xlsPath, 'Sheet', '6_Donut_Plot');
        T7 = readtable(xlsPath, 'Sheet', '7_Strain_Stiffening');
    catch ME
        errordlg(sprintf('Failed to read Excel file: %s', ME.message), 'Error'); return;
    end

    % --- 4. PARSE DATA ---
    time_s     = T1.Time_Seconds;
    disp_norm  = T1.Deformation_Normal_mm;
    disp_inv   = T2.Deformation_Inverted_mm;
    force_g    = T3.Force_Vector_g;
    X_disp     = T6.Cartesian_X;
    Y_disp     = T6.Cartesian_Y;

    % Stiffness values from Table 5
    E_vals     = T5.Stiffness_Value_kPa;
    targets    = T5.Evaluation_Strain_Target_mm;
    P_forces   = T5.Extracted_Force_Value_g;

    % Per-cycle E values from Table 7
    E_c1 = T7.Stiffness_Value_kPa(1:3);
    E_c2 = T7.Stiffness_Value_kPa(4:6);
    E_c3 = T7.Stiffness_Value_kPa(7:9);
    E_avg = mean([E_c1, E_c2, E_c3], 2);

    % --- 5. BUILD VISUALIZATION WINDOW ---
    fig = figure('Name', sprintf('OCT Biomechanical Viewer — %s', sampleName), ...
        'Position', [30, 30, 1400, 900], ...
        'NumberTitle', 'off', ...
        'Color', [0.12 0.12 0.15]);

    sgtitle(sprintf('OCT Analysis: %s', strrep(sampleName, '_', '\_')), ...
        'Color', 'w', 'FontWeight', 'bold', 'FontSize', 14);

    % Dark theme helper
    dk = @(ax) set(ax, 'Color', [0.15 0.15 0.18], 'XColor', 'w', 'YColor', 'w', ...
                        'GridColor', [0.35 0.35 0.35], 'GridAlpha', 0.5);

    % ---- ROW 1: Tables 1, 2, 3, 4 ----
    ax1 = subplot(3, 4, 1);
    plot(time_s, disp_norm, 'Color', [1 0.4 0.4], 'LineWidth', 1.5);
    title('T1: Deformation Normal', 'Color', 'w');
    xlabel('Time (s)'); ylabel('Deform. (mm)');
    grid on; dk(ax1);

    ax2 = subplot(3, 4, 2);
    scatter(time_s, disp_inv, 5, 'r', 'o', ...
        'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.6);
    title('T2: Deformation -1 (dot)', 'Color', 'w');
    xlabel('Time (s)'); ylabel('Deform. x-1 (mm)');
    grid on; dk(ax2);

    ax3 = subplot(3, 4, 3);
    scatter(time_s, force_g, 5, 'b', 'o', ...
        'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.6);
    title('T3: Force (dot)', 'Color', 'w');
    xlabel('Time (s)'); ylabel('Force (g)');
    grid on; dk(ax3);

    ax4 = subplot(3, 4, 4);
    hold on;
    yyaxis left;  plot(time_s, disp_inv, 'Color', [1 0.5 0.5], 'LineWidth', 1.2);
    ylabel('Deformation -1 (mm)');
    yyaxis right; plot(time_s, force_g, 'Color', [0.4 0.7 1], 'LineWidth', 1.2);
    ylabel('Force (g)');
    ax4.YAxis(1).Color = [1 0.5 0.5];
    ax4.YAxis(2).Color = [0.4 0.7 1];
    title('T4: Merged (Deform. x Force)', 'Color', 'w');
    xlabel('Time (s)'); grid on; dk(ax4); hold off;

    % ---- ROW 2: Table 5 + Table 6 + E-value text panel ----
    ax5 = subplot(3, 4, 5:6);
    hold on;
    col5 = {'r','g','b'};
    label5 = {'Cycle 1 E@3.3%','Cycle 2 E@3.3%','Cycle 3 E@3.3%'};
    for k = 1:min(3, length(targets))
        plot(targets(k), P_forces(k), 'o', 'MarkerFaceColor', col5{k}, ...
             'MarkerEdgeColor', 'w', 'MarkerSize', 10, 'DisplayName', label5{k});
        text(targets(k), P_forces(k), sprintf('  E%d=%.2f kPa', k, E_vals(k)), ...
             'Color', col5{k}, 'FontWeight', 'bold', 'FontSize', 9);
    end
    title('T5: Hysteresis Evaluation (E1/E2/E3)', 'Color', 'w');
    xlabel('Target Strain (mm)'); ylabel('Force (g)');
    lgd5 = legend('Location', 'northwest');
    set(lgd5, 'TextColor', 'w', 'Color', [0.2 0.2 0.25], 'EdgeColor', 'w');
    grid on; dk(ax5); hold off;

    ax6 = subplot(3, 4, 7);
    hold on;
    plot(X_disp, Y_disp, ':', 'Color', [0.4 0.6 1], 'LineWidth', 1);
    n_s1 = round(length(X_disp) / 3);
    plot(X_disp(1:n_s1), Y_disp(1:n_s1), 'r-', 'LineWidth', 2);
    axis equal; grid on; hold off;
    title('T6: Donut Spatial Layout', 'Color', 'w');
    dk(ax6);

    % E-value summary text panel
    ax_txt = subplot(3, 4, 8);
    axis off;
    set(ax_txt, 'Color', [0.12 0.12 0.15]);
    str_lines = {
        '═══ E-Value Summary ═══', '', ...
        'Cycle 1:', ...
        sprintf('  E1(1.5%%) = %.2f kPa', E_c1(1)), ...
        sprintf('  E2(3.3%%) = %.2f kPa', E_c1(2)), ...
        sprintf('  E3(5.0%%) = %.2f kPa', E_c1(3)), '', ...
        'Cycle 2:', ...
        sprintf('  E1(1.5%%) = %.2f kPa', E_c2(1)), ...
        sprintf('  E2(3.3%%) = %.2f kPa', E_c2(2)), ...
        sprintf('  E3(5.0%%) = %.2f kPa', E_c2(3)), '', ...
        'Cycle 3:', ...
        sprintf('  E1(1.5%%) = %.2f kPa', E_c3(1)), ...
        sprintf('  E2(3.3%%) = %.2f kPa', E_c3(2)), ...
        sprintf('  E3(5.0%%) = %.2f kPa', E_c3(3)), '', ...
        '─── Average ───', ...
        sprintf('  E1(avg)  = %.2f kPa', E_avg(1)), ...
        sprintf('  E2(avg)  = %.2f kPa', E_avg(2)), ...
        sprintf('  E3(avg)  = %.2f kPa', E_avg(3))
    };
    text(0.03, 0.98, str_lines, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'Color', 'w', 'FontSize', 8.5, 'FontName', 'Courier New', 'Parent', ax_txt);

    % ---- ROW 3: Table 14 — 3-Row Composite Layout ----
    % Row 3A: Deformation -1 full width
    ax14a = subplot(3, 4, 9:10);
    scatter(time_s, disp_inv, 6, 'r', 'o', ...
        'MarkerFaceAlpha', 0.45, 'MarkerEdgeAlpha', 0.65, ...
        'DisplayName', 'Deformation -1');
    title('T14 Row 1 — Deformation -1 (dot)', 'Color', 'w');
    xlabel('Time (s)'); ylabel('Deform. x-1 (mm)');
    lgd14a = legend('Location', 'northeast');
    set(lgd14a, 'TextColor', 'w', 'Color', [0.2 0.2 0.25], 'EdgeColor', 'w');
    grid on; dk(ax14a);

    % Row 3B: Force full width
    ax14b = subplot(3, 4, 11:12);
    scatter(time_s, force_g, 6, 'b', 'o', ...
        'MarkerFaceAlpha', 0.45, 'MarkerEdgeAlpha', 0.65, ...
        'DisplayName', 'Force');
    title('T14 Row 2 — Force (dot)', 'Color', 'w');
    xlabel('Time (s)'); ylabel('Force (g)');
    lgd14b = legend('Location', 'northeast');
    set(lgd14b, 'TextColor', 'w', 'Color', [0.2 0.2 0.25], 'EdgeColor', 'w');
    grid on; dk(ax14b);

    % Note: Row 3C (Merged + Avg Cycles) requires computed fit curves.
    % These are shown in the exported Table14 PNG.
    % Open PNG preview button:
    fprintf('\n✅ Visualization loaded successfully for: %s\n', sampleName);
    fprintf('📁 Output folder: %s\n\n', outDir);
    fprintf('E-Value Summary:\n');
    fprintf('  Cycle 1: E1=%.2f  E2=%.2f  E3=%.2f kPa\n', E_c1(1), E_c1(2), E_c1(3));
    fprintf('  Cycle 2: E1=%.2f  E2=%.2f  E3=%.2f kPa\n', E_c2(1), E_c2(2), E_c2(3));
    fprintf('  Cycle 3: E1=%.2f  E2=%.2f  E3=%.2f kPa\n', E_c3(1), E_c3(2), E_c3(3));
    fprintf('  Average: E1=%.2f  E2=%.2f  E3=%.2f kPa\n', E_avg(1), E_avg(2), E_avg(3));

    % --- 6. OFFER PNG PREVIEWS ---
    png_light = fullfile(outDir, [sampleName, '_Table14_Composite_Summary_Light.png']);
    png_dark  = fullfile(outDir, [sampleName, '_Table14_Composite_Summary_Dark.png']);

    if exist(png_light, 'file') || exist(png_dark, 'file')
        choice = questdlg('Open Table 14 preview image?', 'PNG Preview', ...
            'Light Mode', 'Dark Mode', 'Cancel', 'Light Mode');
        if strcmp(choice, 'Light Mode') && exist(png_light, 'file')
            figure('Name', 'Table 14 — Light Mode', 'NumberTitle', 'off');
            imshow(imread(png_light));
            title(sprintf('Table 14 Light: %s', sampleName), 'Interpreter', 'none');
        elseif strcmp(choice, 'Dark Mode') && exist(png_dark, 'file')
            figure('Name', 'Table 14 — Dark Mode', 'NumberTitle', 'off');
            imshow(imread(png_dark));
            title(sprintf('Table 14 Dark: %s', sampleName), 'Interpreter', 'none');
        end
    end
end
