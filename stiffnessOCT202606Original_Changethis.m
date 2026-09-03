function stiffnessOCT202606Original_Changethis()
    % =========================================================================
    % OCT Original Multi-Cycle Stiffness Analyzer (Auto-Force Edition)
    % Designed for uncalibrated / missing pump CSV data.
    % Features:
    %   - Resizable Multi-Cycle UI Grid (Supports 1 to 5 cycles/waves)
    %   - Batch scanning: detects any *_analysis/timeseries.csv without requiring .csv pump file
    %   - Single-Curve Interactive Annotation on OCT Deformation (2N + 1 points)
    %     with Vertical Snapping & Backspace Undo
    %   - Automatic multi-cycle force generation (0 -> 1g loading, parabolic recovery 1 -> 0g)
    %   - Complete 300 DPI Export Engine (Light & Dark Themes):
    %       * Full_Cycle/ (Tables 1 to 14, Donut, Composite, Caliper, FullCycle_Summary.xlsx)
    %       * Isolated Cycle_1/ to Cycle_N/ subfolders
    %       * Original Overview Graphics (Subplot 1, 2, 3 Dual-Axis, 3-in-1 Composite)
    % =========================================================================

    % Configuration Defaults
    NUM_CYCLES  = 3;   % Default: 3 waves (selectable from 1 to 5)
    FILTER_MODE = 0;   % Default: 0 = Raw, 1 = Savitzky-Golay Filter
    EXPORT_DPI  = 300; % Default: 300 DPI (High Resolution)
    FONT_NAME   = 'Arial';

    % 1. MAIN UI WINDOW CREATION (Resizable)
    fig = uifigure('Name', sprintf('OCT Original Multi-Cycle Stiffness Analyzer (Auto-Force) - %d Waves', NUM_CYCLES), ...
        'Position', [50, 50, 1360, 1060], 'AutoResizeChildren', 'off');
    
    parentDir = '';
    validSamples = {}; 

    % 2. CONTROL INTERFACE COMPONENTS
    lblHeader = uilabel(fig, 'Text', sprintf('1. Select Parent Folder (Contains *_analysis folders)  |  Waves: %d', NUM_CYCLES), ...
        'FontWeight', 'bold', 'FontSize', 14);
    
    btnBrowse = uibutton(fig, 'Text', 'Browse Folder', 'ButtonPushedFcn', @(btn,event) selectFolder());
    lblFolder = uilabel(fig, 'Text', 'No folder selected');
    
    lblWaves = uilabel(fig, 'Text', 'Wave Count:', 'FontWeight', 'bold');
    ddlWaves = uidropdown(fig, 'Items', {'1 Wave', '2 Waves', '3 Waves', '4 Waves', '5 Waves'}, ...
        'ItemsData', [1, 2, 3, 4, 5], 'Value', NUM_CYCLES, ...
        'ValueChangedFcn', @(dd, event) changeWaves(dd.Value));
        
    lblFilter = uilabel(fig, 'Text', 'Filter Mode:', 'FontWeight', 'bold');
    ddlFilter = uidropdown(fig, 'Items', {'1. Raw Signal (Unfiltered)', '2. Savitzky-Golay Filter'}, ...
        'ItemsData', [0, 1], 'Value', FILTER_MODE, ...
        'ValueChangedFcn', @(dd, event) changeFilter(dd.Value));
        
    lblDPI = uilabel(fig, 'Text', 'Export DPI:', 'FontWeight', 'bold');
    ddlDPI = uidropdown(fig, 'Items', {'300 DPI (High Res)', '600 DPI (Ultra High Res)', '150 DPI (Standard)'}, ...
        'ItemsData', [300, 600, 150], 'Value', EXPORT_DPI, ...
        'ValueChangedFcn', @(dd, event) changeDPI(dd.Value));
    
    lblSamplesHeader = uilabel(fig, 'Text', '2. Detected Sample List (No pump CSV required):', 'FontWeight', 'bold');
    lstSamples = uilistbox(fig);
    
    btnProcess = uibutton(fig, 'Text', 'PROCESS ALL SAMPLES', ...
        'FontWeight', 'bold', 'FontSize', 16, 'BackgroundColor', [0.15 0.55 0.25], 'FontColor', 'w', ...
        'ButtonPushedFcn', @(btn,event) processSamples());
    
    lblStatus = uilabel(fig, 'Text', 'Status: Select folder to begin...', 'FontColor', 'b', 'FontSize', 14);
    
    % 3. STANDARDIZED UI GRID — Rows 1 and 2 are fixed (6 panels)
    ax_def_normal = uiaxes(fig); title(ax_def_normal, '1. Deformation Normal (Red)');
    ax_def_inv    = uiaxes(fig); title(ax_def_inv, '2. Deformation -1 (Red)');
    ax_force_time = uiaxes(fig); title(ax_force_time, '3. Auto-Modeled Force (Blue)');
    
    ax_merged     = uiaxes(fig); title(ax_merged, '4. Deformation -1 x Auto-Force Merged (Red/Blue)');
    ax_hyst_final = uiaxes(fig); title(ax_hyst_final, '5. Hysteresis Evaluation (Multi-Cycle)');
    ax_donut      = uiaxes(fig); title(ax_donut, '6. Donut Table Graph Panel');
    
    % Row 3: Dynamic cycle panels
    ax_cycle = {};
    createCycleAxes(NUM_CYCLES);

    fig.SizeChangedFcn = @(~,~) onWindowResize();
    onWindowResize();

    function createCycleAxes(n)
        if ~isempty(ax_cycle)
            for k = 1:length(ax_cycle)
                if isvalid(ax_cycle{k}), delete(ax_cycle{k}); end
            end
        end
        ax_cycle = cell(1, n);
        for c = 1:n
            ax_cycle{c} = uiaxes(fig);
            title(ax_cycle{c}, sprintf('%d. Cycle %d Strain-Stiffening', 6+c, c));
        end
    end

    function changeWaves(val)
        NUM_CYCLES = val;
        lblHeader.Text = sprintf('1. Select Parent Folder (Contains *_analysis folders)  |  Waves: %d', NUM_CYCLES);
        fig.Name = sprintf('OCT Original Multi-Cycle Stiffness Analyzer (Auto-Force) - %d Waves', NUM_CYCLES);
        createCycleAxes(NUM_CYCLES);
        onWindowResize();
    end

    function changeFilter(val)
        FILTER_MODE = val;
    end

    function changeDPI(val)
        EXPORT_DPI = val;
    end

    function onWindowResize()
        W = max(800, fig.Position(3));
        H = max(600, fig.Position(4));

        lblHeader.Position = [20, H - 35, W - 40, 25];
        btnBrowse.Position = [20, H - 70, 120, 30];
        lblFolder.Position = [150, H - 70, max(100, W - 920), 30];
        
        lblWaves.Position  = [W - 760, H - 70, 85, 30];
        ddlWaves.Position  = [W - 675, H - 70, 75, 30];
        
        lblFilter.Position = [W - 590, H - 70, 75, 30];
        ddlFilter.Position = [W - 510, H - 70, 210, 30];
        
        lblDPI.Position    = [W - 290, H - 70, 90, 30];
        ddlDPI.Position    = [W - 195, H - 70, 175, 30];

        lblSamplesHeader.Position = [20, H - 100, 320, 20];
        
        lstW = min(420, floor(W * 0.32));
        lstSamples.Position = [20, H - 200, lstW, 95];
        btnProcess.Position = [lstW + 30, H - 200, min(250, W - lstW - 60), 95];
        lblStatus.Position  = [20, H - 230, W - 40, 25];

        grid_top = H - 240;
        grid_bottom = 15;
        avail_h = max(240, grid_top - grid_bottom);
        row_h = floor((avail_h - 30) / 3);
        col_w3 = floor((W - 60) / 3);

        % Row 1
        y1 = grid_bottom + 2*row_h + 20;
        ax_def_normal.Position = [20, y1, col_w3, row_h];
        ax_def_inv.Position    = [20 + col_w3 + 10, y1, col_w3, row_h];
        ax_force_time.Position = [20 + 2*col_w3 + 20, y1, col_w3, row_h];

        % Row 2
        y2 = grid_bottom + row_h + 10;
        ax_merged.Position     = [20, y2, col_w3, row_h];
        ax_hyst_final.Position = [20 + col_w3 + 10, y2, col_w3, row_h];
        ax_donut.Position      = [20 + 2*col_w3 + 20, y2, col_w3, row_h];

        % Row 3
        y3 = grid_bottom;
        N_c = length(ax_cycle);
        col_wn = floor((W - 40 - (N_c - 1)*10) / N_c);
        for c = 1:N_c
            if isvalid(ax_cycle{c})
                ax_cycle{c}.Position = [20 + (c-1)*(col_wn + 10), y3, col_wn, row_h];
            end
        end
    end
    
    %% Function: Select Folder (No pump CSV required!)
    function selectFolder()
        selDir = uigetdir('', 'Select Parent Folder containing OCT sample folders');
        if selDir == 0, return; end
        parentDir = selDir;
        lblFolder.Text = parentDir;
        
        % Check for direct timeseries.csv in selected folder
        direct_csv = fullfile(parentDir, 'timeseries.csv');
        if exist(direct_csv, 'file')
            [~, sampleName] = fileparts(parentDir);
            sampleName = regexprep(sampleName, '_analysis$', '');
            validSamples = {{sampleName, direct_csv}};
            lstSamples.Items = {sprintf('[Ready] Sample: %s', sampleName)};
            lblStatus.Text = 'Status: 1 direct sample detected.';
            return;
        end
        
        % Search for *_analysis folders
        subDirs = dir(fullfile(parentDir, '*_analysis'));
        subDirs = subDirs([subDirs.isdir]);
        tempList = {};
        tempDisplay = {};
        
        for i = 1:length(subDirs)
            folderName = subDirs(i).name;
            baseName = regexprep(folderName, '_analysis$', '');
            octFile = fullfile(parentDir, folderName, 'timeseries.csv');
            
            if exist(octFile, 'file')
                tempList{end+1} = {baseName, octFile}; %#ok<AGROW>
                tempDisplay{end+1} = sprintf('[Ready] Sample: %s', baseName); %#ok<AGROW>
            end
        end
        
        % If none found, search recursively for any timeseries.csv
        if isempty(tempList)
            all_csv = dir(fullfile(parentDir, '**', 'timeseries.csv'));
            for k = 1:length(all_csv)
                [~, fldName] = fileparts(all_csv(k).folder);
                baseName = regexprep(fldName, '_analysis$', '');
                tempList{end+1} = {baseName, fullfile(all_csv(k).folder, all_csv(k).name)}; %#ok<AGROW>
                tempDisplay{end+1} = sprintf('[Ready] Sample: %s', baseName); %#ok<AGROW>
            end
        end
        
        validSamples = tempList;
        lstSamples.Items = tempDisplay;
        lblStatus.Text = sprintf('Status: %d sample(s) ready for processing.', length(validSamples));
    end
    
    %% Function: Process All Samples
    function processSamples()
        if isempty(validSamples)
            uialert(fig, 'No valid samples found in the selected folder!', 'Warning');
            return;
        end
        
        outputMainDir = fullfile(parentDir, 'Hasil_Analisis_Original');
        if ~exist(outputMainDir, 'dir'), mkdir(outputMainDir); end
        
        for i = 1:length(validSamples)
            sampleName = validSamples{i}{1};
            octFile    = validSamples{i}{2};
            
            lblStatus.Text = sprintf('Status: Annotating %s (%d/%d)...', sampleName, i, length(validSamples));
            drawnow; 
            
            outputSubDir = fullfile(outputMainDir, sampleName);
            if ~exist(outputSubDir, 'dir'), mkdir(outputSubDir); end
            
            try
                runMultiCycleAnalysis(sampleName, octFile, outputSubDir);
            catch ME
                warning('Failed to process %s: %s', sampleName, ME.message);
                errordlg(sprintf('Error on %s: %s', sampleName, ME.message), 'Analysis Error');
            end
        end
        lblStatus.Text = 'Status: ALL SAMPLES PROCESSED SUCCESSFULLY.';
        uialert(fig, 'Multi-Cycle Analysis & 300 DPI Export Complete!', 'Success');
    end
    
    %% Function: Core Multi-Cycle Analysis & Auto-Force Generation
    function runMultiCycleAnalysis(sampleName, octFile, outDir)
        N = NUM_CYCLES;
        n_pts = 2*N + 1; % Start 1, Peak 1, End 1, Peak 2, End 2, ...
        cycle_colors = {'r', 'g', 'b', 'm', 'c'};

        % ====================================================================
        % 1. DATA INGESTION
        % ====================================================================
        data_oct = readtable(octFile); 
        if size(data_oct, 2) < 5
            error('timeseries.csv must have at least 5 columns.');
        end
        data_E_raw = data_oct{:, 5}; 
        
        pixel_to_um = 1000 / 200; % 5 um/px
        fps_oct = 25;
        time_oct_sec = (0:length(data_E_raw)-1)' / fps_oct;
        
        e_um = data_E_raw * pixel_to_um;
        displacement_mm_temp = abs(e_um - e_um(1)) / 1000;
        
        % ====================================================================
        % 2. INTERACTIVE COORDINATE PINPOINTING (OCT CURVE ONLY)
        % ====================================================================
        hFig = figure('Name', sprintf('Cycle Partition Annotation (%d Waves): %s', N, sampleName), ...
            'Position', [120, 120, 1080, 520], 'Color', 'w');
        
        ax_annot = axes('Parent', hFig);
        plot(ax_annot, time_oct_sec, displacement_mm_temp, 'b-', 'LineWidth', 1.8); grid(ax_annot, 'on');
        ylabel(ax_annot, 'Deformation (mm)', 'FontWeight', 'bold');
        xlabel(ax_annot, 'Time (seconds)', 'FontWeight', 'bold');
        hold(ax_annot, 'on');
        
        x_oct = zeros(n_pts, 1);
        h_oct_plots  = cell(1, n_pts);
        h_oct_texts  = cell(1, n_pts);
        h_oct_guides = cell(1, n_pts);
        
        labels_oct = cell(1, n_pts);
        labels_oct{1} = 'Start Pull 1';
        for c = 1:N
            labels_oct{2*c}   = sprintf('Peak (Max Indentation) %d', c);
            labels_oct{2*c+1} = sprintf('End Recovery %d', c);
        end
        
        k = 1;
        while k <= n_pts
            if k > 1
                title(ax_annot, {sprintf('CLICK POINT (%d/%d): %s', k, n_pts, labels_oct{k}), ...
                                 '[Press Backspace or Delete to Undo previous click]'}, ...
                                 'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
            else
                title(ax_annot, sprintf('CLICK POINT (%d/%d): %s', k, n_pts, labels_oct{k}), ...
                    'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
            end
            
            [x_val, y_val, btn] = ginput(1);
            
            % Backspace (8), Delete (127), 'b'/'B' (98/66) Undo
            if isempty(btn) || btn == 8 || btn == 127 || btn == 98 || btn == 66
                if k > 1
                    k_prev = k - 1;
                    if ~isempty(h_oct_plots{k_prev}) && isvalid(h_oct_plots{k_prev}), delete(h_oct_plots{k_prev}); end
                    if ~isempty(h_oct_texts{k_prev}) && isvalid(h_oct_texts{k_prev}), delete(h_oct_texts{k_prev}); end
                    if ~isempty(h_oct_guides{k_prev}) && isvalid(h_oct_guides{k_prev}), delete(h_oct_guides{k_prev}); end
                    h_oct_plots{k_prev} = []; h_oct_texts{k_prev} = []; h_oct_guides{k_prev} = [];
                    x_oct(k_prev) = 0;
                    k = k_prev;
                end
                continue;
            end
            
            % Vertical Snapping onto curve
            idx_curr = min([find(time_oct_sec >= x_val, 1, 'first'), length(time_oct_sec)]);
            if isempty(idx_curr), idx_curr = 1; end
            x_snap = time_oct_sec(idx_curr);
            y_snap = displacement_mm_temp(idx_curr);
            
            x_oct(k) = x_snap;
            h_oct_guides{k} = plot(ax_annot, [x_val, x_snap], [y_val, y_snap], 'm--', 'LineWidth', 1.2);
            h_oct_plots{k}  = plot(ax_annot, x_snap, y_snap, 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);
            h_oct_texts{k}  = text(ax_annot, x_snap, y_snap, sprintf(' %d: %s', k, labels_oct{k}), ...
                'Color', 'k', 'FontWeight', 'bold', 'FontSize', 9);
            drawnow;
            k = k + 1;
        end
        
        get_idx_oct = @(x) min([find(time_oct_sec >= x, 1, 'first'), length(time_oct_sec)]);
        idx_titik = arrayfun(get_idx_oct, sort(x_oct));
        close(hFig);
        
        % ====================================================================
        % 3. POST-LABELING ORIENTATION & FILTERING
        % ====================================================================
        displacement_mm_normal = abs(e_um - e_um(idx_titik(1))) / 1000;
        e_um_inv = -e_um;
        displacement_mm_inv = (e_um_inv - e_um_inv(idx_titik(1))) / 1000;
        
        if FILTER_MODE >= 1
            displacement_mm_normal = smoothdata(displacement_mm_normal, 'sgolay', 25);
            displacement_mm_inv    = smoothdata(displacement_mm_inv, 'sgolay', 25);
        end

        % ====================================================================
        % 4. AUTOMATIC FORCE PROFILE SYNTHESIS (0-1g Loading, Parabolic 1-0g Recovery)
        % ====================================================================
        force_interp_oct = zeros(size(time_oct_sec));
        
        for c = 1:N
            i_start = idx_titik(2*c - 1);
            i_peak  = idx_titik(2*c);
            i_end   = idx_titik(2*c + 1);
            
            n_load = max(2, i_peak - i_start + 1);
            n_rec  = max(2, i_end - i_peak + 1);
            
            % Loading: linear ramp 0 -> 1 g
            f_load = linspace(0, 1, n_load)';
            
            % Recovery: parabolic decay 1 -> 0 g
            t_rel  = linspace(0, 1, n_rec)';
            f_rec  = (1 - t_rel).^2;
            
            force_interp_oct(i_start:i_peak) = f_load;
            force_interp_oct(i_peak:i_end)   = f_rec;
        end
        
        if FILTER_MODE >= 1
            force_interp_oct = smoothdata(force_interp_oct, 'sgolay', 31);
        end
        force_interp_oct(force_interp_oct < 0) = 0;

        % ====================================================================
        % 5. MULTI-CYCLE STIFFNESS & ELASTIC MECHANICS EVALUATION
        % ====================================================================
        v_poisson = 0.45; a_radius = 2.5; k_factor = 3.085; g_gravity = 9.81;
        part1 = (1 - v_poisson^2) / (2 * a_radius * k_factor);
        t0_mm = abs(e_um(idx_titik(1))) / 1000;
        
        w_target_A = (1.67/100) * t0_mm;
        w_target_B = (3.34/100) * t0_mm;
        w_target_C = (5.00/100) * t0_mm;
        
        disp_l = cell(1,N); force_l = cell(1,N);
        disp_r = cell(1,N); force_r = cell(1,N);
        disp_s = cell(1,N); force_s = cell(1,N);
        a_L = cell(1,N);  b_L = cell(1,N);
        a_R = cell(1,N);  b_R = cell(1,N);
        x_plot_c = cell(1,N); fit_L_c = cell(1,N); fit_R_c = cell(1,N);
        x_max_c  = cell(1,N);
        Pg_A = cell(1,N); Pg_B = cell(1,N); Pg_C = cell(1,N);
        E_A_kPa = cell(1,N); E_B_kPa = cell(1,N); E_C_kPa = cell(1,N);
        target_A = cell(1,N); target_B = cell(1,N); target_C = cell(1,N);
        text_str_c = cell(1,N);
        disp_l_sh = cell(1,N); disp_r_sh = cell(1,N);
        
        for c = 1:N
            i_start = idx_titik(2*c - 1);
            i_peak  = idx_titik(2*c);
            i_end   = idx_titik(2*c + 1);
            
            disp_l{c}  = displacement_mm_normal(i_start:i_peak);
            force_l{c} = force_interp_oct(i_start:i_peak);
            disp_r{c}  = displacement_mm_normal(i_peak:i_end);
            force_r{c} = force_interp_oct(i_peak:i_end);
            disp_s{c}  = displacement_mm_normal(i_start:i_end);
            force_s{c} = force_interp_oct(i_start:i_end);
            
            target_A{c} = min(disp_l{c}) + w_target_A;
            target_B{c} = min(disp_l{c}) + w_target_B;
            target_C{c} = min(disp_l{c}) + w_target_C;
            
            [a_L{c}, b_L{c}, a_R{c}, b_R{c}, x_plot_c{c}, fit_L_c{c}, fit_R_c{c}, x_max_c{c}] = ...
                fit_power_law_extended(disp_l{c}, force_l{c}, disp_r{c}, force_r{c}, w_target_C);
            
            Pg_A{c} = a_L{c} * (w_target_A ^ b_L{c});
            Pg_B{c} = a_L{c} * (w_target_B ^ b_L{c});
            Pg_C{c} = a_L{c} * (w_target_C ^ b_L{c});
            
            sl_A = a_L{c} * b_L{c} * (w_target_A ^ (b_L{c}-1));
            sl_B = a_L{c} * b_L{c} * (w_target_B ^ (b_L{c}-1));
            sl_C = a_L{c} * b_L{c} * (w_target_C ^ (b_L{c}-1));
            E_A_kPa{c} = part1 * ((max(0, sl_A) / 1000) * g_gravity) * 1000;
            E_B_kPa{c} = part1 * ((max(0, sl_B) / 1000) * g_gravity) * 1000;
            E_C_kPa{c} = part1 * ((max(0, sl_C) / 1000) * g_gravity) * 1000;
            
            text_str_c{c} = {sprintf('E1 (1.67%%) : %.2f kPa', E_A_kPa{c}), ...
                             sprintf('E2 (3.34%%) : %.2f kPa', E_B_kPa{c}), ...
                             sprintf('E3 (5.00%%) : %.2f kPa', E_C_kPa{c})};
            
            disp_l_sh{c} = disp_l{c} - min(disp_l{c});
            disp_r_sh{c} = disp_r{c} - min(disp_l{c});
        end
        
        % Multi-Cycle Averages
        a_L_avg = mean(cellfun(@(x) x, a_L)); b_L_avg = mean(cellfun(@(x) x, b_L));
        a_R_avg = mean(cellfun(@(x) x, a_R)); b_R_avg = mean(cellfun(@(x) x, b_R));
        x_max_avg = max(mean(cellfun(@(x) x, x_max_c)), w_target_C * 1.08);
        x_plot_avg = linspace(0, x_max_avg, 150)';
        fit_L_avg = a_L_avg * (x_plot_avg .^ b_L_avg);
        fit_R_avg = a_R_avg * (x_plot_avg .^ b_R_avg);
        
        Pg_avg_A = a_L_avg * (w_target_A ^ b_L_avg);
        Pg_avg_B = a_L_avg * (w_target_B ^ b_L_avg);
        Pg_avg_C = a_L_avg * (w_target_C ^ b_L_avg);
        E_avg_A_kPa = mean(cellfun(@(x) x, E_A_kPa));
        E_avg_B_kPa = mean(cellfun(@(x) x, E_B_kPa));
        E_avg_C_kPa = mean(cellfun(@(x) x, E_C_kPa));
        text_str_avg = {sprintf('E1 (1.67%%) : %.2f kPa', E_avg_A_kPa), ...
                        sprintf('E2 (3.34%%) : %.2f kPa', E_avg_B_kPa), ...
                        sprintf('E3 (5.00%%) : %.2f kPa', E_avg_C_kPa)};
        
        E_kPa_B = cellfun(@(x) x, E_B_kPa);
        P_g_B   = cellfun(@(x) x, Pg_B);
        tgt_B   = cellfun(@(x) x, target_B);
        
        total_points = idx_titik(n_pts) - idx_titik(1) + 1;
        theta = linspace(0, 2*N*pi, total_points)';
        R_disp = 100 + (displacement_mm_inv(idx_titik(1):idx_titik(n_pts)) * 100);
        [X_disp, Y_disp] = pol2cart(theta, R_disp);

        % ====================================================================
        % 6. UPDATE LIVE GUI PANELS
        % ====================================================================
        cla(ax_def_normal); plot(ax_def_normal, time_oct_sec, displacement_mm_normal, 'r-', 'LineWidth', 1.5);
        ylabel(ax_def_normal, 'Deformation Normal (mm)'); grid(ax_def_normal, 'on');
        
        cla(ax_def_inv); plot(ax_def_inv, time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
        ylabel(ax_def_inv, 'Deformation x -1 (mm)'); grid(ax_def_inv, 'on');
        
        cla(ax_force_time); plot(ax_force_time, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5);
        ylabel(ax_force_time, 'Auto-Force (g)'); grid(ax_force_time, 'on');
        
        cla(ax_merged);
        yyaxis(ax_merged, 'left'); plot(ax_merged, time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
        ylabel(ax_merged, 'Deformation -1 (mm)'); ax_merged.YColor = 'r';
        yyaxis(ax_merged, 'right'); plot(ax_merged, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5);
        ylabel(ax_merged, 'Auto-Force (g)'); ax_merged.YColor = 'b';
        xlabel(ax_merged, 'Time (s)'); grid(ax_merged, 'on');
        
        cla(ax_hyst_final); hold(ax_hyst_final, 'on');
        plot(ax_hyst_final, displacement_mm_normal(idx_titik(1):idx_titik(n_pts)), ...
             force_interp_oct(idx_titik(1):idx_titik(n_pts)), 'k-', 'LineWidth', 2.0, 'DisplayName', 'Total Profile');
        for c = 1:N
            plot(ax_hyst_final, disp_s{c}, force_s{c}, '-', 'Color', cycle_colors{c}, 'LineWidth', 1.2, 'DisplayName', sprintf('Cycle %d', c));
        end
        for c = 1:N
            plot(ax_hyst_final, tgt_B(c), P_g_B(c), 'o', 'MarkerFaceColor', cycle_colors{c}, 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
            text(ax_hyst_final, tgt_B(c), P_g_B(c), sprintf(' E%d:%.2f kPa', c, E_kPa_B(c)), 'FontWeight', 'bold', 'FontSize', 8);
        end
        xlabel(ax_hyst_final, 'Deformation (mm)'); ylabel(ax_hyst_final, 'Force (g)'); grid(ax_hyst_final, 'on');
        legend(ax_hyst_final, 'Location', 'northwest', 'FontSize', 6); hold(ax_hyst_final, 'off');
        
        cla(ax_donut); plot(ax_donut, X_disp, Y_disp, 'b:', 'LineWidth', 1); hold(ax_donut, 'on');
        n_s1 = length(disp_s{1});
        plot(ax_donut, X_disp(1:n_s1), Y_disp(1:n_s1), 'r-', 'LineWidth', 2);
        axis(ax_donut, 'equal'); grid(ax_donut, 'on'); hold(ax_donut, 'off');
        
        for c = 1:N
            cla(ax_cycle{c}); hold(ax_cycle{c}, 'on');
            scatter(ax_cycle{c}, disp_l_sh{c}, force_l{c}, 10, [0.7 0.7 1], 'filled', 'DisplayName', 'Loading');
            scatter(ax_cycle{c}, disp_r_sh{c}, force_r{c}, 10, [1 0.7 0.7], 'filled', 'DisplayName', 'Recovery');
            plot(ax_cycle{c}, x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Fit Load');
            plot(ax_cycle{c}, x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.0, 'DisplayName', 'Fit Rec');
            plot(ax_cycle{c}, w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
            plot(ax_cycle{c}, w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
            plot(ax_cycle{c}, w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6);
            text(ax_cycle{c}, 0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'bottom', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontWeight', 'bold', 'FontSize', 7);
            xlabel(ax_cycle{c}, 'Disp (mm)'); ylabel(ax_cycle{c}, 'Force (g)'); grid(ax_cycle{c}, 'on'); hold(ax_cycle{c}, 'off');
        end
        drawnow;

        % ====================================================================
        % 7. 300 DPI EXPORT ENGINE: FULL-CYCLE & PER-CYCLE SUBFOLDERS
        % ====================================================================
        outDir_full = fullfile(outDir, 'Full_Cycle');
        if ~exist(outDir_full, 'dir'), mkdir(outDir_full); end

        f_export = figure('Visible', 'off', 'Position', [100, 100, 850, 620]);
        modes = {'Light', 'Dark'};

        for m_idx = 1:2
            mode_str = modes{m_idx};
            if m_idx == 2
                bg = 'k'; fg = 'w'; grid_clr = [0.35 0.35 0.35];
            else
                bg = 'w'; fg = 'k'; grid_clr = [0.85 0.85 0.85];
            end
            fmt_ax  = @(f, ax) [set(f, 'Color', bg, 'InvertHardcopy', 'off'), ...
                                set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr, ...
                                    'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2)];
            fmt_lgd = @(lgd) set(lgd, 'FontName', FONT_NAME, 'FontSize', 9, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg);

            % Table 1: Deformation Normal
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(time_oct_sec, displacement_mm_normal, 'r-', 'LineWidth', 2.0);
            title(sprintf('Table 1: Deformation Normal (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            xlabel('Time (s)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            ylabel('Deformation (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            grid on; box on; hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table1_Deformation_%s.png', sampleName, mode_str)), EXPORT_DPI);

            % Table 2: Deformation -1
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 2.0);
            title(sprintf('Table 2: Deformation -1 (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            xlabel('Time (s)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            ylabel('Deformation x -1 (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            grid on; box on; hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table2_Deformation_Inv_%s.png', sampleName, mode_str)), EXPORT_DPI);

            % Table 3: Force Telemetry (Auto-Generated)
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 2.0);
            title(sprintf('Table 3: Auto-Modeled Force (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            xlabel('Time (s)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            ylabel('Force (g)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            grid on; box on; hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table3_Force_Vector_%s.png', sampleName, mode_str)), EXPORT_DPI);

            % Table 4: Deformation x Force Merged Dual Axis
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            yyaxis left;  plot(time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 2.0, 'DisplayName', 'Deformation -1');
            ylabel('Deformation -1 (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            yyaxis right; plot(time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Auto-Force');
            ylabel('Force (g)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            ax4 = gca;
            ax4.YAxis(1).Color = 'r'; ax4.YAxis(2).Color = 'b';
            xlabel('Time (s)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            title(sprintf('Table 4: Deformation x Auto-Force Merged (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            grid on; box on; fmt_lgd(legend('Location', 'northwest')); hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table4_Deformation_Force_Merged_%s.png', sampleName, mode_str)), EXPORT_DPI);

            % Table 5: Hysteresis Evaluation (All cycles)
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(displacement_mm_normal(idx_titik(1):idx_titik(n_pts)), ...
                 force_interp_oct(idx_titik(1):idx_titik(n_pts)), '-', 'Color', fg, 'LineWidth', 2.2, 'DisplayName', 'Total Profile');
            for c = 1:N
                plot(disp_s{c}, force_s{c}, '-', 'Color', cycle_colors{c}, 'LineWidth', 1.5, 'DisplayName', sprintf('Cycle %d', c));
            end
            for c = 1:N
                plot(tgt_B(c), P_g_B(c), 'o', 'MarkerFaceColor', cycle_colors{c}, 'MarkerEdgeColor', fg, 'MarkerSize', 7);
                text(tgt_B(c), P_g_B(c), sprintf(' E%d:%.2f kPa', c, E_kPa_B(c)), 'Color', fg, 'FontWeight', 'bold', 'FontSize', 9);
            end
            xlabel('Deformation Normal (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            ylabel('Force (g)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            title(sprintf('Table 5: Multi-Cycle Hysteresis Evaluation (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            grid on; box on; fmt_lgd(legend('Location', 'northwest')); hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table5_Hysteresis_Evaluation_%s.png', sampleName, mode_str)), EXPORT_DPI);

            % Table 6: Donut Spatial Layout
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(X_disp, Y_disp, 'b:', 'LineWidth', 1.2);
            plot(X_disp(1:n_s1), Y_disp(1:n_s1), 'r-', 'LineWidth', 2.5);
            axis equal; grid on; box on;
            title(sprintf('Table 6: Donut Spatial Layout (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table6_Donut_Table_%s.png', sampleName, mode_str)), EXPORT_DPI);

            % Tables 7..6+N: Raw Stiffening per cycle
            for c = 1:N
                tbl_raw = 6 + c;
                clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
                scatter(disp_l_sh{c}, force_l{c}, 24, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading');
                scatter(disp_r_sh{c}, force_r{c}, 24, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery');
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 9);
                xlabel('Displacement (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
                ylabel('Force (g)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
                title(sprintf('Table %d: Cycle %d Force vs Displacement (%s)', tbl_raw, c, mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
                grid on; box on; fmt_lgd(legend('Location', 'northwest')); hold off; fmt_ax(f_export, gca);
                saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Cycle%d_Stiffening_%s.png', sampleName, tbl_raw, c, mode_str)), EXPORT_DPI);
            end

            % Tables 7+N..6+2N: Clean Curves per cycle
            for c = 1:N
                tbl_clean = 6 + N + c;
                clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 9);
                xlabel('Displacement (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
                ylabel('Force (g)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
                title(sprintf('Table %d: Cycle %d Clean Curves (%s)', tbl_clean, c, mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
                grid on; box on; fmt_lgd(legend('Location', 'northwest')); hold off; fmt_ax(f_export, gca);
                saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Cycle%d_Clean_%s.png', sampleName, tbl_clean, c, mode_str)), EXPORT_DPI);
            end

            % Table 7+2N: Average
            tbl_avg = 7 + 2*N;
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(x_plot_avg, fit_L_avg, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading (Avg)');
            plot(x_plot_avg, fit_R_avg, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery (Avg)');
            plot(w_target_A, Pg_avg_A, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1');
            plot(w_target_B, Pg_avg_B, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2');
            plot(w_target_C, Pg_avg_C, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3');
            text(0.95, 0.05, text_str_avg, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
                'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 9);
            xlabel('Displacement (mm)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            ylabel('Force (g)', 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold');
            title(sprintf('Table %d: Average of %d Cycles (%s)', tbl_avg, N, mode_str), 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold', 'Color', fg);
            grid on; box on; fmt_lgd(legend('Location', 'northwest')); hold off; fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Cycles_Average_Clean_%s.png', sampleName, tbl_avg, mode_str)), EXPORT_DPI);

            % Table 7+2N+1: Composite Summary
            tbl_comp = 7 + 2*N + 1;
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export);
            set(f_export, 'Position', [100, 100, 1150, 920], 'Color', bg, 'InvertHardcopy', 'off');

            ax14a = subplot(3, 2, [1, 2]);
            scatter(time_oct_sec, displacement_mm_inv, 10, 'r', 'o', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 0.8, 'DisplayName', 'Deformation -1');
            xlabel('Time (s)'); ylabel('Deformation x -1 (mm)');
            title(sprintf('Row 1 — Deformation -1 (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold', 'Color', fg);
            grid on; box on; fmt_lgd(legend('Location', 'northeast')); fmt_ax(f_export, ax14a);

            ax14b = subplot(3, 2, [3, 4]);
            scatter(time_oct_sec, force_interp_oct, 10, 'b', 'o', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 0.8, 'DisplayName', 'Auto-Force');
            xlabel('Time (s)'); ylabel('Force (g)');
            title(sprintf('Row 2 — Auto-Force (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold', 'Color', fg);
            grid on; box on; fmt_lgd(legend('Location', 'northeast')); fmt_ax(f_export, ax14b);

            ax14c = subplot(3, 2, 5); hold(ax14c, 'on');
            yyaxis(ax14c, 'left');  plot(ax14c, time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.8, 'DisplayName', 'Deformation -1');
            ylabel(ax14c, 'Deformation -1 (mm)'); ax14c.YAxis(1).Color = 'r';
            yyaxis(ax14c, 'right'); plot(ax14c, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Auto-Force');
            ylabel(ax14c, 'Force (g)'); ax14c.YAxis(2).Color = 'b';
            xlabel(ax14c, 'Time (s)');
            title(ax14c, sprintf('Row 3A — Merged Plot (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold', 'Color', fg);
            grid(ax14c, 'on'); box(ax14c, 'on'); fmt_lgd(legend(ax14c, 'Location', 'northwest')); hold(ax14c, 'off'); fmt_ax(f_export, ax14c);

            ax14d = subplot(3, 2, 6); hold(ax14d, 'on');
            plot(ax14d, displacement_mm_normal(idx_titik(1):idx_titik(n_pts)), force_interp_oct(idx_titik(1):idx_titik(n_pts)), ...
                '-', 'Color', fg, 'LineWidth', 1.8, 'DisplayName', 'Total Profile');
            for c = 1:N
                plot(ax14d, disp_s{c}, force_s{c}, '-', 'Color', cycle_colors{c}, 'LineWidth', 1.2, 'DisplayName', sprintf('Cycle %d', c));
            end
            for c = 1:N
                plot(ax14d, tgt_B(c), P_g_B(c), 'o', 'MarkerFaceColor', cycle_colors{c}, 'MarkerEdgeColor', fg, 'MarkerSize', 6);
                text(ax14d, tgt_B(c), P_g_B(c), sprintf(' E%d:%.2f', c, E_kPa_B(c)), 'Color', fg, 'FontSize', 8, 'FontWeight', 'bold');
            end
            xlabel(ax14d, 'Deformation (mm)'); ylabel(ax14d, 'Force (g)');
            title(ax14d, sprintf('Row 3B — Hysteresis (%s)', mode_str), 'FontName', FONT_NAME, 'FontSize', 11, 'FontWeight', 'bold', 'Color', fg);
            grid(ax14d, 'on'); box(ax14d, 'on'); fmt_lgd(legend(ax14d, 'Location', 'northwest')); hold(ax14d, 'off'); fmt_ax(f_export, ax14d);

            sgtitle(sprintf('Table %d: Composite Summary (%d Cycles) — %s', tbl_comp, N, mode_str), ...
                'FontName', FONT_NAME, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 14);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Composite_Summary_%s.png', sampleName, tbl_comp, mode_str)), EXPORT_DPI);
            set(f_export, 'Position', [100, 100, 850, 620]);
        end
        close(f_export);

        % FullCycle_Summary.xlsx Workbook
        filename_xls_full = fullfile(outDir_full, sprintf('%s_FullCycle_Summary.xlsx', sampleName));
        t1_sheet = table(time_oct_sec(:), displacement_mm_normal(:), 'VariableNames', {'Time_Seconds', 'Deformation_Normal_mm'});
        t2_sheet = table(time_oct_sec(:), displacement_mm_inv(:), 'VariableNames', {'Time_Seconds', 'Deformation_Inverted_mm'});
        t3_sheet = table(time_oct_sec(:), force_interp_oct(:), 'VariableNames', {'Time_Seconds', 'Force_Vector_g'});
        t4_sheet = table(time_oct_sec(:), displacement_mm_inv(:), force_interp_oct(:), 'VariableNames', {'Time_Seconds', 'Deformation_Inverted_mm', 'Force_Vector_g'});
        cyc_labels = arrayfun(@(c) sprintf('Cycle %d', c), 1:N, 'UniformOutput', false);
        t5_sheet = table(cyc_labels(:), E_kPa_B(:), tgt_B(:), P_g_B(:), ...
            'VariableNames', {'Evaluation_Regime', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
        t6_sheet = table(theta(:), X_disp(:), Y_disp(:), 'VariableNames', {'Theta_Radians', 'Cartesian_X', 'Cartesian_Y'});
        cyc_col = {}; strain_col = {}; E_col = []; tgt_col = []; pg_col = [];
        for c = 1:N
            for s = 1:3
                cyc_col{end+1} = sprintf('Cycle %d', c); %#ok<AGROW>
            end
            strain_col = [strain_col; {'E1_1.67%'; 'E2_3.34%'; 'E3_5.0%'}]; %#ok<AGROW>
            E_col  = [E_col;  E_A_kPa{c}; E_B_kPa{c}; E_C_kPa{c}]; %#ok<AGROW>
            tgt_col = [tgt_col; target_A{c}; target_B{c}; target_C{c}]; %#ok<AGROW>
            pg_col  = [pg_col;  Pg_A{c}; Pg_B{c}; Pg_C{c}]; %#ok<AGROW>
        end
        t7_sheet = table(cyc_col(:), strain_col(:), E_col(:), tgt_col(:), pg_col(:), ...
            'VariableNames', {'Cycle_Regime', 'Strain_Target_Name', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
        
        try
            writetable(t1_sheet, filename_xls_full, 'Sheet', '1_Deformation_Normal');
            writetable(t2_sheet, filename_xls_full, 'Sheet', '2_Deformation_Inverted');
            writetable(t3_sheet, filename_xls_full, 'Sheet', '3_Force_Vector');
            writetable(t4_sheet, filename_xls_full, 'Sheet', '4_Merged_Plot');
            writetable(t5_sheet, filename_xls_full, 'Sheet', '5_Hysteresis_Eval');
            writetable(t6_sheet, filename_xls_full, 'Sheet', '6_Donut_Plot');
            writetable(t7_sheet, filename_xls_full, 'Sheet', '7_Strain_Stiffening');
        catch ME
            warning('Failed to save Excel workbook: %s', ME.message);
        end

        % ====================================================================
        % 8. ISOLATED PER-CYCLE EXPORTS (Folders: Cycle_1 to Cycle_N)
        % ====================================================================
        for c = 1:N
            outDir_c = fullfile(outDir, sprintf('Cycle_%d', c));
            if ~exist(outDir_c, 'dir'), mkdir(outDir_c); end
            
            idx_start_c = idx_titik(2*c - 1);
            idx_end_c   = idx_titik(2*c + 1);
            time_c      = time_oct_sec(idx_start_c:idx_end_c) - time_oct_sec(idx_start_c);
            disp_norm_c = displacement_mm_normal(idx_start_c:idx_end_c);
            disp_inv_c  = displacement_mm_inv(idx_start_c:idx_end_c);
            force_c     = force_interp_oct(idx_start_c:idx_end_c);
            
            f_exp_c = figure('Visible', 'off', 'Position', [100, 100, 850, 620]);
            for m_idx = 1:2
                mode_str = modes{m_idx};
                if m_idx == 2, bg = 'k'; fg = 'w'; grid_clr = [0.35 0.35 0.35];
                else,          bg = 'w'; fg = 'k'; grid_clr = [0.85 0.85 0.85];
                end
                fmt_ax_c = @(f, ax) [set(f, 'Color', bg, 'InvertHardcopy', 'off'), ...
                                     set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr, ...
                                         'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2)];

                % Table 1 Cycle c
                clf(f_exp_c, 'reset'); set(0, 'CurrentFigure', f_exp_c); hold on;
                plot(time_c, disp_norm_c, 'r-', 'LineWidth', 2.0);
                title(sprintf('Table 1: Deformation Normal — Cycle %d (%s)', c, mode_str), 'Color', fg, 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold');
                xlabel('Time (s)'); ylabel('Deformation (mm)'); grid on; box on; hold off; fmt_ax_c(f_exp_c, gca);
                saveHighRes(f_exp_c, fullfile(outDir_c, sprintf('%s_Table1_Deformation_%s.png', sampleName, mode_str)), EXPORT_DPI);

                % Table 4 Cycle c
                clf(f_exp_c, 'reset'); set(0, 'CurrentFigure', f_exp_c); hold on;
                yyaxis left;  plot(time_c, disp_inv_c, 'r-', 'LineWidth', 2.0); ylabel('Deformation -1 (mm)');
                yyaxis right; plot(time_c, force_c, 'b-', 'LineWidth', 2.0);   ylabel('Force (g)');
                ax_c4 = gca;
                ax_c4.YAxis(1).Color = 'r'; ax_c4.YAxis(2).Color = 'b';
                xlabel('Time (s)');
                title(sprintf('Table 4: Merged Plot — Cycle %d (%s)', c, mode_str), 'Color', fg, 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold');
                grid on; box on; hold off; fmt_ax_c(f_exp_c, gca);
                saveHighRes(f_exp_c, fullfile(outDir_c, sprintf('%s_Table4_Merged_Plot_%s.png', sampleName, mode_str)), EXPORT_DPI);

                % Table 7 Cycle c
                clf(f_exp_c, 'reset'); set(0, 'CurrentFigure', f_exp_c); hold on;
                scatter(disp_l_sh{c}, force_l{c}, 24, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading');
                scatter(disp_r_sh{c}, force_r{c}, 24, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery');
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 9);
                xlabel('Displacement (mm)'); ylabel('Force (g)');
                title(sprintf('Table 7: Force vs Displacement — Cycle %d (%s)', c, mode_str), 'Color', fg, 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold');
                grid on; box on; legend('Location', 'northwest'); hold off; fmt_ax_c(f_exp_c, gca);
                saveHighRes(f_exp_c, fullfile(outDir_c, sprintf('%s_Table7_Stiffening_%s.png', sampleName, mode_str)), EXPORT_DPI);

                % Table 8 Clean Cycle c
                clf(f_exp_c, 'reset'); set(0, 'CurrentFigure', f_exp_c); hold on;
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 9);
                xlabel('Displacement (mm)'); ylabel('Force (g)');
                title(sprintf('Table 8: Clean Curves — Cycle %d (%s)', c, mode_str), 'Color', fg, 'FontName', FONT_NAME, 'FontSize', 13, 'FontWeight', 'bold');
                grid on; box on; legend('Location', 'northwest'); hold off; fmt_ax_c(f_exp_c, gca);
                saveHighRes(f_exp_c, fullfile(outDir_c, sprintf('%s_Table8_Clean_%s.png', sampleName, mode_str)), EXPORT_DPI);
            end
            close(f_exp_c);
        end

        % ====================================================================
        % 9. ORIGINAL SPECIAL GRAPHICS EXPORT (Caliper & Overview 3-in-1)
        % ====================================================================
        % M-Mode Caliper
        f_cal = figure('Visible', 'off', 'Position', [100, 100, 1020, 640], 'Color', 'k', 'InvertHardcopy', 'off');
        ax_cal = axes('Parent', f_cal);
        set(ax_cal, 'Color', [0.08 0.08 0.08], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.35 0.35 0.35], ...
            'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2);
        hold(ax_cal, 'on');

        frames_x = 1:size(data_oct, 1);
        top_sc = abs(data_oct{:, 5});
        if size(data_oct, 2) >= 6, bot_sc = abs(data_oct{:, 6}); else, bot_sc = top_sc; end
        if size(data_oct, 2) >= 7, end_ed = abs(data_oct{:, 7}); else, end_ed = top_sc + (t0_mm*1000/pixel_to_um); end

        plot(ax_cal, frames_x, top_sc, 'r-', 'LineWidth', 2.0, 'DisplayName', 'top SC');
        if any(bot_sc ~= top_sc), plot(ax_cal, frames_x, bot_sc, 'y-', 'LineWidth', 2.0, 'DisplayName', 'bot SC'); end
        plot(ax_cal, frames_x, end_ed, 'g-', 'LineWidth', 2.0, 'DisplayName', 'end ED');
        set(ax_cal, 'YDir', 'reverse');

        cap_w = max(4, round(length(frames_x) * 0.012));
        for p_idx = 1:length(idx_titik)
            kp = idx_titik(p_idx);
            y_t = top_sc(kp);
            y_b = end_ed(kp);
            th_px = abs(y_b - y_t);
            th_mm = th_px * pixel_to_um / 1000;

            plot(ax_cal, [kp, kp], [y_t, y_b], 'w-', 'LineWidth', 2.0, 'HandleVisibility', 'off');
            plot(ax_cal, [kp - cap_w, kp + cap_w], [y_t, y_t], 'w-', 'LineWidth', 2.5, 'HandleVisibility', 'off');
            plot(ax_cal, [kp - cap_w, kp + cap_w], [y_b, y_b], 'w-', 'LineWidth', 2.5, 'HandleVisibility', 'off');

            y_mid = (y_t + y_b) / 2;
            text(ax_cal, kp + cap_w + 3, y_mid, sprintf('%.3f mm / %d px', th_mm, round(th_px)), ...
                'FontName', FONT_NAME, 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
                'BackgroundColor', 'k', 'EdgeColor', 'w', 'Margin', 3);
        end

        title(ax_cal, sprintf('OCT M-Mode Caliper Measurements — %s', sampleName), ...
            'FontName', FONT_NAME, 'Color', 'w', 'FontSize', 13, 'FontWeight', 'bold');
        xlabel(ax_cal, 'Frame Index', 'FontName', FONT_NAME, 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel(ax_cal, 'Depth (px)', 'FontName', FONT_NAME, 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
        grid(ax_cal, 'on'); box(ax_cal, 'on');
        lgd_cal = legend(ax_cal, 'Location', 'southwest');
        set(lgd_cal, 'FontName', FONT_NAME, 'TextColor', 'w', 'Color', 'k', 'EdgeColor', 'w', 'FontSize', 9);
        hold(ax_cal, 'off');

        saveHighRes(f_cal, fullfile(outDir_full, sprintf('%s_OCT_MMode_Caliper_Measurements.png', sampleName)), EXPORT_DPI);
        close(f_cal);

        % Overview Composite 3-in-1 (300 DPI)
        f_ov_comp = figure('Visible', 'off', 'Position', [100, 100, 1150, 960]);
        for m_idx = 1:2
            mode_str = modes{m_idx};
            if m_idx == 2, bg = 'k'; fg = 'w'; grid_clr = [0.35 0.35 0.35]; c_sc = [0.3 0.65 1.0]; c_ed = [1.0 0.35 0.35];
            else,          bg = 'w'; fg = 'k'; grid_clr = [0.85 0.85 0.85]; c_sc = [0.0 0.25 0.85]; c_ed = [0.85 0.05 0.05];
            end

            clf(f_ov_comp, 'reset'); set(f_ov_comp, 'Color', bg, 'InvertHardcopy', 'off');

            % Subplot 1
            ax_c1 = subplot(3, 1, 1, 'Parent', f_ov_comp); hold(ax_c1, 'on');
            plot(ax_c1, -data_E_raw, 'Color', c_sc, 'LineWidth', 1.8, 'DisplayName', 'Stratum Corneum');
            if size(data_oct, 2) >= 7, plot(ax_c1, -data_oct{:, 7}, 'Color', c_ed, 'LineWidth', 1.8, 'DisplayName', 'Epidermis'); end
            for k_pt = 1:n_pts
                plot(ax_c1, idx_titik(k_pt), -data_E_raw(idx_titik(k_pt)), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 7);
                text(ax_c1, idx_titik(k_pt), -data_E_raw(idx_titik(k_pt)), sprintf(' %d', k_pt), 'Color', fg, 'FontWeight', 'bold', 'FontSize', 8);
            end
            title(ax_c1, sprintf('Skin Thickness Analysis — %s', sampleName), 'FontName', FONT_NAME, 'FontSize', 12, 'FontWeight', 'bold', 'Color', fg);
            xlabel(ax_c1, 'Frame Index', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'Color', fg);
            ylabel(ax_c1, 'Pixel (Raw)', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'Color', fg);
            set(ax_c1, 'FontName', FONT_NAME, 'FontSize', 9, 'FontWeight', 'bold', 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
            grid(ax_c1, 'on'); box(ax_c1, 'on');
            legend(ax_c1, 'Location', 'northeastoutside', 'FontSize', 8, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg);
            hold(ax_c1, 'off');

            % Subplot 2
            ax_c2 = subplot(3, 1, 2, 'Parent', f_ov_comp);
            plot(ax_c2, time_oct_sec, displacement_mm_normal * 1000, 'r-', 'LineWidth', 1.8);
            title(ax_c2, 'Calibrated Deformation (\mum)', 'FontName', FONT_NAME, 'FontSize', 12, 'FontWeight', 'bold', 'Color', fg);
            xlabel(ax_c2, 'Time (seconds)', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'Color', fg);
            ylabel(ax_c2, 'Deformation (\mum)', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'Color', fg);
            set(ax_c2, 'FontName', FONT_NAME, 'FontSize', 9, 'FontWeight', 'bold', 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
            grid(ax_c2, 'on'); box(ax_c2, 'on');

            % Subplot 3
            ax_c3 = subplot(3, 1, 3, 'Parent', f_ov_comp); hold(ax_c3, 'on');
            yyaxis(ax_c3, 'left');
            plot(ax_c3, time_oct_sec, displacement_mm_normal, 'r-', 'LineWidth', 1.8, 'DisplayName', 'Deformation (mm)');
            ylabel(ax_c3, 'Deformation (mm)', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold');
            ax_c3.YAxis(1).Color = 'r';
            yyaxis(ax_c3, 'right');
            plot(ax_c3, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Auto-Force (g)');
            ylabel(ax_c3, 'Force (g)', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold');
            ax_c3.YAxis(2).Color = 'b';
            xlabel(ax_c3, 'Time (seconds)', 'FontName', FONT_NAME, 'FontSize', 10, 'FontWeight', 'bold', 'Color', fg);
            title(ax_c3, 'Deformation & Auto-Force vs Time', 'FontName', FONT_NAME, 'FontSize', 12, 'FontWeight', 'bold', 'Color', fg);
            set(ax_c3, 'FontName', FONT_NAME, 'FontSize', 9, 'FontWeight', 'bold', 'Color', bg, 'XColor', fg, 'GridColor', grid_clr);
            grid(ax_c3, 'on'); box(ax_c3, 'on');
            legend(ax_c3, 'Location', 'northeast', 'FontSize', 8, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg);
            hold(ax_c3, 'off');

            sgtitle(sprintf('OCT 3-Subplot Pipeline Overview — %s (%s)', sampleName, mode_str), ...
                'FontName', FONT_NAME, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 14);
            saveHighRes(f_ov_comp, fullfile(outDir_full, sprintf('%s_Overview_Composite_3Subplots_%s.png', sampleName, mode_str)), EXPORT_DPI);
        end
        close(f_ov_comp);
    end

    %% Function: Power Law Fitting with Continuous Domain Extension
    function [a_L, b_L, a_R, b_R, x_plot, fit_L, fit_R, x_max] = fit_power_law_extended(disp_l, force_l, disp_r, force_r, target_max)
        x_L = disp_l - min(disp_l); y_L = force_l;
        x_R = disp_r - min(disp_l); y_R = force_r;
        x_max_data = max(x_L); y_max = max(y_L);
        
        valid_L = (x_L > 1e-4 & y_L > 1e-4);
        if sum(valid_L) > 2
            p_L = polyfit(log(x_L(valid_L)), log(y_L(valid_L)), 1);
            b_L = max(1.5, p_L(1));
        else
            b_L = 1.5;
        end
        a_L = max(0.001, y_max / (x_max_data^b_L));
        
        valid_R = (x_R > 1e-4 & y_R > 1e-4);
        if sum(valid_R) > 2
            p_R = polyfit(log(x_R(valid_R)), log(y_R(valid_R)), 1);
            b_R = max(1.8, p_R(1));
        else
            b_R = 1.8;
        end
        if b_R <= b_L
            b_R = b_L + 0.5;
        end
        a_R = max(0.001, y_max / (x_max_data^b_R));
        
        % Continuous Extension: ensures curve seamlessly connects to E3 target
        x_max = max(x_max_data, target_max * 1.08);
        x_plot = linspace(0, x_max, 150)';
        fit_L = a_L * (x_plot.^b_L);
        fit_R = a_R * (x_plot.^b_R);
    end

    %% Function: High-Resolution Figure Exporter (300 DPI Guard)
    function saveHighRes(fig_handle, filepath, dpi)
        try
            exportgraphics(fig_handle, filepath, 'Resolution', dpi, 'BackgroundColor', 'current');
        catch
            print(fig_handle, filepath, '-dpng', sprintf('-r%d', dpi));
        end
    end
end