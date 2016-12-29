function myLog(handle,varargin)
str=sprintf(varargin{:});
if ~isempty(handle)
    handle.append(str);
else
    fprintf(str);
end
end