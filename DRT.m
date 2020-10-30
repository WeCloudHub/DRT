function varargout = DRT(varargin)
%--------------------------------------------------------------------------
% The detailed description of options
% [edit] InputPath  : Select the folder where the raw data files are stored
% [edit] OutputPath : Select the folder where the result data files are generated
%
%% Mode %%
% [radiobutton] OnlySEDS         : Execute wb_EEGfiles_Standardization functions only
% [radiobutton] OnlyQA           : Execute wb_pipeline_EEG_QA functions only
% [radiobutton] SEDS->QA(default): Execute wb_EEGfiles_Standization functions before wb_pipeline_EEG QA functions
%
%% SEDS %%
% [checkbox] Add the sub-XXXXX (default is unchecked)                       : If checked, the name of folder where raw data file is stored is "sub-XXXXX_<FilePath>.<FileName>".
% [checkbox] Same as the name of original file (default is checked)         : If checked, the name of folder is same as the name of original file.
% [checkbox] Compress into zip package (default is checked)                 : If checked, each data files will be packaged into zip
% [checkbox] Convert into EEGLAB files(*.set and *fdt)(default is unchecked): If checked, raw data files will be converted into the data format conforming to the EEGLAB (*.set && *.fdt). 
%                                                                             Currently, the supported EEG data formats include: neroscan(*.CNT), biosmi(*.bdf), European data format(*.edf), 
%                                                                             brainvision (*.vhdr),ASCLL file(*.txt) and MATLAB data file (*.mat).
% [checkbox] Generate descriptive files (default is checked)                : If checked, the info,event and channel descriptive files will be generated in the same 
%                                                                             directory as data file
%  
%% Extend %%
% [pushbutton] QA : Enter QA parameter configuration interface
% 
%% Capture filter %%
% Operation 
%   [radiobutton] Include(default): Extract files including keywords
%   [radiobutton] Exclude         : Remove files with keywords
% type  
%   [radiobutton] FolderName       : Keywords from folder name
%   [radiobutton] FileName(default): Keywords from file name
%   [radiobutton] QA               : Keywords from QA results
% [edit] KeyWord (default is null) : Fill in the corresponding keywords according to the type of filter 
%      
%% Import Information %%
% [edit] Sample rate(default is null)                   : Sample rate is required when data format is *.txt and *.mat 
% [edit] Select channels location file(default is null) : If the raw data files are to be converted into EEGLAB files,
%                                                         the channels location file is required when data format is *.txt and *.mat 
%
% -------------------------------------------------------------------------
% Written by Yufan Zhang (zyf15816794709@163.com)
% $ 2020.5.5   V0.1  first version
% $ 2020.8.18  V0.6  developing version for ifly
% -------------------------------------------------------------------------

%% DRT code %%
% DRT MATLAB code for DRT.fig
%      DRT, by itself, creates a new DRT or raises the existing
%      singleton*.
%
%      H = DRT returns the handle to a new DRT or the handle to
%      the existing singleton*.
%
%      DRT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DRT.M with the given input arguments.
%
%      DRT('Property','Value',...) creates a new DRT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DRT_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DRT_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DRT

% Last Modified by GUIDE v2.5 02-Jul-2020 22:26:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DRT_OpeningFcn, ...
                   'gui_OutputFcn',  @DRT_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

if nargin == 0
    disp(datestr(now));
    fprintf('Welcome to Data Restructure toolbox (DRT). \n');
    fprintf('The current release is V1.0 and you can be available from Website(https://webrain.uestc.edu.cn/) \nand Wiki(https://github.com/WeCloudHub/DRT). \n');   
end

