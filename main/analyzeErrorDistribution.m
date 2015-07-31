%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 该函数分析估值函数的误差分布
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyzeErrorDistribution()
%% 添加工程目录
    Files = dir(fullfile( '..\','*.*'));
    for i = 1:length(Files)
        if( Files(i).isdir )
            addpath( ['..\' Files(i).name ])
        end
    end

%% 变量设置
    root = '..\result';
    year = 2015;    % 按年统计才有意义;
    filterD = [year 01 06; year 12 31]; %设置开始与结束的年月日
    begD = getIntDay(filterD(1, :));
    endD = getIntDay(filterD(2, :));
    % 设置保存目录
    root_dir = [root '\预估净值分布'];
    if ~exist(root_dir,'dir')
        disp(['mkdir ' root_dir]);
        mkdir(root_dir);
    end
    save_dir = [ '..\result\estimateResult\'];
    if ~exist(save_dir,'dir')
        mkdir( save_dir );
    end
    init2();
    global statList fjDailyTable estimate;
%% 分析
    % 读配置文件(存储需要分析的基金信息)
    T = readcsv2('\config.csv', 12);   
    num = size(T{:,1},1);

    mi = 1;%母基金代码列号
    ii = 3;%指数代码列号
    mcs = T{mi};
    ics = T{ii};

    meanTable = zeros(num,7);   % 统计每个品种均值。
    for index = 2:num
        muName = mcs{index};
        
        muCode = str2num(muName(3:end));
        meanTable(index,1) = muCode;
        
        zsName = ics{index};
        fjAName = T{statList.fjAName}{index};      %子基金A名：深交所的以SZ开头
        fjBName = T{statList.fjBName}{index};
        disp([num2str(index) ]);
        try
            %读取母基金，其分级基金A、B，以及对应指数的相关数据：每日净值、涨幅等等
            mValues = csvread(['G:\datastore\母基金1\' muName '.csv']);
            fjAData = csvread(['G:\datastore\日线1\' fjAName '.csv']);
            fjBData = csvread(['G:\datastore\日线1\' fjBName '.csv']);
            aShare = str2double(cell2mat( T{statList.aShare}(index) ))/10;   
            bShare = str2double(cell2mat( T{statList.bShare}(index) ))/10;   
            applyFee = str2double(cell2mat( T{statList.applyFee}(index) ));     
            redeemFee = str2double(cell2mat( T{statList.redeemFee}(index) ));  
            YjThresholds = applyFee + 0.002;
            ZjThresholds = -redeemFee -0.002;
        catch ME
            disp([ME.message ' ' muName]);
            continue ;
        end   

        mValueRange = mValues(mValues(:,1)>=begD & mValues(:,1)<endD & mValues(:,2)>0,:);

        iChanges = csvread(['G:\datastore\日线1\' zsName '.csv']);
        iChangeRange = iChanges(iChanges(:,1)>=begD & iChanges(:,1)<endD,:);

        mNum = size(mValueRange,1);
        resTable = zeros( mNum, 5);
        resTable(:,1) = mValueRange(:,1);   %复制日期列

        if mNum == 0
            continue;
        end

        lastValue = mValueRange(1, 2);
        for i = 2:mNum
            day = mValueRange(i, 1);
            value = mValueRange(i, 2);

            fjAIdx = find( fjAData(:,fjDailyTable.date)==day);
            fjBIdx = find( fjBData(:,fjDailyTable.date)==day);
            iIndex = find(iChangeRange(:,1)==day);

            if ( isempty(fjAIdx) || isempty(fjBIdx) || isempty(iIndex) )
                % 检查是否缺数据
                continue;
            end

            if (value-lastValue)/lastValue>0.4      %下折
                disp([muName ' 下折 ' num2str(value)]);
            elseif (value-lastValue)/lastValue<-0.4   %上折
                disp([muName ' 上折 ' num2str(value)]);
            else


                change = iChangeRange(iIndex, 3);

                calValue = getPreValue(lastValue, change);
                disRate = (fjAData(fjAIdx,fjDailyTable.closingPrice)*aShare+fjBData(fjBIdx,fjDailyTable.closingPrice)*bShare - calValue)/calValue;

                if( disRate < 0 )   % 说明是折价
                    resTable(i,estimate.zjFlag) = 1;  
                    if( disRate < ZjThresholds )    % 说明超过阈值
                        resTable(i,estimate.thrFlag) = 1;
                    end
                else                % 说明只溢价
                    if( disRate > YjThresholds )
                        resTable(i,estimate.thrFlag) = 1;
                    end
                end
                
                resTable(i,estimate.predict) = calValue; 
                resTable(i,estimate.realNetValue) = value;
                resTable(i,estimate.eps) = calValue-value;
                resTable(i,estimate.disRate) = disRate;
                resTable(i,estimate.epsPercent) = (calValue-value)/value;
            end

            lastValue = value;
        end
        resTable( resTable(:,estimate.epsPercent)== 0,: ) = [];
        
        % 画全部日期的误差分布 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            zjEps = resTable( resTable(:,estimate.zjFlag)==1,:);
            yjEps = resTable( resTable(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];

            xMin = min(totalEps(:,estimate.epsPercent));
            xMax = max(totalEps(:,estimate.epsPercent));
            x = xMin:(xMax-xMin)/100:xMax;
            if length(x) < 1    % 居然没有误差？或者说没有数据
                close(figure1);
                continue;
            end          
            % 画概率密度分布
            f1 = ksdensity(totalEps(:,estimate.epsPercent), x);   % 总的            
            f2 = ksdensity(zjEps(:,estimate.epsPercent), x);      % 折价的
            f3 = ksdensity(yjEps(:,estimate.epsPercent), x);      % 溢价的
            
            subplot(1,2,1);
            fTitle = {[muName '-' list2str(filterD(1,:))  list2str(filterD(2,:))];['全日期范围误差概率分布']};
            title(fTitle);
            hold on;
            plot(x,f1);      
            plot(x,f2,'r');
            plot(x,f3,'g');
            legend('全部日期范围', '折价日期范围', '溢价日期范围');
            % 打印变量作图
            Mean = mean(totalEps(:,estimate.epsPercent));
            Variance1 = var(totalEps(:,estimate.epsPercent));
            Standard1 = std(totalEps(:,estimate.epsPercent));
            YRange = get(gca,'Ylim'); %y轴范围
            maxY = YRange(2);
            text(Mean, maxY * 0.96, ['\fontsize{8}\color{blue}Sample = ' num2str(size(totalEps,1))]);
            text(Mean, maxY * 0.88, ['\fontsize{8}\color{blue}Mean = ' num2str(Mean)]);
            text(Mean, maxY * 0.80, ['\fontsize{8}\color{blue}Variance = ' num2str(Variance1)]);
            text(Mean, maxY * 0.72, ['\fontsize{8}\color{blue}Standard = ' num2str(Standard1)]);
            Mean2 = mean(zjEps(:,estimate.epsPercent));
            Variance2 = var(zjEps(:,estimate.epsPercent));
            Standard2 = std(zjEps(:,estimate.epsPercent));
            %maxY = max(f2);
            text(Mean2, maxY * 0.64, ['\fontsize{8}\color{red}Sample = ' num2str((size(zjEps,1)))]);
            text(Mean2, maxY * 0.56, ['\fontsize{8}\color{red}Mean = ' num2str(Mean2)]);
            text(Mean2, maxY * 0.48, ['\fontsize{8}\color{red}Variance = ' num2str(Variance2)]);
            text(Mean2, maxY * 0.40, ['\fontsize{8}\color{red}Standard = ' num2str(Standard2)]);  
            Mean3 = mean(yjEps(:,estimate.epsPercent));
            Variance3 = var(yjEps(:,estimate.epsPercent));
            Standard3 = std(yjEps(:,estimate.epsPercent));
            %maxY = max(f2);
            text(Mean3, maxY * 0.32, ['\fontsize{8}\color{green}Sample = ' num2str((size(yjEps,1)))]);
            text(Mean3, maxY * 0.24, ['\fontsize{8}\color{green}Mean = ' num2str(Mean3)]);
            text(Mean3, maxY * 0.16, ['\fontsize{8}\color{green}Variance = ' num2str(Variance3)]);
            text(Mean3, maxY * 0.08, ['\fontsize{8}\color{green}Standard = ' num2str(Standard3)]);  
            meanTable(index,[2 3 4]) = [Mean, Mean2, Mean3];
            
        % 画有收益的日期的误差分布
            zyEpsThr = resTable( resTable(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);
            
            xMin = min(zyEpsThr(:,estimate.epsPrecent));
            xMax = max(zyEpsThr(:,estimate.epsPrecent));
            x = xMin:(xMax-xMin)/100:xMax;
            if length(x) < 1    % 居然没有误差？或者说没有数据
                close(figure1);
                continue;
            end          
            % 画概率密度分布
            f1 = ksdensity(zyEpsThr(:,estimate.epsPercent), x);   % 总的            
            f2 = ksdensity(zjEpsThr(:,estimate.epsPercent), x);      % 折价的
            f3 = ksdensity(yjEpsThr(:,estimate.epsPercent), x);      % 溢价的
            
            subplot(1,2,2);
            fTitle = {[muName '-' list2str(filterD(1,:))  list2str(filterD(2,:))];['预测有盈利的日期范围误差概率分布']};
            title(fTitle);
            hold on;
            plot(x,f1);      
            plot(x,f2,'r');
            plot(x,f3,'g');
            legend('全部日期范围', '折价日期范围', '溢价日期范围');
            % 打印变量作图
            Mean = mean(zyEpsThr(:,estimate.epsPercent));
            Variance1 = var(zyEpsThr(:,estimate.epsPercent));
            Standard1 = std(zyEpsThr(:,estimate.epsPercent));
            YRange = get(gca,'Ylim'); %y轴范围
            maxY = YRange(2);
            text(Mean, maxY * 0.96, ['\fontsize{8}\color{blue}Sample = ' num2str(size(zyEpsThr,1))]);
            text(Mean, maxY * 0.88, ['\fontsize{8}\color{blue}Mean = ' num2str(Mean)]);
            text(Mean, maxY * 0.80, ['\fontsize{8}\color{blue}Variance = ' num2str(Variance1)]);
            text(Mean, maxY * 0.72, ['\fontsize{8}\color{blue}Standard = ' num2str(Standard1)]);
            Mean2 = mean(zjEpsThr(:,estimate.epsPercent));
            Variance2 = var(zjEpsThr(:,estimate.epsPercent));
            Standard2 = std(zjEpsThr(:,estimate.epsPercent));
            %maxY = max(f2);
            text(Mean2, maxY * 0.64, ['\fontsize{8}\color{red}Sample = ' num2str((size(zjEpsThr,1)))]);
            text(Mean2, maxY * 0.56, ['\fontsize{8}\color{red}Mean = ' num2str(Mean2)]);
            text(Mean2, maxY * 0.48, ['\fontsize{8}\color{red}Variance = ' num2str(Variance2)]);
            text(Mean2, maxY * 0.40, ['\fontsize{8}\color{red}Standard = ' num2str(Standard2)]);  
            Mean3 = mean(yjEpsThr(:,estimate.epsPercent));
            Variance3 = var(yjEpsThr(:,estimate.epsPercent));
            Standard3 = std(yjEpsThr(:,estimate.epsPercent));
            %maxY = max(f2);
            text(Mean3, maxY * 0.32, ['\fontsize{8}\color{green}Sample = ' num2str((size(yjEpsThr,1)))]);
            text(Mean3, maxY * 0.24, ['\fontsize{8}\color{green}Mean = ' num2str(Mean3)]);
            text(Mean3, maxY * 0.16, ['\fontsize{8}\color{green}Variance = ' num2str(Variance3)]);
            text(Mean3, maxY * 0.08, ['\fontsize{8}\color{green}Standard = ' num2str(Standard3)]);   
            meanTable(index, [5 6 7]) = [Mean, Mean2, Mean3];
            
            figurePath = [root_dir '\' fTitle{1} '.bmp'];
            
            %saveas( gcf, figurePath );
            hold off;
            close(figure1);

        % save resTable
        fTitle{1} = strrep( fTitle{1},'.','-');   
        save_path = [save_dir fTitle{1} ];
        sheet = 1;   
        xlswrite( save_path, estimate.listHeader, sheet);   % 确保文件名中不存在字符'.'
        startE = 'A2';
        xlswrite( save_path, resTable, sheet, startE);
        %csvwrite( save_path, resTable );
    end
    meanTable(1,:) = [];
    listHeader = {'基金代码', '全部日期误差均值','折价日期误差均值','溢价日期误差均值','预计盈利日期误差均值','预计折价盈利日期误差均值','预计溢价盈利日期误差均值' };
    filename = [save_dir  num2str(year) '年预估净值误差均值统计表' ];
    sheet = 1;   
    xlswrite( filename, listHeader, sheet);
    startE = 'A2';
    xlswrite( filename, meanTable, sheet, startE);
    
end
