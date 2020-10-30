% pop_MarkModeSelect() - pop up a graphic interface to select models for
% marking events
%
% Usage:
%   >> [EEG] = pop_chansel(EEG); % a window pops up
%
% Inputs:
%   EEG     - EEG data structure.
%
% Output:
%   EEG2     - modeled EEG for marking
% Written by Li Dong (Li_dong729@163.com), UESTC, $ 2015/8/7
function [EEG2] = pop_MarkModelSelect(EEG)     
    if nargin < 1
        help pop_MarkModelSelect;
        return;
    end;
    if isempty(EEG), disp('Empty input'); return; end;
    
    DEFAULT_FIG_COLOR = [1 1 1];
    % positions of buttons
    posbut(1,:) = []; 
    
    figh = figure('Color',DEFAULT_FIG_COLOR,...
        'MenuBar','none','Units','Normalized',...
        'Menu', 'None','Position',[0.1 0.1 0.6 0.6],...
        'numbertitle', 'off');
    
end