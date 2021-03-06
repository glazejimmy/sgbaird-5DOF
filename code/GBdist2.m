function [omega_new, oct_new, zeta_new,wveclist_out,octonion_pair_sym_list_out] = GBdist2(data,pgnum,genplot)
% GBDIST2  troubleshooting for GBdist() (deprecated)
%% INPUT DATA
%
% data: an N x 16 matrix of GB octonion pairs for the distance calculation
% a single octonion pair should have the form: (o1,o2) = (qA,qB,qC,qD), each of the four quaternions should be normalized
% pgnum: number of point group symmetry operators (from 1 to 32, cubic is 30, names given in crystal_symmetry_ops/PGnames.mat)
%
% test = importdata('../Data/olm_octonion_list.txt',' ',1); %list of GB octonions with number of octonions in file at top
% data0 = test.data;
%
% % as example data, lets fold the Olmsted dataset in half to give a 194x16 matrix of GB pairs
% data = zeros(388/2,16);
% data(:,1:8) = data0(1:194,:);
% data(:,9:16) = data0(195:end,:);
%
% pgnum = 30;
% genplot = true;
%
%% Output data
%
% omega_new: Nx1 vector, minimum distance (geodesic distance) computed for each input GB pair
% oct_new: Nx16 matrix, symmetrized octonions that give minimum geodesic distance
% zeta_new: Nx1 vector, minimizing U(1) angle.


%% load crystal symmetry
symnames = load('PGnames.mat'); %need to add crystal_symmetry_ops to path in order for this to work
symops = load('PGsymops.mat');

pgname = symnames.PG_names{pgnum};
% disp('loading point group:')
% disp(pgname)


%% perform distance calculation

qpt = symops.Q{pgnum}; %choose point group symmetry
npt = length(qpt(:,1));
nmax = length(data(:,1));
pair_list = 1:nmax; %nmax; %(nmax-1); %1:500000;
npairs = length(pair_list);

%cells to keep track of final minimized angles
oct_new = data(pair_list,1:16); %symmetrized octonions
omega_new = zeros(1,length(pair_list)); %minimum octonion distances
zeta_new = zeros(1,length(pair_list)); %minimizing U(1) angles

wveclist = cell(1,npairs);
octonion_pair_sym_list = wveclist;

% disp('Performing distance calculation ...')

