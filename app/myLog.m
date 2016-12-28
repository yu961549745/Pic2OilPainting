function myLog(handles,varargin)
hlog=getappdata(handles.figure,'hlog');
str=sprintf(varargin{:});
hlog.append(str);
end