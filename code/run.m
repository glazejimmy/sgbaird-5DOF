clear; close all force
%  RUN  script to generate octonions and interpolate grain boundary energy values (deprecated, see interp5DOF.m)
%---------------------------------run.m------------------------------------
% Author: Sterling Baird
%
% Date: 2020-07-01
%
% Description: script to generate an octonion data and mesh set and
% interpolate grain boundary values based on the specified properties.
% Using interp5DOF.m instead of run.m is preferred because it has been
% better maintained and interp5DOF.m was written to act as a
% "plug-and-play" style function for grain boundary interpolation. See
% interp5DOF_test.m. This workflow does, however, incorporate things like
% looking at the perimeter of an octonion mesh, generating high- vs.
% low-symmetry grain boundaries, and 
%
% References:
%		Check if ray intersects internals of D-facet:
%		https://math.stackexchange.com/q/1256236
%--------------------------------------------------------------------------
tic
%% Setup

%set random number generator
seed = 10;
rng(seed);

%mesh and data types

addpathdir({'misFZfeatures.mat','PGnames.mat','nlt.m','q2rod.m',...
	'GBfive2oct.m','qu2ax.m','readNODE.m','var_names.m'})

%'hypersphereGrid', 'Rohrer2009', 'Kim2011', '5DOF',
%'Olmsted2004','5DOF_vtx','5DOF_misFZfeatures',
%'5DOF_interior','5DOF_exterior', '5DOF_oct_vtx','5DOF_hsphext'
%'5DOF_exterior_hsphext', 'ocubo'
meshMethod = 'ocubo';
dataMethod = 'ocubo';

%initialize
meshopts = struct();
dataopts = meshopts;

%mesh parameters
meshopts.res = 12.5;
meshopts.nint = 1; % 1 == zero subdivisions, 2 == one subdivision, etc.
meshopts.octsubdiv = 1;
meshopts.ocuboOpts.n = 388; % # of octonions to generate, [] also ok if sidelength specified
meshopts.ocuboOpts.method = 'random'; % 'random' or 'uniform' cubochoric sampling
meshopts.ocuboOpts.sidelength = []; %sidelength of cubochoric grid (only specify if 'uniform', [] ok)
meshopts.ocuboOpts.seed = 15; %sidelength of cubochoric grid (only specify if 'uniform', [] ok)
meshopts.delaunayQ = true;

%data parameters
dataopts.res = 12.5;
dataopts.nint = 1;
dataopts.octsubdiv = 1;
dataopts.ocuboOpts.n = 500; % # of octonions to generate, [] also ok if sidelength specified
dataopts.ocuboOpts.method = 'random'; % 'random' or 'uniform' cubochoric sampling
dataopts.ocuboOpts.sidelength = []; %sidelength of cubochoric grid (only specify if 'uniform', [] ok)
dataopts.ocuboOpts.seed = 20; %integer or 'shuffle' OK
dataopts.delaunayQ = false;

T = true; %just makes it easier to switch back and forth between true and false
F = false;
meshloadQ = F;
dataloadQ = F;
meshdataloadQ = F; %whether to check for and load intersection & barycentric data from previous run

%% generate mesh
disp('generating mesh')
mesh = datagen_setup(meshMethod,meshopts,meshloadQ);
disp(['--nfacets: ' int2str(size(mesh.sphK,1))])

toc; disp(' ')

%% generate data
disp('generating data')
data = datagen_setup(dataMethod,dataopts,dataloadQ);
ndatapts = size(data.pts,1);

toc; disp(' ')

%% find intersecting facet of datapoints
disp('find intersecting facet for each datapoint')

%project mesh and data together
tol = 1e-4; %consider not doing quaternion renormalization in datagen
zeroQ = false;
[a,usv] = proj_down([mesh.pts;data.pts],tol,'zeroQ',zeroQ); %better to not have zeroQ enabled (2020-08-04)

if size(a,2) <= 7
	mesh.ppts = proj_down(mesh.pts,tol,usv,'zeroQ',zeroQ);
	data.ppts = proj_down(data.pts,tol,usv,'zeroQ',zeroQ);
else
	mesh.ppts = mesh.pts;
	data.ppts = data.pts;
end

if contains(meshMethod,'hsphext')
	%compute triangulation
	meshtmp = projfacet2hyperplane(mean(mesh.ppts),mesh.ppts);
	meshtmp = proj_down(meshtmp);
	% --delaunay triangulation
	disp('--delaunayn')
	mesh.sphK = delaunayn(meshtmp);
end

