function IndexInd = wb_findevent(eventtype,allevents)
% find event indices in EEG events (EEG.event)
% -------------------------------------------------------------------------
% Written by Li Dong (UESTC, Li_dong729@163.com)
% revised: 
%   $ 2018.7.26 compare strings after delete space characters
% -------------------------------------------------------------------------
IndexInd = [];
if ~isempty(allevents)
    % ----------
    if ischar(allevents(1).type)
        types = {allevents.type};
        % delete space characters
        for k = 1:length(types)
            temp1 = types{1,k};
            types{1,k} = temp1(~isspace(temp1));
        end
        eventtype = eventtype(~isspace(eventtype)); % delete space characters
        
        [Eventtypes, ~, ~] = unique_bc(types); % indexcolor contians the event type
        TypeInd = [];
        for j = 1:length(Eventtypes)
            k = 1;
            tempInd = [];
            for i = 1:length(types)
                if isequal(Eventtypes{j},types{i})
                    tempInd(k) = i;
                    k = k+1;
                end
            end
            TypeInd(1,j).index = tempInd;
        end
        LogiVal = cellfun(@(x) isequal(x,eventtype), Eventtypes);
    else
        [Eventtypes, ~, ~] = unique_bc([allevents.type]); % indexcolor countinas the event type
        TypeInd = [];
        for j = 1:length(Eventtypes)
            TypeInd(1,j).index = find(Eventtypes(j)==[allevents.type]);
        end
        
        if isnumeric(eventtype)
            LogiVal = Eventtypes == eventtype;
        else
            eventtype = eventtype(~isspace(eventtype)); % delete space characters
            if isnan(str2double(eventtype))
                LogiVal = Eventtypes == eventtype;
            else
                LogiVal = Eventtypes == str2double(eventtype);
            end
        end
        
    end;
    IndexInd = TypeInd(1,LogiVal); % find eventlabel
end