%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 该函数分析尾盘成交量占当天成交量的比重，以及其分布
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyzeTransaction()
%% 添加工程目录
    Files = dir(fullfile( '..\','*.*'));
    for i = 1:length(Files)
        if( Files(i).isdir )
            addpath( ['..\' Files(i).name ])
        end
    end

%% 变量设置
    save_root = '..\result';
    data_root = 'G:\datastore';
    configFile = '\config滤流动性.csv'; %滤流动性副本
    year = 2013;    % 按年统计才有意义;
    filterD = [year 01 06; year 12 31]; %设置开始与结束的年月日
    begD = getIntDay(filterD(1, :));
    endD = getIntDay(filterD(2, :));
    
    % 计算分时数据才用到
    filterT = [14 54 00; 14 57 00];
    begT = getDoubleTime(filterT(1, :));    % 实盘开始时间
    endT = getDoubleTime(filterT(2, :));
    % 设置保存目录
    save_dir = [ save_root '\交易额统计结果' configFile(1:end-4) '\' num2str(year)];
    if ~exist(save_dir,'dir')
        mkdir( save_dir );
    end
    init2();
    global statList fjDailyTable tickTable turnoverTHeader;
 
%% 分析
    % 读配置文件(存储需要分析的基金信息)
    config = readcsv2(configFile, 12);   
    tableLen = length(config{1});  

    turnoverTable = zeros(tableLen,turnoverTHeader.numOfEntries);   % 统计每个品种尾盘交易额的信息。
    for k = 2:tableLen
        muName = config{statList.muName}{k};
        % 配置文件中基金代号不规范，可能不是完整的8位数，所以要多加判断
        if( length(muName) < 8 )
            muName = ['OF' muName];
        end
        muCode = str2num(muName(3:end));
        turnoverTable(k,turnoverTHeader.muCode) = muCode;
               
        fjAName = config{statList.fjAName}{k};      %子基金A名：深交所的以SZ开头
        if( length(fjAName) < 8 )
            fjAName = ['SZ' fjAName];
        end
        fjBName = config{statList.fjBName}{k};
        if( length(fjBName) < 8 )
            fjBName = ['SZ' fjBName];
        end
        zsName = config{statList.zsName}{k};
        if( length(zsName) < 8 )
            zsName = ['SZ' zsName];
        end
        disp([num2str(k) ]);
        try
            %读取母基金，其分级基金A、B，以及对应指数的相关数据：每日净值、涨幅等等
            mValues = csvread([data_root '\母基金1\' muName '.csv']);
            fjAData = csvread([data_root '\日线1\' fjAName '.csv']);
            fjBData = csvread([data_root '\日线1\' fjBName '.csv']);              
            aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
            bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
            applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
            redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
            YjThresholds = applyFee + 0.002;
            ZjThresholds = -redeemFee -0.002;
        catch ME
            disp([ME.message ' ' muName]);
            continue ;
        end   

        mValueRange = mValues(mValues(:,1)>=begD & mValues(:,1)<endD & mValues(:,2)>0,:);

        iChanges = csvread([data_root '\日线1\' zsName '.csv']);
        iChangeRange = iChanges(iChanges(:,1)>=begD & iChanges(:,1)<endD,:);

        mNum = size(mValueRange,1);
        if mNum == 0
            continue;
        end
        
        APercent = zeros( mNum, 1 );
        BPercent = zeros( mNum, 1 );
        lastValue = mValueRange(1, 2);
        for i = 2:mNum
            day = mValueRange(i, 1);
            value = mValueRange(i, 2);

            fjAIdx = find( fjAData(:,fjDailyTable.date)==day);
            fjBIdx = find( fjBData(:,fjDailyTable.date)==day);
            iIndex = find(iChangeRange(:,1)==day);

            if ( isempty(fjAIdx) || isempty(fjBIdx) || isempty(iIndex) || iIndex == 1)
                % 检查是否缺数据
                continue;
            end

            if (value-lastValue)/lastValue>0.1      %下折
                disp([muName ' 下折 ' num2str(value)]);
            elseif (value-lastValue)/lastValue<-0.1   %上折
                disp([muName ' 上折 ' num2str(value)]);
            else
                
                change = (iChangeRange(iIndex,2)-iChangeRange(iIndex-1,2))/iChangeRange(iIndex-1,2)*100;     %要乘以100
                calValue = getPreValue(lastValue, change);
                disRate = (fjAData(fjAIdx,fjDailyTable.closingPrice)*aShare+fjBData(fjBIdx,fjDailyTable.closingPrice)*bShare - calValue)/calValue;
                if( disRate < ZjThresholds && disRate > YjThresholds )
                    continue;
                end
                
                [Y, M, D] = getVectorDay( day );
                %分析A的分时数据
                    fileDir = [data_root '\ticks\' fjAName];
                    if exist(fileDir,'dir') == 0    %检查数据库中是否有该基金的分时数据
                        disp([fileDir ' not found']);
                        continue;
                    end              
                    fileDir2 = [fileDir '\' fjAName '_' num2str(Y) '_' num2str(M)];     % 进入都对应日期的目录
                    filename = [fileDir2 '\' fjAName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
                    try
                        ticks = csvread(filename);  % 读取分时数据
                    catch e
                        disp( [fjAName ':' num2str(Y) '.' num2str(M) '.' num2str(D) ] );
                        disp(e);
                        continue;
                    end
                    %validIdx = abs(ticks(:,tickTable.increase)) < 10;   % 非涨跌停
                    ticksRange = ticks(ticks(:,tickTable.time) >= day+begT & ticks(:,tickTable.time) < day+endT,:); %筛选尾盘数据
                    if size(ticksRange, 1) < 10
                        disp([ fjAName '-' num2str(Y) '.' num2str(M) '.' num2str(D) ' no enough valid range']);
                        continue;
                    end
                    sumA = sum( ticksRange(:,tickTable.turnover) );
                    APercent(i) = sumA / fjAData(fjAIdx, fjDailyTable.turnover)*100;
                %分析B的分时数据
                    fileDir = [data_root '\ticks\' fjBName];
                    if exist(fileDir,'dir') == 0    %检查数据库中是否有该基金的分时数据
                        disp([fileDir ' not found']);
                        continue;
                    end              
                    fileDir2 = [fileDir '\' fjBName '_' num2str(Y) '_' num2str(M)];     % 进入到对应日期的目录
                    filename = [fileDir2 '\' fjBName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
                    try
                        ticks = csvread(filename);  % 读取分时数据
                    catch e
                        disp( [fjBName ':' num2str(Y) '.' num2str(M) '.' num2str(D) ]);
                        disp( e );
                        continue;
                    end
                    ticksRange = ticks(ticks(:,tickTable.time) >= day+begT & ticks(:,tickTable.time) < day+endT ,:); %筛选尾盘数据
                    if size(ticksRange, 1) < 10
                        disp([fjBName '-' num2str(Y) '.' num2str(M) '.' num2str(D) ' no enough valid range']);
                        continue;
                    end
                    sumB = sum( ticksRange(:,tickTable.turnover) );
                    BPercent(i) = sumB / fjBData(fjBIdx, fjDailyTable.turnover)*100;
            end
            lastValue = value;
        end
        APercent( APercent == 0 ) = [];
        BPercent( BPercent == 0 ) = [];
        
        % plot result
        figure1 = figure();
        set(gcf,'outerposition',get(0,'screensize'));
            % for A
            subplot(1,2,1);
            xMin = min(APercent);
            xMax = max(APercent);
            x = xMin:(xMax-xMin)/100:xMax;
            if length(APercent) < 10  
                close(figure1);
                continue;
            end          

            f1 = ksdensity(APercent, x);   %  
            fTitle = {[fjAName '-' list2str(filterD(1,:))  list2str(filterD(2,:))]; '尾盘交易额比重(百分比)概率分布'};
            title(fTitle);
            hold on;
            plot(x,f1,'b');     
            [~,PeakIdx] = max(f1);
            Mean = mean(APercent);
            Variance = var(APercent);
            Standard = std(APercent);
            Median = median(APercent);
            XRange = get(gca,'Xlim');
            YRange = get(gca,'Ylim'); %y轴范围
            text(XRange(1),  YRange(1)*0.1+YRange(2)*0.9, ['\fontsize{8}\color{blue}Sample = ' num2str(length(APercent))]);
            text(XRange(1), YRange(1)*0.15+YRange(2)*0.85, ['\fontsize{8}\color{blue}Mean = ' num2str(Mean)]);
            text(XRange(1), YRange(1)*0.2+YRange(2)*0.8, ['\fontsize{8}\color{blue}Variance = ' num2str(Variance)]);
            text(XRange(1), YRange(1)*0.25+YRange(2)*0.75, ['\fontsize{8}\color{blue}Standard = ' num2str(Standard)]);
            text(XRange(1), YRange(1)*0.3+YRange(2)*0.70, ['\fontsize{8}\color{blue}Peak = ' num2str(x(PeakIdx))]);
            text(XRange(1), YRange(1)*0.35+YRange(2)*0.65, ['\fontsize{8}\color{blue}Median = ' num2str(Median)]);
            turnoverTable(k,[turnoverTHeader.fundAMean turnoverTHeader.fundAPeak turnoverTHeader.fundAMedian]) = [Mean x(PeakIdx) Median ];
            % for B
            subplot(1,2,2);
            xMin = min(BPercent);
            xMax = max(BPercent);
            x = xMin:(xMax-xMin)/100:xMax;
            if length(BPercent) < 10  
                close(figure1);
                continue;
            end          

            f1 = ksdensity(BPercent, x);   %  
            fTitle = {[fjBName '-' list2str(filterD(1,:))  list2str(filterD(2,:))]; '尾盘交易额比重(百分比）概率分布'};
            title(fTitle);
            hold on;
            plot(x,f1,'r');      
            [~,PeakIdx] = max(f1);
            Mean = mean(BPercent);
            Variance = var(BPercent);
            Standard = std(BPercent);
            Median = median(BPercent);
            XRange = get(gca,'Xlim');
            YRange = get(gca,'Ylim'); %y轴范围
            text(XRange(1), YRange(1)*0.1+YRange(2)*0.9, ['\fontsize{8}\color{red}Sample = ' num2str(length(BPercent))]);
            text(XRange(1), YRange(1)*0.15+YRange(2)*0.85, ['\fontsize{8}\color{red}Mean = ' num2str(Mean)]);
            text(XRange(1), YRange(1)*0.2+YRange(2)*0.8, ['\fontsize{8}\color{red}Variance = ' num2str(Variance)]);
            text(XRange(1), YRange(1)*0.25+YRange(2)*0.75, ['\fontsize{8}\color{red}Standard = ' num2str(Standard)]);
            text(XRange(1), YRange(1)*0.3+YRange(2)*0.70, ['\fontsize{8}\color{red}Peak = ' num2str(x(PeakIdx))]);
            text(XRange(1), YRange(1)*0.35+YRange(2)*0.65, ['\fontsize{8}\color{red}Median = ' num2str(Median)]);
            turnoverTable(k,[turnoverTHeader.fundBMean turnoverTHeader.fundBPeak turnoverTHeader.fundBMedian]) = [Mean x(PeakIdx) Median];
            
        figurePath = [save_dir '\' [muName '-' list2str(filterD(1,:))  list2str(filterD(2,:))] '.bmp'];            
        saveas( gcf, figurePath );
        hold off;
        close(figure1);       
    end
    
    turnoverTable(1,:) = [];
    filename = [save_dir  '\' num2str(year) '分级A、B尾盘交易额比重统计表' ];
    sheet = 1;   
    xlswrite( filename, turnoverTHeader.listHeader, sheet);
    startE = 'A2';
    xlswrite( filename, turnoverTable, sheet, startE);
    
end
