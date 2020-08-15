function q = eu2qu(eu)
%--------------------------------------------------------------------------
% Date:
%
% Description:  from Euler angles to quaternions
% 
% Inputs:
%  a - a
%
% Outputs:
%  b - b
%
% Usage:
%  a = b(a);
%
% Dependencies:
%  *
%
% Notes:
%  Vectorized by SGB 2020-08-15
%--------------------------------------------------------------------------
global epsijk
epsijk
if isempty(epsijk)
	epsijk = -1;
	warning(['global variable epsijk not set. Using Bunge convention: epsijk == ' int2str(epsijk)])
end

aphi1 = eu(:,1);
aPhi = eu(:,2);
aphi2 = eu(:,3);

sigma = 0.5*(aphi1+aphi2);
delta = 0.5*(aphi1-aphi2);
c = cos(aPhi/2);
s = sin(aPhi/2);

q = [c*cos(sigma); -epsijk*s*cos(delta); -epsijk*s*sin(delta); -epsijk*c*sin(sigma)];

ids = q(:,1) >= 0;
q(ids,:) = -q(ids,:);

% set values very close to 0 as 0
thr = 1e-10;

q(abs(q)<thr) = 0;

end

%--------------------------------CODE GRAVEYARD----------------------------
%{
% epsijk = -1;

% q = zeros(1,4);

% q = [c*cos(sigma); -epsijk*s*cos(delta); -epsijk*s*sin(delta); -epsijk*c*sin(sigma)];


% q0 = c*cos(sigma);

% if q0>=0
%     q = [c*cos(sigma), -epsijk*s*cos(delta), -epsijk*s*sin(delta), -epsijk*c*sin(sigma)];
% else
%     q = [-c*cos(sigma), epsijk*s*cos(delta), epsijk*s*sin(delta), epsijk*c*sin(sigma)];
% end


if (abs(q(1))-0)<thr
    q(1)=0.0;
elseif (abs(q(2))-0)<thr
    q(2)=0.0;
elseif (abs(q(3))-0)<thr
    q(3)=0.0;
elseif (abs(q(4))-0)<thr
    q(4)=0.0;    
end


%}