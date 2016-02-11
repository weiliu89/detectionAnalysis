function displayDetectionTrend(result, tics, titlestr)
% displayDetectionTrend(result, tics, titlestr)
%
% Displays stacked area plots showing trend of detections/false positives
% with rank, along with recall for strong and weak localization.  If a
% group of objects is analyzed (numel(result)>1), the number of fps and
% recall is averaged across categories
%


if numel(result)==1
  npos = result.all.npos;
else
  tmp = [result.all];
  npos = round(mean([tmp.npos]));
end

ncor = getCumulativeCount({result.iscorrect});
nsim = getCumulativeCount({result.issim});
nbg = getCumulativeCount({result.isbg_notobj});
nloc = getCumulativeCount({result.isloc});
noth = getCumulativeCount({result.isother});
ntotal = ncor+nsim+nbg+nloc+nbg+noth;

ncor = getFpCounts(ncor, ntotal, tics*npos);
nsim = getFpCounts(nsim, ntotal, tics*npos);
nbg = getFpCounts(nbg, ntotal, tics*npos);
nloc = getFpCounts(nloc, ntotal, tics*npos);
noth = getFpCounts(noth, ntotal, tics*npos);

ntotal = ncor+nsim+nbg+nloc+noth;

figure(3), hold off
area(1:numel(tics), [ncor(:) nloc(:) nsim(:) noth(:) nbg(:)] ./ repmat(ntotal(:), [1 5]) * 100);
set(gca, 'xtick', 1:numel(tics));
set(gca, 'xticklabel', num2cell(tics))
set(gca,'Layer','top')
colormap([[255 255 255]/255 ; [79 129 189]/255 ; [192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
set(gca, 'fontsize', 20);
axis([1 numel(tics) 0 100])
legend({'Cor', 'Loc', 'Sim', 'Oth', 'BG'}, 'location', 'southeast')
title(titlestr);
xlabel(sprintf('total detections (x %d)', npos));
ylabel('percentage of each type');

hold on
if numel(result)==1  
  recall_weak = result.fixloc.r(min(round(tics*npos), numel(result.fixloc.r)));
  recall_strong = result.all.r(min(round(tics*npos), numel(result.all.r)));
else  
  recall_weak = 0;
  recall_strong = 0;
  for k = 1:numel(result)    
    nposk = result(k).all.npos;
    recall_weak = recall_weak + result(k).fixloc.r(min(round(tics*nposk), numel(result(k).fixloc.r)))/numel(result);
    recall_strong = recall_strong + result(k).all.r(min(round(tics*nposk), numel(result(k).all.r)))/numel(result);
  end  
end
plot(1:numel(tics), recall_strong*100, '-r', 'linewidth', 3);
plot(1:numel(tics), recall_weak*100, '--r', 'linewidth', 3);

% figure(4), 
% set(gcf, 'DefaultAxesColorOrder', [[79 129 189]/255 ; [192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
% plot(1:numel(nfp), [nloc(:) nsim(:) noth(:) nbg(:)] ./ repmat(ntotal(:), [1 4])*100, 'linewidth', 3);
% set(gca, 'xtick', 1:numel(nfp));
% set(gca, 'xticklabel', num2cell(nfp))
% set(gca, 'fontsize', 16);
% axis([1 numel(nfp) 0 100])
% legend({'Loc', 'Sim', 'Oth', 'BG'})
% title(titlestr);
% xlabel('total false positives')
% ylabel('percentage of each type')
% 
% figure(5), 
% set(gcf, 'DefaultAxesColorOrder', [[192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
% plot(1:numel(nfp), [nsim(:) noth(:) nbg(:)] ./ repmat(ntotal(:)-nloc(:), [1 3])*100, 'linewidth', 3);
% set(gca, 'xtick', 1:numel(nfp));
% set(gca, 'xticklabel', num2cell(nfp))
% %colormap([[192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
% set(gca, 'fontsize', 16);
% axis([1 numel(nfp) 0 100])
% legend({'Sim', 'Oth', 'BG'})
% title(titlestr);
% xlabel('total false positives')
% ylabel('pctg of each type (excluding loc)')


function count = getCumulativeCount(n)
count = double(n{1});
for k = 2:numel(n)
  if numel(n{k})>numel(count)
    tmp = count;
    count = double(n{k});
    count(1:numel(tmp)) = double(count(1:numel(tmp))) + double(tmp);
  else
    count(1:numel(n{k})) = double(count(1:numel(n{k}))) + double(n{k});
  end
end
count = cumsum(count);

function count = getFpCounts(tmpc, total, nfp)
count = zeros(size(nfp));
t = 1;
for k = 1:numel(tmpc)
  while t<=numel(nfp) && nfp(t)<=total(k)
    count(t) = tmpc(k);
    t = t+1;
  end
  if t > numel(nfp)
    break;
  end
end