%might be able to replace intersect_facet with the following
% [a,usv] = proj_down(projfacet2hyperplane(mean([mesh.ppts;data.ppts]),[mesh.ppts;data.ppts]));
% meshpts = a(1:size(mesh.pts,1),:);
% datapts = a(size(mesh.pts,1)+1:end,:);
% intfacetIDs = tsearchn(meshpts,mesh.sphK,datapts);

%compute intersecting facet IDs (might be zero, might have more than one)
inttol = 1e-2;
inttype = 'planar';
disp(['inttype: ' inttype ', inttol: ' num2str(inttol)])
intfacetIDs = intersect_facet(mesh.ppts,mesh.sphK,data.ppts,inttol,'inttype',inttype,'nnMax',10);

barytype = 'spherical';

switch barytype
	case 'planar'
		barytol = 1e-6;
	case 'spherical'
		barytol = 0.2;
		mesh.ppts = normr(mesh.ppts);
		data.ppts = normr(data.ppts);
end
disp(['barytype: ' barytype ', barytol: ' num2str(barytol)])
[datainterp,databary,facetprops,nndistList,nonintDists] = ...
    get_interp(mesh,data,intfacetIDs,barytype,barytol,'saveQ',true,'savename','ocubo.mat');

toc; disp(' ')

%% plotting
interpplot('temp.mat') %need to update to pass get_interp arguments
% into interpplot

