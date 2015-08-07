%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 该函数分析估值函数(用于估算收盘母基金净值)的误差分布,分级基金和指数的涨幅用
% 尾盘均值估计。
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
    save_root = '..\result';
    data_root = 'G:\datastore';
    configFile = '\config滤流动性.csv'; %滤流动性副本
    year = 2015;    % 按年统计才有意义;
    filterD = [year 01 06; year 12 31]; %设置开始与结束的年月日
    begD = getIntDay(filterD(1, :));
    endD = getIntDay(filterD(2, :));
    
    % 计算分时数据才用到
    filterT = [14 54 00; 14 57 00];
    begT = getDoubleTime(filterT(1, :));    % 实盘开始时间
    endT = getDoubleTime(filterT(2, :));
    % 设置保存目录
    save_dir = [ save_root '\estimateResult' configFile(1:end-4) '\' num2str(year)];
    if ~exist(save_dir,'dir')
        mkdir( save_dir );
    end
    init();
    global muDailyTable idxDailyTable resultTable statList fjDailyTable estimate meanTHeader;
    
    configT = {1,'母基金分布',0; 3,'涨幅均差分布',0; 5,'分级A均差分布',2000000; 7,'分级B均差分布',10000000};
    IfilterAmount = configT{2,3};
    AfilterAmount = configT{3,3};
    BfilterAmount = configT{4,3};
    
    estiMode = 0;
    estiMode = bitor( estiMode, estimate.FundA_Mode );
    estiMode = bitor( estiMode, estimate.FundB_Mode );
    estiMode = bitor( estiMode, estimate.Index_Mode );
    estiMode = bitor( estiMode, estimate.Predict_Mode);
    
%% 分析
    % 读配置文件(存储需要分析的基金信息)
    config = readcsv2(configFile, 12);   
    tableLen = length(config{1});  

    meanTable = zeros(tableLen,meanTHeader.numOfEntries);   % 统计每个品种均值。
    for k = 2:tableLen
        muName = config{statList.muName}{k};
        % 配置文件中基金代号不规范，可能不是完整的8位数，所以要多加判断
        if( length(muName) < 8 )
            muName = ['OF' muName];
        end
        muCode = str2num(muName(3:end));
        meanTable(k,meanTHeader.muCode) = muCode;
               
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

        mValueRange = mValues(mValues(:,muDailyTable.date)>=begD & mValues(:,muDailyTable.date)<endD & mValues(:,muDailyTable.netValue)>0,:);

        iChanges = csvread([data_root '\日线1\' zsName '.csv']);
        iChangeRange = iChanges(iChanges(:,idxDailyTable.date)>=begD & iChanges(:,idxDailyTable.date)<endD,:);

        mNum = size(mValueRange,1);
        resTable = zeros( mNum, estimate.numOfEntries);
        resTable(:,resultTable.date) = mValueRange(:,muDailyTable.date);   %复制日期列

        if mNum == 0
            continue;
        end

        lastValue = mValueRange(1, muDailyTable.netValue);
        for i = 2:mNum
            day = mValueRange(i, muDailyTable.date);
            value = mValueRange(i, muDailyTable.netValue);

            fjAIdx = find( fjAData(:,fjDailyTable.date)==day);
            fjBIdx = find( fjBData(:,fjDailyTable.date)==day);
            iIndex = find(iChangeRange(:,idxDailyTable.date)==day);

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
                
                
                if bitand( estiMode, estimate.Index_Mode )  % 指数涨幅没有阈值控制
                    tickIncreaseMean = calTickAverage( data_root, day, zsName, begT,endT );
                    resTable(i,estimate.predIdxIncrease) = tickIncreaseMean;
                    realIncrease = change;  %该项前面已经算过,就是chagne
                    resTable(i,estimate.IndexEps) = realIncrease - tickIncreaseMean;
                end
                if bitand( estiMode, estimate.FundA_Mode )
                    if( fjAData(fjAIdx, fjDailyTable.turnover) > AfilterAmount ) % 当天交易量大于我们设定的阈值才计算。
                        tickIncreaseMean = calTickAverage( data_root, day, fjAName, begT,endT );
                        resTable(i,estimate.predAIncrease) = tickIncreaseMean;
                        realIncrease = fjAData(fjAIdx, fjDailyTable.increase);
                        resTable(i,estimate.FundAeps) = realIncrease - tickIncreaseMean;
                    end
                end
                if bitand( estiMode, estimate.FundB_Mode )
                    if( fjBData(fjBIdx, fjDailyTable.turnover) > BfilterAmount ) % 当天交易量大于我们设定的阈值才计算。
                        tickIncreaseMean = calTickAverage( data_root, day, fjBName, begT,endT );
                        resTable(i,estimate.predBIncrease) = tickIncreaseMean;
                        realIncrease = fjBData(fjBIdx, fjDailyTable.increase);
                        resTable(i,estimate.FundBeps) = realIncrease - tickIncreaseMean;
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
        %resTable( resTable(:,estimate.epsPercent)== 0,: ) = [];
        
        if bitand( estiMode, estimate.Predict_Mode)     % 预估净值预测误差分析
            % 画全部日期的误差分布 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.epsPercent)~= 0,:); %子表，筛选出预估净值误差不为0的，即当天有数据的。
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, muName, estimate.Predict_Mode );
            if status == 0
                close(figure1);
                continue;
            end           
            % 画有收益的日期的误差分布
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, muName, estimate.Predict_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.muMean) = meanVec;
            subDir = [save_dir '\母基金预测净值误差分布'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        
        if bitand( estiMode, estimate.Index_Mode)     % 指数涨幅预测误差分析
            % 画全部日期的误差分布 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.predIdxIncrease)~= 0,:); %子表，筛选出预估涨幅不为0的，即当天有数据的。
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, zsName, estimate.Index_Mode );
            if status == 0
                close(figure1);
                continue;
            end           
            % 画有收益的日期的误差分布
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, zsName, estimate.Index_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.indexMean) = meanVec;
            subDir = [save_dir '\指数预测涨幅误差分布'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        
        if bitand( estiMode, estimate.FundA_Mode)     % 基金A涨幅预测误差分析
            % 画全部日期的误差分布 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.predAIncrease)~= 0,:); %子表，筛选出预估涨幅不为0的，即当天有数据的。
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status, meanVec ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, fjAName, estimate.FundA_Mode );
            if status == 0
                close(figure1);
                continue;
            end            
            % 画有收益的日期的误差分布
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, fjAName, estimate.FundA_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.fundAMean) = meanVec;
            subDir = [save_dir '\分级基金A预测涨幅误差分布'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        
        if bitand( estiMode, estimate.FundB_Mode)     % 基金B涨幅预测误差分析
            % 画全部日期的误差分布 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.predBIncrease)~= 0,:); %子表，筛选出预估涨幅不为0的，即当天有数据的。
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, fjBName, estimate.FundB_Mode );
            if status == 0
                close(figure1);
                continue;
            end                      
            % 画有收益的日期的误差分布
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, fjBName, estimate.FundB_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.fundBMean) = meanVec;
            subDir = [save_dir '\分级基金B预测涨幅误差分布'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        % save resTable
        fTitle = [muName '-' list2str(filterD(1,:))  list2str(filterD(2,:))];
        fTitle = strrep( fTitle,'.','-');
        
        save_path = [save_dir '\' fTitle ];
        sheet = 1;   
        xlswrite( save_path, estimate.listHeader, sheet);   % 请自行确保保存文件名中不存在字符'.'
        startE = 'A2';
        xlswrite( save_path, resTable, sheet, startE);
        %csvwrite( save_path, resTable );
        
        
    end
    meanTable(1,:) = [];
    filename = [save_dir  '\' num2str(year) '年各项指标预估值误差均值统计表' ];
    sheet = 1;   
    xlswrite( filename, meanTHeader.listHeader, sheet);
    startE = 'A2';
    xlswrite( filename, meanTable, sheet, startE);
    
end
