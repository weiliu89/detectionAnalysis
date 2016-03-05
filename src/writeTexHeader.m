function writeTexHeader(outdir, detname)


if ~exist(outdir, 'file'), mkdir(outdir); end;
global fid 
fid = fopen(fullfile(outdir, ['header.tex']), 'w');

pr('The \\textbf{%s} detector is analyzed. This is an automatically created document.\n\n', detname);

fclose(fid);

function pr(varargin)
global fid;
fprintf(fid, varargin{:});
