%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 该函数求三个输入向量的概率密度分布，并作在同一张图上
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status, meanVec, fTitle]  = plotKsDensity( src, src1, src2, filterD, name, Mode )
    status = 0;
    meanVec = [0 0 0];
    fTitle = '';
    if( isempty(src) || isempty(src1) || isempty(src2) )
        return;
    end
    
    global estimate;
    switch Mode
        case estimate.Predict_Mode
            estimateValue = estimate.epsPercent;
            ss = '预估净值';
        case estimate.FundA_Mode
            estimateValue = estimate.FundAeps;
            ss ='分级A预估收盘价';
        case estimate.FundB_Mode
            estimateValue = estimate.FundBeps;
            ss ='分级B预估收盘价';
        case estimate.Index_Mode
            estimateValue = estimate.IndexEps;
            ss ='指数预估收盘价';
    end    
    
    
    %figure1=figure();
    set(gcf,'outerposition',get(0,'screensize'));

    xMin = min(src(:,estimateValue));
    xMax = max(src(:,estimateValue));
    x = xMin:(xMax-xMin)/100:xMax;
    if length(x) < 1    % 居然没有误差？或者说没有数据       
        return;
    end          
    % 画概率密度分布
    f1 = ksdensity(src(:,estimateValue), x);   % 总的            
    f2 = ksdensity(src1(:,estimateValue), x);      % 折价的
    f3 = ksdensity(src2(:,estimateValue), x);      % 溢价的

    
    
    fTitle = {[name '-' list2str(filterD(1,:))  list2str(filterD(2,:))];[ ss '误差概率分布']};
    title(fTitle);
    hold on;
    plot(x,f1);      
    plot(x,f2,'r');
    plot(x,f3,'g');
    legend('全部日期范围', '折价日期范围', '溢价日期范围');
    % 打印变量作图
    Mean = mean(src(:,estimateValue));
    Variance1 = var(src(:,estimateValue));
    Standard1 = std(src(:,estimateValue));
    YRange = get(gca,'Ylim'); %y轴范围
    maxY = YRange(2);
    text(Mean, maxY * 0.96, ['\fontsize{8}\color{blue}Sample = ' num2str(size(src,1))]);
    text(Mean, maxY * 0.88, ['\fontsize{8}\color{blue}Mean = ' num2str(Mean)]);
    text(Mean, maxY * 0.80, ['\fontsize{8}\color{blue}Variance = ' num2str(Variance1)]);
    text(Mean, maxY * 0.72, ['\fontsize{8}\color{blue}Standard = ' num2str(Standard1)]);
    Mean2 = mean(src1(:,estimateValue));
    Variance2 = var(src1(:,estimateValue));
    Standard2 = std(src1(:,estimateValue));
    %maxY = max(f2);
    text(Mean2, maxY * 0.64, ['\fontsize{8}\color{red}Sample = ' num2str((size(src1,1)))]);
    text(Mean2, maxY * 0.56, ['\fontsize{8}\color{red}Mean = ' num2str(Mean2)]);
    text(Mean2, maxY * 0.48, ['\fontsize{8}\color{red}Variance = ' num2str(Variance2)]);
    text(Mean2, maxY * 0.40, ['\fontsize{8}\color{red}Standard = ' num2str(Standard2)]);  
    Mean3 = mean(src2(:,estimateValue));
    Variance3 = var(src2(:,estimateValue));
    Standard3 = std(src2(:,estimateValue));
    %maxY = max(f2);
    text(Mean3, maxY * 0.32, ['\fontsize{8}\color{green}Sample = ' num2str((size(src2,1)))]);
    text(Mean3, maxY * 0.24, ['\fontsize{8}\color{green}Mean = ' num2str(Mean3)]);
    text(Mean3, maxY * 0.16, ['\fontsize{8}\color{green}Variance = ' num2str(Variance3)]);
    text(Mean3, maxY * 0.08, ['\fontsize{8}\color{green}Standard = ' num2str(Standard3)]); 
    
    status = 1;
    meanVec = [Mean, Mean2, Mean3 ];
    return ;
end