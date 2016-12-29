function [cs,rs,ds] = loadFromHoughEdge(im,minLen,plotAxis)
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
    plot(plotAxis,[x1,x2],[y1,y2],'-r');
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