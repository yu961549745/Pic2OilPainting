function canvas = oilPainting(imgName,imScale,minLen,m,n,LSS,WSS,drawThreshs,...
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

if ~isempty(handles)
    plotAxis=handles.oilAxis;
    cla(plotAxis);
    logHandle=getappdata(handles.figure,'hlog');
else
    figure;
    axis;
    plotAxis=get(gcf,'CurrentAxes');
    logHandle=[];
end

[~,name,ext]=fileparts(imgName);
myLog(logHandle,'%s%s\n',name,ext);
startTime=tic();
% 图片准备
im=im2double(imread(imgName));
im=imresize(im,imScale);
scaledImgName=strcat(imgName,'.jpg');
imwrite(im,scaledImgName);
gim=rgb2gray(im);
[M,N]=size(gim);

% 获取插值基向量
imagesc(gim,'Parent',plotAxis);
axis(plotAxis,'equal');
axis(plotAxis,'tight');
axis(plotAxis,'off');
colormap gray;
hold(plotAxis,'on');
title(plotAxis,'');
drawnow;
myLog(logHandle,'获取基向量...\n');

% 基于特征边界
myLog(logHandle,'基于特征边界...\n');
tic
[cs1,rs1,ds1]=loadFromHoughEdge(im,minLen,plotAxis);
title(plotAxis,'基于特征边界');
drawnow;
myLog(logHandle,'时间已过 %f 秒。\n',toc);

% 基于人脸识别
myLog(logHandle,'基于人脸识别...\n');
tic
if correctCode==2
    [cs2,rs2,ds2,edgeBW]=loadFromSTASM(scaledImgName,plotAxis,logHandle);
else
    [cs2,rs2,ds2]=loadFromSTASM(scaledImgName,plotAxis,logHandle);
end
title(plotAxis,'基于人脸识别');
drawnow;
myLog(logHandle,'时间已过 %f 秒。\n',toc);
cs=[cs1;cs2];
rs=[rs1;rs2];
ds=[ds1;ds2];

% 插值计算方向
tic
myLog(logHandle,'计算方向...\n');
R=(m+n)/4;
indr=round(m/2):m:M;
indc=round(n/2):n:N;
[X,Y]=meshgrid(indc,indr);
FI=scatteredInterpolant(cs,rs,ds);
dis=FI(X(:),Y(:));
for k=1:numel(X)
    plot(plotAxis,[X(k)-R*cos(dis(k)),X(k)+R*cos(dis(k))],...
        [Y(k)-R*sin(dis(k)),Y(k)+R*sin(dis(k))],...
        '-g');
end
title(plotAxis,'笔刷方向场');
axis(plotAxis,[1,N,1,M]);
drawnow;
myLog(logHandle,'时间已过 %f 秒。\n',toc);

% 加载笔刷模板
shapes=cell(NBS,1);
textures=cell(NBS,1);
for bs=1:NBS
    [shapes{bs},textures{bs}]=getBrushStoke(sprintf('../bs/bs%d.png',bs));
end

% 分层绘制笔刷
if ~isempty(handles)
    cla(plotAxis);
end
canvas=OilCanvas(im);
load colors CS;% 加载模板颜色
rotateAngles=-90:90;
NA=length(rotateAngles);
for layer=1:length(LSS)
    tic
    myLog(logHandle,'绘制第%d层笔刷...\n',layer);
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
    if isempty(handles)
        figure;
        axis;
        plotAxis=get(gcf,'CurrentAxes');
    end
    canvas.showImg(lamda,CS,textureScale,plotAxis);
    title(plotAxis,sprintf('第%d层笔刷',layer));
    drawnow;
    myLog(logHandle,'时间已过 %f 秒。\n',toc);
end

% 修正图像
tic
myLog(logHandle,'修正图像...\n');
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
if isempty(handles)
    figure;
    axis;
    plotAxis=get(gcf,'CurrentAxes');
end
canvas.showImg(lamda,CS,textureScale,plotAxis);
title(plotAxis,'最终结果');
drawnow;
myLog(logHandle,'时间已过 %f 秒。\n',toc);

delete(scaledImgName);
myLog(logHandle,'总时间：%f 秒。\n',toc(startTime));
myLog(logHandle,'-------------------\n');
end