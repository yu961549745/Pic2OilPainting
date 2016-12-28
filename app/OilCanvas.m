classdef OilCanvas < handle
    properties
        im
        canvas
        isPloted
        texture
    end
    methods
        function obj = OilCanvas(im)
            [m,n,~]=size(im);
            obj.im=im;
            obj.canvas=ones(m,n,3);
            obj.isPloted=false(m,n);
            obj.texture=ones(m,n);
        end
        function drawBrush(this,shape,texture,cx,cy,drawThresh)
            % 阈值绘制算法
            [M,N,~]=size(this.canvas);
            [m,n]=size(shape);
            % 笔刷平移
            rInd=(1:m)+cy-round(m/2);
            cInd=(1:n)+cx-round(n/2);
            % 笔刷裁剪
            vr=rInd>=1&rInd<=M;
            vc=cInd>=1&cInd<=N;
            shape=shape(vr,vc);
            texture=texture(vr,vc);
            rInd=rInd(vr);
            cInd=cInd(vc);
            % 笔刷颜色
            temp=this.im(rInd,cInd,:);
            temp=temp(repmat(shape,[1,1,3]));
            temp=reshape(temp,[numel(temp)/3,3]);
            if any(max(temp)-min(temp)>drawThresh)
                return;
            end
            color=mean(temp);
            % 绘制笔刷
            for k=1:3
                temp=this.canvas(rInd,cInd,k);
                temp(shape)=color(k);
                this.canvas(rInd,cInd,k)=temp;
            end
            this.isPloted(rInd,cInd)=this.isPloted(rInd,cInd)|shape;
            temp=this.texture(rInd,cInd);
            temp(shape)=texture(shape);
            this.texture(rInd,cInd)=temp;
        end
        function im = getImg(this,lamda,CS,textureScale)
            % 根据不同的lamda和textureScale重建图像
            [M,N,~]=size(this.canvas);
            ind=bsxfun(@plus,find(this.isPloted),(0:2)*M*N);
            plotedColors=reshape(this.canvas(ind),[sum(this.isPloted(:)),3]);
            D=pdist2(plotedColors,CS);
            [~,closedColorInd]=min(D,[],2);
            closedColors=CS(closedColorInd,:);
            im=ones(M,N,3);
            showTexture=1+textureScale*(this.texture-1);
            im(ind)=(lamda*plotedColors+(1-lamda)*closedColors)...
                .*repmat(showTexture(this.isPloted),[1,3]);
        end
        function showImg(this,lamda,CS,textureScale,ax)
            imagesc(this.getImg(lamda,CS,textureScale),'Parent',ax);
            axis(ax,'equal');
            axis(ax,'tight');
            axis(ax,'off');
        end
        function showCmp(this,lamda,CS,textureScale)
            figure;
            subplot(121)
            imagesc(this.im);
            axis equal
            axis tight
            title 原始图像
            subplot(122)
            imagesc(this.getImg(lamda,CS,textureScale));
            title 最终效果
            axis equal
            axis tight
            drawnow;
        end
        function saveCmp(this,lamda,CS,textureScale,fname)
            imwrite(cat(2,this.im,this.getImg(lamda,CS,textureScale)),fname);
        end
    end
end