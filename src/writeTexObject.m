function writeTexObject(name, outdir, gt)
% writeTexObject(name, outdir, gt)
% 
% Adds latex code to an existing file for one object:
%   * table displaying missed object characteristics (if gt is not empty)
%   * false positive trend plots
%   * examples of top false positives
%   * analysis of object characteristics
%   * difficult detections

if ~exist(outdir, 'file'), mkdir(outdir); end;
global fid 
fid = fopen(fullfile(outdir, [name '.tex']), 'w');

pr('\\section{%s}\n\n', name);

% create table 
if ~isempty(gt)
  pr('\\begin{verbatim}\n');
  pr('Characteristics: ntotal=%d ntrunc=%d \n', sum(~gt.isdiff), sum(gt.istrunc));
  if ~isempty(gt.details{1})
    details = cat(1, gt.details{:});
    pr('    occlevel: None=%d Low=%d Med=%d High=%d\n', hist([details.occ_level], 1:4));

    sv = [details.side_visible];
    names = fieldnames(details(1).side_visible);
    pr('    side visible: \n');
    for k = 1:numel(names)
      pr('        %s: Yes=%d  No=%d \n', names{k}, sum([sv.(names{k})]==1), sum([sv.(names{k})]==0));
    end
    pr('    part visible: \n');
    sv = [details.part_visible];
    names = fieldnames(details(1).part_visible);
    for k = 1:numel(names)
      pr('        %s: Yes=%d  No=%d \n', names{k}, sum([sv.(names{k})]==1), sum([sv.(names{k})]==0));
    end  
  end
  pr('\\end{verbatim}\n');
  pr('\n\n');  
end

if exist(fullfile(outdir(1:end-4), sprintf('plots_fp_trendarea_%s.pdf', name)), 'file')
  pr('\\begin{figure*}[hp]\n')
  pr('\\begin{center}\n');
  pr('\\begin{tabular}{c c}\n');
  pr('\\includegraphics[width=0.45\\textwidth]{../plots_fp_trendarea_%s.pdf} & \n', name); 
  pr('\\includegraphics[width=0.45\\textwidth]{../plots_fp_dttrendarea_%s.pdf} \\\\ \n', name);    
  pr('\\end{tabular}\n');
  pr('\\end{center}\n');  
  pr('\\caption{\\textbf{False positive/detection trends with rank.}  Left: stacked area plot showing fraction of FP of each type as the total number of FP increase. Right: type of detection as number of detections increases; line plots show recall as function of the number of objects (dashed=weak localization, solid=strong localization).}\n', name);
  pr('\\end{figure*}\n');

  pr('\n\n');
end

pr('\\begin{figure*}[hp]\n')
pr('\\begin{tabular}{c c c c c}\n');
for k = 1:20
  nstr = num2str(k+10000); 
  if mod(k, 5)==0
    pr('\\hspace{-0.17in}\n \\includegraphics[height=0.85in]{../fp/%s_fp_%s.pdf} \\\\ \n', name, nstr(2:end));
  else
    pr('\\hspace{-0.17in}\n\\includegraphics[height=0.85in]{../fp/%s_fp_%s.pdf} & \n', name, nstr(2:end));
  end
end 
pr('\\end{tabular}\n');
pr('\\caption{\\textbf{Examples of top %s false positives}}\n', name);
pr('\\end{figure*}\n');


pr('\n\n');

if exist(fullfile(outdir(1:end-4), sprintf('plots_%s_strong.pdf', name)), 'file')
  pr('\\begin{figure*}[hp]\n')
  pr('\\begin{center}\n');
  pr('\\includegraphics[width=\\textwidth]{../plots_%s_strong.pdf} \\\\ \n', name);  

  pr('\\end{center}\n');
  pr('\\caption{\\textbf{Analysis of %s characteristics: } APn (+) wtih standard error bars (red).  Black dashed lines indicate overall APn.  See paper for further details.}\n', name);
  pr('\\end{figure*}\n');

  pr('\n\n');
  
pr('\\begin{figure*}[hp]\n')
pr('\\begin{tabular}{c c c c c}\n');
fn = dir(fullfile(outdir(1:end-4), 'tp', sprintf('%s*.pdf', name)));
for k = 1:numel(fn)
  %nstr = num2str(k+10000); 
  if mod(k, 5)==0
    pr('\\hspace{-0.17in}\n \\includegraphics[height=0.85in]{../tp/%s} \\\\ \n', fn(k).name);
  else
    pr('\\hspace{-0.17in}\n \\includegraphics[height=0.85in]{../tp/%s} & \n', fn(k).name);
  end
end    
pr('\\end{tabular}\n');
pr('\\caption{\\textbf{Unexpectedly difficult %s detections: } Ground truth object is red; predicted confidence in italics; green box is highest scoring detection; blue box is highest scoring with overlap; detection confidence in upper-left corner.}\n', name);
pr('\\end{figure*}\n');
end
pr('\\clearpage\n');
fclose(fid);



function pr(varargin)
global fid;
fprintf(fid, varargin{:});
