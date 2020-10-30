% eegplot helper function to read key strokes

function eegplot_readkey(src,evnt)
    if strcmp(evnt.Key, 'rightarrow')==1
        nit_eegplot('drawp',4); % edit by Li Dong (2016/3/12)
    elseif strcmp(evnt.Key, 'leftarrow')==1 
        nit_eegplot('drawp',1);% edit by Li Dong (2016/3/12)
    end
