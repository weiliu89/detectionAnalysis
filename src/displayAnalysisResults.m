function displayAnalysisResults(results_all, titlename)

close all

drawline = true;
makeMultiCategoryPlot(1, results_all, 'occ', [titlename ': Occlusion'], 1, {'0', 'L', 'M', 'H'}, drawline);
makeMultiCategoryPlot(2, results_all, 'area', [titlename ': BBox Area'], 1, {'XS', 'S', 'M', 'L', 'XL'}, drawline);
makeMultiCategoryPlot(3, results_all, 'height', [titlename ': BBox Height'], 1, {'XS', 'S', 'M', 'L', 'XL'}, drawline);
makeMultiCategoryPlot(4, results_all, 'aspect', [titlename ': Aspect Ratio'], 1, {'XT', 'T', 'M', 'W', 'XW'}, drawline);
makeMultiCategoryPlot(5, results_all, 'truncated', [titlename ': Truncation'], 1, {'N', 'T'}, drawline);
f=5;

fs = 8;

% Visible parts
f=f+1;
tickstr = {};
np=0;

for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).part);
  for p = 1:numel(pnames)
    np=np+1;
    results_all(o).tmp((p-1)*2+(1:2)) = results_all(o).part.(pnames{p});    
    %tickstr(end+1) = {sprintf('%s\non/off', pnames{p})};
  end  
end
drawline = false;
makeMultiCategoryPlot(f, results_all, 'tmp', [titlename ': Parts Visible'], 1, tickstr, drawline);
n=0;
for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).part);
  n=n+1;
  for p = 1:numel(pnames)
    name = pnames{p}; if numel(name)>5, name = removeVowels(name); end;
    text(n+1, -0.05, sprintf('%s\n0/1', name), 'fontsize', fs);
    n = n+2;
  end
end
results_all = rmfield(results_all, 'tmp');

% Visible sides
f=f+1;
tickstr = {};
np=0;
for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).side);
  for p = 1:numel(pnames)
    np=np+1;
    results_all(o).tmp((p-1)*2+(1:2)) = results_all(o).side.(pnames{p});    
    %tickstr(end+1) = {sprintf('%s\non/off', pnames{p})};
  end  
end
drawline = false;
makeMultiCategoryPlot(f, results_all, 'tmp', [titlename ': Sides Visible'], 1, tickstr, drawline);
n=0;
for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).side);
  n=n+1;
  for p = 1:numel(pnames)
    name = pnames{p}; if numel(name)>5, name = removeVowels(name); end;
    text(n+1, -0.05, sprintf('%s\n0/1', name), 'fontsize', fs);
    n = n+2;
  end
end
results_all = rmfield(results_all, 'tmp');



function makeMultiCategoryPlot(f, results, rname, title_str, xtickstep, xticklab, drawline)

fs = 10;
setupplot(f);

nobj = numel(results);

rangex = 0;
maxy = 0;
xticks = [];
firsttick = zeros(nobj,1);
for o = 1:nobj
  result = results(o);
  nres = numel(results(o).(rname));
  rangex = rangex(end)+1+(1:nres);
  plotapnbars(result.(rname), rangex, drawline);
  maxy = max(maxy, round(max(([result.(rname).apn]+0.15))*10)/10);
  h=plot(rangex([1 end]), [1 1]*result.all.apn, 'k--', 'linewidth', 1);  
  firsttick(o) = rangex(1);
  xticks = [xticks rangex(1:xtickstep:end)];  
end  
maxy = min(maxy, 1);
if numel(xticklab)==nres
  xticklab = repmat(xticklab, [1 nobj]);
end
axis([0 rangex(end)+1 0 maxy]);
for o = 1:numel(results)
  if strcmp(results(o).name, 'diningtable')
    results(o).name = 'table';
  elseif strcmp(results(o).name, 'aeroplane')
    results(o).name = 'airplane';
  end
  text(firsttick(o), maxy-0.05, results(o).name, 'fontsize', fs);
end
title(title_str, 'fontsize', fs);
set(gca, 'xtick', xticks); 
%set(gca, 'ytick', 0:0.1:maxy); 
set(gca, 'xticklabel', xticklab);
set(gca, 'ygrid', 'on')
set(gca, 'xgrid', 'on')
set(gca, 'fontsize', fs);
set(gca, 'ticklength', [0.001 0.001]);


function plotapnbars(resall, x, drawline)
for k = 1:numel(resall)
  res =resall(k);
  if isnan(res.apn), res.apn = 0; end
  if ~isnan(res.apn_stderr)
    errorbar(x(k), res.apn, res.apn_stderr, 'r', 'linewidth', 1);
  end
  hold on;
  plot(x(k), res.apn, '+', 'linewidth', 1, 'markersize', 5);  
  text(x(k)+0.12, res.apn, sprintf('%0.2f', res.apn), 'fontsize', 8);  
end
if drawline
  plot(x, [resall.apn], 'b-', 'linewidth', 1);
else % draw every other
  for i=1:2:numel(x)
    plot(x([i i+1]), [resall([i i+1]).apn], 'b-', 'linewidth', 1);
  end
end
%axis([0 x(end+1) numel(resall)+1 0 ceil(max([resall.apn]+[resall.apn_stderr]+0.1)*10)/10])

function str = removeVowels(str)
for v = 'aeiou'
  str(str==v) = [];
end


function setupplot(f)
figure(f), hold off 
