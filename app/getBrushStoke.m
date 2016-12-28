function [shape,texture] = getBrushStoke(fname)
% 提取笔刷
% 输入：
%   fname 笔刷图样文件名
%   textureScale 纹理缩放系数
% 输出：
%   shape 笔刷形状掩码
%   texture 笔刷颜色的比例系数

% 提取形状
im=imread(fname);
im=im2double(im);
gim=rgb2gray(im);
shape=~im2bw(gim,graythresh(gim));
shape=imerode(shape,strel('disk',9));
% 形状裁剪
rsum=sum(shape,2);
sr=find(rsum>0,1,'first');
er=find(rsum>0,1,'last');
csum=sum(shape,1);
sc=find(csum>0,1,'first');
ec=find(csum>0,1,'last');
shape=shape(sr:er,sc:ec);
gim=gim(sr:er,sc:ec);
% 提取纹理
gim(~shape)=0;
texture=gim/mean(gim(shape));
texture(~shape)=1;
end