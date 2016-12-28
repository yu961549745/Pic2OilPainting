function fs = getlib(path)
fs=dir(path);
fs=arrayfun(@(x){x.name},fs(3:end));
fs=fs(cellfun(@(x)~isempty(regexp(x,'.*?\.lib','once'))&&...
    isempty(regexp(x,'.*?d\.lib','once')),fs));
end