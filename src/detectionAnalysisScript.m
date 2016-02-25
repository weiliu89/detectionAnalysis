function detectionAnalysisScript(detname, detpath, resultdir, dataset)
% detectionAnalysisScript (main script)

if nargin < 1
    fprintf(['Usage: detectionAnalysisScript(detname, detpath, dataset)\n',...
        '  - detname: name of the detector to be analyzed\n',...
        '  - detpath: detection file pattern\n',...
        '  - resultdir: directory of storing the analysis results\n',...
        '  - dataset: ''voc'', ''voc_compatible'' or ''ilsvrc''\n']);
    return;
end

DO_TP_ANALYSIS = 1;  % initial TP analysis; run first
DO_FP_ANALYSIS = 1;  % initial FP analysis; run first
DO_TP_DISPLAY = 1;   % display TP analysis
DO_FP_DISPLAY = 1;   % display FP analysis
DO_DISPLAY_TOP_FP = 0; % requires both this and DO_FP_DISPLAY to be set, not required for pots
DO_TEX = 1;

% options below are for visualization, not required for plots
DO_SHOW_SURPRISING_LOW_CONFIDENCE_DETECTIONS = 0;
DO_SHOW_SURPRISING_MISSES = 0;

SKIP_SAVED_FILES = 1; % set true to not overwrite any analysis results

NORM_FRACT = 0.15; % parameter for setting normalized precision (default = 0.15)

displayname = strrep(detname, '_', '-');
if nargin < 2 || isempty(detpath)
    % use default configuration
    [detpath, resultdir, detname] = setDetectorInfo(detname);
end
if nargin < 3
    resultdir = sprintf('../results/%s', detname);
end
% type of dataset
%   use 'voc' for any VOC dataset
%   use 'voc_compatible' if readDatasetAnnotations/readDetections produce
%      structures that are the same as those produced for VOC
%   use 'ilsvrc' for ILSVRC dataset
if nargin < 4
    dataset = 'voc';
end

dataset_params = setDatasetParameters(dataset);
objnames_all = dataset_params.objnames_all;
objnames_extra = dataset_params.objnames_extra;

objnames_selected  = objnames_all;  % objects to analyze (could be a subset)

tp_display_localization = 'strong'; % set to 'weak' to do analysis ignoring localization error

%%%%%%%%%%%%% Below this line should not require editing %%%%%%%%%%%%%%%%%

fprintf('\nevaluating detector %s\n\n', detname);

% sets detector paths, may need to be modified for your detector
dataset_params.detpath = detpath;
if ~exist(resultdir, 'file'), mkdir(resultdir); end;

% reads the records, attaches annotations: requires modification if not using VOC2007
ann = readDatasetAnnotations(dataset, dataset_params);

if isempty(gcp('nocreate'))
    % If parfor complains that it cannot allocate 20 workers. Go to
    % preferences > Parallel Computing Toolbox > Cluster Profile Manager
    % Click Edit and change the NumWorkers to 20.
    % If you do not want to use these many workers, simply comment the
    % following line and change parfor to for.
    parpool(20);
end
parfor o = 1:numel(objnames_selected)
    objname = objnames_selected{o};
    %% Analyze true positives and their detection confidences
    % Get overall and individual AP and PR curves for: occlusion, part visible,
    % side visible, aspect ratio, and size.  For aspect ratio, split into
    % bottom 10%, 10-30%, middle 40%, 70-90%, and top 10%.  Same for size
    % (measured in terms of height).  For AP, compute confidence interval (it
    % is a mean of confidence).
    if DO_TP_ANALYSIS
        outdir = resultdir;
        
        outfile_weak = fullfile(outdir, sprintf('results_%s_weak.mat', objname));
        outfile_strong = fullfile(outdir, sprintf('results_%s_strong.mat', objname));
        if ~exist(outfile_weak, 'file') || ~exist(outfile_strong, 'file') || ~SKIP_SAVED_FILES
            
            disp(objname)
            % read ground truth and detections, needs to be modified if not using VOC
            det = readDetections(dataset, dataset_params, ann, objname);
            
            outdir = resultdir;
            if ~exist(outdir, 'file'), mkdir(outdir); end;
            
            nposNorm = NORM_FRACT*det.nimages;
            
            % Creates precision-recall curves for various subsets of objects:
            % may need to be modified for new datasets or criteria
            if ~exist(outfile_weak, 'file') || ~SKIP_SAVED_FILES
                result = analyzeTrueDetections(dataset, dataset_params, objname, det, ann, nposNorm, 'weak');
                parsave(fullfile(outdir, sprintf('results_%s_weak.mat', objname)), result);
            end
            
            if ~exist(outfile_strong, 'file') || ~SKIP_SAVED_FILES
                result = analyzeTrueDetections(dataset, dataset_params, objname, det, ann, nposNorm, 'strong');
                parsave(fullfile(outdir, sprintf('results_%s_strong.mat', objname)), result);
            end
        end
    end
    
    %% False positive analysis
    if DO_FP_ANALYSIS
        % for each object
        outfile = fullfile(outdir, sprintf('results_fp_%s.mat', objname));
        if ~exist(outfile, 'file') || ~SKIP_SAVED_FILES
            o_ind = find(strcmp(objnames_all, objname));
            
            % Read detections
            det = readDetections(dataset, dataset_params, ann, objname);
            
            nposNorm = NORM_FRACT*det.nimages;
            
            if ~exist(outdir, 'file'), mkdir(outdir); end;
            
            % Get indices of similar objects
            allsimilar = dataset_params.similar_classes;
            similar_ind = [];
            for k = 1:numel(allsimilar),
                if any(allsimilar{k}==o_ind)
                    similar_ind = union(similar_ind, setdiff(allsimilar{k}, o_ind));
                end
            end
            similar_ind = similar_ind';
            
            % Analyze FP
            result_fp = analyzeFalsePositives(dataset, dataset_params, ann, o_ind, similar_ind, det, nposNorm);
            result_fp.name = objname;
            result_fp.o = o_ind;
            cc = result_fp.confuse_count;
            fprintf('%s:\tloc=%d  bg=%d  similar=%d  other=%d\n', objname, cc.loc(1), cc.bg(1), cc.similarobj(1), cc.otherobj(1));
            parsave(fullfile(outdir, sprintf('results_fp_%s.mat', objname)), result_fp);
        end
    end
