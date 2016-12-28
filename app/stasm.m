function P = stasm(impath)
P=mexStasm(impath,'../data');
if ~ischar(P)
    P=floor(P')+1;
end
end