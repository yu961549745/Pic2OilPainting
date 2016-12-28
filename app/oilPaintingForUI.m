function canvas = oilPaintingForUI(imgName,imScale,minLen,m,n,LSS,WSS,drawThreshs,...
    textureScale,lamda,correctCode,correctR,NBS,handles)
% 油画风格化绘制
% 输入：
%   imgName 图片路径
%   imScale 图片缩放倍数，图片越大，笔刷纹理越清晰，但所需时间越长。
%   minLen 基于边界提取特征方向时的最短直线长度
%   m,n 绘制第一层第二层笔刷的网格大小
%   LSS,WSS 三层笔刷的宽度和长度
%   drawTrreshs 三层笔刷的落笔阈值，在[0,1]之间，因为这里的图片颜色用0,1之间的
%               浮点数表示
%   textureScale 从模板读取笔刷的纹理缩放系数，系数越大纹理越明显，但有可能过曝
%   lamda 图片颜色和模板颜色的加权系数,0,1之间，越小越接近模板颜色
%   correctCode 修正方案代码：
%               1 表示基于人脸轮廓进行修正
%               2 表示基于图像边界进行修正
%               在无法识别人脸时默认调用方案1
%   correctR 修正半径
%   NBS 笔刷模板数，即bs文件夹下bs%d.png的文件个数，笔刷模板用png格式存储，
%       默认纹理是横向的。
%   handles OilGUI的句柄
% 输出：
%   canvas 绘制结果

[~,name,ext]=fileparts(imgName);
myLog(handles,'%s%s\n',name,ext);
startTime=tic();
% 图片准备
im=im2double(imread(imgName));
im=imresize(im,imScale);
scaledImgName=strcat(imgName,'.jpg');
imwrite(im,scaledImgName);
gim=rgb2gray(im);
[M,N]=size(gim);

% 获取插值基向量

cla(handles.oilAxis);
imagesc(gim,'Parent',handles.oilAxis);
axis(handles.oilAxis,'equal');
axis(handles.oilAxis,'tight');
axis(handles.oilAxis,'off');
colormap gray;
hold(handles.oilAxis,'on');
title(handles.oilAxis,'');
drawnow;

myLog(handles,'获取基向量...\n');
myLog(handles,'基于特征边界...\n');
tic
[cs1,rs1,ds1]=loadFromHoughEdge(im,minLen,handles);
title(handles.oilAxis,'基于特征边界');
drawnow;
myLog(handles,'时间已过 %f 秒。\n',toc);
myLog(handles,'基于人脸识别...\n');
tic
if correctCode==2
    [cs2,rs2,ds2,edgeBW]=loadFromSTASM(scaledImgName,handles);
else
    [cs2,rs2,ds2]=loadFromSTASM(scaledImgName,handles);
end
title(handles.oilAxis,'基于人脸识别');
drawnow;
myLog(handles,'时间已过 %f 秒。\n',toc);
cs=[cs1;cs2];
rs=[rs1;rs2];
ds=[ds1;ds2];

% 插值计算方向
tic
myLog(handles,'计算方向...\n');
R=(m+n)/4;
indr=round(m/2):m:M;
indc=round(n/2):n:N;
[X,Y]=meshgrid(indc,indr);
FI=scatteredInterpolant(cs,rs,ds);
dis=FI(X(:),Y(:));
for k=1:numel(X)
    plot(handles.oilAxis,[X(k)-R*cos(dis(k)),X(k)+R*cos(dis(k))],...
        [Y(k)-R*sin(dis(k)),Y(k)+R*sin(dis(k))],...
        '-g');
end
title(handles.oilAxis,'笔刷方向场');
axis(handles.oilAxis,[1,N,1,M]);
drawnow;
myLog(handles,'时间已过 %f 秒。\n',toc);

% 加载笔刷模板
shapes=cell(NBS,1);
textures=cell(NBS,1);
for bs=1:NBS
    [shapes{bs},textures{bs}]=getBrushStoke(sprintf('../bs/bs%d.png',bs));
end