% add the paths
% -------------
DRTpath = which('DRT.m');
DRTpath = DRTpath(1:end-length('DRT.m'));
if strcmpi(DRTpath, './') || strcmpi(DRTpath, '.\')
    DRTpath = [ pwd filesep ];
end;

addpath(genpath([DRTpath,'libs']));
addpath(genpath([DRTpath,'customs']));


% --- Executes just before DRT is made visible.
function DRT_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DRT (see VARARGIN)

% Choose default command line output for DRT
handles.output = hObject;

global GUI_InputPath GUI_OutputPath GUI_KeyWord;
%-----------init Parameter--------------------
if isempty(GUI_InputPath)
    handles.cfg.InputPath=[]; 
else
    handles.cfg.InputPath=GUI_InputPath; 
end
if isempty(GUI_OutputPath)
    handles.cfg.OutputPath=[]; 
else
    handles.cfg.OutputPath=GUI_OutputPath; 
end
if isempty(GUI_KeyWord)
    handles.cfg.KeyWord=[]; 
else
    handles.cfg.KeyWord=GUI_KeyWord; 
end


handles.cfg.combs_project_id=1;
set(handles.edit_InputPath,'string',handles.cfg.InputPath);
set(handles.edit_OutputPath,'string',handles.cfg.OutputPath);
set(handles.edit_KeyWord,'string',handles.cfg.KeyWord);

s=sprintf('If checked, raw data files will be converted into the data format conforming to the EEGLAB (*.set && *.fdt).\n Currently, the supported EEG data formats include: neroscan(*.CNT), biosmi(*.bdf), European data format(*.EDF), \n brainvision (*.vhdr),ASCLL file(*.txt) and MATLAB data file (*.mat). ');
set(handles.checkbox_All2setFlag,'TooltipString',s);

%Mode
handles.cfg.Mode_Flag=1; % 1：OnlySEDS  2:OnlyQA  3:SEDS2QA
set(handles.radiobutton_OnlySEDS,'Value',1);
set(handles.radiobutton_OnlyQA,'Value',0);
set(handles.radiobutton_SEDS2QA,'Value',0);
     
set(handles.checkbox_AddSubFlag,'enable','on');
set(handles.checkbox_SameFileNameFlag,'enable','on');
set(handles.checkbox_CompressFlag,'enable','on');
set(handles.checkbox_All2setFlag,'enable','on');
set(handles.checkbox_GenDescriptionFlag,'enable','on');
set(handles.pushbutton_QA,'enable','off');

%SEDS
handles.cfg.SubFlag='0';
set(handles.checkbox_AddSubFlag,'Value',0);

handles.cfg.CompressFlag='1';
set(handles.checkbox_CompressFlag,'Value',1);

handles.cfg.All2setFlag='0';
set(handles.checkbox_All2setFlag,'Value',0);

if  handles.cfg.All2setFlag=='0'
    set(handles.text10,'enable','off');
    set(handles.text11,'enable','off');
    set(handles.edit_srate,'enable','off');
    set(handles.edit_ChanlocsFile,'enable','off');
    set(handles.pushbutton_ChanlocsFile,'enable','off');
elseif handles.cfg.All2setFlag=='1'
    set(handles.text10,'enable','on');
    set(handles.text11,'enable','on');
    set(handles.edit_srate,'enable','on');
    set(handles.edit_ChanlocsFile,'enable','on');
    set(handles.pushbutton_ChanlocsFile,'enable','on');        
end

handles.cfg.GenDescriptionFlag='1';
set(handles.checkbox_GenDescriptionFlag,'Value',1);

handles.cfg.SameFileNameFlag='1';
set(handles.checkbox_SameFileNameFlag,'Value',1);

handles.cfg.ArrangeFlag='0'; %0：extract  1：remove
set(handles.radiobutton_Extract,'Value',1);
set(handles.radiobutton_Remove,'Value',0);

%Capture
handles.cfg.CaptureType_Flag='2'; % 1：FolderName 2:FileName 3:QA
set(handles.radiobutton_type_FolderName,'Value',0);
set(handles.radiobutton_type_FileName,'Value',1);
set(handles.radiobutton_type_QA,'Value',0);

% handles.cfg.KeyWord=' ';
handles.cfg.srate=[];
handles.cfg.ChanlocsFile=[];

set(handles.edit_KeyWord,'string',handles.cfg.KeyWord);
set(handles.edit_srate,'string',handles.cfg.srate);
set(handles.edit_ChanlocsFile,'string',handles.cfg.ChanlocsFile);

%QA
handles.cfg.WindowSeconds=1;
handles.cfg.HighPassband=1;
handles.cfg.seleChanns='all';
handles.cfg.badWindowThreshold=0.4;
handles.cfg.robustDeviationThreshold=5;
handles.cfg.PowerFrequency=50;
handles.cfg.FrequencyNoiseThreshold=3;
handles.cfg.flagNotchFilter=0;
handles.cfg.correlationThreshold=0.6;
handles.cfg.ransacCorrelationThreshold=[];
handles.cfg.ransacChannelFraction=0.3;
handles.cfg.ransacSampleSize=50;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DRT wait for user response (see UIRESUME)
% uiwait(handles.DRTfigure);

% [handles.cfg.WindowSeconds,handles.cfg.HighPassband,handles.cfg.badWindowThreshold]=QA;
% uiwait(handles.DRTfigure);


% --- Outputs from this function are returned to the command line.
function varargout = DRT_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton_Extract.
function radiobutton_Extract_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_Extract (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_Extract
ExtractValue=get(hObject,'Value');
if ExtractValue == 1
    handles.cfg.ArrangeFlag='0';
    set(handles.radiobutton_Remove,'Value',0);
    guidata(hObject, handles);
else
    handles.cfg.ArrangeFlag='1';
    set(handles.radiobutton_Remove,'Value',1);
    guidata(hObject, handles);
end
    
% --- Executes on button press in radiobutton_Remove.
function radiobutton_Remove_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_Remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_Remove
RemoveValue=get(hObject,'Value');
if RemoveValue == 1
    handles.cfg.ArrangeFlag='1'; 
    set(handles.radiobutton_Extract,'Value',0);
    guidata(hObject, handles);
else
    handles.cfg.ArrangeFlag='0';
    set(handles.radiobutton_Extract,'Value',1);
    guidata(hObject, handles);
end
    

% --- Executes on button press in pushbutton_OK.
function pushbutton_OK_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.cfg.InputPath)
    uiwait(msgbox('Please select the InputPath!','warning','warn'));
    return;
end
if isempty(handles.cfg.OutputPath)
    uiwait(msgbox('Please select the OutputPath!','warning','warn'));
    return;
end

global bar bar_str;

bar=waitbar(0,'运行中...')    % waitbar显示进度条
bar_str=['运行中...','0','%']    % 百分比形式显示处理进程,不需要删掉这行代码就行
waitbar(0,bar,bar_str)        % 更新进度条bar，配合bar使用

if handles.cfg.Mode_Flag == 1 
    wb_EEGfiles_Standardization(...
    handles.cfg.InputPath,...
    handles.cfg.OutputPath,...
    handles.cfg.SubFlag,...
    handles.cfg.CompressFlag,...
    handles.cfg.All2setFlag,...
    handles.cfg.GenDescriptionFlag,...
    handles.cfg.SameFileNameFlag,...
    handles.cfg.ArrangeFlag,...
    handles.cfg.CaptureType_Flag,...
    handles.cfg.KeyWord,...
    handles.cfg.srate,...
    handles.cfg.ChanlocsFile,...
    handles.cfg.Mode_Flag);

    str=['运行结束','100','%'];   
    waitbar(100/100,bar,str);      % 更新进度条bar
    
elseif handles.cfg.Mode_Flag == 2
    QA_InputFile=wb_EEGfiles_Search(handles.cfg.InputPath);
    if isempty(handles.cfg.srate)
        QA_srate='[]';
    end
    wb_pipeline_EEG_QA(...
    QA_InputFile,...
    handles.cfg.OutputPath,...
    handles.cfg.combs_project_id,...
    handles.cfg.WindowSeconds,...
    handles.cfg.HighPassband,...
    handles.cfg.seleChanns,...
    handles.cfg.badWindowThreshold,...
    handles.cfg.robustDeviationThreshold,...
    handles.cfg.PowerFrequency,...
    handles.cfg.FrequencyNoiseThreshold,...
    handles.cfg.flagNotchFilter,...
    handles.cfg.correlationThreshold,...
    handles.cfg.ransacCorrelationThreshold,...
    handles.cfg.ransacChannelFraction,...
    handles.cfg.ransacSampleSize,...
    QA_srate,...
    handles.cfg.Mode_Flag);

    str=['运行结束','100','%'];    
    waitbar(100/100,bar,str)        % 更新进度条bar
    
elseif handles.cfg.Mode_Flag == 3  
 
    SEDS_OutputPath = [handles.cfg.OutputPath,filesep,'SEDS'];
    mkdir(SEDS_OutputPath);
    if isempty(handles.cfg.srate)
        QA_srate='[]';
    end
    wb_EEGfiles_Standardization(...
    handles.cfg.InputPath,...
    SEDS_OutputPath,...
    handles.cfg.SubFlag,...
    handles.cfg.CompressFlag,...
    handles.cfg.All2setFlag,...
    handles.cfg.GenDescriptionFlag,...
    handles.cfg.SameFileNameFlag,...
    handles.cfg.ArrangeFlag,...
    handles.cfg.CaptureType_Flag,...
    handles.cfg.KeyWord,...
    handles.cfg.srate,...
    handles.cfg.ChanlocsFile,... 
    handles.cfg.Mode_Flag);
        
    str=['运行中...','50','%'];   
    waitbar(50/100,bar,str);        % 更新进度条bar
    
    QA_OutputPath = [handles.cfg.OutputPath,filesep,'QA'];
    mkdir(QA_OutputPath);
    QA_InputFile=wb_EEGfiles_Search(SEDS_OutputPath);
    wb_pipeline_EEG_QA(...
    QA_InputFile,...
    QA_OutputPath,...
    handles.cfg.combs_project_id,...
    handles.cfg.WindowSeconds,...
    handles.cfg.HighPassband,...
    handles.cfg.seleChanns,...
    handles.cfg.badWindowThreshold,...
    handles.cfg.robustDeviationThreshold,...
    handles.cfg.PowerFrequency,...
    handles.cfg.FrequencyNoiseThreshold,...
    handles.cfg.flagNotchFilter,...
    handles.cfg.correlationThreshold,...
    handles.cfg.ransacCorrelationThreshold,...
    handles.cfg.ransacChannelFraction,...
    handles.cfg.ransacSampleSize,...
    QA_srate,...
    handles.cfg.Mode_Flag);

    if handles.cfg.CaptureType_Flag=='3'; 
        QA_tablefile = [QA_OutputPath,filesep,'TaskID-1_QA_table.mat'];
        CaptureFilter_OutputPath = [handles.cfg.OutputPath,filesep,'FilteredSEDS']; 
        mkdir(CaptureFilter_OutputPath);
        wb_EEGfiles_CaptureFilter(SEDS_OutputPath,CaptureFilter_OutputPath,QA_tablefile,handles.cfg.ArrangeFlag,handles.cfg.KeyWord) ;
    end
 
    str=['运行结束.','100','%'];   
    waitbar(100/100,bar,str)        % 更新进度条bar
end
    

% --- Executes on button press in pushbutton_Cancel.
function pushbutton_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.DRTfigure);


