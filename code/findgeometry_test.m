clear; close all;

%assumption is 'FCC' or 'BCC' crystal type (2020-06-30)

geomchecktypeList = {...
	'OAB','OBCE','OADE','CDE',... surfaces
	'OB','CE','ED','OE','OA','AC',... lines
	'B','E','A','C','O'}; %points

geomchecktypeList = {...
	'B','A','C'}; %points

k = sqrt(2)-1;

for i = 1:length(geomchecktypeList)
	geomchecktype = geomchecktypeList{i};
	switch geomchecktype
		%surfaces
		case 'OAB'
			q = [1,0.5,1,0];
		case 'OBCE'
			q = [3,0.5,0.5,1];
		case 'OADE'
			q = [3 1 2 2];
		case 'CDE'
			q = [3,0.5,1.5,1];
			%lines
		case 'OB'
			q = [0.5,1,1,0];
		case 'CE'
			q = [5,1,1,3];
		case 'ED'
			q = [5 1 2 2];
		case 'OE'
			q = [0.5,1,1,1];
		case 'OA'
			q = [0.5,1,0,0];
		case 'AC'
			q = [1,sqrt(2)-1,2,(sqrt(2)-1)*2];
			%points
		case 'B'
			q = [1/sqrt(1+2*k^2),k/sqrt(1+2*k^2),k/sqrt(1+2*k^2),0];
		case 'E'
			q = [sqrt(3)/2,1/(2*sqrt(3)),1/(2*sqrt(3)),1/(2*sqrt(3))];
		case 'A'
			q = [cos(pi/8),sin(pi/8),0,0];
		case 'C'
			q = 1/(2*sqrt(2))*[1/k,1,1,k];
		case 'O'
			q = [1,0,0,0];
		case 'interior'
			q = [0.7489,0.2646,0.2281,0.1336]; %randomly generated (and then plugged into disorientation(q,'cubic')
			%q = [1,0.5,1,0]+[3,0.5,1.5,1]; %OAB + CDE examples
	end
	q = q/norm(q); %normalize quaternion
	
	geometry = findgeometry(q);
	check(i) = strcmp(geomchecktype,geometry);
end

if all(check) ~= 1
	disp('something went wrong with findgeometry(). Displaying ones that do not match.')
	disp(geomchecktypeList(~check))
else
	disp('geometries matched input test cases.')
end