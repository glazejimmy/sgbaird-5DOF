function tblout = tblvertcat(tbl)
arguments (Repeating)
    tbl table
end
% TBLVERTCAT  vertically catenate tables with different variables, filling in dummy values as needed
%--------------------------------------------------------------------------
% Author(s): Sterling Baird 
%
% Date: 2020-09-04
%
% Inputs:
%  tbl - table, where each table can have a different number of rows and
%  same and/or different variables*
%
% Outputs:
%  tblout - vertically catenated table
%
% Usage:
%  tblout = tblvertcat(tbl1,tbl2);
%  tblout = tblvertcat(tbl1,tbl2,tbl3);
%
% See also CONVERTVARS
%
% Notes:
%  See https://www.mathworks.com/matlabcentral/answers/179290-merge-tables-with-different-dimensions
%
%  *variables of the same name must also be of the same datatype. Types
%  'cell' and 'struct' are not supported by missing. Here, cell is
%  impelemented manually, but struct is not supported. A workaround for
%  using structs in tables is to wrap them in a cell. To implement struct()
%  would require at minimum making empty structs that mimic each field so
%  that they can be vertically catenated. Starting points would be:
%  https://www.mathworks.com/matlabcentral/answers/96973-how-can-i-concatenate-or-merge-two-structures
%  https://www.mathworks.com/matlabcentral/answers/315858-how-to-combine-two-or-multiple-structs-with-different-fields
%  https://www.mathworks.com/matlabcentral/fileexchange/7842-catstruct
%--------------------------------------------------------------------------
%number of tables
ntbls = length(tbl);
[tblvarnames,tbltypes] = deal(cell(ntbls,1));
%% convert types (e.g. char to string, struct to {struct})
for n = 1:ntbls
    t = tbl{n}; %unpack
    
    t = changestruct(t,'cell', @(x) num2cell(x,2), @(x) ~isscalar(x)); %cell vector to cell scalar
    t = changestruct(t,'cell', @(x) categorical(cellstr(x{1})), @(x) iscell(x) && isscalar(x) && (isstring(x{1}) || ischar(x{1})));
    t = changestruct(t,'char', @categorical); %char vector to string
    t = changestruct(t,'struct', @(x) num2cell(x,2)); %struct to {struct} (cell scalar)
    t = changestruct(t,'logical', @double);
    t = changestruct(t,'uint32', @double);
    t = changestruct(t,'double', @(x) num2cell({x},2), @(x) ~isscalar(x));
    
    tblvarnames{n} = t.Properties.VariableNames;
    tbltypes{n} = varfun(@class,t,'OutputFormat','cell');
    
    tbl{n} = t;
    
%     varnames = t.Properties.VariableNames; %variable names
%     vartypes = varfun(@class,t,'OutputFormat','cell'); %variable types
%     chartypeID = strcmp('char',vartypes); %char variables
%     charnames = varnames(chartypeID); %names of 'char' variables
%     %convert chars to strings
%     for p = 1:length(charnames)
%         charname = charnames{p};
%         tbl{n}.(charname)=string(t.(charname));
%     end
%     
%     varlen = varfun(@length,t,'OutputFormat','uniform'); %variable lengths
%     cellarrayID = (varlen > 1) & strcmp('cell',vartypes); %cell variables
%     cellnames = varnames(cellarrayID); %names of 'char' variables
%     %convert cell vectors to cell scalars
%     for p = 1:length(cellnames)
%         cellname = cellnames{p};
%         cellnametmp = matlab.lang.makeUniqueStrings(cellname,varnames);
%         t.Properties.VariableNames = strrep(varnames,cellname,cellnametmp);
%         t.(cellname) = num2cell(t.(cellnametmp),2);
%         t = removevars(t,cellnametmp);
%     end
%     tbl{n} = t;
%     
%     structID = (varlen > 1) & strcmp('struct',vartypes); %cell variables
%     structnames = varnames(structID); %names of 'char' variables
%     %convert cell vectors to cell scalars
%     for p = 1:length(structnames)
%         structname = structnames{p};
%         structnametmp = matlab.lang.makeUniqueStrings(structname,varnames);
%         t.Properties.VariableNames = strrep(varnames,structname,structnametmp);
%         t.(structname) = num2cell(t.(structnametmp),2);
%         t = removevars(t,structnametmp);
%     end
    
end

[masternames,ia] = unique(horzcat(tblvarnames{:}));
tbltypestmp = horzcat(tbltypes{:});
mastertypes = tbltypestmp(ia);

%% nested loop through table pairs
for n = 1:ntbls %not parfor compatible
    if mod(n,50) == 0
        disp(n)
    end
%     for p = n:ntbls
        %skip self
%         if p ~= n
            %% unpack table pair
            t1 = tbl{n};
%             t2 = tbl{p};
            
            %% find missing variables
            nrows1 = height(t1);
%             nrows2 = height(t2);
            
            %dummy vars for variable names
            t1varnames = t1.Properties.VariableNames;
%             t2varnames = t2.Properties.VariableNames;
            
            %get variable names from t2 that are not in t1
            [missingtmp1,ia1] = setdiff(masternames,t1varnames);
            %get variable names from t1 that are not in t2