% --- Executes on button press in pushbutton_InputPath.
function pushbutton_InputPath_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_InputPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
InputPath=uigetdir('*', 'Select the input path of EEG data files of a participant');
if InputPath ~=0,
   handles.cfg.InputPath=InputPath ;
   set(handles.edit_InputPath, 'string',handles.cfg.InputPath);
   guidata(hObject, handles);
end;


function edit_InputPath_Callback(hObject, eventdata, handles)
% hObject    handle to edit_InputPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_InputPath as text
%        str2double(get(hObject,'String')) returns contents of edit_InputPath as a double
InputPath=get(hObject, 'String');	



% --- Executes during object creation, after setting all properties.
function edit_InputPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_InputPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_KeyWord_Callback(hObject, eventdata, handles)
% hObject    handle to edit_KeyWord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_KeyWord as text
%        str2double(get(hObject,'String')) returns contents of edit_KeyWord as a double
handles.cfg.KeyWord=get(hObject, 'String');	
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_KeyWord_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_KeyWord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_OutputPath_Callback(hObject, eventdata, handles)
% hObject    handle to edit_OutputPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_OutputPath as text
%        str2double(get(hObject,'String')) returns contents of edit_OutputPath as a double
OutputPath =get(hObject, 'String');	

% --- Executes during object creation, after setting all properties.
function edit_OutputPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_OutputPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_OutputPath.
function pushbutton_OutputPath_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_OutputPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
OutputPath=uigetdir('*', 'Select the output path of EEG data files');
if OutputPath ~=0
   handles.cfg.OutputPath=OutputPath;
   set(handles.edit_OutputPath, 'string',OutputPath);
   guidata(hObject, handles);
