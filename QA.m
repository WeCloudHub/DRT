function varargout = QA(varargin)
% QA MATLAB code for QA.fig
%      QA, by itself, creates a new QA or raises the existing
%      singleton*.
%
%      H = QA returns the handle to a new QA or the handle to
%      the existing singleton*.
%
%      QA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in QA.M with the given input arguments.
%
%      QA('Property','Value',...) creates a new QA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before QA_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to QA_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help QA

% Last Modified by GUIDE v2.5 10-May-2020 17:31:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @QA_OpeningFcn, ...
                   'gui_OutputFcn',  @QA_OutputFcn, ...
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


% --- Executes just before QA is made visible.
function QA_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to QA (see VARARGIN)

% Choose default command line output for QA
handles.output = hObject;

handles.cfg.WindowSeconds=varargin{1};
handles.cfg.HighPassband=varargin{2};
handles.cfg.seleChanns=varargin{3};
handles.cfg.badWindowThreshold=varargin{4};
handles.cfg.robustDeviationThreshold=varargin{5};
handles.cfg.PowerFrequency=varargin{6};
handles.cfg.FrequencyNoiseThreshold=varargin{7};
handles.cfg.flagNotchFilter=varargin{8};
handles.cfg.correlationThreshold=varargin{9};
handles.cfg.ransacCorrelationThreshold=varargin{10};
handles.cfg.ransacChannelFraction=varargin{11};
handles.cfg.ransacSampleSize=varargin{12};

set(handles.edit_WindowSeconds, 'string',handles.cfg.WindowSeconds);
set(handles.edit_HighPassband, 'string',handles.cfg.HighPassband);
set(handles.edit_seleChanns, 'string',handles.cfg.seleChanns);
set(handles.edit_badWindowThreshold, 'string',handles.cfg.badWindowThreshold);
set(handles.edit_robustDeviationThreshold, 'string',handles.cfg.robustDeviationThreshold);
set(handles.edit_PowerFrequency, 'string',handles.cfg.PowerFrequency);

if handles.cfg.flagNotchFilter == 0
    set(handles.checkbox_NotchFilterFlag,'Value',0);
elseif handles.cfg.flagNotchFilter == 1
    set(handles.checkbox_NotchFilterFlag,'Value',1);
end

set(handles.edit_correlationThreshold, 'string',handles.cfg.correlationThreshold);
set(handles.edit_ransacCorrelationThreshold, 'string',handles.cfg.ransacCorrelationThreshold);
set(handles.edit_ransacChannelFraction, 'string',handles.cfg.ransacChannelFraction);
set(handles.edit_ransacSampleSize, 'string',handles.cfg.ransacSampleSize);

% handles.cfg.WindowSeconds=1;
% handles.cfg.HighPassband=1;
% handles.cfg.seleChanns='all';
% handles.cfg.badWindowThreshold=0.4;
% handles.cfg.robustDeviationThreshold=5;
% handles.cfg.PowerFrequency=50;
% handles.cfg.FrequencyNoiseThreshold=3;
% handles.cfg.flagNotchFilter=0;
% handles.cfg.correlationThreshold=0.6;
% handles.cfg.ransacCorrelationThreshold=[];
% handles.cfg.ransacChannelFraction=0.3;
% handles.cfg.ransacSampleSize=50;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes QA wait for user response (see UIRESUME)
uiwait(handles.QAfigure); 


% --- Outputs from this function are returned to the command line.
function varargout = QA_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
%varargout{1} = handles.output;
varargout{1}=handles.cfg.WindowSeconds;
varargout{2}=handles.cfg.HighPassband;
varargout{3}=handles.cfg.seleChanns;
varargout{4}=handles.cfg.badWindowThreshold;
varargout{5}=handles.cfg.robustDeviationThreshold;
varargout{6}=handles.cfg.PowerFrequency;
varargout{7}=handles.cfg.FrequencyNoiseThreshold;
varargout{8}=handles.cfg.flagNotchFilter;
varargout{9}=handles.cfg.correlationThreshold;
varargout{10}=handles.cfg.ransacCorrelationThreshold;
varargout{11}=handles.cfg.ransacChannelFraction;
varargout{12}=handles.cfg.ransacSampleSize;
delete(handles.QAfigure);


function edit_WindowSeconds_Callback(hObject, eventdata, handles)
% hObject    handle to edit_WindowSeconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_WindowSeconds as text
%        str2double(get(hObject,'String')) returns contents of edit_WindowSeconds as a double
WindowSeconds= str2double(get(hObject, 'String'));	
if WindowSeconds > 0
	handles.cfg.WindowSeconds = WindowSeconds;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_WindowSeconds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_WindowSeconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_HighPassband_Callback(hObject, eventdata, handles)
