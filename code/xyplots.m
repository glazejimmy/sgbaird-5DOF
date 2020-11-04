function xyplots(mastertbl,xytypes,xtype,ytype,NV)
arguments
   mastertbl table
   xytypes cell
   xtype char
   ytype char
   NV.yunits char = 'J/m^2'
   NV.XScale char {mustBeMember(NV.XScale,{'log','linear'})} = 'log'
   NV.YScale char {mustBeMember(NV.YScale,{'log','linear'})} = 'linear'
   NV.xmin double = []
   NV.ymin double = []
   NV.lgdloc char = 'best'
   NV.charlblQ(1,1) logical = false
   NV.charlbl char = ''
   NV.charlblnum double = []
   NV.Interpreter char {mustBeMember(NV.Interpreter,{'latex','tex'})} = 'latex'
end
% XYPLOTS  plot multiple datasets on the same axes using a "master" table and findgroups()
ax = gca;
ax.XScale = 'log';
xlabel(xtype)
if ~isempty(NV.yunits)
    ylabel([ytype ' (' NV.yunits ')'],'Interpreter',NV.Interpreter)
else
    ylabel(ytype,'Interpreter',NV.Interpreter)
end
axis square

for xytype = xytypes
    tbl = mastertbl(ismember(mastertbl.method,xytype),:);
    [G,ID] = findgroups(tbl.nmeshpts);
    
    xyplot(tbl,G,xtype,ytype)
end

if ~isempty(NV.xmin)
    ax.XLim(1) = NV.xmin;
end
if ~isempty(NV.ymin)
    ax.YLim(1) = NV.ymin;
end

legend(xytypes,'Location',NV.lgdloc,'FontSize',9,'Interpreter',NV.Interpreter)

% label for figure tiles, e.g. '(a)', '(b)', '(c)', '(d)'
if NV.charlblQ && ~isempty(NV.charlbl)
    papertext(charlbl)
%     text(0.025,0.95,NV.charlbl,'Units','normalized','FontSize',12,'Interpreter',NV.Interpreter)
end

end

%% CODE GRAVEYARD
%{
%     [npts,rmse,mae,runtime] = deal(tbl.nmeshpts,tbl.rmse,tbl.mae,tbl.runtime);
    
    nmeshpts = splitapply(@(x)x(1),npts,G1);
    medRMSE = splitapply(@median,rmse,G1);
    stdRMSE = splitapply(@std,rmse,G1);
    medMAE = splitapply(@median,mae,G1);
    stdMAE = splitapply(@std,mae,G1);
    medruntime = splitapply(@median,runtime,G1);
    stdruntime = splitapply(@std,runtime,G1);
    
    semilogx(t1,nmeshpts,medRMSE,'-o')
    xlabel('nmeshpts')
    ylabel('RMSE (J/m^2)')
    axis square
    hold off
    
    semilogx(t2,nmeshpts,medMAE,'-o')
    xlabel('nmeshpts')
    ylabel('MAE (J/m^2)')
    axis square
    hold off
%     semilogx(nmeshpts,medruntime,'-o')

    figure(fig2)
    hold on
    semilogx(nmeshpts,medruntime,'-o')
    xlabel('nmeshpts')
    ylabel('runtime (s)')
    axis square
    hold off
%}