end


%% Create plots and .txt files for true positive analysis
if DO_TP_DISPLAY && strcmp(dataset, 'voc')
    localization = tp_display_localization;
    outfile = fullfile(resultdir, sprintf('missed_object_characteristics_%s_%s.txt', detname, localization));
    if ~exist(outfile, 'file') || ~SKIP_SAVED_FILES
        detail_subset = [1 4 5 6]; % objects for which to create per-object detailed plots
        plotnames = {'occlusion', 'area', 'height', 'aspect', 'truncation', 'parts', 'view'};
        
        clear result;
        for o = 1:numel(objnames_extra)
            tmp = load(fullfile(resultdir, sprintf('results_%s_%s.mat', objnames_extra{o}, localization)));
            results(o) = tmp.result;
        end
        
        % Create plots for all objects and write out the first five plots
        displayPerCharacteristicPlots(results, displayname)
        for f = 1:5
            set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 8.5 2.5]);
            print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', plotnames{f}, localization)));
        end
        
        % Create plots for a selection of objects and write out parts/view (6/7)
        if ~isempty(detail_subset)
            displayPerCharacteristicPlots(results(detail_subset), displayname);
            for f = 6:7
                set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 8.5 2.5]);
                print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', plotnames{f}, localization)));
            end
        end
        
        % Create plots for all characteristics for each object
        displayCharacteristicPerClassPlots(results, displayname);
        for f = 1:numel(objnames_extra)
            set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 8 2.5]);
            print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', objnames_extra{f}, localization)));
        end
        
        % Display summary of sensitivity and impact
        displayAverageSensitivityImpactPlot(results, displayname);
        f=1;set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 4 2.75]);
        print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', 'impact', localization)));
        
        
        % Write text file of missed object characteristics
        writeMissedObjectCharacteristics(results, detname, outfile);
    end
end

if DO_SHOW_SURPRISING_LOW_CONFIDENCE_DETECTIONS
    % Save the object examples that are classified less well than predicted
    nimages = 15;
    if ~exist(fullfile(resultdir, 'tp'), 'file'), mkdir(fullfile(resultdir, 'tp')); end;
    objnames = intersect(objnames_selected, objnames_extra);
    for o = 1:numel(objnames)
        tmp = load(fullfile(resultdir, sprintf('results_%s_%s.mat', objnames{o}, localization)), 'result');
        displayGtConfidencePredictions(dataset_params.imdir, ann.rec, tmp.result, fullfile(resultdir, 'tp'), nimages);
    end
end

if DO_SHOW_SURPRISING_MISSES
    localization = 'strong';
    objnames = intersect(objnames_selected, objnames_extra);
    for o = 1:numel(objnames)
        tmp = load(fullfile(resultdir, sprintf('results_%s_%s.mat', objnames{o}, localization)), 'result');
        showSurprisingMisses(dataset_params.imdir, ann.rec, tmp.result); % for displaying unlikely misses
    end
end