% 分层绘制笔刷
cla(handles.oilAxis);
canvas=OilCanvas(im);
load colors CS;% 加载模板颜色
rotateAngles=-90:90;
NA=length(rotateAngles);
for layer=1:length(LSS)
    tic
    myLog(handles,'绘制第%d层笔刷...\n',layer);
    lss=LSS(layer);
    wss=WSS(layer);
    drawThresh=drawThreshs(layer);
    % 预生成旋转和缩放的形状和纹理，加快速度
    resizedShapes=cellfun(@(s){imresize(s,[wss,lss])},shapes);
    resizedTextures=cellfun(@(s){imresize(s,[wss,lss])},textures);
    shapeMap=cell(NBS,NA);
    for i=1:NBS
        for j=1:NA
            % logical的imresize比double慢很多
            shapeMap{i,j}=logical((imrotate((uint8(resizedShapes{i})),...
                rotateAngles(j))));
        end
    end
    textureMap=cell(NBS,NA);
    for i=1:NBS
        for j=1:NA
            textureMap{i,j}=((imrotate(((resizedTextures{i})),rotateAngles(j))));
            textureMap{i,j}(~shapeMap{i,j})=1;
        end
    end
    % 最后一层细化绘制网格
    if layer==length(LSS)
        [Y,X]=find(~canvas.isPloted);
        dis=FI(X(:),Y(:));
    end
    % 绘制笔刷
    for k=1:numel(X)
        if ~canvas.isPloted(Y(k),X(k))
            mapi=unidrnd(NBS);
            mapj=-round(radtodeg(dis(k)))+91;
            canvas.drawBrush(shapeMap{mapi,mapj},textureMap{mapi,mapj},...
                X(k),Y(k),drawThresh);
        end
    end
    % 展示绘制结果
    canvas.showImg(lamda,CS,textureScale,handles.oilAxis);
    title(handles.oilAxis,sprintf('第%d层笔刷',layer));
    drawnow;
    myLog(handles,'时间已过 %f 秒。\n',toc);
end

% 修正图像
tic
myLog(handles,'修正图像...\n');
% 附加修正区域
if correctCode>0
    if correctCode==1
        edgeBW=edge(gim,'canny');
    end
    edgeBW=imdilate(edgeBW,strel('disk',correctR));
    canvas.isPloted=canvas.isPloted&~edgeBW;
end
% 修正图像
ind=bsxfun(@plus,find(~canvas.isPloted),(0:2)*M*N);
canvas.canvas(ind)=canvas.im(ind);
canvas.texture(~canvas.isPloted)=1;
canvas.isPloted=true(M,N);
canvas.showImg(lamda,CS,textureScale,handles.oilAxis);
title(handles.oilAxis,'最终结果');
drawnow;
myLog(handles,'时间已过 %f 秒。\n',toc);

delete(scaledImgName);
myLog(handles,'总时间：%f 秒。\n',toc(startTime));
myLog(handles,'-------------------\n');
end
%--------------------------------------------------------------------------
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
%--------------------------------------------------------------------------
function [cs,rs,ds] = loadFromHoughEdge(im,minLen,handles)
% 将边界分解成连通分量
% 对于每个连通分量利用霍夫变换求直线
% 返回基于边界信息的方向向量

gim=rgb2gray(im);
bw=edge(gim,'canny');
% 寻找边界
list=java.util.ArrayList();
while any(bw(:))
    stats=regionprops(bw,'Area','BoundingBox','Image');
    for k=1:length(stats)
        sbw=stats(k).Image;
        bx=stats(k).BoundingBox;
        bx=ceil(bx);
        indr=bx(2):(bx(2)+bx(4)-1);
        indc=bx(1):(bx(1)+bx(3)-1);
        if stats(k).Area<minLen
            mbw=false(size(sbw));
        else
            [H,T,R]=hough(sbw);
            P=houghpeaks(H,1);
            lines=houghlines(sbw,T,R,P,'MinLength',minLen);
            if isempty(lines)
                mbw=false(size(sbw));
            else
                line=lines(1);
                x1=line.point1(1);y1=line.point1(2);
                x2=line.point2(1);y2=line.point2(2);
                mbw=markLinePrivate(sbw,x1,x2,y1,y2);
                xy=[line.point1+bx([1,2])-1;line.point2+bx([1,2])-1];
                list.add(xy);
            end
        end
        bw(indr,indc)=mbw;
    end
