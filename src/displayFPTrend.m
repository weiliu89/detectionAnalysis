function displayFPTrend(result, nfp, titlestr)
% displayFPTrend(result, nfp)
%
% Displays stacked area plots showing trend of false positives with rank

nsim = getCumulativeCount({result.issim});
nbg = getCumulativeCount({result.isbg_notobj});
nloc = getCumulativeCount({result.isloc});
noth = getCumulativeCount({result.isother});
ntotal = nsim+nbg+nloc+nbg+noth;

nsim = getFpCounts(nsim, ntotal, nfp);
nbg = getFpCounts(nbg, ntotal, nfp);
nloc = getFpCounts(nloc, ntotal, nfp);
noth = getFpCounts(noth, ntotal, nfp);

ntotal = nsim+nbg+nloc+noth;

figure(3), hold off
area(1:numel(nfp), [nloc(:) nsim(:) noth(:) nbg(:)] ./ repmat(ntotal(:), [1 4]) * 100);
set(gca, 'xtick', 1:numel(nfp));
set(gca, 'xticklabel', num2cell(nfp))
set(gca,'Layer','top')
colormap([[79 129 189]/255 ; [192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
set(gca, 'fontsize', 20);
axis([1 numel(nfp) 0 100])
legend({'Loc', 'Sim', 'Oth', 'BG'})
title(titlestr);
xlabel('total false positives')
ylabel('percentage of each type')


figure(4), 
set(gcf, 'DefaultAxesColorOrder', [[79 129 189]/255 ; [192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
plot(1:numel(nfp), [nloc(:) nsim(:) noth(:) nbg(:)] ./ repmat(ntotal(:), [1 4])*100, 'linewidth', 3);
set(gca, 'xtick', 1:numel(nfp));
set(gca, 'xticklabel', num2cell(nfp))
set(gca, 'fontsize', 16);
axis([1 numel(nfp) 0 100])
legend({'Loc', 'Sim', 'Oth', 'BG'})
title(titlestr);
xlabel('total false positives')
ylabel('percentage of each type')

figure(5), 
set(gcf, 'DefaultAxesColorOrder', [[192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
plot(1:numel(nfp), [nsim(:) noth(:) nbg(:)] ./ repmat(ntotal(:)-nloc(:), [1 3])*100, 'linewidth', 3);
set(gca, 'xtick', 1:numel(nfp));
set(gca, 'xticklabel', num2cell(nfp))
%colormap([[192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
set(gca, 'fontsize', 16);
axis([1 numel(nfp) 0 100])
legend({'Sim', 'Oth', 'BG'})
title(titlestr);
xlabel('total false positives')
ylabel('pctg of each type (excluding loc)')


function count = getCumulativeCount(n)
count = n{1};
for k = 2:numel(n)
  if numel(n{k})>numel(count)
    tmp = count;
    count = n{k};
    count(1:numel(tmp)) = count(1:numel(tmp))+tmp;
  else
    count(1:numel(n{k})) = count(1:numel(n{k})) + n{k};
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