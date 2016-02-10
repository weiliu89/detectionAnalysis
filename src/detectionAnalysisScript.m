% detectionAnalysisScript (main script)

DO_TP_ANALYSIS = 0;  % initial TP analysis; run first
DO_FP_ANALYSIS = 0;  % initial FP analysis; run first
DO_TP_DISPLAY = 0;   % display TP analysis
DO_FP_DISPLAY = 1;   % display FP analysis
DO_DISPLAY_TOP_FP = 1; % requires both this and DO_FP_DISPLAY to be set, not required for pots
DO_TEX = 1;

% options below are for visualization, not required for plots
DO_SHOW_SURPRISING_LOW_CONFIDENCE_DETECTIONS = 0;  
DO_SHOW_SURPRISING_MISSES = 1; 

SKIP_SAVED_FILES = 0; % set true to not overwrite any analysis results

NORM_FRACT = 0.15; % parameter for setting normalized precision (default = 0.15)

% type of dataset
%   use 'voc' for any VOC dataset
%   use 'voc_compatible' if readDatasetAnnotations/readDetections produce
%      structures that are the same as those produced for VOC
dataset = 'voc';  

% specify which detectors to evaluate
full_set = {'felzenszwalb_v2', 'felzenszwalb_v3', 'felzenszwalb_v4', 'vedaldi2009', 'cnn_v7-bb'}; % for reference
detectors = {'felzenszwalb_v4', 'vedaldi2009', 'cnn_v7-bb'};  % detectors that will be analyzed

dataset_params = setDatasetParameters(dataset);
objnames_all = dataset_params.objnames_all;
objnames_extra = dataset_params.objnames_extra;

objnames_selected  = objnames_all;  % objects to analyze (could be a subset)    
  
tp_display_localization = 'strong'; % set to 'weak' to do analysis ignoring localization error

%%%%%%%%%%%%% Below this line should not require editing %%%%%%%%%%%%%%%%%