end
% 标准化数据
NL=list.size();
rs=zeros(NL,1);
cs=zeros(NL,1);
ds=zeros(NL,1);
for i=1:list.size()
    xy=list.get(i-1);
    x1=xy(1,1);y1=xy(1,2);
    x2=xy(2,1);y2=xy(2,2);
    rs(i)=(y1+y2)/2;
    cs(i)=(x1+x2)/2;
    ds(i)=atan((y2-y1)/(x2-x1));
end
for i=1:list.size()
    xy=list.get(i-1);
    x1=xy(1,1);y1=xy(1,2);
    x2=xy(2,1);y2=xy(2,2);
    plot(handles.oilAxis,[x1,x2],[y1,y2],'-r');
end
% 增加边界参考
[M,N]=size(gim);
BS=[1,1,pi/2;
    N,1,pi/2;
    1,M,pi/2;
    N,M,pi/2;];
% 考虑画面上下两端一般是被截断的
% 而物体的变化其实还是竖直的
% 因此删除水平边，保持上下两端的画笔是竖直的
%     2,1,0;
%     N-1,1,0;
%     2,M,0;
%     N-1,M,0;];
cs=[cs;BS(:,1)];
rs=[rs;BS(:,2)];
ds=[ds;BS(:,3)];
end
%--------------------------------------------------------------------------
function bw = markLinePrivate(bw,x1,x2,y1,y2)
% 标记直线，经检验，小图用此算法比较快，大图用生成直线的中点算法比较快
A=y1-y2;
B=-(x1-x2);
C=x1*y2-x2*y1;
[Y,X]=find(bw);
ind= X>=min(x1,x2) & X<=max(x1,x2) & Y>=min(y1,y2) & Y<=max(y1,y2);
X=X(ind);
Y=Y(ind);
d=abs(A*X+B*Y+C)/sqrt(A^2+B^2);
ind=d<sqrt(2);
bw(Y(ind),X(ind))=false;
end
%--------------------------------------------------------------------------
function [cs,rs,ds,bw] = loadFromSTASM(imgName,handles)
% 从 stasm.txt 读取预定向量组合
% 利用 stasm.exe 获取人脸特征点
% 返回基于特征点构造的方向向量

% 读取向量下标组合
fid=fopen('stasm.txt');
C=textscan(fid,'%[^\n]');
fclose(fid);
C=C{1};
list=java.util.ArrayList();
for i=1:length(C)
    str=C{i};
    inds=sscanf(str,'%d');
    for k=1:length(inds)-1
        list.add([inds(k),inds(k+1)]);
    end
end
NV=list.size();
IND=zeros(NV,2);
for k=1:NV
    IND(k,:)=(list.get(k-1))';
end
% 读取坐标点
P=stasm(imgName);
if ischar(P)
    myLog(handles,'警告：%s',P);
    cs=[];
    rs=[];
    ds=[];
    if nargout>3
        im=imread(imgName);
        bw=false(size(im(:,:,1)));
    end
    return;
end
% 构造向量
cs=zeros(NV,1);
rs=zeros(NV,1);
ds=zeros(NV,1);
for k=1:NV
    x1=P(IND(k,1),1);y1=P(IND(k,1),2);
    x2=P(IND(k,2),1);y2=P(IND(k,2),2);
    rs(k)=(y1+y2)/2;
    cs(k)=(x1+x2)/2;
    ds(k)=atan((y2-y1)/(x2-x1));
end
for k=1:NV
    x1=P(IND(k,1),1);y1=P(IND(k,1),2);
    x2=P(IND(k,2),1);y2=P(IND(k,2),2);
    plot(handles.oilAxis,[x1,x2],[y1,y2],'-b');
end
if nargout>3
    im=imread(imgName);
    [m,n,~]=size(im);
    bw=false(m,n);
    marker=LineMarker(bw);
    for k=1:NV
        x1=P(IND(k,1),1);y1=P(IND(k,1),2);
        x2=P(IND(k,2),1);y2=P(IND(k,2),2);
        marker.drawLine(x1,x2,y1,y2,true);
    end
    bw=marker.M;
end
end
%--------------------------------------------------------------------------
function myLog(handles,varargin)
hlog=getappdata(handles.figure,'hlog');
str=sprintf(varargin{:});
hlog.append(str);
end
