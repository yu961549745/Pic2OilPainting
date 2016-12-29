clc,clear,close all;
addpath('../app');
imgName='D:\__study\CodeLib\Pic2OilPainting\pics\mm.jpg';
imScale=1;
minLen=20;
m=20;
n=20;
LSS=[60;30;12];
WSS=[20;10;6];
drawThreshs=[0.2;0.4;0.7];
textureScale=0.2;
lamda=0;
correctCode=2;
correctR=3;
NBS=2;
canvas = oilPainting(imgName,imScale,minLen,m,n,LSS,WSS,drawThreshs,...
    textureScale,lamda,correctCode,correctR,NBS,[]);