for d = 1:numel(detectors)  % loops through each detector and performs analysis
  
  detector = detectors{d};
  fprintf('\nevaluating detector %s\n\n', detector);
  
  % sets detector paths, may need to be modified for your detector
  [dataset_params.detpath, resultdir, detname] = setDetectorInfo(detector); 
  if ~exist(resultdir, 'file'), mkdir(resultdir); end;
    
  % reads the records, attaches annotations: requires modification if not using VOC2007
  ann = readDatasetAnnotations(dataset, dataset_params);
  outdir = resultdir;

  %% Analyze true positives and their detection confidences
  % Get overall and individual AP and PR curves for: occlusion, part visible,
  % side visible, aspect ratio, and size.  For aspect ratio, split into
  % bottom 10%, 10-30%, middle 40%, 70-90%, and top 10%.  Same for size
  % (measured in terms of height).  For AP, compute confidence interval (it
  % is a mean of confidence).
  if DO_TP_ANALYSIS
    
    for o = 1:numel(objnames_selected)      
      objname = objnames_selected{o};
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
          save(fullfile(outdir, sprintf('results_%s_weak.mat', objname)), 'result');  
        end

        if ~exist(outfile_strong, 'file') || ~SKIP_SAVED_FILES
          result = analyzeTrueDetections(dataset, dataset_params, objname, det, ann, nposNorm, 'strong');
          save(fullfile(outdir, sprintf('results_%s_strong.mat', objname)), 'result');
        end
      end
    end
  end  

  %% False positive analysis
  if DO_FP_ANALYSIS
                   
    % for each object
    for o = 1:numel(objnames_selected)
      objname = objnames_selected{o}; 
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

        % Analyze FP                
        result_fp = analyzeFalsePositives(dataset, dataset_params, ann, o_ind, similar_ind, det, nposNorm);
        result_fp.name = objname;
        result_fp.o = o_ind;
        cc = result_fp.confuse_count;
        fprintf('%s:\tloc=%d  bg=%d  similar=%d  other=%d\n', objname, cc.loc(1), cc.bg(1), cc.similarobj(1), cc.otherobj(1));
        save(fullfile(outdir, sprintf('results_fp_%s.mat', objname)), 'result_fp');  
      end
    end
  end
   
 
  %% Create plots and .txt files for true positive analysis
  if DO_TP_DISPLAY
    
    localization = tp_display_localization; 
    outfile = fullfile(resultdir, sprintf('missed_object_characteristics_%s_%s.txt', detector, localization));
    if ~exist(outfile, 'file') || ~SKIP_SAVED_FILES
      detail_subset = [1 4 5 6]; % objects for which to create per-object detailed plots 
      plotnames = {'occlusion', 'area', 'height', 'aspect', 'truncation', 'parts', 'view'}; 

      
      clear result;
      for o = 1:numel(objnames_extra)
        tmp = load(fullfile(resultdir, sprintf('results_%s_%s.mat', objnames_extra{o}, localization)));
        result(o) = tmp.result;
      end

      % Create plots for all objects and write out the first five plots
      displayPerCharacteristicPlots(result, detname)
      for f = 1:5
        set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 8.5 2.5]);
        print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', plotnames{f}, localization)));
      end

      % Create plots for a selection of objects and write out parts/view (6/7)
      if ~isempty(detail_subset)
        displayPerCharacteristicPlots(result(detail_subset), detname);
        for f = 6:7
          set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 8.5 2.5]);
          print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', plotnames{f}, localization)));
        end    
      end

      % Create plots for all characteristics for each object
      displayCharacteristicPerClassPlots(result, detname);
      for f = 1:numel(objnames_extra)      
        set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 8 2.5]);
        print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', objnames_extra{f}, localization)));      
      end

      % Display summary of sensitivity and impact
      displayAverageSensitivityImpactPlot(result, detname);
      f=1;set(f, 'PaperUnits', 'inches'); set(f, 'PaperSize', [8.5 11]); set(f, 'PaperPosition', [0 11-3 4 2.75]);
      print('-dpdf', ['-f' num2str(f)], fullfile(resultdir, sprintf('plots_%s_%s.pdf', 'impact', localization)));    


      % Write text file of missed object characteristics
      writeMissedObjectCharacteristics(result, detector, ...
        fullfile(resultdir, sprintf('missed_object_characteristics_%s_%s.txt', detector, localization)));
    end 
  end
  
  if DO_SHOW_SURPRISING_LOW_CONFIDENCE_DETECTIONS
    % Save the object examples that are classified less well than predicted
    nimages = 15;
    if ~exist(fullfile(resultdir, 'tp'), 'file'), mkdir(fullfile(resultdir, 'tp')); end;
    objnames = intersect(objnames_selected, objnames_extra);
    for o = 1:numel(objnames)      
      load(fullfile(resultdir, sprintf('results_%s_%s.mat', objnames{o}, localization)), 'result');   
      displayGtConfidencePredictions(dataset_params.imdir, ann.rec, result, fullfile(resultdir, 'tp'), nimages);
    end
  end
  
  if DO_SHOW_SURPRISING_MISSES
    localization = 'strong';
    objnames = intersect(objnames_selected, objnames_extra);
    for o = 1:numel(objnames)
      load(fullfile(resultdir, sprintf('results_%s_%s.mat', objnames{o}, localization)), 'result');                  
      showSurprisingMisses(dataset_params.imdir, ann.rec, result); % for displaying unlikely misses
    end
  end
  
  %% Write summaries of false positive displays
  if DO_FP_DISPLAY
    clear result_fp det gt;
    for o = 1:numel(objnames_selected)
      objname = objnames_selected{o};
      tmp = load(fullfile(resultdir, sprintf('results_fp_%s.mat', objname)));
      if ~isfield(tmp.result_fp, 'ignoresimilar')
        tmp.result_fp.ignoresimilar.ap = -1; tmp.result_fp.ignoresimilar.apn = -1; 
        tmp.result_fp.onlysimilar.ap = -1;  tmp.result_fp.onlysimilar.apn = -1;
      end            
      result_fp(o) = orderfields(tmp.result_fp);              
            
      % display top false positives
      if DO_DISPLAY_TOP_FP
        
        % read detections
        det = readDetections(dataset, dataset_params, ann, objname);         
        
        nimages = 20;
        try; mkdir(fullfile(resultdir, 'fp')); catch; end;
        displayTopFP(dataset, dataset_params, ann, objnames_selected{o}, result_fp(o), det, fullfile(resultdir, 'fp'), nimages);          
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
      displayFalsePositiveImpactPlot(result_fp(sets{f}), '', setnames{f});
      set(1, 'PaperUnits', 'inches'); set(1, 'PaperSize', [8.5 11]); set(1, 'PaperPosition', [0 11-1.5 3 1.5]);   
      print('-dpdf', '-f1', fullfile(resultdir, sprintf('plots_fp_%s.pdf', setnames{f})));
      set(2, 'PaperUnits', 'inches'); set(2, 'PaperSize', [8.5 11]); set(2, 'PaperPosition', [0 11-3 3 3]);   
      print('-dpdf', '-f2', fullfile(resultdir, sprintf('plots_fp_pie_%s.pdf', setnames{f})));            
      
      nfp = [25 50 100 200 400 800 1600 3200];
      displayFPTrend(result_fp(sets{f}), nfp, setnames{f});
      set(3, 'PaperUnits', 'inches'); set(3, 'PaperSize', [8.5 11]); set(3, 'PaperPosition', [0 11-6 6 6]);   
      print('-dpdf', '-f3', fullfile(resultdir, sprintf('plots_fp_trendarea_%s.pdf', setnames{f})));            
      set(4, 'PaperUnits', 'inches'); set(4, 'PaperSize', [8.5 11]); set(4, 'PaperPosition', [0 11-6 6 6]);   
      print('-dpdf', '-f4', fullfile(resultdir, sprintf('plots_fp_trendline_%s.pdf', setnames{f})));                   
      set(5, 'PaperUnits', 'inches'); set(5, 'PaperSize', [8.5 11]); set(5, 'PaperPosition', [0 11-6 6 6]);   
      print('-dpdf', '-f5', fullfile(resultdir, sprintf('plots_fp_trendline_nl_%s.pdf', setnames{f})));                   
      
      tics = [1/8 1/4 1/2 1 2 4 8];
      displayDetectionTrend(result_fp(sets{f}), tics, setnames{f}); 
      set(3, 'PaperUnits', 'inches'); set(3, 'PaperSize', [8.5 11]); set(3, 'PaperPosition', [0 11-6 6 6]);   
      print('-dpdf', '-f3', fullfile(resultdir, sprintf('plots_fp_dttrendarea_%s.pdf', setnames{f})));            
      
    end   
    
    % text summary
    writeFPAnalysisSummary(result_fp, objnames_selected, detname, ...
      fullfile(resultdir, sprintf('false_positive_analysis_%s.txt', detector)));
       
  end
  
  if DO_TEX
    if ~exist(fullfile(resultdir, 'tex'), 'file'), mkdir(fullfile(resultdir, 'tex')); end;
    system(sprintf('cp ../results/*.tex %s', fullfile(resultdir, 'tex')));
    for o = 1:numel(objnames_selected)
      writeTexHeader(fullfile(resultdir, 'tex'), detname)
      gt = [];
      if strcmp(dataset, 'voc')
        writeTexObject(objnames_selected{o}, fullfile(resultdir, 'tex'), ann.gt(o)); 
      else
        writeTexObject(objnames_selected{o}, fullfile(resultdir, 'tex'),[]); 
      end
    end
  end
  
end

  