end;
%clear filename filepath tagOutputPath;


% --- Executes on button press in checkbox_AddSubFlag.
function checkbox_AddSubFlag_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_AddSubFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_AddSubFlag
AddSubFlag=get(hObject,'Value');
if AddSubFlag == 1
    handles.cfg.SubFlag = '1';
else
    handles.cfg.SubFlag = '0';
end
guidata(hObject, handles);

% --- Executes on button press in checkbox_CompressFlag.
function checkbox_CompressFlag_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_CompressFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_CompressFlag
CompressFlag=get(hObject,'Value');
if CompressFlag == 1
    handles.cfg.CompressFlag = '1';
else
    handles.cfg.CompressFlag = '0';
end
guidata(hObject, handles);

% --- Executes on button press in checkbox_All2setFlag.
function checkbox_All2setFlag_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_All2setFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_All2setFlag
All2setFlag=get(hObject,'Value');
if All2setFlag == 1
    handles.cfg.All2setFlag = '1';
else
    handles.cfg.All2setFlag = '0';
end

if  handles.cfg.All2setFlag=='0'
    set(handles.text10,'enable','off');
    set(handles.text11,'enable','off');
    set(handles.edit_srate,'enable','off');
    set(handles.edit_ChanlocsFile,'enable','off');
    set(handles.pushbutton_ChanlocsFile,'enable','off');	
