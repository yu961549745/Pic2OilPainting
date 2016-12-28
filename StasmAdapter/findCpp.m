function fs = findCpp(path)
list=java.util.ArrayList();
addCpp(list,path);
n=list.size();
fs=cell(n,1);
for i=1:n
    fs{i}=list.get(i-1);
end
end
function addCpp(list,path)
fs=dir(path);
for i=3:length(fs)
    if fs(i).isdir
        addCpp(list,fullfile(path,fs(i).name));
    elseif ~isempty(regexp(fs(i).name,'.*\.cpp','once'))
        list.add(fullfile(path,fs(i).name));
    end
end
end