%             [missingtmp2,ia2] = setdiff(t1varnames,t2varnames);
            
            % cell tables (cell with 0x0 double inside)
            [celltbl1,creplaceNames1] = replacevartbl(mastertypes,nrows1,ia1,cell(1),masternames);
%             [celltbl2,creplaceNames2] = replacevartbl(t1,nrows2,ia2,cell(1),t1varnames);

%             [dbltbl,dreplaceNames] = replacevartbl(mastertypes,nrows1,ia1,NaN,masternames);
            
            % remove values that are represented in cell and struct tables
            missing1 = setdiff(missingtmp1,creplaceNames1,'stable');
%                         missing1 = setdiff(missingtmp1,horzcat(creplaceNames1,dreplaceNames),'stable');
%             missing2 = setdiff(missingtmp2,creplaceNames2,'stable');
            
            %% splice the missing variable tables into original tables
            % matrices of missing elements to splice into original
            missingmat1 = repelem(missing,nrows1,numel(missing1));
%             missingmat2 = repelem(missing,nrows2,numel(missing2));
            
            %tables to splice into original tables
            missingtbl1 = array2table(missingmat1,'VariableNames',missing1);
%             missingtbl2 = array2table(missingmat2,'VariableNames',missing2);
            
            %perform the splice
            tbl{n} = [t1, missingtbl1, celltbl1];
%             tbl{n} = [t1, dbltbl, missingtbl1, celltbl1];
%             tbl{p} = [t2 missingtbl2, celltbl2];
%         end
%     end
end
%catenate all tables
tblout = vertcat(tbl{:});
end

%% REPLACE VARIABLE TABLE
function [replacetbl,replaceNames] = replacevartbl(vartypes,nrows,ia,replaceval,varnames)
%replace type
replacetype = class(replaceval);
%% missing variable IDs and names
%variable names
% varnames = t.Properties.VariableNames;
%variable types
% vartypes=varfun(@class,tvarnames,'OutputFormat','cell');
%variable IDs of some type
IDtmp = find(strcmp(replacetype,vartypes));
%missing variable IDs of different types
ID = intersect(ia,IDtmp);
%missing variable names of different types
replaceNames = varnames(ID);

%% construct table with replacement values and names
%table dimensions
nvars = length(ID);
if isstruct(replaceval) && isempty(replaceval)
    error('if type struct, cannot be empty. Instead supply struct with no fields via struct()')
end
replacemat = repelem(replaceval,nrows,nvars);
replacetbl = array2table(replacemat);
if ~isempty(replacetbl)
    replacetbl.Properties.VariableNames = replaceNames;
end

end

%% CHANGESTRUCT
function t = changestruct(t,type,changefn,checkfn)
arguments
    t table
    type char = 'char'
    changefn = @string
    checkfn = @(x) 1
end
varnames = t.Properties.VariableNames; %variable names
vartypes = varfun(@class,t,'OutputFormat','cell'); %variable types
varprop = varfun(checkfn,t,'OutputFormat','uniform'); %variable lengths
ID = varprop & strcmp(type,vartypes); %cell variables

names = varnames(ID); %names of 'char' variables
%convert to new type
for p = 1:length(names)
    name = names{p};
    t.(name) = changefn(t.(name));
end

end


%% CODE GRAVEYARD
%{
            %get variable types for each
            vartypes1=varfun(@class,t1,'OutputFormat','cell');
            vartypes2=varfun(@class,t2,'OutputFormat','cell');
            
            %% find variable IDs of different types
            %struct
            structIDtmp1 = find(strcmp('struct',vartypes1));
            structIDtmp2 = find(strcmp('struct',vartypes2));
            
            %cell
            cellIDtmp1 = find(strcmp('cell',vartypes1));
            cellIDtmp2 = find(strcmp('cell',vartypes2));
            
            %% find missing variable IDs of different types
            %struct
            structID1 = union(ia1,structIDtmp1);
            structID2 = union(ia2,structIDtmp2);
            
            %cell
            cellID1 = union(ia1,cellIDtmp1);
            cellID2 = union(ia2,cellIDtmp2);


% for i = 1:n
%     strcmp('struct',varfun(@class,tbl{i},'OutputFormat','cell')
% end

%             ia1([structID1,cellID1]) = [];
%             ia2([structID2,cellID2]) = [];

if isstruct(replaceval)
    for i = ID
        varname = varnames{ID};
        sfields = fields(t(varname));
        for j = 1:length(sfields)
            sfield = sfields{j};
            sfieldtype = 
            replaceval.(sfield) = 

        for k = 1:height(t)
            t = removevars(t,cellname);
            tbl{n} = addvars(t,
            tbl{n}.(cellname)(k) = {t.(cellname)(k)};
        end


%convert to new type
for p = 1:length(names)
    name = names{p};
%     nametmp = matlab.lang.makeUniqueStrings(name,varnames);
%     t.Properties.VariableNames = strrep(varnames,name,nametmp);
    t.(name) = changefn(t.(name));
%     t = removevars(t,nametmp);
end

%}