%%
toc
disp('end run')
disp(' ')
%%
%-----------------------------CODE GRAVEYARD-------------------------------
%{

mesh.sphK = convhulln(meshpts); % check to see if % of intersections increases at all

	maxnormQ = true;
 	mesh.sphK = sphconvhulln(meshpts,maxnormQ);

% if size(meshpts,2) ~= size(mesh.sphK,2)
% 	disp('--recomputing convex hull for mesh')
% 	projpts = projfacet2hyperplane(normr(mean(meshpts)),meshpts);
% 	projpts = proj_down(projpts,1e-6);
% 	mesh.sphK = delaunayn(projpts);
	%consider making the above lines a separate function and implementing elsewhere
% end



%% projection, sph. barycentric coordinates & interpolation

%initialize
databary = NaN(size(datapts));
facetprops = databary;
datainterp = NaN(size(datapts,1),1);
nonintDists = datainterp;
nnID = [];
ilist = [];

% databaryTemp = cell(1,size(datapts,1));
for i = 1:ndatapts
	datapt = datapts(i,:); %use down-projected data (and mesh)
	if any(isnan(datapt))
		warning('NaN datapoint values')
	end
	baryOK = false; %initialize
	if ~isempty(intfacetIDs{i})
		%setup
		intfacetID = intfacetIDs{i}(1); %take only the first intersecting facet? Average values? Use oSLERP instead?
		vtxIDs = mesh.sphK(intfacetID,:);
		facet = meshpts(vtxIDs,:); %vertices of facet
		facetprops(i,:) = mesh.props(vtxIDs).'; %properties of vertices of facet
		prop = data.props(i,:);
		
		baryType = 'spherical'; %'spherical', 'planar'
		%% barycentric coordinates
		switch baryType
			case 'spherical'
				databary(i,:) = sphbary(datapt,facet); %need to save for inference input
				nonNegQ = all(databary(i,:) >= -1e-6);
				greaterThanOneQ = sum(databary(i,:)) >= 1-1e-6;
				numcheck = all(~isnan(databary(i,:)) & ~isinf(databary(i,:)));
				baryOK = nonNegQ && greaterThanOneQ && numcheck;
				
			case 'planar'
				%[~,databaryTemp] = intersect_facet(facet,1:7,datapt,1e-6,true);
				[~,~,databaryTemp,~,~] = projray2hypersphere(facet,1:7,datapt,1e-6,true);
% 				[intIDtemp,databaryTemp] = intersect_facet(meshpts,mesh.sphK,datapt,1e-6,true);
				if ~isempty(databaryTemp)
					databary(i,:) = databaryTemp;
					nonNegQ = all(databary(i,:) >= -1e-6);
					equalToOneQ = abs(sum(databary(i,:)) - 1) < 1e-6;
					numcheck = all(~isnan(databary(i,:)) & ~isinf(databary(i,:)));
					baryOK = nonNegQ && equalToOneQ && numcheck;
				end
		end
		
		if baryOK
			%% interpolate using bary coords
			datainterp(i) = dot(databary(i,:),facetprops(i,:));
		else
			disp([num2str(databary(i,:),2) ' ... sum == ' num2str(sum(databary(i,:)),10)]);
		end
	end
	if ~baryOK
		disp(['i == ' int2str(i) ...
			'; no valid intersection, taking NN with dist = ' num2str(nndistList(i))])
		nonintDists(i) = nndistList(i);
		nndistList(i) = NaN; %to distinguish interp vs. NN distances in plotting
		nnID = [nnID nnList(i)]; %nearest neighbor indices
		ilist = [ilist i]; % possible to separate out making baryOK a logical array & using 2 for loops
		% 			datainterp(i) = mesh.props(k(i));
	end
end
fpath = fullfile('data',meshdata.fname);
save(fpath)

disp(['# non-intersections: ' int2str(sum(~isnan((nnID)))) '/' int2str(ndatapts)])




% parity plot
% xmin = min(data.props);
% xmax = max(data.props);




pseudoMethod = [meshMethod '_pseudo'];

%psuedo mesh parameters
pseudoOpts.res = meshopts.res;
pseudoOpts.nint = meshopts.nint;
pseudoOpts.octsubdiv = 1;
pseudoOpts.ocuboOpts.n = 1; % # of octonions to generate, [] also ok if sidelength specified
pseudoOpts.ocuboOpts.method = 'random'; % 'random' or 'uniform' cubochoric sampling
pseudoOpts.ocuboOpts.sidelength = []; %sidelength of cubochoric grid (only specify if 'uniform', [] ok)
pseudoOpts.ocuboOpts.seed = 25; %integer or 'shuffle' OK

pseudoloadQ = T;

%% generate pseudomesh
disp('generating pseudo mesh')
pseudo = datagen_setup(pseudoMethod,pseudoOpts,pseudoloadQ);

toc; disp(' ')

% r = 0.1; %Euclidean distance
if exist('r','var') ~= 0
	meshdata.fname = ['mesh_' mesh.fname(1:end-4) '_data_' data.fname(1:end-4) '_100r--' int2str(100*r) '.mat'];
else
	meshdata.fname = ['mesh_' mesh.fname(1:end-4) '_data_' data.fname];
end


%find symmetrically equivalent octonions inside convex hull
% 	xyz = mesh.Ktr.main.pts;
% 	tess = mesh.Ktr.main.K;

% 	xyz = mesh.pts;
% 	tess = mesh.sphK;
% 	pts = data.pts;
% 	usv = mesh.usv;
% 	five = data.five;
% 	savename = [meshdata.fname(1:end-4) '_oint.mat'];
% 	oint = inhull_setup(pts,usv,xyz,tess,five,savename);

% 	if ~isempty(mesh.usv) && (size(mesh.pts,2) == 8)
% 		ptstemp = proj_down(mesh.pts,1e-6,mesh.usv);
% 	else
% 		ptstemp = mesh.pts;
% 	end
% [nnList,nndistList] = dsearchn(mesh.pts,data.pts);


% 	disp('convert mesh to 5DOF FZ')
%	meshfiveFZ = tofiveFZ(mesh.five,mesh.pts);

% 	disp('convert data to 5DOF FZ')
%	datafiveFZ = tofiveFZ(data.five,datapts);

% 	d_all = vertcat(meshfiveFZ.d);
% 	Y = vertcat(datafiveFZ.d);
d_all = q2rod(disorientation(vertcat(pseudo.five.q),'cubic'));
Y = q2rod(disorientation(vertcat(data.five.q),'cubic'));

%check for points within specified distance
%[idxlist,D] = rangesearch(d_all,Y,r);
%[idxlist,D] = knnsearch(d_all,Y,'K',1000);
%idxlist = num2cell(idxlist,2);

%find nearest vertex of pseudomesh to datapoint
psdata.pts = zeros(size(data.pts));
psdata.five(ndatapts) = struct;
psdata.wmin = zeros(size(data.pts,1),1);

% %for i = 1:ndatapts
% for i = []
% 	%unpack point
% 	pt = data.pts(i,:);
% 	
% 	idx = idxlist{i};
% 	disp([int2str(length(idx)) ' octonion inputs to GBdist'])
% 	%olist = pseudo.pts(idx,:);
% 	olist = mesh.pts(idx,:);
%     %  		olist = pseudo.pts;
% 	%olist = mesh.pts;
% 	
% 	ptrep = repmat(pt,size(olist,1),1); % matrix of repeated rows (pt)
% 	olistnorm = sqrt2norm(olist,'oct');
% 	ptrepnorm = sqrt2norm(ptrep,'oct');
% 	
% 	omega = GBdist([olistnorm ptrepnorm],32,false,false);
% 	
% 	[mintemp,minID] = min(omega);
% 	ptstemp = olist(minID,:);
% 	disp(mintemp)
% 	
% 	psdata.wmin(i) = mintemp;
% 	psdata.pts(i,:) = ptstemp;
% 	
% 	if mod(i,10) == 0
% 		disp(['i = ' int2str(i)])
% 	end
% 
% end


%1
% o1tmp = mesh.pts(1,:);
% o2 = mesh.pts(2:end,:);
% o1rep = repmat(o1tmp,size(o2,1),1);
% [~,o2] = GBdist4(o1rep,o2,32,'norm');
% mesh.pts = [o1tmp;vertcat(o2{:})];
% mesh.pts = normr(mesh.pts);

%2
% mesh.pts = get_octpairs(mesh.pts);
% mesh.pts = sqrt2norm(mesh.pts,'quat');
% mesh.pts = normr(mesh.pts);

%add extra points to interior
% [A,b] = vert2con(mesh.pts);
% extrapts = cprnd(100,A,b);
% extrapts = get_octpairs(extrapts);
% mesh.pts = [mesh.pts;extrapts];
% fivetmp = GBoct2five(extrapts);
% extraprops = GB5DOF_setup(fivetmp);
% mesh.props = [mesh.props;extraprops];

%1
% o2 = data.pts;
% o1rep = repmat(o1tmp,size(o2,1),1);
% [~,o2] = GBdist4(o1rep,o2,32,'norm');
% data.pts = vertcat(o2{:});
% data.pts = normr(data.pts);

%2
% data.pts = get_octpairs(data.pts);
% data.pts = sqrt2norm(data.pts,'quat');
% data.pts = normr(data.pts);

% mesh.ppts = [mean(mesh.ppts);mesh.ppts];

% [Ktr,K,mesh.pts] = hypersphere_subdiv(mesh.pts,[],2,true);
% mesh.pts = get_octpairs(mesh.pts);
% fivetmp = GBoct2five(mesh.pts);
% mesh.props = GB5DOF_setup(fivetmp);

% [~,mesh.sphK,mesh.ppts] = hypersphere_subdiv(mesh.ppts,mesh.sphK,2,true);
% mesh.ppts = normr(mesh.ppts);

% mesh.pts = proj_up(mesh.ppts,mesh.usv);
% mesh.five = GBoct2five(mesh.pts,false);
% mesh.props = GB5DOF_setup(mesh.five);


% 	error('no degenerate dimension found')





nnList = dsearchn(mesh.pts,data.pts);

% %remember to have each quaternion normalized to 1 before using get_omega
% meshtemp = sqrt2norm(mesh.pts(nnList,:),'oct');
% datatemp = sqrt2norm(data.pts,'oct');
% nndistList = get_omega(meshtemp,datatemp);



% find nearest vertex of mesh to datapoint
disp('--nearest neighbor search for all datapoints')
%filename
meshdata.fname = ['mesh_' mesh.fname(1:end-4) '_data_' data.fname];



%renormalize projected points
data.ppts = normr(data.ppts); %not normalizing produced 100% non-intersections (2020-07-29)
mesh.ppts = normr(mesh.ppts);


% if strcmp(barytype,'spherical')
% 	mesh.ppts = proj_down(mesh.pts,tol,usv,'zeroQ',true);
% 	data.ppts = proj_down(data.pts,tol,usv,'zeroQ',true);
% end


% mesh.pts = get_octpairs(mesh.pts);
% data.pts = get_octpairs(data.pts);

%{
Generate an approximated sphere using gridded matrix points and
hypersphere(), normalize the vectors, and compute a convex hull for
triangulation and interpolation. Barycentric coordinates can be output as
well, and these can be extended into spherical barycentric coordinates by
projecting all vertices onto a hyperplane tangent to the point of interest
and using the barycentric coordinates of that hyperplane.

n: odd values preferred to reduce chance of single points in separate plane
which could mess up centering. I think centering formula also needs to
change if using even numbers. n = 15 gives "out of memory" on 4 GB RAM
surface pro 4 i5 processor using 7D sphere embedded in 8D. n = 13 for same
gives ~0.9 GB matrix for s, and an extra few hundred MB for other variables
combined. 1.6E6 points for n = 13 in 7Dsphere@8D case.

convhulln() for a hypersphere with n = 5 and d = 7 (d === dimension), takes
~4 min (2982 vertices,1082756 facets) n = 7, d = 7 gives 30578 vertices,
and 2.8591e13 facets, or 2.64e7 x more facets Given 1e4 vertices in 7D, we
get 1e12 facets, and might take ~7 years to compute..

Once the dimension & # vertices gets high enough (e.g. 10,000 pts in 7D
cartesian, it would probably make more sense to use a k-nearest neighbor
approach and fit a hyperplane using griddatan. Or, I could do a subdivision
scheme once I've found the containing facet. This way, I can triangulate it
in a sort of r-tree indexing scheme. Start out with a coarse mesh and
refine it.
%}



%}