% hObject    handle to edit_HighPassband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_HighPassband as text
%        str2double(get(hObject,'String')) returns contents of edit_HighPassband as a double
HighPassband=str2double(get(hObject, 'String'));	
if HighPassband > 0
	handles.cfg.HighPassband = HighPassband;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end



% --- Executes during object creation, after setting all properties.
function edit_HighPassband_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_HighPassband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_seleChanns_Callback(hObject, eventdata, handles)
% hObject    handle to edit_seleChanns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_seleChanns as text
%        str2double(get(hObject,'String')) returns contents of edit_seleChanns as a double
seleChanns=get(hObject, 'String');	
handles.cfg.seleChanns = seleChanns;
guidata(hObject, handles);	


% --- Executes during object creation, after setting all properties.
function edit_seleChanns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_seleChanns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_badWindowThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_badWindowThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_badWindowThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_badWindowThreshold as a double
badWindowThreshold=str2double(get(hObject, 'String'));	
if badWindowThreshold >= 0 && badWindowThreshold <= 1
	handles.cfg.badWindowThreshold = badWindowThreshold;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_badWindowThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_badWindowThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_robustDeviationThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_robustDeviationThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_robustDeviationThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_robustDeviationThreshold as a double
robustDeviationThreshold= str2double(get(hObject, 'String'));	
if robustDeviationThreshold >= 0 
        handles.cfg.robustDeviationThreshold= robustDeviationThreshold;
        guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_robustDeviationThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_robustDeviationThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_PowerFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to edit_PowerFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_PowerFrequency as text
%        str2double(get(hObject,'String')) returns contents of edit_PowerFrequency as a double
PowerFrequency= str2double(get(hObject, 'String'));	
if PowerFrequency > 0 
	handles.cfg.PowerFrequency = PowerFrequency;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_PowerFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_PowerFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_FrequencyNoiseThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_FrequencyNoiseThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_FrequencyNoiseThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_FrequencyNoiseThreshold as a double
FrequencyNoiseThreshold=str2double(get(hObject, 'String'));	
if FrequencyNoiseThreshold > 0 
	handles.cfg.FrequencyNoiseThreshold = FrequencyNoiseThreshold;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_FrequencyNoiseThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_FrequencyNoiseThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ransacSampleSize_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ransacSampleSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_ransacSampleSize as text
%        str2double(get(hObject,'String')) returns contents of edit_ransacSampleSize as a double
ransacSampleSize= str2double(get(hObject, 'String'));	
if ransacSampleSize > 0 
	handles.cfg.ransacSampleSize= ransacSampleSize;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_ransacSampleSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ransacSampleSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ransacChannelFraction_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ransacChannelFraction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_ransacChannelFraction as text
%        str2double(get(hObject,'String')) returns contents of edit_ransacChannelFraction as a double
ransacChannelFraction=str2double(get(hObject, 'String'));	
if ransacChannelFraction >= 0  && ransacChannelFraction <= 1
	handles.cfg.ransacSampleSize=ransacChannelFraction;
	guidata(hObject, handles);	
else
    uiwait(msgbox('Parameter error!','warning','warn'));
end


% --- Executes during object creation, after setting all properties.
function edit_ransacChannelFraction_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ransacChannelFraction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ransacCorrelationThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ransacCorrelationThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_ransacCorrelationThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_ransacCorrelationThreshold as a double
ransacCorrelationThreshold=str2double(get(hObject, 'String'));	
if ~isempty(ransacCorrelationThreshold)
    if ransacCorrelationThreshold >= 0  && ransacCorrelationThreshold <= 1
        handles.cfg.ransacCorrelationThreshold=ransacCorrelationThreshold;
        guidata(hObject, handles);	
    else
        uiwait(msgbox('Parameter error!','warning','warn'));
    end
end


% --- Executes during object creation, after setting all properties.
function edit_ransacCorrelationThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ransacCorrelationThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_NotchFilterFlag.
function checkbox_NotchFilterFlag_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_NotchFilterFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_NotchFilterFlag
flagNotchFilter=get(hObject,'Value');
if flagNotchFilter == 1
    handles.cfg.flagNotchFilter = 1;
else
    handles.cfg.flagNotchFilter = 0;
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton_Cancel.
function pushbutton_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.QAfigure);

% --- Executes on button press in pushbutton_OK.
function pushbutton_OK_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.QAfigure);

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doc wb_pipeline_EEG_QA;

   

function edit_correlationThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_correlationThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_correlationThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_correlationThreshold as a double
correlationThreshold=str2double(get(hObject, 'String'));	
if ~isempty(correlationThreshold)
    if correlationThreshold >= 0  && correlationThreshold <= 1
        handles.cfg.correlationThreshold=correlationThreshold;
        guidata(hObject, handles);	
    else
        uiwait(msgbox('Parameter error!','warning','warn'));
    end
end


% --- Executes during object creation, after setting all properties.
function edit_correlationThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_correlationThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