%% Write summaries of false positive displays
if DO_FP_DISPLAY
    
    fpfile = fullfile(resultdir, sprintf('false_positive_analysis_%s.txt', detname));
    if ~exist(fpfile, 'file') || ~SKIP_SAVED_FILES
        clear result_fp det gt;
        for o = 1:numel(objnames_selected)
            objname = objnames_selected{o};
            tmp = load(fullfile(resultdir, sprintf('results_fp_%s.mat', objname)));
            if ~isfield(tmp.result, 'ignoresimilar')
                tmp.result.ignoresimilar.ap = -1; tmp.result.ignoresimilar.apn = -1;
                tmp.result.onlysimilar.ap = -1;  tmp.result.onlysimilar.apn = -1;
            end
            results_fp(o) = orderfields(tmp.result);
            
            % display top false positives
            if DO_DISPLAY_TOP_FP
                
                % read detections
                det = readDetections(dataset, dataset_params, ann, objname);
                
                nimages = 20;
                if ~exist(fullfile(resultdir, 'fp'), 'dir')
                    mkdir(fullfile(resultdir, 'fp'));
                end;
                displayTopFP(dataset, dataset_params, ann, objnames_selected{o}, results_fp(o), det, fullfile(resultdir, 'fp'), nimages);
            end
            
        end
        
        % plot impact summary
        if numel(objnames_selected)==numel(objnames_all)
            % sets are grouped into all, animals, vehicles, furniture
            sets = cat(2, num2cell(1:numel(objnames_all)), dataset_params.summary_sets);
            setnames = cat(2, objnames_all, dataset_params.summary_setnames);
        else
            sets = num2cell(1:numel(objnames_selected));
            setnames = objnames_selected;
        end
        for f = 1:numel(sets)
            displayFalsePositiveImpactPlot(results_fp(sets{f}), '', setnames{f});
            set(1, 'PaperUnits', 'inches'); set(1, 'PaperSize', [8.5 11]); set(1, 'PaperPosition', [0 11-1.5 3 1.5]);
            print('-dpdf', '-f1', fullfile(resultdir, sprintf('plots_fp_%s.pdf', setnames{f})));
            set(2, 'PaperUnits', 'inches'); set(2, 'PaperSize', [8.5 11]); set(2, 'PaperPosition', [0 11-3 3 3]);
            print('-dpdf', '-f2', fullfile(resultdir, sprintf('plots_fp_pie_%s.pdf', setnames{f})));
            
            nfp = [25 50 100 200 400 800 1600 3200];
            displayFPTrend(results_fp(sets{f}), nfp, setnames{f});
            set(3, 'PaperUnits', 'inches'); set(3, 'PaperSize', [8.5 11]); set(3, 'PaperPosition', [0 11-6 6 6]);
            print('-dpdf', '-f3', fullfile(resultdir, sprintf('plots_fp_trendarea_%s.pdf', setnames{f})));
            set(4, 'PaperUnits', 'inches'); set(4, 'PaperSize', [8.5 11]); set(4, 'PaperPosition', [0 11-6 6 6]);
            print('-dpdf', '-f4', fullfile(resultdir, sprintf('plots_fp_trendline_%s.pdf', setnames{f})));
            set(5, 'PaperUnits', 'inches'); set(5, 'PaperSize', [8.5 11]); set(5, 'PaperPosition', [0 11-6 6 6]);
            print('-dpdf', '-f5', fullfile(resultdir, sprintf('plots_fp_trendline_nl_%s.pdf', setnames{f})));
            
            tics = [1/8 1/4 1/2 1 2 4 8];
            displayDetectionTrend(results_fp(sets{f}), tics, setnames{f});
            set(3, 'PaperUnits', 'inches'); set(3, 'PaperSize', [8.5 11]); set(3, 'PaperPosition', [0 11-6 6 6]);
            print('-dpdf', '-f3', fullfile(resultdir, sprintf('plots_fp_dttrendarea_%s.pdf', setnames{f})));
            
        end
        
        % text summary
        writeFPAnalysisSummary(results_fp, objnames_selected, detname, fpfile);
    end
end
close all

if DO_TEX
    texdir = fullfile(resultdir, 'tex');
    if ~exist(texdir, 'dir'), mkdir(texdir); end;
    system(sprintf('cp ../results/*.tex %s', texdir));
    for o = 1:numel(objnames_selected)
        writeTexHeader(fullfile(resultdir, 'tex'), displayname)
        gt = [];
        if strcmp(dataset, 'voc')
            writeTexObject(objnames_selected{o}, fullfile(resultdir, 'tex'), ann.gt(o), DO_DISPLAY_TOP_FP);
        else
            writeTexObject(objnames_selected{o}, fullfile(resultdir, 'tex'),[]);
        end
    end
    system(sprintf('cd %s; find . -name "*.pdf" -print0 | xargs -P6 -0 -I file pdfcrop file file 1>NUL 2>NUL', resultdir));
    system(sprintf('cd %s; pdflatex detectionAnalysisAutoReportTemplate.tex 1>NUL 2>NUL', texdir));
    fprintf('Result is generated at: %s/detectionAnalysisAutoReportTemplate.pdf\n', texdir);
end