%     if handles.cfg.Mode_Flag==3
%         set(handles.text10,'enable','on');
%         set(handles.text11,'enable','off');
%         set(handles.edit_srate,'enable','on');
%         set(handles.edit_ChanlocsFile,'enable','off');
%         set(handles.pushbutton_ChanlocsFile,'enable','off');            
% 	else 
%         set(handles.text10,'enable','off');
%         set(handles.text11,'enable','off');
%         set(handles.edit_srate,'enable','off');
%         set(handles.edit_ChanlocsFile,'enable','off');
%         set(handles.pushbutton_ChanlocsFile,'enable','off');
%     end
elseif handles.cfg.All2setFlag=='1'
    set(handles.text10,'enable','on');
    set(handles.text11,'enable','on');
    set(handles.edit_srate,'enable','on');
    set(handles.edit_ChanlocsFile,'enable','on');
    set(handles.pushbutton_ChanlocsFile,'enable','on');        
end
guidata(hObject, handles);


% --- Executes on button press in checkbox_SameFileNameFlag.
function checkbox_SameFileNameFlag_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_SameFileNameFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_SameFileNameFlag
SameFileNameFlag=get(hObject,'Value');
if SameFileNameFlag == 1
    handles.cfg.SameFileNameFlag = '1';
else
    handles.cfg.SameFileNameFlag = '0';
end
guidata(hObject, handles);