for k = 1:npairs
	
	%     disp(k)
	pair_id = pair_list(k);
	
	%
	%     if mod(k,100)==0
	%         disp(['pair ',num2str(k)])
	%     end
	GBO_super = data(pair_id,:);
	
	o1 = GBO_super(:,1:8); %symmetrized octonion 1, unnormalized
	o2 = GBO_super(:,9:16); %symmetrized octonion 2, unnormalized
	
	qA = GBO_super(:,1:4); qB = GBO_super(:,5:8);
	qC = GBO_super(:,9:12); qD = GBO_super(:,13:16);
	
	GBOM_curr = 2*pi; %current GBOM angle. We want to lower this value via crystal symmetry!
	omega_keep = GBOM_curr;
	
	min_rep_count = 0; %keep track of angles as they are minimized.
	diff = 1000; %large value
	min_rep_oct = [];
	min_rep_GBOM = [];
	min_rep_zeta = [];
	
	wveclist{k} = NaN(npt^2,1);
	octonion_pair_sym_list{k} = NaN(npt^2,16);
	
	ct = 0; %counter
	for i = 1:1 %:npt
		for j = 1:1 %:npt
			for m = 1:npt
				for l = 1:npt
					ct_old = ct;
					ct = ct + 8;
					ctrange = ct_old+1:ct;
					
					%define symmetry operators
					Si = qpt(i,:);
					Sj = qpt(j,:);
					Sm = qpt(m,:);
					Sl = qpt(l,:);
					
					%apply symmetry operators
					%                     qSA = qmult(Si,qA);
					%                     qSB = qmult(Sj,qB);
					qSC = qmult(Sm,qC);
					qSD = qmult(Sl,qD);
					
					%now we implement U(1) and grain exchange symmetry
					
					%1. (A B C'(zeta) D'(zeta))
					zm1 = zeta_min(qA,qB,qSC,qSD);
					qzm1 = [cos(zm1/2) 0 0 sin(zm1/2)];
					qCz1 = qmult(qSC,qzm1);
					qDz1 = qmult(qSD,qzm1);
					w1 = 2*acos(abs(sum(qA.*qCz1)-sum(qB.*qDz1))/2);
					w5 = 2*acos(abs(sum(-qA.*qCz1)-sum(qB.*qDz1))/2);
					
					%2. (B A C'(sigma) D'(sigma))
					
					sm1 = zeta_min(qB,qA,qSC,qSD);
					qsm1 = [cos(sm1/2) 0 0 sin(sm1/2)];
					qCs1 = qmult(qSC,qsm1);
					qDs1 = qmult(qSD,qsm1);
					w2 = 2*acos(abs(sum(qB.*qCs1)-sum(qA.*qDs1))/2);
					w6 = 2*acos(abs(sum(qB.*qCs1)-sum(qA.*-qDs1))/2);
					
					%3. (A -B C'(zeta') D'(zeta'))
					
					zm2 = zeta_min(qA,-qB,qSC,qSD);
					qzm2 = [cos(zm2/2) 0 0 sin(zm2/2)];
					qCz2 = qmult(qSC,qzm2);
					qDz2 = qmult(qSD,qzm2);
					
					w3 = 2*acos(abs(sum(qA.*qCz2)-sum(-qB.*qDz2))/2);
					w7 = 2*acos(abs(sum(-qA.*-qCz2)-sum(-qB.*qDz2))/2);
					
					
					%4. (B -A C'(sigma') D'(sigma'))
					
					sm2 = zeta_min(qB,-qA,qSC,qSD);
					qsm2 = [cos(sm2/2) 0 0 sin(sm2/2)];
					qCs2 = qmult(qSC,qsm2);
					qDs2 = qmult(qSD,qsm2);
					
					w4 = 2*acos(abs(sum(qB.*-qCs2)-sum(qA.*qDs2))/2);
					w8 = 2*acos(abs(sum(-qB.*qCs2)-sum(-qA.*qDs2))/2);
					
					%store candidate omega values
					wvec = [w1 w2 w3 w4 w5 w6 w7 w8];
					wveclist{k}(ctrange) = wvec.';
					
					octonion_pair_sym = [qA qB qCz1 qDz1
						qA qB qDs1 qCs1
						qA qB qCz2 -qDz2
						qA qB -qDs2 qCs2
						qA qB -qCz1 qDz1
						qA qB -qDs1 qCs1
						qA qB -qCz2 -qDz2
						qA qB -qDs2 -qCs2];
					%                           qB qA qCs1 qDs1;
					%                           qA -qB qCz2 qDz2;
					%                           qB -qA qCs2 qDs2;
					%                           -qA qB qCz1 qDz1;
					%                           -qB qA qCs1 qDs1;
					%                           -qA -qB qCz2 qDz2;
					%                           -qB -qA qCs2 qDs2]; %symmetrically equivalent candidate octonion pairs
					
					octonion_pair_sym_list{k}(ctrange,:) = octonion_pair_sym;
					
					%                   % take minimum omega value and corresponding symmetrized octonion
					[omega_test,iwmin] = min(wvec);
					zeta_sym = [zm1 sm1 zm2 sm2 zm1 sm1 zm2 sm2];
					
					% 						  zeta_sym_list = [zeta_sym_list zeta_sym];
					
					if (omega_test) <= omega_keep+1e-5
						
						omega_keep = omega_test;
						oct_keep = octonion_pair_sym(iwmin,:);
						zeta_keep = zeta_sym(iwmin);
						%                         disp('theta (deg)')
						%                         disp(rad2deg(omega_keep))
						%                         disp('octonion:')
						%                         disp(oct_keep)
						%                         disp('U(1) angle (deg):')
						%                         disp(rad2deg(zeta_keep))
						
						min_rep_count = min_rep_count+1; %how many times in min angle repeated?
						
						
						%                         min_rep_oct(min_rep_count,:) = oct_keep;
						min_rep_GBOM(min_rep_count) = omega_keep;
						%                         min_rep_zeta(min_rep_count) = zeta_keep;
						
						if min_rep_count > Inf %if min angle is repeated nine times, exit symmetry loop %modified 2020-07-14 SGB
							diff = abs(omega_keep - min_rep_GBOM(min_rep_count-1));
							if diff < 1e-5
								%                                 disp('break')
								break
							end
						end
						
						
					end
					
					if diff < 1e-5
						%                         disp('break')
						break
					end
					
				end
				
				if diff < 1e-5
					%                         disp('break')
					break
				end
			end
			
			if diff < 1e-5
				%                         disp('break')
				break
			end
		end
	end
	oct_new(k,:) = oct_keep; %keep octonion
	omega_new(k) = omega_keep; %keep
	zeta_new(k,:) = zeta_keep;
	
	%     repoct_cell{k} = min_rep_oct;
	%     repomega_cell{k} = min_rep_GBOM;
	%     repzeta_cell{k} = min_rep_zeta;
	
	
	
