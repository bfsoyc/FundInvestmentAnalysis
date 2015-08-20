%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 模拟实际交易
% 策略是：每个品种在某个时刻可套利的情况下，按持仓量全部卖出或买入，五档挂单量不
% 够的自动放弃。同一天内，不同的品种溢价套利可同时下单，连续两次折价套利之间需要相隔5秒.
% 同一品种，分笔交易时，两次交易时间间隔不少于15s
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 添加工程目录
Files = dir(fullfile( '..\','*.*'));
for i = 1:length(Files)
    if( Files(i).isdir )
        addpath( ['..\' Files(i).name ])
    end
end
    
%% 变量设置
clear;     % 先清理一下
bgtyear = 2015;
edtyear = 2015;
init();
global resultTable fjDailyTable rateTable tickTable muDailyTable idxDailyTable rDetialTable statList;

% 计算分时数据用到
filterT = [14 54 00; 14 57 00];
begT = getDoubleTime(filterT(1, :));    % 实盘操作开始时间
endT = getDoubleTime(filterT(2, :));

initMoney = 6e6;
handleRate = [2 3];%2/3、2/4持仓
zjType =1;     %折价类型 一倍，两倍……
slipRatio = 0;  %N倍滑点率，0时代表不考虑滑点

save_root = '..\result';
data_root = 'G:\datastore';
configFile = '\config7_30.csv';
[~,w] = getSelectionFund();
%w = [1 1 1];
w = w/sum(w);

%%  读取数据
config = readcsv2(configFile, 12);   %
zsHs300 = csvread('G:\datastore\日线1\SZ399300.csv');
tableLen = length(config{1});    
Src = cell(1,tableLen);
for k = 2:tableLen     %第一行是表头
    
    muName = config{statList.muName}{k};
    if( length(muName) < 8 )
        muName = ['OF' muName];
    end
    muCode = str2num(muName(3:end));
    
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
    try
        %读取母基金，其分级基金A、B，以及对应指数的相关数据：每日净值、涨幅等等
        temp.data.muData = csvread(['G:\datastore\母基金1\' muName,'.csv']);
        temp.data.fjAData = csvread(['G:\datastore\日线1\' fjAName  '.csv']);
        temp.data.fjBData = csvread(['G:\datastore\日线1\' fjBName  '.csv']);      
        temp.data.zsData = csvread(['G:\datastore\日线1\' zsName  '.csv']);
        temp.configInfo = ConfigInfo;
        temp.configInfo.name = muCode;  
        temp.configInfo.fjAName = fjAName;
        temp.configInfo.fjBName = fjBName;
        temp.configInfo.slipRate = 0.01;    %
        temp.configInfo.aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
        temp.configInfo.bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
        temp.configInfo.applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
        temp.configInfo.redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
        temp.configInfo.stockFee = 0.00025;    % 固定的
        temp.configInfo.YjThresholds = temp.configInfo.applyFee + 0.002;
        temp.configInfo.ZjThresholds = -temp.configInfo.redeemFee -0.002;
        Src(k) = {temp};
    catch ME
        disp([ME.message ' ' muName]);
        error('数据不全');
    end
    if exist([data_root '\ticks\' Src{k}.configInfo.fjAName],'dir') == 0    %检查数据库中是否有该基金的分时数据
        error('没有%s的分时数据',Src{k}.configInfo.fjAName);
    end
    if exist([data_root '\ticks\' Src{k}.configInfo.fjBName],'dir') == 0    %检查数据库中是否有该基金的分时数据
        error('没有%s的分时数据',Src{k}.configInfo.fjBName);
    end
end
% 清除空cell
emptyCell = cellfun( @isempty, Src ) ;
Src(emptyCell) = [];

%% 开始模拟交易
typeNum = size(Src,2);
% 按年计算
for year = bgtyear:edtyear
    bgt = getIntDay([year, 1, 1]);
    edt = getIntDay([year, 12, 31]);
    
    diary off;
    delete([save_root '\log.txt']);
    diary([save_root '\log.txt']); %日志   
    manager = tradeSimulator(initMoney,handleRate(1)/handleRate(2));
    % 先建仓
    for i = 1:typeNum              
        muData = Src{i}.data.muData(Src{i}.data.muData(:, muDailyTable.date) >= bgt & Src{i}.data.muData(:, muDailyTable.date) < edt, : );
        idx = 1;       
        while( ~muData(idx, muDailyTable.netValue ) )
            idx = idx + 1;
        end
        manager.addTypes(Src{i}.configInfo, w(i), muData(idx, muDailyTable.netValue ) );
    end
    
    Result=zeros(1,resultTable.numOfEntries);  % Result每一行记录了每一个交易日的总体折溢盈亏状况， 这里初始化第一行。
    
    resDetial = zeros( rDetialTable.numOfEntries,1,typeNum+1 ); % resDetial( :, i, j) 记录了第i个交易日第j个基金品种的信息（折溢率等等，详情见结构体 rDetialtable,由第一个索引指定）, 这里预先分配内存。

    ResultRowCnt = 2;                %Result 表格的行计数器 从第二行开始
    zsHsBgt = 0;
    zsHsClose = 0;
     
    %按日计算
    for date = bgt+1:edt % 确保取到昨日净值
        manager.date = date;
        referenceTime = date + begT;
        resDetial(:,ResultRowCnt, rateTable.date ) = date;
        dailyRes = zeros(1, resultTable.numOfEntries);  % result Table 的一行.
        predictNetValue = zeros(1,typeNum);             % 记录预测净值.
        realNetValue = zeros(1,typeNum);                % 记录真实净值.
        [Y, M, D] = getVectorDay( date );       
        constSec = 1/24/60/60;  % 1s的长度
        for i = 1:typeNum    % 对每个品种分级基金tick数据筛选出尾盘3分钟的交易的数据并折算时间。 
            timeListA{i} = [];      % 由于timeListA 的数据不会清楚，而后面又以timeListA是否为空作为有无数据的标准,这里必须清空
            timeListB{i} = [];
            
            indexMu = find( Src{i}.data.muData(:,muDailyTable.date)==date);   
            indexFjA = find( Src{i}.data.fjAData(:,fjDailyTable.date)==date);
            indexFjB = find( Src{i}.data.fjBData(:,fjDailyTable.date)==date);
            indexZs = find( Src{i}.data.zsData(:,idxDailyTable.date)==date);
            indexHs = find( zsHs300(:,idxDailyTable.date)==date);  
            
            if isempty(indexMu) || isempty(indexFjA) || isempty(indexZs) || isempty(indexFjB) || isempty(indexHs)
               continue;
            end
            if indexMu <= 1 || indexFjA <= 1 || indexFjB <= 1 || indexZs <= 1 || indexHs <= 1
                continue;
            end
            % 设置变量别名           
            muData = Src{i}.data.muData( indexMu , : );          %当天母基金数据
            prev_muData = Src{i}.data.muData( indexMu-1 , : );    %前一天数据    
            zsData = Src{i}.data.zsData( indexZs, : ); 
            
            if muData(muDailyTable.netValue) == 0   % 当天无母基金数据
                continue;
            end
            % 先判断是否发生上下折           
            openPriceM = prev_muData(muDailyTable.netValue); % 前一天的净值            
            closePriceM = muData(muDailyTable.netValue); % 当天的净值
            realNetValue(i) = closePriceM;
            
            changeM = closePriceM/openPriceM - 1;           
            if  changeM > 0.12
                fprintf(['--(' num2str(date) ')基金 ' num2str(manager.funds(i).name) ' 发生下折\n']);
                continue;
            elseif changeM < -0.12
                fprintf(['--(' num2str(date) ')基金 ' num2str(manager.funds(i).name) ' 发生上折\n']);
                continue;
            end
            
            %预测当日净值
            zsChange = Src{i}.data.zsData(indexZs,3)/100;
            predictNetValue(i) = prev_muData(muDailyTable.netValue) * (1 + 0.95*zsChange);
            
            % 读A 
            fileDir = [data_root '\ticks\' manager.funds(i).fjAName];
            fileDir2 = [fileDir '\' manager.funds(i).fjAName '_' num2str(Y) '_' num2str(M)];     % 进入都对应日期的目录
            filename = [fileDir2 '\' manager.funds(i).fjAName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
            try
                ticks = csvread(filename);  % 读取分时数据
            catch e
                continue;
            end
            range = ticks(:,tickTable.time) >= date+begT & ticks(:,tickTable.time) < date+endT; %筛选尾盘数据
            StartIdx = find( range,1,'first');
            EndIdx = find( range,1,'last');
            if( isempty( StartIdx ) )   % 实际上为无数据
                continue;
            end
            StartIdx = max( StartIdx, 2 );  % 下表越界检查，保证StartIdx-1 > 0
            ticksDataA{i} = ticks( StartIdx-1:EndIdx, : );     % 需要一个begT之前的交易数据，极端情况下若不存在这个数据，用begT后出现的第一个数据替代。
            % 同理读B
            fileDir = [data_root '\ticks\' manager.funds(i).fjBName];
            fileDir2 = [fileDir '\' manager.funds(i).fjBName '_' num2str(Y) '_' num2str(M)];     % 进入都对应日期的目录
            filename = [fileDir2 '\' manager.funds(i).fjBName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
            try
                ticks = csvread(filename);  % 读取分时数据
            catch e
                continue;
            end
            range = ticks(:,tickTable.time) >= date+begT & ticks(:,tickTable.time) < date+endT; %筛选尾盘数据
            StartIdx = find( range,1,'first');
            EndIdx = find( range,1,'last');
            if( isempty( StartIdx ) )   % 实际上为无数据
                continue;
            end
            StartIdx = max( StartIdx, 2 );  % 下表越界检查，同上
            ticksDataB{i} = ticks( StartIdx-1:EndIdx, : );     % 需要一个begT之前的交易数据，同上。
            
            timeListA{i} = zeros(180,tickTable.maxEntry);  % 每一行代表尾盘3分钟内每一秒的行情.
            timeListB{i} = zeros(180,tickTable.maxEntry);
            
            for j = 2:size(ticksDataA{i},1)    % 知道第一个值是早于referenceTime的，用于初始化curA
                t = round( (ticksDataA{i}(j,tickTable.time) - referenceTime)/constSec);
                timeListA{i}( t+1,: ) = ticksDataA{i}( j, 1:tickTable.maxEntry );
            end
            for j = 2:size(ticksDataB{i},1)
                t = round( (ticksDataB{i}(j,tickTable.time) - referenceTime)/constSec);
                timeListB{i}( t+1,: ) = ticksDataB{i}( j, 1:tickTable.maxEntry );
            end   
            curA{i} = ticksDataA{i}(1,1:tickTable.maxEntry);    
            curB{i} = ticksDataB{i}(1,1:tickTable.maxEntry);
        end
       
        if sum( realNetValue ) == 0
            continue;
        end
        previousZjTime = -6;    % 记录当天上一次做折价套利的时间
        % 模拟每一秒       
        for sec = 1:180
            if date == 42024
                pp = 1;
            end
            manager.referTime = sec;

            % 判断是否溢价
            for j = 1:typeNum
                if predictNetValue(j)==0 || isempty(timeListA{j}) || isempty(timeListB{j})
                    continue;
                end                   
                if timeListA{j}(sec,1)   % 这一秒分级A有交易记录，更新当前A的行情
                    curA{j} = timeListA{j}(sec,:);  
                end
                if timeListB{j}(sec,1)           
                    
                    curB{j} = timeListB{j}(sec,:);
                end
                [premRate, tradeVol] = manager.calPremRate( j, curA{j}(tickTable.buyPrice), curB{j}(tickTable.buyPrice), curA{j}(tickTable.buyVolume)', curB{j}(tickTable.buyVolume)', predictNetValue(j) );
                if premRate <= 0 
                    continue;
                end
%                 if zjType==2 && manager.funds(j).holdingStatus == 1  % 需要拆分
%                     manager.splitFund(j);
%                 end
                if  premRate > manager.funds(j).YjThresholds % 可以进行溢价套利
                    manager.doYj(j, premRate, tradeVol, predictNetValue(j));
                end
            end
              
            % 判断是否折价( 注意1s内只做一次折价 )
            if sec < previousZjTime + 5
                continue;
            end
            disStruct.rate = 0;     % 这个结构体记录折价套利率最大品种
            disStruct.margin = 0;
            disStruct.tradeVol = 0;
            disStruct.idx = 1;
            for j = 1:typeNum
                if predictNetValue(j)==0 || isempty(timeListA{j}) || isempty(timeListB{j})
                    continue;
                end                   
                % 行情已经更新过了 这里不再重复               
                [disRate, tradeVol] = manager.calDisRate( j, curA{j}(tickTable.salePrice), curB{j}(tickTable.salePrice), curA{j}(tickTable.saleVolume)', curB{j}(tickTable.saleVolume)', predictNetValue(j) );
                if disRate - manager.funds(j).ZjThresholds < disStruct.margin % 不是维护最大的折价率,而是维护利润空间最大
                    disStruct.rate = disRate;
                    disStruct.margin = disRate - manager.funds(j).ZjThresholds;
                    disStruct.tradeVol = tradeVol;
                    disStruct.idx = j;
                end
%                 switch zjType
%                     case 1
%                         
%                     case 2
%                         manager.mergeFund(j);    
%                 end
            end
            if disStruct.rate  < manager.funds(disStruct.idx).ZjThresholds      % 折价套利
                manager.doZj(disStruct.idx, disStruct.rate, disStruct.tradeVol, predictNetValue(disStruct.idx) );
                previousZjTime = sec;
            end
        end
        
        indexHs = find( zsHs300(:,idxDailyTable.date)==date);  
        zsHsClose  = zsHs300(indexHs, 2);
        if zsHsBgt == 0
            zsHsBgt = zsHsClose;
        end
        dailyRes(resultTable.date) = date;
        dailyRes(resultTable.zsRate) = zsHsClose / zsHsBgt; 
        dailyRes(resultTable.validMoney) = manager.validMoney;
        
        Result(ResultRowCnt,:) = dailyRes;
        Result(ResultRowCnt,resultTable.cumVar ) = Result(ResultRowCnt-1,resultTable.cumVar )+Result(ResultRowCnt,resultTable.cumVar );       
        ResultRowCnt= ResultRowCnt+1;
        
        manager.updateState(realNetValue);      %每日交易结束，模拟证券公司操作，更新资产状态   
        manager.dispHolding();
    end
    manager.updateState();  % 回收最后一天冻结的资金
    manager.dispHolding();
    diary off;
    
    Result(:,resultTable.tlRate) = Result(:,resultTable.yjRate) + Result(:,resultTable.zjRate); %totalTlRate = yjRate + zjRate; 总的套利率等于溢价套利率加上折价套利率 
    Result(:,resultTable.opNum) = Result(:,resultTable.yjNum) + Result(:,resultTable.zjNum);    %opNum = yjNums + zjNums;       总的套利次数等于溢价套利次数加上折价套利次数
    Result(1,:) = []; %删除第一行

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tradeDays = size(Result,1);
    timesDuration = Result(end,1)-bgt+1;
    result = Result(end,:)*100; 
    %日均率计算
    resultD = result;    
    resultD(resultTable.transVar) = resultD(resultTable.transVar)/tradeDays;
    %年化率计算
    resultY = result; 
    resultY(resultTable.transVar) = resultY(resultTable.transVar)/timesDuration*365;
 
    typeNumsM = mean(Result(:,resultTable.vilidVar));
    %%
    figure1=figure();
    set(gcf,'outerposition',get(0,'screensize'));   % 全屏,后面保存为bmp, 可保留屏幕中图的格式不变
    % subplot(211);
    hold on;
    x = Result(:,1)+693960;
    y = Result(:,resultTable.tlRate);
    plot(x,y+1, 'r');
    xl = linspace(x(1),x(end),12);
    set(gca,'XTick',xl);
    datetick('x',20,'keepticks');
    xmin = min(x);
    xmax = max(x);
    ymin = 0.5;
    ymax = 1.7;
    axis([xmin xmax ymin ymax]);
    if zjType == 2
        fTitle = '两倍折价';
    else
        fTitle = '一倍折价';
    end
    %title(fTitle);
    inner = (ymax-ymin)/10;
%     text(xmin+10,ymax-inner*1,['开始时间：',datestr(Result(1,resultTable.date)+693960,'yyyy-mm-dd'),'    ','结束时间：',datestr(Result(end,resultTable.date)+693960,'yyyy-mm-dd')],'FontSize',10);
%     text(xmin+10,ymax-inner*2,['实际交易日：' num2str(tradeDays) '天      输入时间跨度：' num2str(timesDuration) '天    持仓品种数均值：' num2str(typeNumsM)],'FontSize',10);
    text(xmin+10,ymax-inner*3,['总投入资金:' num2str(initMoney) ' 总收益率：' num2str(result(resultTable.tlRate)) '%    年化收益率：' num2str(resultY(resultTable.tlRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.tlRate)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*4,['折价总收益率：' num2str(result(resultTable.zjRate)) '%    折价年化收益率：' num2str(resultY(resultTable.zjRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.zjRate)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*5,['溢价总收益率：' num2str(result(resultTable.yjRate)) '%    溢价年化收益率：' num2str(resultY(resultTable.yjRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.yjRate)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*6,['折价额外总收益率：' num2str(result(resultTable.zjRatePlus)) '%    折价额外年化收益率：' num2str(resultY(resultTable.zjRatePlus)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*7,['折价剩余总收益率：' num2str(result(resultTable.zjRateLeft)) '%    折价剩余年化收益率：' num2str(resultY(resultTable.zjRateLeft)) '%'],'FontSize',10);
    
%     text(xmin+10,ymax-inner*8,['溢价剩余总收益率：' num2str(result(resultTable.yjRateLeft)) '%    溢价剩余年化收益率：' num2str(resultY(resultTable.yjRateLeft)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*9,['溢价浪费总收益率：' num2str(result(resultTable.zjRateFail)) '%    溢价浪费年化收益率：' num2str(resultY(resultTable.zjRateFail)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*9.5,['涨跌停剩余总收益率：' num2str(result(resultTable.tradeLimitLeft)) '%    涨跌停浪费年化收益率：' num2str(resultY(resultTable.tradeLimitLeft)) '%'],'FontSize',10);
    plot(x,Result(:,resultTable.zsRate),'g');
%    plot(x,Result(:,resultTable.tlRate) + Result(:,resultTable.zsRate),'b');
%     plot(x,Result(:,resultTable.zjRateLeft)+1,'k');
%     plot(x,Result(:,resultTable.zjRatePlus)+1,'y');
%     plot(x,Result(:,resultTable.yjRateLeft)+1,'c');
%     plot(x,Result(:,resultTable.tradeLimitLeft)+1,'m');
%     plot(x,Result(:,resultTable.holdingValue)/(manager.initAsset*manager.handleRate),'Color',[0.6 0.2 0.4]);
%     legend('套利净值', '沪深300', '资金总净值', '折价套利剩余空间', '二倍折价额外收益', '二倍折价溢价减益','涨跌停剩余收益率','持仓净值波动', -1);
    legend('套利净值', '沪深300', -1);

    configFile = configFile(1:end-4); % 去除拓展名
    saveDir = ['..\result\分时数据模拟' configFile '_' num2str(slipRatio) '倍滑点_持仓比' num2str(handleRate(1)) '-' num2str(handleRate(2))];
    if exist(saveDir,'dir') == 0
        mkdir(saveDir);
    end
    figurePath = [saveDir '\' fTitle '_' num2str(year) '.bmp'];
    saveas( gcf, figurePath );
    save_path = [saveDir '\' num2str(year) 'Result'];
    sheet = 1;   
    xlswrite( save_path, resultTable.listHeader, sheet);   % 确保文件名中不存在字符'.'
    startE = 'A2';
    xlswrite( save_path, Result, sheet, startE);
    %csvwrite([saveDir '\' num2str(year) 'Result.csv'], Result );
    
    csvwrite([saveDir '\' num2str(year) '折溢价率.csv'], squeeze(resDetial( rDetialTable.ZYRate,:,:)) );
    csvwrite([saveDir '\' num2str(year) '折价率.csv'], squeeze(resDetial( rDetialTable.ZjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '溢价率.csv'], squeeze(resDetial( rDetialTable.YjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '折价收益率.csv'], squeeze(resDetial( rDetialTable.ZjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '折价亏损率.csv'], squeeze(resDetial( rDetialTable.ZjKsRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '溢价收益率.csv'], squeeze(resDetial( rDetialTable.YjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '分拆合并折溢价率.csv'], squeeze(resDetial( rDetialTable.FHRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '分拆溢价率.csv'], squeeze(resDetial( rDetialTable.FcRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '合并折价率.csv'], squeeze(resDetial( rDetialTable.HbRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '涨跌停时预计收益率.csv'], squeeze(resDetial( rDetialTable.TradeLimit,:,:)));

end
