m function OCT_ForceXDeformation_Aligner()
    % ============================================================
    % CONFIGURATION — Defaults: 3 Waves, Mode 0: Raw, DPI: 300 (High Res)
    % ============================================================
    NUM_CYCLES  = 3;   % Default: 3 waves (1 to 5)
    FILTER_MODE = 0;   % Default: 0 = Tanpa Filter, 1 = Filter Smooth, 2 = Filter + Max-Min Stretch
    EXPORT_DPI  = 300; % Default: 300 DPI (High Resolution: 150, 300, 600 DPI)
    % ============================================================

    % 1. MAIN UI WINDOW CREATION (Resizable)
    fig = uifigure('Name', sprintf('Generative Biomechanical Analyzerwith this? - %d-Cycle Edition', NUM_CYCLES), ...
        'Position', [50, 50, 1350, 1060], 'AutoResizeChildren', 'off');
    
    % Global Variables
    parentDir = '';
    validPairs = {}; 
    
    % 2. CONTROL INTERFACE COMPONENTS
    lblHeader = uilabel(fig, 'Text', sprintf('1. Select Parent Folder  |  NUM_CYCLES = %d', NUM_CYCLES), 'FontWeight', 'bold', 'FontSize', 14);
    
    btnBrowse = uibutton(fig, 'Text', 'Browse Folder', 'ButtonPushedFcn', @(btn,event) selectFolder());
    lblFolder = uilabel(fig, 'Text', 'No folder selected');
    
    % Controls for Waves (Default: 3 Waves) & Filter Mode (Default: 0 - Tanpa Filter)
    lblWaves = uilabel(fig, 'Text', 'Wave Count:', 'FontWeight', 'bold');
    ddlWaves = uidropdown(fig, 'Items', {'1 Wave', '2 Waves', '3 Waves', '4 Waves', '5 Waves'}, ...
        'ItemsData', [1, 2, 3, 4, 5], 'Value', NUM_CYCLES, ...
        'ValueChangedFcn', @(dd, event) changeWaves(dd.Value));
        
    lblFilter = uilabel(fig, 'Text', 'Filter Mode:', 'FontWeight', 'bold');
    ddlFilter = uidropdown(fig, 'Items', {'1. Raw Signal (Unfiltered - Default)', '2. Savitzky-Golay Filter'}, ...
        'ItemsData', [0, 1], 'Value', FILTER_MODE, ...
        'ValueChangedFcn', @(dd, event) changeFilter(dd.Value));
        
    lblDPI = uilabel(fig, 'Text', 'Export DPI:', 'FontWeight', 'bold');
    ddlDPI = uidropdown(fig, 'Items', {'300 DPI (High Res - Default)', '600 DPI (Ultra High Res)', '150 DPI (Standard)'}, ...
        'ItemsData', [300, 600, 150], 'Value', EXPORT_DPI, ...
        'ValueChangedFcn', @(dd, event) changeDPI(dd.Value));
    
    lblSamplesHeader = uilabel(fig, 'Text', '2. Detected Sample List:', 'FontWeight', 'bold');
    lstSamples = uilistbox(fig);
    
    btnProcess = uibutton(fig, 'Text', 'PROCESS ALL SAMPLES', ...
        'FontWeight', 'bold', 'FontSize', 16, 'BackgroundColor', [0.2 0.6 0.2], 'FontColor', 'w', ...
        'ButtonPushedFcn', @(btn,event) processSamples());
    
    lblStatus = uilabel(fig, 'Text', 'Status: Waiting for folder selection...', 'FontColor', 'b', 'FontSize', 14);
    
    % 3. STANDARDIZED UI GRID — Row 1 and Row 2 are fixed (6 panels)
    ax_def_normal = uiaxes(fig); title(ax_def_normal, '1. Deformation (Red)');
    ax_def_inv    = uiaxes(fig); title(ax_def_inv, '2. Deformation -1 (Red)');
    ax_force_time = uiaxes(fig); title(ax_force_time, '3. Force (Blue)');
    
    ax_merged     = uiaxes(fig); title(ax_merged, '4. Deformation -1 x Force Merged (Red / Blue)');
    ax_hyst_final = uiaxes(fig); title(ax_hyst_final, '5. Hysteresis Evaluation (Normal Displacement - No -1)');
    ax_donut      = uiaxes(fig); title(ax_donut, '6. Donut Table Graph Panel');
    
    % Row 3: Dynamic cycle panels
    ax_cycle = {};
    createCycleAxes(NUM_CYCLES);

    % Configure Window Resizability
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
        lblHeader.Text = sprintf('1. Select Parent Folder  |  NUM_CYCLES = %d', NUM_CYCLES);
        fig.Name = sprintf('Generative Biomechanical Analyzer - %d-Cycle Edition', NUM_CYCLES);
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

        lblSamplesHeader.Position = [20, H - 100, 300, 20];
        
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
    
    %% Function: Select Folder
    function selectFolder() %% This is the function of Select Folder
        selDir = uigetdir('', 'Select Parent Folder');
        if selDir == 0, return; end
        parentDir = selDir;
        lblFolder.Text = parentDir;
        
        subDirs = dir(fullfile(parentDir, '*_analysis')); %% Declare about take any Parent folder thath CONTAIN _analysis
        numDirs = length(subDirs); %% Detect all the SubDirs inside the parent Folder
        tempPairs = cell(1, numDirs);
        tempDisplay = cell(1, numDirs);
        validCount = 0;
        
        for i = 1:numDirs
            if subDirs(i).isdir
                folderName = subDirs(i).name;
                baseName = strrep(folderName, '_analysis', '');
                octFile = fullfile(parentDir, folderName, 'timeseries.csv');
                forceFile = fullfile(parentDir, [baseName, '.csv']);
                
                validCount = validCount + 1;
                if exist(octFile, 'file') && exist(forceFile, 'file')
                    tempPairs{validCount} = {baseName, octFile, forceFile};
                    tempDisplay{validCount} = sprintf('[Ready] Sample: %s', baseName);
                else
                    tempPairs{validCount} = {}; 
                    tempDisplay{validCount} = sprintf('[Error] Incomplete Data: %s', baseName);
                end
            end
        end
        
        validIdx = ~cellfun('isempty', tempPairs(1:validCount));
        validPairs = tempPairs(validIdx);
        lstSamples.Items = tempDisplay(1:validCount);
        lblStatus.Text = sprintf('Status: %d samples ready for processing.', length(validPairs));
    end
    
    %% Function: Process All Samples
    function processSamples()
        if isempty(validPairs)
            uialert(fig, 'No valid samples found!', 'Warning');
            return;
        end
        
        outputMainDir = fullfile(parentDir, 'Analysis_Results');
        if ~exist(outputMainDir, 'dir'), mkdir(outputMainDir); end
        
        for i = 1:length(validPairs)
            baseName = validPairs{i}{1};
            octFile = validPairs{i}{2};
            forceFile = validPairs{i}{3};
            
            lblStatus.Text = sprintf('Status: Annotation Session for %s (%d/%d)...', baseName, i, length(validPairs));
            drawnow; 
            
            outputSubDir = fullfile(outputMainDir, baseName);
            if ~exist(outputSubDir, 'dir'), mkdir(outputSubDir); end
            
            try
                runAnalysisLogic(baseName, octFile, forceFile, outputSubDir);
            catch ME
                warning('Failed to process %s: %s', baseName, ME.message);
            end
        end
        lblStatus.Text = 'Status: ALL PROCESSES COMPLETED.';
        uialert(fig, 'Processing and Figure Export Completed!', 'Success');
    end
    
    %% Function: Core Analysis Logic
    function runAnalysisLogic(sampleName, octFile, forceFile, outDir)
        % ============================================================
        % CONFIG (inherited from outer scope via closure)
        % ============================================================
        N = NUM_CYCLES;  % shorthand
        n_pts = 2*N + 1; % total annotation points (start + peak+end per cycle)
        cycle_colors = {'r', 'g', 'b', 'm', 'c'};  % up to 5 cycles
        % cycle_colors = {'k', 'k', 'k', 'k', 'k'};

        % ====================================================================
        % 1. DATA INGESTION
        % ====================================================================
        data_oct = readtable(octFile); 
        data_E_raw = data_oct{:, 5}; 
        
        data_sensor = readtable(forceFile);
        time_sensor_ms = data_sensor{:, 1};
        force_sensor_gram = data_sensor{:, 2}; 
        force_sensor_gram = force_sensor_gram - min(force_sensor_gram); 
        
        pixel_to_um = 1000 / 200; 
        fps_oct = 25;
        time_oct_sec = (0:length(data_E_raw)-1)' / fps_oct;
        time_sensor_sec = time_sensor_ms / 1000;
        
        % Compute base scaled vector once, reuse everywhere
        e_um = data_E_raw * pixel_to_um;
        displacement_mm_temp = abs(e_um - e_um(1)) / 1000;
        
        % ====================================================================
        % 2. INTERACTIVE COORDINATE PINPOINTING
        % ====================================================================
        hFig = figure('Name', ['Experiment Annotation Session: ', sampleName], 'Position', [100, 100, 1000, 700]);
        
        % --- A. OCT Displacements Mapping ---
        subplot(2, 1, 1);
        plot(time_oct_sec, displacement_mm_temp, 'r-', 'LineWidth', 1.5); grid on;
        ylabel('Raw Deformation (mm)'); hold on;
        
        x_oct = zeros(n_pts, 1);
        h_oct_plots  = cell(1, n_pts);
        h_oct_texts  = cell(1, n_pts);
        h_oct_guides = cell(1, n_pts);
        
        labels_oct = cell(1, n_pts);
        labels_oct{1} = 'Start Pull 1';
        for c = 1:N
            labels_oct{2*c}   = sprintf('Peak %d', c);
            labels_oct{2*c+1} = sprintf('End %d', c);
        end
        
        k = 1;
        while k <= n_pts
            subplot(2, 1, 1);
            if k > 1
                title({sprintf('CLICK OCT DEFORMATION POINT (%d/%d)  |  [Press BACKSPACE to Undo]', k, n_pts), ...
                       ['Target: ', labels_oct{k}]});
            else
                title({sprintf('CLICK OCT DEFORMATION POINT (%d/%d)', k, n_pts), ['Target: ', labels_oct{k}]});
            end
            
            [x_val, y_val, btn] = ginput(1);
            
            % Check if Backspace (8) or Delete (127) or 'b'/'B' (98/66) was pressed
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
            
            % Global Snapping: Pull pin vertically onto the actual curve value at x_val
            idx_curr = min([find(time_oct_sec >= x_val, 1, 'first'), length(time_oct_sec)]);
            if isempty(idx_curr), idx_curr = 1; end
            x_snap = time_oct_sec(idx_curr);
            y_snap = displacement_mm_temp(idx_curr);
            
            x_oct(k) = x_snap;
            
            % Draw vertical guide line pulling click to curve
            h_oct_guides{k} = plot([x_val, x_snap], [y_val, y_snap], 'm--', 'LineWidth', 1);
            h_oct_plots{k}  = plot(x_snap, y_snap, 'm*', 'MarkerSize', 12, 'LineWidth', 2);
            h_oct_texts{k}  = text(x_snap, y_snap, ['  ', num2str(k)], 'Color', 'm', 'FontWeight', 'bold');
            drawnow;
            k = k + 1;
        end
        get_idx_oct = @(x) min([find(time_oct_sec >= x, 1, 'first'), length(time_oct_sec)]);
        idx_titik = arrayfun(get_idx_oct, sort(x_oct));
        
        % --- B. Force Metrics Mapping ---
        subplot(2, 1, 2);
        plot(time_sensor_sec, force_sensor_gram, 'b-', 'LineWidth', 1.5); grid on;
        xlabel('Sensor Data Time (s)'); ylabel('Sensor Force (g)'); hold on;
        
        x_force = zeros(n_pts, 1);
        h_force_plots  = cell(1, n_pts);
        h_force_texts  = cell(1, n_pts);
        h_force_guides = cell(1, n_pts);
        
        labels_force = cell(1, n_pts);
        labels_force{1} = 'Start Pull 1';
        for c = 1:N
            labels_force{2*c}   = sprintf('Peak %d', c);
            labels_force{2*c+1} = sprintf('End %d', c);
        end
        
        k = 1;
        while k <= n_pts
            subplot(2, 1, 2);
            if k > 1
                title({sprintf('CLICK FORCE SENSOR POINT (%d/%d)  |  [Press BACKSPACE to Undo]', k, n_pts), ...
                       ['Target: ', labels_force{k}]});
            else
                title({sprintf('CLICK FORCE SENSOR POINT (%d/%d)', k, n_pts), ['Target: ', labels_force{k}]});
            end
            
            [x_val, y_val, btn] = ginput(1);
            
            % Check if Backspace (8) or Delete (127) or 'b'/'B' (98/66) was pressed
            if isempty(btn) || btn == 8 || btn == 127 || btn == 98 || btn == 66
                if k > 1
                    k_prev = k - 1;
                    if ~isempty(h_force_plots{k_prev}) && isvalid(h_force_plots{k_prev}), delete(h_force_plots{k_prev}); end
                    if ~isempty(h_force_texts{k_prev}) && isvalid(h_force_texts{k_prev}), delete(h_force_texts{k_prev}); end
                    if ~isempty(h_force_guides{k_prev}) && isvalid(h_force_guides{k_prev}), delete(h_force_guides{k_prev}); end
                    h_force_plots{k_prev} = []; h_force_texts{k_prev} = []; h_force_guides{k_prev} = [];
                    x_force(k_prev) = 0;
                    k = k_prev;
                end
                continue;
            end
            
            % Global Snapping: Pull pin vertically onto the actual curve value at x_val
            idx_curr = min([find(time_sensor_sec >= x_val, 1, 'first'), length(time_sensor_sec)]);
            if isempty(idx_curr), idx_curr = 1; end
            x_snap = time_sensor_sec(idx_curr);
            y_snap = force_sensor_gram(idx_curr);
            
            x_force(k) = x_snap;
            
            % Draw vertical guide line pulling click to curve
            h_force_guides{k} = plot([x_val, x_snap], [y_val, y_snap], 'c--', 'LineWidth', 1);
            h_force_plots{k}  = plot(x_snap, y_snap, 'kv', 'MarkerFaceColor', 'c', 'MarkerSize', 12);
            h_force_texts{k}  = text(x_snap, y_snap, ['  ', num2str(k)], 'Color', 'k', 'FontWeight', 'bold');
            drawnow;
            k = k + 1;
        end
        get_idx_force = @(x) min([find(time_sensor_sec >= x, 1, 'first'), length(time_sensor_sec)]);
        idx_force = arrayfun(get_idx_force, sort(x_force));
        
        close(hFig); 
        
        % ====================================================================
        % 3. POST-LABELING ORIENTATION FACTORS OVERRIDE
        % ====================================================================
        displacement_mm_normal = abs(e_um - e_um(idx_titik(1))) / 1000;
        if FILTER_MODE >= 1
            displacement_mm_normal = smoothdata(displacement_mm_normal, 'sgolay', 25);
        end
        
        e_um_inv = -e_um;
        displacement_mm_inv = (e_um_inv - e_um_inv(idx_titik(1))) / 1000;
        if FILTER_MODE >= 1
            displacement_mm_inv = smoothdata(displacement_mm_inv, 'sgolay', 25);
        end
        
        % ====================================================================
        % 4. MULTI-CYCLE TIME-WARPING LOGIC (loop over N cycles)
        % ====================================================================
        force_interp_oct = zeros(size(time_oct_sec));
        
        for c = 1:N
            i_start = idx_titik(2*c - 1);
            i_peak  = idx_titik(2*c);
            i_end   = idx_titik(2*c + 1);
            j_start = idx_force(2*c - 1);
            j_peak  = idx_force(2*c);
            j_end   = idx_force(2*c + 1);
            
            % Loading segment
            f_L_raw = force_sensor_gram(j_start:j_peak);
            if length(f_L_raw) >= 2 && (i_peak > i_start)
                force_interp_oct(i_start:i_peak) = interp1(linspace(0,1,length(f_L_raw)), f_L_raw, linspace(0,1,i_peak-i_start+1), 'pchip')';
            elseif i_start <= i_peak
                force_interp_oct(i_start:i_peak) = mean(f_L_raw);
            end
            
            % Recovery segment
            f_R_raw = force_sensor_gram(j_peak:j_end);
            if length(f_R_raw) >= 2 && (i_end > i_peak)
                force_interp_oct(i_peak:i_end) = interp1(linspace(0,1,length(f_R_raw)), f_R_raw, linspace(0,1,i_end-i_peak+1), 'pchip')';
            elseif i_peak <= i_end
                force_interp_oct(i_peak:i_end) = mean(f_R_raw);
            end
        end
        
        % Smooth assembled vector if FILTER_MODE >= 1
        if FILTER_MODE >= 1
            force_interp_oct = smoothdata(force_interp_oct, 'sgolay', 51);
        end
        force_interp_oct(force_interp_oct < 0) = 0;
        
        % ====================================================================
        % 5. STIFFNESS EVALUATION (loop over N cycles)
        % ====================================================================
        v_poisson = 0.45; a_radius = 2.5; k_factor = 3.085; g_gravity = 9.81;
        part1 = (1 - v_poisson^2) / (2 * a_radius * k_factor);
        t0_mm = abs(e_um(idx_titik(1))) / 1000;
        
        w_target_A = (1.5/100) * t0_mm;
        w_target_B = (3.3/100) * t0_mm;
        w_target_C = (5.0/100) * t0_mm;
        
        % Cell arrays for all per-cycle quantities
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
            
            disp_l{c} = displacement_mm_normal(i_start:i_peak);
            force_l{c} = force_interp_oct(i_start:i_peak);
            disp_r{c} = displacement_mm_normal(i_peak:i_end);
            force_r{c} = force_interp_oct(i_peak:i_end);
            disp_s{c} = displacement_mm_normal(i_start:i_end);
            force_s{c} = force_interp_oct(i_start:i_end);
            
            target_A{c} = min(disp_l{c}) + w_target_A;
            target_B{c} = min(disp_l{c}) + w_target_B;
            target_C{c} = min(disp_l{c}) + w_target_C;
            
            [a_L{c}, b_L{c}, a_R{c}, b_R{c}, x_plot_c{c}, fit_L_c{c}, fit_R_c{c}, x_max_c{c}] = ...
                fit_power_law(disp_l{c}, force_l{c}, disp_r{c}, force_r{c});
            
            Pg_A{c} = a_L{c} * (w_target_A ^ b_L{c});
            Pg_B{c} = a_L{c} * (w_target_B ^ b_L{c});
            Pg_C{c} = a_L{c} * (w_target_C ^ b_L{c});
            
            sl_A = a_L{c} * b_L{c} * (w_target_A ^ (b_L{c}-1));
            sl_B = a_L{c} * b_L{c} * (w_target_B ^ (b_L{c}-1));
            sl_C = a_L{c} * b_L{c} * (w_target_C ^ (b_L{c}-1));
            E_A_kPa{c} = part1 * ((max(0, sl_A) / 1000) * g_gravity) * 1000;
            E_B_kPa{c} = part1 * ((max(0, sl_B) / 1000) * g_gravity) * 1000;
            E_C_kPa{c} = part1 * ((max(0, sl_C) / 1000) * g_gravity) * 1000;
            
            text_str_c{c} = {sprintf('E1 (1.5%%) : %.2f kPa', E_A_kPa{c}), ...
                             sprintf('E2 (3.3%%) : %.2f kPa', E_B_kPa{c}), ...
                             sprintf('E3 (5.0%%) : %.2f kPa', E_C_kPa{c})};
            
            disp_l_sh{c} = disp_l{c} - min(disp_l{c});
            disp_r_sh{c} = disp_r{c} - min(disp_l{c});
        end
        
        % Average fit across all N cycles
        a_L_avg = mean(cellfun(@(x) x, a_L)); b_L_avg = mean(cellfun(@(x) x, b_L));
        a_R_avg = mean(cellfun(@(x) x, a_R)); b_R_avg = mean(cellfun(@(x) x, b_R));
        x_max_avg = mean(cellfun(@(x) x, x_max_c));
        x_plot_avg = linspace(0, x_max_avg, 100)';
        fit_L_avg = a_L_avg * (x_plot_avg .^ b_L_avg);
        fit_R_avg = a_R_avg * (x_plot_avg .^ b_R_avg);
        
        w_target_avg_A = w_target_A;
        w_target_avg_B = w_target_B;
        w_target_avg_C = w_target_C;
        
        Pg_avg_A = a_L_avg * (w_target_A ^ b_L_avg);
        Pg_avg_B = a_L_avg * (w_target_B ^ b_L_avg);
        Pg_avg_C = a_L_avg * (w_target_C ^ b_L_avg);
        
        sl_avg_A = a_L_avg * b_L_avg * (w_target_A ^ (b_L_avg-1));
        sl_avg_B = a_L_avg * b_L_avg * (w_target_B ^ (b_L_avg-1));
        sl_avg_C = a_L_avg * b_L_avg * (w_target_C ^ (b_L_avg-1));
        E_avg_A_kPa = part1 * ((max(0, sl_avg_A) / 1000) * g_gravity) * 1000;
        E_avg_B_kPa = part1 * ((max(0, sl_avg_B) / 1000) * g_gravity) * 1000;
        E_avg_C_kPa = part1 * ((max(0, sl_avg_C) / 1000) * g_gravity) * 1000;
        
        text_str_avg = {sprintf('E1 (1.5%%) : %.2f kPa', E_avg_A_kPa), ...
                        sprintf('E2 (3.3%%) : %.2f kPa', E_avg_B_kPa), ...
                        sprintf('E3 (5.0%%) : %.2f kPa', E_avg_C_kPa)};
        
        % Table 5 targets (use cycle-B values for hysteresis markers)
        E_kPa_B = cellfun(@(x) x, E_B_kPa);
        P_g_B   = cellfun(@(x) x, Pg_B);
        tgt_B   = cellfun(@(x) x, target_B);
        
        % Donut polar computation
        total_points = idx_titik(n_pts) - idx_titik(1) + 1;
        theta = linspace(0, 2*N*pi, total_points)';
        R_disp = 100 + (displacement_mm_inv(idx_titik(1):idx_titik(n_pts)) * 100);
        [X_disp, Y_disp] = pol2cart(theta, R_disp);
        
        % ====================================================================
        % 6. POPULATING THE STANDARDIZED UI SCREEN GRAPHICS
        % ====================================================================
        cla(ax_def_normal); plot(ax_def_normal, time_oct_sec, displacement_mm_normal, 'r-', 'LineWidth', 1.5);
        ylabel(ax_def_normal, 'Deformation Normal (mm)'); grid(ax_def_normal, 'on');
        
        cla(ax_def_inv); plot(ax_def_inv, time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
        ylabel(ax_def_inv, 'Deformation Inverted -1 (mm)'); grid(ax_def_inv, 'on');
        
        cla(ax_force_time); plot(ax_force_time, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5);
        ylabel(ax_force_time, 'Force Vector (g)'); grid(ax_force_time, 'on');
        
        cla(ax_merged);
        yyaxis(ax_merged, 'left'); plot(ax_merged, time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
        ylabel(ax_merged, 'Deformation -1 (mm)'); ax_merged.YColor = 'r';
        yyaxis(ax_merged, 'right'); plot(ax_merged, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5);
        ylabel(ax_merged, 'Force Vector (g)'); ax_merged.YColor = 'b';
        xlabel(ax_merged, 'Time (s)'); grid(ax_merged, 'on');
        
        % Table 5 UI: Hysteresis (all N cycles)
        cla(ax_hyst_final); hold(ax_hyst_final, 'on');
        plot(ax_hyst_final, displacement_mm_normal(idx_titik(1):idx_titik(n_pts)), ...
             force_interp_oct(idx_titik(1):idx_titik(n_pts)), 'y-', 'LineWidth', 3.5, 'DisplayName', 'Total Profile');
        for c = 1:N
            plot(ax_hyst_final, disp_s{c}, force_s{c}, '-', 'Color', cycle_colors{c}, 'LineWidth', 1.2, 'DisplayName', sprintf('S%d Real', c));
        end
        for c = 1:N
            xA = target_A{c}; xB = target_B{c}; xC = target_C{c};
            [x_u, idx_u] = unique(disp_l{c});
            y_u = force_l{c}(idx_u);
            if length(x_u) >= 2
                yA = interp1(x_u, y_u, xA, 'pchip', 'extrap');
                yB = interp1(x_u, y_u, xB, 'pchip', 'extrap');
                yC = interp1(x_u, y_u, xC, 'pchip', 'extrap');
            else
                yA = Pg_A{c}; yB = Pg_B{c}; yC = Pg_C{c};
            end
            
            plot(ax_hyst_final, xA, yA, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'HandleVisibility', 'off');
            text(ax_hyst_final, xA, yA, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 8);
            
            plot(ax_hyst_final, xB, yB, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6, 'HandleVisibility', 'off');
            text(ax_hyst_final, xB, yB, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 8);
            
            plot(ax_hyst_final, xC, yC, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6, 'HandleVisibility', 'off');
            text(ax_hyst_final, xC, yC, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 8);
        end
        xlabel(ax_hyst_final, 'Deformation Normal (mm)'); ylabel(ax_hyst_final, 'Force (g)'); grid(ax_hyst_final, 'on');
        legend(ax_hyst_final, 'Location', 'northwest', 'FontSize', 6); hold(ax_hyst_final, 'off');
        
        % Table 6 UI: Donut
        cla(ax_donut); plot(ax_donut, X_disp, Y_disp, 'k:', 'LineWidth', 1); hold(ax_donut, 'on');
        n_s1 = length(disp_s{1});
        plot(ax_donut, X_disp(1:n_s1), Y_disp(1:n_s1), 'r-', 'LineWidth', 2);
        axis(ax_donut, 'equal'); grid(ax_donut, 'on'); hold(ax_donut, 'off');
        
        % Row 3 UI: Cycle panels
        for c = 1:N
            cla(ax_cycle{c}); hold(ax_cycle{c}, 'on');
            scatter(ax_cycle{c}, disp_l_sh{c}, force_l{c}, 10, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading');
            scatter(ax_cycle{c}, disp_r_sh{c}, force_r{c}, 10, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery');
            plot(ax_cycle{c}, x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
            plot(ax_cycle{c}, x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
            plot(ax_cycle{c}, w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'DisplayName', 'Target E1 (1.5%)'); text(ax_cycle{c}, w_target_A, Pg_A{c}, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold');
            plot(ax_cycle{c}, w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6, 'DisplayName', 'Target E2 (3.3%)'); text(ax_cycle{c}, w_target_B, Pg_B{c}, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold');
            plot(ax_cycle{c}, w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6, 'DisplayName', 'Target E3 (5.0%)'); text(ax_cycle{c}, w_target_C, Pg_C{c}, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold');
            text(ax_cycle{c}, 0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontWeight', 'bold');
            xlabel(ax_cycle{c}, 'Displacement (mm)'); ylabel(ax_cycle{c}, 'Force (g)'); grid(ax_cycle{c}, 'on'); hold(ax_cycle{c}, 'off');
        end
          % ====================================================================
        % 7. HIGH-RESOLUTION IMAGE & EXCEL EXPORT ENGINE (SUBFOLDERS: Full_Cycle + Cycle_1..N)
        % ====================================================================
        
        % --------------------------------------------------------------------
        % A. FULL CYCLE BUNDLE EXPORT (Folder: Full_Cycle)
        % --------------------------------------------------------------------
        outDir_full = fullfile(outDir, 'Full_Cycle');
        if ~exist(outDir_full, 'dir'), mkdir(outDir_full); end
        
        f_export = figure('Visible', 'off', 'Position', [100, 100, 800, 600]);
        modes = {'Light', 'Dark'};
        
        for m_idx = 1:2
            mode_str = modes{m_idx};
            if m_idx == 2
                bg = 'k'; fg = 'w'; grid_clr = [0.4 0.4 0.4];
            else
                bg = 'w'; fg = 'k'; grid_clr = [0.8 0.8 0.8];
            end
            fmt_ax  = @(f, ax) [set(f, 'Color', bg), set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr)];
            fmt_lgd = @(lgd) set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
            
            % ---- Table 1 ----
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(time_oct_sec, displacement_mm_normal, 'r-', 'LineWidth', 1.5);
            title(sprintf('Table 1: Deformation Normal (%s)', mode_str), 'Color', fg);
            xlabel('Time (s)'); ylabel('Deformation (mm)'); grid on; hold off;
            fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table1_Deformation_%s.png', sampleName, mode_str)), EXPORT_DPI);
            
            % ---- Table 2 ----
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
            title(sprintf('Table 2: Deformation -1 (%s)', mode_str), 'Color', fg);
            xlabel('Time (s)'); ylabel('Deformation x -1 (mm)'); grid on; hold off;
            fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table2_Deformation_Inv_%s.png', sampleName, mode_str)), EXPORT_DPI);
            
            % ---- Table 3 ----
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5);
            title(sprintf('Table 3: Force Telemetry (%s)', mode_str), 'Color', fg);
            xlabel('Time (s)'); ylabel('Force (g)'); grid on; hold off;
            fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table3_Force_Vector_%s.png', sampleName, mode_str)), EXPORT_DPI);
            
            % ---- Table 4 ----
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            yyaxis left;  plot(time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5);
            ylabel('Deformation -1 (mm)');
            yyaxis right; plot(time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5);
            ylabel('Force Vector (g)');
            ax4 = gca; ax4.YAxis(1).Color = 'r'; ax4.YAxis(2).Color = 'b';
            xlabel('Time (s)'); title(sprintf('Table 4: Deformation x Force Merged (%s)', mode_str), 'Color', fg); grid on; hold off;
            fmt_ax(f_export, ax4);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table4_Deformation_Force_Merged_%s.png', sampleName, mode_str)), EXPORT_DPI);
            
            % ---- Table 5 ----
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(displacement_mm_normal(idx_titik(1):idx_titik(n_pts)), ...
                 force_interp_oct(idx_titik(1):idx_titik(n_pts)), '-', 'Color', fg, 'LineWidth', 2.5, 'DisplayName', 'Total Profile');
            for c = 1:N
                plot(disp_s{c}, force_s{c}, '-', 'Color', fg, 'LineWidth', 1.2, 'DisplayName', sprintf('Cycle %d', c));
            end
            for c = 1:N
                xA = target_A{c}; xB = target_B{c}; xC = target_C{c};
                [x_u, idx_u] = unique(disp_l{c});
                y_u = force_l{c}(idx_u);
                if length(x_u) >= 2
                    yA = interp1(x_u, y_u, xA, 'pchip', 'extrap');
                    yB = interp1(x_u, y_u, xB, 'pchip', 'extrap');
                    yC = interp1(x_u, y_u, xC, 'pchip', 'extrap');
                else
                    yA = Pg_A{c}; yB = Pg_B{c}; yC = Pg_C{c};
                end
                
                plot(xA, yA, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(xA, yA, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                
                plot(xB, yB, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(xB, yB, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                
                plot(xC, yC, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(xC, yC, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
            end
            xlabel('Deformation Normal (mm)'); ylabel('Force (g)');
            title(sprintf('Table 5: Hysteresis Evaluation (%s)', mode_str), 'Color', fg);
            grid on; fmt_lgd(legend('Location', 'northwest')); hold off;
            fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table5_Hysteresis_Evaluation_%s.png', sampleName, mode_str)), EXPORT_DPI);
            
            % ---- Table 6 ----
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(X_disp, Y_disp, 'b:', 'LineWidth', 1);
            plot(X_disp(1:n_s1), Y_disp(1:n_s1), 'r-', 'LineWidth', 2.5);
            axis equal; grid on;
            title(sprintf('Table 6: Donut Spatial Layout (%s)', mode_str), 'Color', fg); hold off;
            fmt_ax(f_export, gca);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table6_Donut_Table_%s.png', sampleName, mode_str)), EXPORT_DPI);
            
            % ---- Tables 7..6+N : Raw per cycle ----
            for c = 1:N
                tbl_raw = 6 + c;
                clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
                scatter(disp_l_sh{c}, force_l{c}, 20, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading Data');
                scatter(disp_r_sh{c}, force_r{c}, 20, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery Data');
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1 (1.5%)'); text(w_target_A, Pg_A{c}, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2 (3.3%)'); text(w_target_B, Pg_B{c}, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3 (5.0%)'); text(w_target_C, Pg_C{c}, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
                xlabel('Displacement (mm)'); ylabel('Force (g)');
                title(sprintf('Table %d: Cycle %d Force vs Displacement (%s)', tbl_raw, c, mode_str), 'Color', fg); grid on;
                fmt_ax(f_export, gca); fmt_lgd(legend('Location', 'northwest')); hold off;
                saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Cycle%d_Stiffening_%s.png', sampleName, tbl_raw, c, mode_str)), EXPORT_DPI);
            end
            
            % ---- Tables 7+N..6+2N : Clean per cycle ----
            for c = 1:N
                tbl_clean = 6 + N + c;
                clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1 (1.5%)'); text(w_target_A, Pg_A{c}, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2 (3.3%)'); text(w_target_B, Pg_B{c}, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3 (5.0%)'); text(w_target_C, Pg_C{c}, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
                xlabel('Displacement (mm)'); ylabel('Force (g)');
                title(sprintf('Table %d: Cycle %d Clean Curves (%s)', tbl_clean, c, mode_str), 'Color', fg); grid on;
                fmt_ax(f_export, gca); fmt_lgd(legend('Location', 'northwest')); hold off;
                saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Cycle%d_Clean_%s.png', sampleName, tbl_clean, c, mode_str)), EXPORT_DPI);
            end
            
            % ---- Table 7+2N : Average ----
            tbl_avg = 7 + 2*N;
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export); hold on;
            plot(x_plot_avg, fit_L_avg, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading (Average)');
            plot(x_plot_avg, fit_R_avg, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery (Average)');
            plot(w_target_A, Pg_avg_A, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1 (1.5%)'); text(w_target_A, Pg_avg_A, sprintf(' E1:%.2f kPa', E_avg_A_kPa), 'Color', fg, 'FontWeight', 'bold');
            plot(w_target_B, Pg_avg_B, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2 (3.3%)'); text(w_target_B, Pg_avg_B, sprintf(' E2:%.2f kPa', E_avg_B_kPa), 'Color', fg, 'FontWeight', 'bold');
            plot(w_target_C, Pg_avg_C, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3 (5.0%)'); text(w_target_C, Pg_avg_C, sprintf(' E3:%.2f kPa', E_avg_C_kPa), 'Color', fg, 'FontWeight', 'bold');
            text(0.95, 0.05, text_str_avg, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
            xlabel('Displacement (mm)'); ylabel('Force (g)');
            title(sprintf('Table %d: Average of %d Cycles (%s)', tbl_avg, N, mode_str), 'Color', fg); grid on;
            fmt_ax(f_export, gca); fmt_lgd(legend('Location', 'northwest')); hold off;
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Cycles_Average_Clean_%s.png', sampleName, tbl_avg, mode_str)), EXPORT_DPI);
            
            % ---- Table 7+2N+1 : Composite 3-Row Summary ----
            tbl_comp = 7 + 2*N + 1;
            clf(f_export, 'reset'); set(0, 'CurrentFigure', f_export);
            set(f_export, 'Position', [100, 100, 1100, 900], 'Color', bg);
            
            ax14a = subplot(3, 2, [1, 2]);
            scatter(time_oct_sec, displacement_mm_inv, 8, 'r', 'o', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.7, 'DisplayName', 'Deformation -1');
            xlabel(ax14a, 'Time (s)'); ylabel(ax14a, 'Deformation x -1 (mm)');
            title(ax14a, sprintf('Row 1 — Deformation -1 (%s)', mode_str), 'Color', fg);
            grid(ax14a, 'on'); fmt_lgd(legend(ax14a, 'Location', 'northeast'));
            set(ax14a, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
            
            ax14b = subplot(3, 2, [3, 4]);
            scatter(time_oct_sec, force_interp_oct, 8, 'b', 'o', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.7, 'DisplayName', 'Force');
            xlabel(ax14b, 'Time (s)'); ylabel(ax14b, 'Force (g)');
            title(ax14b, sprintf('Row 2  — Force (%s)', mode_str), 'Color', fg);
            grid(ax14b, 'on'); fmt_lgd(legend(ax14b, 'Location', 'northeast'));
            set(ax14b, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
            
            ax14c = subplot(3, 2, 5);
            hold(ax14c, 'on');
            yyaxis(ax14c, 'left');  plot(ax14c, time_oct_sec, displacement_mm_inv, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Deformation -1');
            ylabel(ax14c, 'Deformation -1 (mm)');
            yyaxis(ax14c, 'right'); plot(ax14c, time_oct_sec, force_interp_oct, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Force');
            ylabel(ax14c, 'Force (g)');
            ax14c.YAxis(1).Color = 'r'; ax14c.YAxis(2).Color = 'b';
            xlabel(ax14c, 'Time (s)');
            title(ax14c, sprintf('Row 3A — Merged (%s)', mode_str), 'Color', fg);
            grid(ax14c, 'on'); set(ax14c, 'Color', bg, 'XColor', fg, 'GridColor', grid_clr);
            fmt_lgd(legend(ax14c, 'Location', 'northwest')); hold(ax14c, 'off');
            
            % -- Row 3B: Table 5 -- Hysteresis Evaluation --
            ax14d = subplot(3, 2, 6);
            hold(ax14d, 'on');
            plot(ax14d, displacement_mm_normal(idx_titik(1):idx_titik(n_pts)), ...
                 force_interp_oct(idx_titik(1):idx_titik(n_pts)), '-', 'Color', fg, 'LineWidth', 2, 'DisplayName', 'Total Profile');
            for c = 1:N
                plot(ax14d, disp_s{c}, force_s{c}, '-', 'Color', fg, 'LineWidth', 1.2, 'DisplayName', sprintf('Cycle %d', c));
            end
            for c = 1:N
                xA = target_A{c}; xB = target_B{c}; xC = target_C{c};
                [x_u, idx_u] = unique(disp_l{c});
                y_u = force_l{c}(idx_u);
                if length(x_u) >= 2
                    yA = interp1(x_u, y_u, xA, 'pchip', 'extrap');
                    yB = interp1(x_u, y_u, xB, 'pchip', 'extrap');
                    yC = interp1(x_u, y_u, xC, 'pchip', 'extrap');
                else
                    yA = Pg_A{c}; yB = Pg_B{c}; yC = Pg_C{c};
                end
                
                plot(ax14d, xA, yA, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(ax14d, xA, yA, sprintf(' E1:%.2f', E_A_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                
                plot(ax14d, xB, yB, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(ax14d, xB, yB, sprintf(' E2:%.2f', E_B_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                
                plot(ax14d, xC, yC, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(ax14d, xC, yC, sprintf(' E3:%.2f', E_C_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
            end
            xlabel(ax14d, 'Deformation Normal (mm)'); ylabel(ax14d, 'Force (g)');
            title(ax14d, sprintf('Row 3B — Table 5: Hysteresis (%s)', mode_str), 'Color', fg);
            grid(ax14d, 'on'); set(ax14d, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
            fmt_lgd(legend(ax14d, 'Location', 'northwest', 'FontSize', 6)); hold(ax14d, 'off');

            sgtitle(sprintf('Table %d: Composite Summary (%d Cycles) — %s', tbl_comp, N, mode_str), ...
                'Color', fg, 'FontWeight', 'bold', 'FontSize', 14);
            saveHighRes(f_export, fullfile(outDir_full, sprintf('%s_Table%d_Composite_Summary_%s.png', sampleName, tbl_comp, mode_str)), EXPORT_DPI);
            set(f_export, 'Position', [100, 100, 800, 600]);
        end
        close(f_export);
        
        % Full-Cycle Excel Export
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
            strain_col = [strain_col; {'E1_1.5%'; 'E2_3.3%'; 'E3_5.0%'}]; %#ok<AGROW>
            E_col  = [E_col;  E_A_kPa{c}; E_B_kPa{c}; E_C_kPa{c}]; %#ok<AGROW>
            tgt_col = [tgt_col; target_A{c}; target_B{c}; target_C{c}]; %#ok<AGROW>
            pg_col  = [pg_col;  Pg_A{c}; Pg_B{c}; Pg_C{c}]; %#ok<AGROW>
        end
        t7_sheet = table(cyc_col(:), strain_col(:), E_col(:), tgt_col(:), pg_col(:), ...
            'VariableNames', {'Cycle_Regime', 'Strain_Target_Name', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
        
        writetable(t1_sheet, filename_xls_full, 'Sheet', '1_Deformation_Normal');
        writetable(t2_sheet, filename_xls_full, 'Sheet', '2_Deformation_Inverted');
        writetable(t3_sheet, filename_xls_full, 'Sheet', '3_Force_Vector');
        writetable(t4_sheet, filename_xls_full, 'Sheet', '4_Merged_Plot');
        writetable(t5_sheet, filename_xls_full, 'Sheet', '5_Hysteresis_Eval');
        writetable(t6_sheet, filename_xls_full, 'Sheet', '6_Donut_Plot');
        writetable(t7_sheet, filename_xls_full, 'Sheet', '7_Strain_Stiffening');


        % --------------------------------------------------------------------
        % B. ISOLATED PER-CYCLE EXPORTS (Folders: Cycle_1, Cycle_2, ..., Cycle_N)
        % --------------------------------------------------------------------
        for c = 1:N
            outDir_c = fullfile(outDir, sprintf('Cycle_%d', c));
            if ~exist(outDir_c, 'dir'), mkdir(outDir_c); end
            
            % Sliced time range for cycle c
            idx_start_c = idx_titik(2*c - 1);
            idx_end_c   = idx_titik(2*c + 1);
            time_c      = time_oct_sec(idx_start_c:idx_end_c) - time_oct_sec(idx_start_c); % Re-zero to 0s
            disp_norm_c = displacement_mm_normal(idx_start_c:idx_end_c);
            disp_inv_c  = displacement_mm_inv(idx_start_c:idx_end_c);
            force_c     = force_interp_oct(idx_start_c:idx_end_c);
            
            % Donut coords isolated for cycle c
            n_pts_c = length(time_c);
            theta_c = linspace(0, 2*pi, n_pts_c)';
            R_disp_c = 100 + (disp_inv_c * 100);
            [X_disp_c, Y_disp_c] = pol2cart(theta_c, R_disp_c);
            
            f_export_c = figure('Visible', 'off', 'Position', [100, 100, 800, 600]);
            
            for m_idx = 1:2
                mode_str = modes{m_idx};
                if m_idx == 2
                    bg = 'k'; fg = 'w'; grid_clr = [0.4 0.4 0.4];
                else
                    bg = 'w'; fg = 'k'; grid_clr = [0.8 0.8 0.8];
                end
                fmt_ax  = @(f, ax) [set(f, 'Color', bg), set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr)];
                fmt_lgd = @(lgd) set(lgd, 'TextColor', fg, 'Color', bg, 'EdgeColor', fg, 'FontSize', 7);
                
                % ---- Table 1 (Cycle c) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                plot(time_c, disp_norm_c, 'r-', 'LineWidth', 1.5);
                title(sprintf('Table 1: Deformation Normal — Cycle %d (%s)', c, mode_str), 'Color', fg);
                xlabel('Time (s)'); ylabel('Deformation (mm)'); grid on; hold off;
                fmt_ax(f_export_c, gca);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table1_Deformation_%s.png', sampleName, mode_str)), EXPORT_DPI);
                
                % ---- Table 2 (Cycle c) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                plot(time_c, disp_inv_c, 'r-', 'LineWidth', 1.5);
                title(sprintf('Table 2: Deformation -1 — Cycle %d (%s)', c, mode_str), 'Color', fg);
                xlabel('Time (s)'); ylabel('Deformation x -1 (mm)'); grid on; hold off;
                fmt_ax(f_export_c, gca);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table2_Deformation_Inv_%s.png', sampleName, mode_str)), EXPORT_DPI);
                
                % ---- Table 3 (Cycle c) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                plot(time_c, force_c, 'b-', 'LineWidth', 1.5);
                title(sprintf('Table 3: Force Telemetry — Cycle %d (%s)', c, mode_str), 'Color', fg);
                xlabel('Time (s)'); ylabel('Force (g)'); grid on; hold off;
                fmt_ax(f_export_c, gca);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table3_Force_Vector_%s.png', sampleName, mode_str)), EXPORT_DPI);
                
                % ---- Table 4 (Cycle c) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                yyaxis left;  plot(time_c, disp_inv_c, 'r-', 'LineWidth', 1.5);
                ylabel('Deformation -1 (mm)');
                yyaxis right; plot(time_c, force_c, 'b-', 'LineWidth', 1.5);
                ylabel('Force Vector (g)');
                ax4 = gca; ax4.YAxis(1).Color = 'r'; ax4.YAxis(2).Color = 'b';
                xlabel('Time (s)'); title(sprintf('Table 4: Deformation x Force Merged — Cycle %d (%s)', c, mode_str), 'Color', fg); grid on; hold off;
                fmt_ax(f_export_c, ax4);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table4_Deformation_Force_Merged_%s.png', sampleName, mode_str)), EXPORT_DPI);
                
                % ---- Table 5 (Cycle c Hysteresis) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                plot(disp_s{c}, force_s{c}, '-', 'Color', fg, 'LineWidth', 2.0, 'DisplayName', sprintf('Cycle %d Profile', c));
                xA = target_A{c}; xB = target_B{c}; xC = target_C{c};
                plot(xA, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(xA, Pg_A{c}, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                plot(xB, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(xB, Pg_B{c}, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                plot(xC, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(xC, Pg_C{c}, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                xlabel('Deformation Normal (mm)'); ylabel('Force (g)');
                title(sprintf('Table 5: Hysteresis Evaluation — Cycle %d (%s)', c, mode_str), 'Color', fg);
                grid on; fmt_lgd(legend('Location', 'northwest')); hold off;
                fmt_ax(f_export_c, gca);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table5_Hysteresis_Evaluation_%s.png', sampleName, mode_str)), EXPORT_DPI);
                
                % ---- Table 6 (Cycle c Donut Layout) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                plot(X_disp_c, Y_disp_c, 'r-', 'LineWidth', 2);
                axis equal; grid on;
                title(sprintf('Table 6: Donut Spatial Layout — Cycle %d (%s)', c, mode_str), 'Color', fg); hold off;
                fmt_ax(f_export_c, gca);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table6_Donut_Table_%s.png', sampleName, mode_str)), EXPORT_DPI);
                
                % ---- Table 7 (Cycle c Fit Raw) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                scatter(disp_l_sh{c}, force_l{c}, 20, [0.7 0.7 1], 'filled', 'DisplayName', 'Raw Loading Data');
                scatter(disp_r_sh{c}, force_r{c}, 20, [1 0.7 0.7], 'filled', 'DisplayName', 'Raw Recovery Data');
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1 (1.5%)'); text(w_target_A, Pg_A{c}, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2 (3.3%)'); text(w_target_B, Pg_B{c}, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3 (5.0%)'); text(w_target_C, Pg_C{c}, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
                xlabel('Displacement (mm)'); ylabel('Force (g)');
                title(sprintf('Table 7: Cycle %d Force vs Displacement (%s)', c, mode_str), 'Color', fg); grid on;
                fmt_ax(f_export_c, gca); fmt_lgd(legend('Location', 'northwest')); hold off;
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table7_Cycle%d_Stiffening_%s.png', sampleName, c, mode_str)), EXPORT_DPI);
                
                % ---- Table 8 (Cycle c Clean Curves) ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c); hold on;
                plot(x_plot_c{c}, fit_L_c{c}, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Loading');
                plot(x_plot_c{c}, fit_R_c{c}, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Fit: Recovery');
                plot(w_target_A, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Target E1 (1.5%)'); text(w_target_A, Pg_A{c}, sprintf(' E1:%.2f kPa', E_A_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_B, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Target E2 (3.3%)'); text(w_target_B, Pg_B{c}, sprintf(' E2:%.2f kPa', E_B_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                plot(w_target_C, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'Target E3 (5.0%)'); text(w_target_C, Pg_C{c}, sprintf(' E3:%.2f kPa', E_C_kPa{c}), 'Color', fg, 'FontWeight', 'bold');
                text(0.95, 0.05, text_str_c{c}, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', bg, 'EdgeColor', fg, 'Color', fg, 'FontWeight', 'bold');
                xlabel('Displacement (mm)'); ylabel('Force (g)');
                title(sprintf('Table 8: Cycle %d Clean Curves (%s)', c, mode_str), 'Color', fg); grid on;
                fmt_ax(f_export_c, gca); fmt_lgd(legend('Location', 'northwest')); hold off;
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table8_Cycle%d_Clean_%s.png', sampleName, c, mode_str)), EXPORT_DPI);
                
                % ---- Table 9 (Table 14 Equivalent): Composite Summary for Cycle c ----
                clf(f_export_c, 'reset'); set(0, 'CurrentFigure', f_export_c);
                set(f_export_c, 'Position', [100, 100, 1100, 900], 'Color', bg);
                
                ax14a = subplot(3, 2, [1, 2]);
                scatter(time_c, disp_inv_c, 8, 'r', 'o', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.7, 'DisplayName', 'Deformation -1');
                xlabel(ax14a, 'Time (s)'); ylabel(ax14a, 'Deformation x -1 (mm)');
                title(ax14a, sprintf('Row 1 — Deformation -1 — Cycle %d (%s)', c, mode_str), 'Color', fg);
                grid(ax14a, 'on'); fmt_lgd(legend(ax14a, 'Location', 'northeast'));
                set(ax14a, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
                
                ax14b = subplot(3, 2, [3, 4]);
                scatter(time_c, force_c, 8, 'b', 'o', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.7, 'DisplayName', 'Force');
                xlabel(ax14b, 'Time (s)'); ylabel(ax14b, 'Force (g)');
                title(ax14b, sprintf('Row 2  — Force — Cycle %d (%s)', c, mode_str), 'Color', fg);
                grid(ax14b, 'on'); fmt_lgd(legend(ax14b, 'Location', 'northeast'));
                set(ax14b, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
                
                ax14c = subplot(3, 2, 5);
                hold(ax14c, 'on');
                yyaxis(ax14c, 'left');  plot(ax14c, time_c, disp_inv_c, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Deformation -1');
                ylabel(ax14c, 'Deformation -1 (mm)');
                yyaxis(ax14c, 'right'); plot(ax14c, time_c, force_c, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Force');
                ylabel(ax14c, 'Force (g)');
                ax14c.YAxis(1).Color = 'r'; ax14c.YAxis(2).Color = 'b';
                xlabel(ax14c, 'Time (s)');
                title(ax14c, sprintf('Row 3A — Merged — Cycle %d (%s)', c, mode_str), 'Color', fg);
                grid(ax14c, 'on'); set(ax14c, 'Color', bg, 'XColor', fg, 'GridColor', grid_clr);
                fmt_lgd(legend(ax14c, 'Location', 'northwest')); hold(ax14c, 'off');
                
                ax14d = subplot(3, 2, 6);
                hold(ax14d, 'on');
                plot(ax14d, disp_s{c}, force_s{c}, '-', 'Color', fg, 'LineWidth', 2, 'DisplayName', sprintf('Cycle %d Profile', c));
                plot(ax14d, xA, Pg_A{c}, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(ax14d, xA, Pg_A{c}, sprintf(' E1:%.2f', E_A_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                plot(ax14d, xB, Pg_B{c}, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(ax14d, xB, Pg_B{c}, sprintf(' E2:%.2f', E_B_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                plot(ax14d, xC, Pg_C{c}, 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 6, 'HandleVisibility', 'off');
                text(ax14d, xC, Pg_C{c}, sprintf(' E3:%.2f', E_C_kPa{c}), 'Color', fg, 'FontSize', 7, 'FontWeight', 'bold');
                xlabel(ax14d, 'Deformation Normal (mm)'); ylabel(ax14d, 'Force (g)');
                title(ax14d, sprintf('Row 3B — Table 5: Hysteresis — Cycle %d (%s)', c, mode_str), 'Color', fg);
                grid(ax14d, 'on'); set(ax14d, 'Color', bg, 'XColor', fg, 'YColor', fg, 'GridColor', grid_clr);
                fmt_lgd(legend(ax14d, 'Location', 'northwest', 'FontSize', 6)); hold(ax14d, 'off');
                
                sgtitle(sprintf('Table 9: Composite Summary — Cycle %d — %s', c, mode_str), ...
                    'Color', fg, 'FontWeight', 'bold', 'FontSize', 14);
                saveHighRes(f_export_c, fullfile(outDir_c, sprintf('%s_Table9_Composite_Summary_Cycle%d_%s.png', sampleName, c, mode_str)), EXPORT_DPI);
                set(f_export_c, 'Position', [100, 100, 800, 600]);
            end
            close(f_export_c);
            
            % Single-Cycle Excel Export
            filename_xls_c = fullfile(outDir_c, sprintf('%s_Cycle%d_Output.xlsx', sampleName, c));
            t1_sheet_c = table(time_c(:), disp_norm_c(:), 'VariableNames', {'Time_Seconds', 'Deformation_Normal_mm'});
            t2_sheet_c = table(time_c(:), disp_inv_c(:), 'VariableNames', {'Time_Seconds', 'Deformation_Inverted_mm'});
            t3_sheet_c = table(time_c(:), force_c(:), 'VariableNames', {'Time_Seconds', 'Force_Vector_g'});
            t4_sheet_c = table(time_c(:), disp_inv_c(:), force_c(:), 'VariableNames', {'Time_Seconds', 'Deformation_Inverted_mm', 'Force_Vector_g'});
            t5_sheet_c = table({sprintf('Cycle %d', c)}, E_kPa_B(c), tgt_B(c), P_g_B(c), ...
                'VariableNames', {'Evaluation_Regime', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
            t6_sheet_c = table(theta_c(:), X_disp_c(:), Y_disp_c(:), 'VariableNames', {'Theta_Radians', 'Cartesian_X', 'Cartesian_Y'});
            t7_sheet_c = table({sprintf('Cycle %d', c); sprintf('Cycle %d', c); sprintf('Cycle %d', c)}, ...
                {'E1_1.5%'; 'E2_3.3%'; 'E3_5.0%'}, ...
                [E_A_kPa{c}; E_B_kPa{c}; E_C_kPa{c}], ...
                [target_A{c}; target_B{c}; target_C{c}], ...
                [Pg_A{c}; Pg_B{c}; Pg_C{c}], ...
                'VariableNames', {'Cycle_Regime', 'Strain_Target_Name', 'Stiffness_Value_kPa', 'Evaluation_Strain_Target_mm', 'Extracted_Force_Value_g'});
            
            writetable(t1_sheet_c, filename_xls_c, 'Sheet', '1_Deformation_Normal');
            writetable(t2_sheet_c, filename_xls_c, 'Sheet', '2_Deformation_Inverted');
            writetable(t3_sheet_c, filename_xls_c, 'Sheet', '3_Force_Vector');
            writetable(t4_sheet_c, filename_xls_c, 'Sheet', '4_Merged_Plot');
            writetable(t5_sheet_c, filename_xls_c, 'Sheet', '5_Hysteresis_Eval');
            writetable(t6_sheet_c, filename_xls_c, 'Sheet', '6_Donut_Plot');
            writetable(t7_sheet_c, filename_xls_c, 'Sheet', '7_Strain_Stiffening');
        end
        
        drawnow; 
    end

    %% Function: High Resolution Figure Exporter (DPI Support)
    function saveHighRes(fig_handle, filepath, dpi)
        try
            exportgraphics(fig_handle, filepath, 'Resolution', dpi);
        catch
            print(fig_handle, filepath, '-dpng', sprintf('-r%d', dpi));
        end
    end

    %% Function: Power Law Fitting (Loading & Recovery)
    function [a_L, b_L, a_R, b_R, x_plot, fit_L, fit_R, x_max] = fit_power_law(disp_l, force_l, disp_r, force_r)
        x_L = disp_l - min(disp_l); y_L = force_l;
        x_R = disp_r - min(disp_l); y_R = force_r;
        x_max = max(x_L); y_max = max(y_L);
        
        valid_L = (x_L > 1e-4 & y_L > 1e-4);
        if sum(valid_L) > 2
            p_L = polyfit(log(x_L(valid_L)), log(y_L(valid_L)), 1);
            b_L = max(1.5, p_L(1));
        else
            b_L = 1.5;
        end
        a_L = y_max / (x_max^b_L);
        
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
        a_R = y_max / (x_max^b_R);
        
        x_plot = linspace(0, x_max, 100)';
        fit_L = a_L * (x_plot.^b_L);
        fit_R = a_R * (x_plot.^b_R);
    end
end
