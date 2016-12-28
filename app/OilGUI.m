function varargout = OilGUI(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @OilGUI_OpeningFcn, ...
    'gui_OutputFcn',  @OilGUI_OutputFcn, ...
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

function OilGUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

function varargout = OilGUI_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

function [imScale,NBS,minLen,correctR,LSS,WSS,drawThreshs,m,n,correctCode] = getBuildParams(handles)
imScale=str2double(get(handles.imScale,'String'));
NBS=str2double(get(handles.NBS,'String'));
minLen=str2double(get(handles.minLen,'String'));
correctR=str2double(get(handles.correctR,'String'));
LSS=sscanf(get(handles.LSS,'String'),'%f');
WSS=sscanf(get(handles.WSS,'String'),'%f');
drawThreshs=sscanf(get(handles.drawThreshs,'String'),'%f');
m_n=sscanf(get(handles.m_n,'String'),'%f');
m=m_n(1);n=m_n(2);
correctCode=get(handles.correctCode,'Value');

function [lamda,textureScale] = getShowParams(handles)
lamda=get(handles.lamda,'Value');
textureScale=get(handles.textureScale,'Value');


function selectImg_Callback(hObject, eventdata, handles)
[fname,path]=uigetfile({'*.*','All Files'},'选择图片','../pics/');
if fname~=0
    im=im2double(imread(fullfile(path,fname)));
    setappdata(handles.figure,'imgName',fullfile(path,fname));
    imagesc(im,'Parent',handles.imAxis);
    axis(handles.imAxis,'equal');
    axis(handles.imAxis,'tight');
    axis(handles.imAxis,'off');
    title(handles.imAxis,'原始图片');
end


function saveImg_Callback(hObject, eventdata, handles)
[fname,path] = uiputfile('*.jpg');
if fname~=0
    canvas=getappdata(get(hObject,'Parent'),'canvas');
    if isempty(canvas)
        return;
    end
    [lamda,textureScale]=getShowParams(handles);
    load colors CS;
    im=canvas.getImg(lamda,CS,textureScale);
    imwrite(im,fullfile(path,fname));
end

function rebuild_Callback(hObject, eventdata, handles)
[imScale,NBS,minLen,correctR,LSS,WSS,drawThreshs,m,n,correctCode] = getBuildParams(handles);
[lamda,textureScale] = getShowParams(handles);
imgName=getappdata(handles.figure,'imgName');
if isempty(imgName)
    return;
end
canvas = oilPaintingForUI(imgName,imScale,minLen,m,n,LSS,WSS,drawThreshs,...
    textureScale,lamda,correctCode,correctR,NBS,handles);
setappdata(handles.figure,'canvas',canvas);

function showRes(handles)
[lamda,textureScale] = getShowParams(handles);
canvas=getappdata(handles.figure,'canvas');
if ~isempty(canvas)
    load colors CS;
    canvas.showImg(lamda,CS,textureScale,handles.oilAxis);
end

function cmp_Callback(hObject, eventdata, handles)
[lamda,textureScale] = getShowParams(handles);
canvas=getappdata(handles.figure,'canvas');
if ~isempty(canvas)
    load colors CS;
    canvas.showCmp(lamda,CS,textureScale);
end


function saveCmp_Callback(hObject, eventdata, handles)
[fname,path] = uiputfile('*.jpg');
if fname~=0
    [lamda,textureScale] = getShowParams(handles);
    canvas=getappdata(handles.figure,'canvas');
    if ~isempty(canvas)
        load colors CS;
        canvas.saveCmp(lamda,CS,textureScale,fullfile(path,fname));
    end
end


function lamda_Callback(hObject, eventdata, handles)
set(handles.lamdaText,'String',sprintf('颜色系数=%.2f',get(hObject,'Value')));
showRes(handles);


function lamda_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',0.2);

function textureScale_Callback(hObject, eventdata, handles)
set(handles.textureScaleText,'String',sprintf('纹理系数=%.2f',get(hObject,'Value')));
showRes(handles);


function textureScale_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',0.4);

function scale_Callback(hObject, eventdata, handles)
imScale=getBuildParams(handles);
minLen=round(20*imScale);
correctR=round(3*imScale);
LSS=round([60 30 12]*imScale);
WSS=round([20 10 6]*imScale);
m=round(20*imScale);
n=round(20*imScale);
set(handles.minLen,'String',num2str(minLen));
set(handles.correctR,'String',num2str(correctR));
set(handles.LSS,'String',num2str(LSS));
set(handles.WSS,'String',num2str(WSS));
set(handles.m_n,'String',num2str([m,n]));


function correctCode_Callback(hObject, eventdata, handles)

function correctCode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'Value',2);


function LSS_Callback(hObject, eventdata, handles)

function LSS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function WSS_Callback(hObject, eventdata, handles)

function WSS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function imScale_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function NBS_Callback(hObject, eventdata, handles)

function NBS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function minLen_Callback(hObject, eventdata, handles)

function minLen_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function m_n_Callback(hObject, eventdata, handles)

function m_n_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function drawThreshs_Callback(hObject, eventdata, handles)

function drawThreshs_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function correctR_Callback(hObject, eventdata, handles)

function correctR_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function imAxis_CreateFcn(hObject, eventdata, handles)

function oilAxis_CreateFcn(hObject, eventdata, handles)
