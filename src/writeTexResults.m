function writeTexResults(outdir, mapfile)
% writeTexResults()
%
% Adds latex code to create a comparing table.
%

if ~exist(outdir, 'file'), mkdir(outdir); end;
global fid
fid = fopen(fullfile(outdir, ['results.tex']), 'w');

if ~exist(mapfile, 'file')
    return;
end
load(mapfile);
if ~exist('aps', 'var') || isempty(aps)
    return;
end

pr('\\begin{table}[ht]\\scriptsize\n');
pr('\\centering\n');
pr('\\setlength{\\tabcolsep}{0.8pt}\n');
pr('\\begin{tabular*}{\\textwidth}{l@{\\hspace{0.1cm}}ccccccccccccccccccccc}\n');
pr('\\toprule\n');
pr('\\noalign{\\smallskip}\n');
pr('\\textbf{System} & \\textbf{aero} & \\textbf{bike} & \\textbf{bird} & \\textbf{boat} & \\textbf{bottle} & \\textbf{bus} & \\textbf{car} & \\textbf{cat} & \\textbf{chair} & \\textbf{cow} & \\textbf{table} & \\textbf{dog} & \\textbf{horse} & \\textbf{mbike} & \\textbf{person} & \\textbf{plant} & \\textbf{sheep} & \\textbf{sofa} & \\textbf{train} & \\textbf{tv} & \\emph{mAP}\\\\ \\noalign{\\smallskip}\\cline{2-22}\n');
pr('\\noalign{\\smallskip}\n');
pr('Fast R-CNN & 77.0 & 78.1 & 69.3 & 59.4 & 38.3 & 81.6 & 78.6 & 86.7 & 42.8 & 78.8 & 68.9 & 84.7 & 82.0 & 76.6 & 69.9 & 31.8 & 70.1 & 74.8 & 80.4 & 70.4 & 70.0\\\\\n');
pr('Faster R-CNN & 76.5 & 79.0 & 70.9 & 65.5 & 52.1 & 83.1 & 84.7 & 86.4 & 52.0 & 81.9 & 65.7 & 84.8 & 84.6 & 77.5 & 76.7 & 38.8 & 73.6 & 73.9 & 83.0 & 72.6 & 73.2\\\\\n');
pr('\\hline\\hline\n');

% Write results for current detector.
pr('This detector');
for i = 1:length(aps)
    pr(' & %.1f', aps(i) * 100);
end
pr(' & %.1f\\\\\n', mean(aps) * 100);

pr('\\bottomrule\n');
pr('\\end{tabular*}\n');
pr('\\end{table}\n');

function pr(varargin)
global fid;
fprintf(fid, varargin{:});
