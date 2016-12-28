% æ≤Ã¨±‡“Î STASM Œ™ mex
clc,clear,close all;
fname='mexStasm.cpp';
cvLibPath='D:/opencv2411/build/x64/vc12/staticlib';
cvIncludePath='D:/opencv2411/build/include';
stasmPath='D:/__study/CodeLib/ Ó∆⁄ µœ∞/stasm4.1.0/stasm';
opts=[{['-L',cvLibPath];
    ['-I',stasmPath];
    ['-I',fullfile(stasmPath,'/MOD_1')];
    ['-I',cvIncludePath];
    'COMPFLAGS="/Zp8 /GR /W3 /EHs /nologo /MT"';};
    cellfun(@(x){sprintf('-l%s',x)},...
    getlib(cvLibPath));];
fs=findCpp(stasmPath);
mex('-v',opts{:},fname,fs{:},'-output','../app/mexStasm');