% --- Executes on button press in radiobutton_type_FolderName.
function radiobutton_type_FolderName_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_type_FolderName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_type_FolderName
Value=get(hObject,'Value');
if Value == 1
    set(handles.radiobutton_type_FolderName,'Value',1);
    set(handles.radiobutton_type_FileName,'Value',0);
    set(handles.radiobutton_type_QA,'Value',0);
    handles.cfg.CaptureType_Flag='1'; % 1：FolderName 2:FileName  3:QA
    guidata(hObject, handles);
elseif Value == 0
    set(handles.radiobutton_type_FolderName,'Value',0);
    set(handles.radiobutton_type_FileName,'Value',1);
    set(handles.radiobutton_type_QA,'Value',0);
    handles.cfg.CaptureType_Flag='2'; % 1：FolderName 2:FileName 3:QA
    guidata(hObject, handles);  
end

% --- Executes on button press in radiobutton_type_FileName.
function radiobutton_type_FileName_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_type_FileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_type_FileName
Value=get(hObject,'Value');
if Value == 1
    set(handles.radiobutton_type_FolderName,'Value',0);
    set(handles.radiobutton_type_FileName,'Value',1);
    set(handles.radiobutton_type_QA,'Value',0);
    handles.cfg.CaptureType_Flag='2'; % 1：FolderName 2:FileName  3:QA
    guidata(hObject, handles);
elseif Value == 0
    set(handles.radiobutton_type_FolderName,'Value',1);
    set(handles.radiobutton_type_FileName,'Value',0);
    set(handles.radiobutton_type_QA,'Value',0);
    handles.cfg.CaptureType_Flag='1'; % 1：FolderName 2:FileName 3:QA
    guidata(hObject, handles);
end


% --- Executes on button press in checkbox_GenDescriptionFlag.
function checkbox_GenDescriptionFlag_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_GenDescriptionFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_GenDescriptionFlag
GenDescriptionFlag=get(hObject,'Value');
if GenDescriptionFlag == 1
    handles.cfg.GenDescriptionFlag = '1';
else
    handles.cfg.GenDescriptionFlag = '0';
end
guidata(hObject, handles);

function edit_srate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_srate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_srate as text
%        str2double(get(hObject,'String')) returns contents of edit_srate as a double
srate=get(hObject,'String');
if isempty(srate)
    handles.cfg.srate='[]';
else
    handles.cfg.srate=srate;  %str2num(srate); 
end
guidata(hObject, handles);
    
% --- Executes during object creation, after setting all properties.
function edit_srate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_srate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_ChanlocsFile_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ChanlocsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_ChanlocsFile as text
%        str2double(get(hObject,'String')) returns contents of edit_ChanlocsFile as a double
handles.cfg.ChanlocsFile=get(hObject,'String');


% --- Executes during object creation, after setting all properties.
function edit_ChanlocsFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ChanlocsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_ChanlocsFile.
function pushbutton_ChanlocsFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ChanlocsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, filepath]=uigetfile('*', 'Select a channels location file');
if filename(1) ~=0,
   handles.cfg.ChanlocsFile=[filepath filename];
   set(handles.edit_ChanlocsFile, 'string',handles.cfg.ChanlocsFile);
   guidata(hObject, handles);
end;
%clear filename filepath pushbutton_ChanlocsFile;

% --- Executes on button press in pushbutton_QA.
function pushbutton_QA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_QA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[out1,out2,out3,out4,out5,out6,out7,out8,out9,out10,out11,out12]=QA(handles.cfg.WindowSeconds,...
                                                                    handles.cfg.HighPassband,...
                                                                    handles.cfg.seleChanns,...
                                                                    handles.cfg.badWindowThreshold,...
                                                                    handles.cfg.robustDeviationThreshold,...
                                                                    handles.cfg.PowerFrequency,...
                                                                    handles.cfg.FrequencyNoiseThreshold,...
                                                                    handles.cfg.flagNotchFilter,...
                                                                    handles.cfg.correlationThreshold,...
                                                                    handles.cfg.ransacCorrelationThreshold,...
                                                                    handles.cfg.ransacChannelFraction,...
                                                                    handles.cfg.ransacSampleSize) ;
                                                              
