function [ax,mu,sigma,D,nnpts,idx] = nnhist(pts,dtype,K,NV)
arguments
    pts
    dtype char {mustBeMember(dtype,{'omega','norm','alen'})} = 'omega'
    K(1,1) double {mustBePositive,mustBeInteger} = 1
    NV.plotQ(1,1) logical = true
    NV.dispQ(1,1) logical = true
end
% NNHIST  nearest neighbor distance histogram
%--------------------------------------------------------------------------
% Author(s): Sterling Baird
%
% Date: 2020-07-27
%
% Inputs:
%  pts - rows of points (euclidean)
%
%  dtype - distance type
%
% Outputs:
%  creates a histogram figure
%
% Usage:
%	pts = sqrt2norm(normr(rand(1000,8))); %octonion case (omega), input must have norm == sqrt(2)
%  nnhist(pts)
%
%  pts = nnhist(rand(1000,5)); % euclidean distance
%  nnhist(pts)
%
% Dependencies:
%  get_omega.m
%
% Notes:
%  *
%--------------------------------------------------------------------------
%get distances

[nnpts,D,mu,sigma,idx] = get_knn(pts,dtype,K,'dispQ',NV.dispQ);

% if NV.plotQ
%     paperfigure()
% end

if NV.plotQ
    %% plotting
    switch dtype
        case 'omega'
            xlbl = 'NN $\omega$ (deg)';
        case 'norm'
            xlbl = 'NN Euclidean distance';
        case 'alen' %general arc length formula
            xlbl = 'NN $\omega = cos^{-1}(p_1 \cdot p_2)$ (deg)';
    end
    xlabel(xlbl,'Interpreter','latex','FontSize',12)
    ylabel('counts','Interpreter','latex','FontSize',12)
    hold on
    for k = 1:K
        histfit(D{k});
    end
    hold off
else
    ax = [];
end

axis square

end
%---------------------------------CODE GRAVEYARD---------------------------
%{
% pts = uniquetol(pts,'ByRows',true);

    %get distances for plotting
    switch dtype
        case 'omega'
            Drad = get_omega(pts,nnpts);
            D = rad2deg(Drad);
            xlbl = 'NN \omega (deg)';
        case 'norm'
            D = Dtmp(:,2);
            xlbl = 'NN euclidean octonion distance';
        case 'alen' %general arc length formula
            Drad = real(acos(dot(pts,nnpts,2)));
            D = rad2deg(Drad);
            xlbl = 'NN \omega = cos^{-1}(p_1 \cdot p_2) (deg)';
    end


[mu,sigma] = deal(zeros(K,1));
D = cell(K,1);

for k = 1:K
    idx = idxtmp(:,k+1);
    
    %nearest neighbor pts
    nnpts = pts(idx,:);
    
    %get distances for plotting
    switch dtype
        case 'omega'
            Drad = get_omega(pts,nnpts);
            D{k} = rad2deg(Drad);
        case 'norm'
            D{k} = Dtmp(:,2);
        case 'alen' %general arc length formula
            Drad = real(acos(dot(pts,nnpts,2)));
            D{k} = rad2deg(Drad);
    end
    
    mu(k) = mean(D{k});
    sigma(k) = std(D{k});
    
    if NV.dispQ
        disp(['nn: ' int2str(k) ', mu = ' num2str(mu(k)) ', sigma = ' num2str(sigma(k))])
    end
end

%}