end

wveclist_out = vertcat(wveclist{:});
octonion_pair_sym_list_out = vertcat(octonion_pair_sym_list{:});

%% Optional plotting routine


if genplot
	
	pgsplit = strsplit(pgname,' ');
	pgname_use = pgsplit{end};
	
	%Fig 1: geodesic GB pair angle distribution
	figure
	histogram(rad2deg(omega_new),20,'Normalization','Probability')
	xlabel('GBOM angle (degrees)','FontSize',14)
	ylabel('probability');
	title(['point group: ',pgname_use])
	
	%Fig 2: minimizing U(1) angle distribution
	figure
	histogram(rad2deg(zeta_new),20,'Normalization','Probability')
	xlabel('U(1) angle (degrees)','FontSize',14)
	ylabel('probability');
	title(['point group: ',pgname_use])
	
end

end

%% Auxiliary functions: to understand these, read the original octonion paper

function zm = zeta_min(qA,qB,qC,qD)
%%% zeta is twist angle of U(1) symmetry (6 --> 5 DOF)
%%% GBOM angle can be analytically minimized w.r.t. zeta (EQN 25, octonion paper)

% [cA,sA,aA,~] = q2ax(qA);
% [cB,sB,aB,~] = q2ax(qB);
% [cC,sC,aC,~] = q2ax(qC);
% [cD,sD,aD,~] = q2ax(qD);

%quaternion dot products = cos(omega/2), omega is misorientation angle

qdot_AC = sum(qA.*qC); % dot(qA,qC);%qdot(cA,cC,sA,sC,aA,aC);
qdot_BD = sum(qB.*qD); %dot(qB,qD);%qdot(cB,cD,sB,sD,aB,aD);

mu_num1 = qA(4)*qC(1)-qC(4)*qA(1)+qB(4)*qD(1)-qD(4)*qB(1);
crossAC = crossp(qA(2:4),qC(2:4));
crossBD = crossp(qB(2:4),qD(2:4));

mu_arg = (mu_num1 + crossAC(3) + crossBD(3))/(qdot_AC+qdot_BD);
mu = 2*atan(mu_arg);

if mu >= 0
	zm = mu;
else
	zm = mu + 2*pi;
end

end

function Omega = GBOM(qA,qB,qC,qD)
%%%octonion dot product = cos(Omega/2), Omega is GBOM angle
%%%be careful about normalization here: see eqns (21,22)

[cA,sA,aA,~] = q2ax(qA);
[cB,sB,aB,~] = q2ax(qB);
[cC,sC,aC,~] = q2ax(qC);
[cD,sD,aD,~] = q2ax(qD);

%quaternion dot products = cos(omega/2), omega is misorientation angle

qdot_AC = qdot(cA,cC,sA,sC,aA,aC);
qdot_BD = qdot(cB,cD,sB,sD,aB,aD);

Omega = 2*acos(abs(qdot_AC-qdot_BD)/2); %normalized octonions account for factor of 1/2 in arg

end


function out = qdot(cA,cB,sA,sB,aA,aB)
%%% dot product between two quaternions, expressed in terms of c,s,a
%%% out = cos(omega/2), where omega is misorientation angle
out = cA*cB + sA*sB*sum(aA.*aB); %dot(aA,aB);

end

function out = qmult(pp,qq)
%%% multiply two quaternions p*q
p = pp(2:4); q = qq(2:4);

qr = pp(1)*qq(1)-sum(p.*q); %dot(p,q);
qi = pp(1)*q + qq(1)*p + crossp(p,q);

out = [qr qi];
end


function [c,s,a,theta] = q2ax(qq)
%%% input: qq, quaternion with real component first
%%% output: c = cos(theta/2), s = sin(theta/2), axis a, angle theta
%%% qq = [c,s*a], where theta is angle and a is axis in axis angle pair

thr = 1e-8;
theta = 2.0 * acos(qq(1));

if ((qq(1)-0.0)<thr)
	c = 0; s = 1;
	theta = pi;
	a = [qq(2) qq(3) qq(4)];
else
	c = qq(1);
	ss =  sign(qq(1))/sqrt(qq(2)^2+qq(3)^2+qq(4)^2);
	a = [qq(2)*ss, qq(3)*ss, qq(4)*ss];
	s = sin(theta/2);
end

end

function c = crossp(a,b)
%%% faster implementation of cross product

c = [a(2).*b(3)-a(3).*b(2) a(3).*b(1)-a(1).*b(3) a(1).*b(2)-a(2).*b(1)];
end