handles.cfg.WindowSecond=out1;
handles.cfg.HighPassband=out2;
handles.cfg.seleChanns=out3;
handles.cfg.badWindowThreshold=out4;
handles.cfg.robustDeviationThreshold=out5;
handles.cfg.PowerFrequency=out6;
handles.cfg.FrequencyNoiseThreshold=out7;
handles.cfg.flagNotchFilter=out8;
handles.cfg.correlationThreshold=out9;
handles.cfg.ransacCorrelationThreshold=out10;
handles.cfg.ransacChannelFraction=out11;
handles.cfg.ransacSampleSize=out12;

guidata(hObject, handles);


% --- Executes on button press in pushbutton_help.
function pushbutton_help_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doc DRT

% --- Executes on button press in radiobutton_OnlySEDS.
function radiobutton_OnlySEDS_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_OnlySEDS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_OnlySEDS
Value=get(hObject,'Value');
if Value == 1
    set(handles.radiobutton_OnlySEDS,'Value',1);
    set(handles.radiobutton_OnlyQA,'Value',0);
    set(handles.radiobutton_SEDS2QA,'Value',0);
    handles.cfg.Mode_Flag=1; 
     
    set(handles.checkbox_AddSubFlag,'enable','on');
    set(handles.checkbox_SameFileNameFlag,'enable','on');
    set(handles.checkbox_CompressFlag,'enable','on');
    set(handles.checkbox_All2setFlag,'enable','on');
    set(handles.checkbox_GenDescriptionFlag,'enable','on');
    set(handles.pushbutton_QA,'enable','off');
 
    set(handles.text12,'enable','on');
    set(handles.text13,'enable','on');
    set(handles.text9,'enable','on'); 
    set(handles.radiobutton_Extract,'enable','on');
    set(handles.radiobutton_Remove,'enable','on');
    set(handles.radiobutton_type_FolderName,'enable','on');
    set(handles.radiobutton_type_FileName,'enable','on');
    set(handles.radiobutton_type_QA,'enable','off');  
    set(handles.edit_KeyWord,'enable','on');
    
    if  handles.cfg.All2setFlag=='0'
        set(handles.text10,'enable','off');
        set(handles.text11,'enable','off');
        set(handles.edit_srate,'enable','off');
        set(handles.edit_ChanlocsFile,'enable','off');
        set(handles.pushbutton_ChanlocsFile,'enable','off');
    elseif handles.cfg.All2setFlag=='1'
        set(handles.text10,'enable','on');
        set(handles.text11,'enable','on');
        set(handles.edit_srate,'enable','on');
        set(handles.edit_ChanlocsFile,'enable','on');
        set(handles.pushbutton_ChanlocsFile,'enable','on');        
    end
    guidata(hObject, handles);
end


% --- Executes on button press in radiobutton_OnlyQA.
function radiobutton_OnlyQA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_OnlyQA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_OnlyQA
Value=get(hObject,'Value');
if Value == 1
    set(handles.radiobutton_OnlySEDS,'Value',0);
    set(handles.radiobutton_OnlyQA,'Value',1);
    set(handles.radiobutton_SEDS2QA,'Value',0);
    handles.cfg.Mode_Flag=2; 
       
    set(handles.checkbox_AddSubFlag,'enable','off');
    set(handles.checkbox_SameFileNameFlag,'enable','off');
    set(handles.checkbox_CompressFlag,'enable','off');
    set(handles.checkbox_All2setFlag,'enable','off');
    set(handles.checkbox_GenDescriptionFlag,'enable','off');
    set(handles.pushbutton_QA,'enable','on');
     
    set(handles.text10,'enable','on');
    set(handles.text11,'enable','off');
    set(handles.edit_srate,'enable','on');
    set(handles.edit_ChanlocsFile,'enable','off');
    set(handles.pushbutton_ChanlocsFile,'enable','off');     
 
    set(handles.text12,'enable','off');
    set(handles.text13,'enable','off');
    set(handles.text9,'enable','off'); 
    set(handles.radiobutton_Extract,'enable','off');
    set(handles.radiobutton_Remove,'enable','off');
    set(handles.radiobutton_type_FolderName,'enable','off');
    set(handles.radiobutton_type_FileName,'enable','off');
    set(handles.radiobutton_type_QA,'enable','off');  
    set(handles.edit_KeyWord,'enable','off');
  
    guidata(hObject, handles);
end

% --- Executes on button press in radiobutton_SEDS2QA.
function radiobutton_SEDS2QA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_SEDS2QA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_SEDS2QA
Value=get(hObject,'Value');
if Value == 1
    set(handles.radiobutton_OnlySEDS,'Value',0);
    set(handles.radiobutton_OnlyQA,'Value',0);
    set(handles.radiobutton_SEDS2QA,'Value',1);
    handles.cfg.Mode_Flag=3; 
          
    set(handles.checkbox_AddSubFlag,'enable','on');
    set(handles.checkbox_SameFileNameFlag,'enable','on');
    set(handles.checkbox_CompressFlag,'enable','on');
    set(handles.checkbox_All2setFlag,'enable','on');
    set(handles.checkbox_GenDescriptionFlag,'enable','on');
    set(handles.pushbutton_QA,'enable','on');

    set(handles.text12,'enable','on');
    set(handles.text13,'enable','on');
    set(handles.text9,'enable','on'); 
    set(handles.radiobutton_Extract,'enable','on');
    set(handles.radiobutton_Remove,'enable','on');
    set(handles.radiobutton_type_FolderName,'enable','on');
    set(handles.radiobutton_type_FileName,'enable','on');
    set(handles.radiobutton_type_QA,'enable','on');  
    set(handles.edit_KeyWord,'enable','on');
    
	if  handles.cfg.All2setFlag=='0'
        set(handles.text10,'enable','off');
        set(handles.text11,'enable','off');
        set(handles.edit_srate,'enable','off');
        set(handles.edit_ChanlocsFile,'enable','off');
        set(handles.pushbutton_ChanlocsFile,'enable','off'); 
    elseif handles.cfg.All2setFlag=='1'
        set(handles.text10,'enable','on');
        set(handles.text11,'enable','on');
        set(handles.edit_srate,'enable','on');
        set(handles.edit_ChanlocsFile,'enable','on');
        set(handles.pushbutton_ChanlocsFile,'enable','on');     
    end
    guidata(hObject, handles);
end

% --- Executes on button press in radiobutton_type_QA.
function radiobutton_type_QA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_type_QA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_type_QA
Value=get(hObject,'Value');
if Value == 1
    set(handles.radiobutton_type_FolderName,'Value',0);
    set(handles.radiobutton_type_FileName,'Value',0);
    set(handles.radiobutton_type_QA,'Value',1);
    handles.cfg.CaptureType_Flag='3'; % 1：FolderName 2:FileName 3:QA
    guidata(hObject, handles);
elseif Value == 0
    set(handles.radiobutton_type_FolderName,'Value',0);
    set(handles.radiobutton_type_FileName,'Value',1);
    set(handles.radiobutton_type_QA,'Value',0);
    handles.cfg.CaptureType_Flag='2'; % 1：FolderName 2:FileName 3:QA
    guidata(hObject, handles);
end


% --- Executes when user attempts to close DRTfigure.
function DRTfigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to DRTfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global GUI_InputPath GUI_OutputPath GUI_KeyWord;
GUI_InputPath=handles.cfg.InputPath;
GUI_OutputPath=handles.cfg.OutputPath;
GUI_KeyWord=handles.cfg.KeyWord; 
disp(datestr(now));
fprintf('Operation has been cancelled\n'); 
delete(hObject);
