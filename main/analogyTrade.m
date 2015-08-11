%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 模拟实际交易
% 策略是：每个品种在某个时刻可套利的情况下，按持仓量全部卖出或买入，五档挂单量不
% 够的自动放弃。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 添加工程目录
Files = dir(fullfile( '..\','*.*'));
for i = 1:length(Files)
    if( Files(i).isdir )
        addpath( ['..\' Files(i).name ])
    end
end
    
%% 变量设置
bgtyear = 2015;
edtyear = 2015;
init();
global resultTable fjDailyTable rateTable tickTable muDailyTable idxDailyTable rDetialTable statList;

% 计算分时数据用到
filterT = [14 54 00; 14 57 00];
begT = getDoubleTime(filterT(1, :));    % 实盘操作开始时间
endT = getDoubleTime(filterT(2, :));

initMoney = 1e6;
handleRate = [2 4];%2/3、2/4持仓
zjType =2;     %折价类型 一倍，两倍……
slipRatio = 0;  %N倍滑点率，0时代表不考虑滑点

save_root = '..\result';
data_root = 'G:\datastore';
configFile = '\config7_30.csv';
[selectFund,w] = getSelectionFund();
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
        temp.muData = csvread(['G:\datastore\母基金1\' muName,'.csv']);
        temp.fjAData = csvread(['G:\datastore\日线1\' fjAName  '.csv']);
        temp.fjBData = csvread(['G:\datastore\日线1\' fjBName  '.csv']);
        temp.zsData = csvread(['G:\datastore\日线1\' zsName  '.csv']);
        temp.name = muCode;  
        temp.fjAName = fjAName;
        temp.fjBName = fjBName;
        temp.slipRate = 0.01;    %
        temp.aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
        temp.bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
        temp.applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
        temp.redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
        temp.stockFee = 0.00025;    % 固定的
        temp.YjThresholds = temp.applyFee + 0.002;
        temp.ZjThresholds = -temp.redeemFee -0.002;
        Src(k) = {temp};
    catch ME
        disp([ME.message ' ' muName]);
        error('数据不全');
    end
    if exist([data_root '\ticks\' Src{k}.fjAName],'dir') == 0    %检查数据库中是否有该基金的分时数据
        error('没有%s的分时数据',Src{k}.fjAName);
    end
    if exist([data_root '\ticks\' Src{k}.fjBName],'dir') == 0    %检查数据库中是否有该基金的分时数据
        error('没有%s的分时数据',Src{k}.fjBName);
    end
end
% 清除空cell
emptyCell = cellfun( @isempty, Src ) ;
Src(emptyCell) = [];

%% 开始模拟交易
srclen = size(Src,2);
% 按年计算
for year = bgtyear:edtyear
    bgt = getIntDay([year, 1, 1]);
    edt = getIntDay([year, 12, 31]);
    
    diary off;
    delete([save_root '\log.txt']);
    diary([save_root '\log.txt']); %日志   
    manager = AssetManagerQQQ(initMoney,handleRate(1)/handleRate(2));
    % 先建仓
    for i = 1:srclen              
        muData = Src{i}.muData(Src{i}.muData(:, muDailyTable.date) >= bgt & Src{i}.muData(:, muDailyTable.date) < edt, : );
        idx = 1;       
        while( ~muData(idx, muDailyTable.netValue ) )
            idx = idx + 1;
        end
        manager.addTypes(Src{i}.name,w(i), muData(idx, muDailyTable.netValue ) );
    end
    
    Result=zeros(1,resultTable.numOfEntries);  % Result每一行记录了每一个交易日的总体折溢盈亏状况， 这里初始化第一行。
    
    resDetial = zeros( rDetialTable.numOfEntries,1,srclen+1 ); % resDetial( :, i, j) 记录了第i个交易日第j个基金品种的信息（折溢率等等，详情见结构体 rDetialtable,由第一个索引指定）, 这里预先分配内存。

    ResultRowCnt = 2;                %Result 表格的行计数器 从第二行开始
    zsHsBgt = 0;
    zsHsClose = 0;
    
    
    
    %按日计算
    for date = bgt+1:edt % 确保取到昨日净值
        resDetial(:,ResultRowCnt, rateTable.date ) = date;
        [Y, M, D] = getVectorDay( date );
        allTicks = [];
        for i = 1:srclen    % 对每个品种分级基金tick数据筛选出尾盘3分钟的交易的数据并计算折溢价率。
            indexMu = find( Src{i}.muData(:,muDailyTable.date)==date);   
            indexFjA = find( Src{i}.fjAData(:,fjDailyTable.date)==date);
            indexFjB = find( Src{i}.fjBData(:,fjDailyTable.date)==date);
            indexZs = find( Src{i}.zsData(:,idxDailyTable.date)==date);
            indexHs = find( zsHs300(:,idxDailyTable.date)==date);  
            
            if isempty(indexMu) || isempty(indexFjA) || isempty(indexZs) || isempty(indexFjB) || isempty(indexHs)
               continue;
            end
            if indexMu <= 1 || indexFjA <= 1 || indexFjB <= 1 || indexZs <= 1 || indexHs <= 1
                continue;
            end
            % 设置变量别名           
            muData = Src{i}.muData( indexMu , : );          %当天母基金数据
            prev_muData = Src{i}.muData( indexMu-1 , : );    %前一天数据                   
            zsData = Src{i}.zsData( indexZs, : ); 
            
            if muData(muDailyTable.netValue) == 0   % 当天无母基金数据
                continue;
            end
            % 先判断是否发生上下折           
            openPriceM = prev_muData(muDailyTable.netValue); % 前一天的净值            
            closePriceM = muData(muDailyTable.netValue); % 当天的净值
            changeM = closePriceM/openPriceM - 1;           
            if  changeM > 0.12
                fprintf(['--(' num2str(date) ')基金 ' num2str(Src{i}.name) ' 发生下折\n']);
                continue;
            elseif changeM < -0.12
                fprintf(['--(' num2str(date) ')基金 ' num2str(Src{i}.name) ' 发生上折\n']);
                continue;
            end
            
            %计算实际折价率
            %预测当日净值
            predictNetValue = prev_muData(muDailyTable.netValue)*(1+0.95*Src{i}.zsData(indexZs,3)/100);
            
            % 读A 
            fileDir = [data_root '\ticks\' Src{i}.fjAName];
            fileDir2 = [fileDir '\' Src{i}.fjAName '_' num2str(Y) '_' num2str(M)];     % 进入都对应日期的目录
            filename = [fileDir2 '\' Src{i}.fjAName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
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
            ticksDataA = ticks( StartIdx-1:EndIdx, : );     % 需要一个begT之前的交易数据，极端情况下若不存在这个数据，用begT后出现的第一个数据替代。
            % 同理读B
            fileDir = [data_root '\ticks\' Src{i}.fjBName];
            fileDir2 = [fileDir '\' Src{i}.fjBName '_' num2str(Y) '_' num2str(M)];     % 进入都对应日期的目录
            filename = [fileDir2 '\' Src{i}.fjBName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
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
            ticksDataB = ticks( StartIdx-1:EndIdx, : );     % 需要一个begT之前的交易数据，同上。
            
            tickNodes = extractTickNode( ticksDataA, ticksDataB, Src{i}.name, predictNetValue, manager.holdings(i),Src{i}.aShare, Src{i}.bShare, Src{i}.YjThresholds, Src{i}.ZjThresholds, date+begT );
            allTicks = [allTicks; tickNodes ];
        end
        if isempty(allTicks)    % 今天没有可以套利的空间
            continue;
        end
        [~, idx] = sort([allTicks.time]);   % 先按时间排序
        allTicks = allTicks(idx);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        used = zeros(srclen,1);         % 标记是否使用过
        dailyRes = zeros(1, resultTable.numOfEntries);  % result Table 的一行.
        numOfTicks = length( allTicks );
        startIdx = 1;
        while( startIdx <= numOfTicks )
            endIdx = startIdx+1;
            while( endIdx <= numOfTicks && allTicks(endIdx).time == allTicks(startIdx).time )
                endIdx = endIdx+1;
            end
            secNodes = allTicks( startIdx:endIdx-1 ); % 提取出每一秒内所有的可盈利的交易方案            
            % 先处理溢价的. premium
            preNodes =  secNodes([secNodes.disRate] > 0);
            for j = 1:length(preNodes)
                node = preNodes(j);
                [isOk, pos] = manager.canDoYj(node.code);
                if used(pos)
                    continue;
                end          
                used(pos) = 1;
                % 计算收益率
                indexMu = find( Src{pos}.muData(:,muDailyTable.date)==date);
                netvalue = Src{pos}.muData(indexMu,muDailyTable.netValue);      % 取出当天母基金真实净值。
                cost = netvalue * manager.holdings(pos) * (1 + Src{pos}.applyFee);
                gain = ( node.fjAPrice*node.fjAVolume + node.fjBPrice*node.fjBVolume )*(1-Src{i}.stockFee-Src{i}.slipRate*slipRatio);
                profitRate = (gain-cost)/manager.initAsset;
                               
                % 二倍折价时 溢价用于拆分，这里还需要考虑
                if isOk == 2    % 溢价是基本都可以做的，唯一不可以做的情况是没有子基金A,B的持仓（前一天为了做二倍折价而多合并了母基金）
                    if node.disRate > 0% 其实这个条件判断是多余的因为溢价肯定大于0的
                        manager.doSpl(node.code);    % 溢价情况下，多了母基金，则要拆分。
                        resDetial( rDetialTable.FHRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                        resDetial( rDetialTable.FcRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                    end
                    if node.disRate > Src{pos}.YjThresholds    % 这个条件判断也是多余的，因为前面是大于阈值才保存下来的  
                        dailyRes( resultTable.yjRateLeft ) = dailyRes( resultTable.yjRateLeft ) + profitRate;  % 超出阈值，可以做溢价套利，但是没有子基金而不能操作，溢价剩余收益累加加。                       
                    end
                elseif isOk == 1 % 后面这个条件多余就不判断了 && item.rate > Src{item.pos}.YjThresholds  
                    manager.doYj(node.code, gain-cost);  %%！！TODO更新实时操作而导致资产状态变化
                    dailyRes( resultTable.yjNum ) = dailyRes( resultTable.yjNum )+1;
                    dailyRes( resultTable.yjRate ) = dailyRes( resultTable.yjRate ) + profitRate;        % 套利率累加
                    resDetial( rDetialTable.YjSyRate , ResultRowCnt, rateTable.date+pos) = profitRate;
                    % log
                    format = [ '--(%d,%2d)申购母基金 %d(pred%.2f %.2f) \n' ...
                        '%12s卖出分级A [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...
                        '%12s卖出分级B [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...                    
                        '%12s花费 %.2f, 盈利 %.2f, 收益 %.2f 总现金 %.2f\n' ];
                    fprintf(format, date, node.time, node.code, netvalue, node.netvalue, ...
                        '', node.fjAVolume, node.fjAPrice, ... 
                        '', node.fjBVolume, node.fjBPrice, ... 
                        '', cost, gain, gain-cost, manager.validMoney);
                end                
            end
            
            % 再处理折价的. discount
            disNodes =  secNodes([secNodes.disRate] < 0);
            [~,idx] = sort( [disNodes.disRate] );   % 按折价率(绝对值)从大到小排序.
            disNodes = disNodes( idx );
            for j = 1:length(disNodes)                
                node = disNodes(j);
                cost = ( node.fjAPrice*node.fjAVolume + node.fjBPrice*node.fjBVolume )*(1-Src{i}.stockFee-Src{i}.slipRate*slipRatio);   % 花费
                [isOk, pos] = manager.canDoZj(node.code,cost);
                if used( pos )
                    continue;
                end
                % 计算收益率
                indexMu = find( Src{pos}.muData(:,muDailyTable.date)==date);
                netvalue = Src{pos}.muData(indexMu,muDailyTable.netValue);      % 取出当天母基金真实净值。
                gain = netvalue * manager.holdings(pos) * (1 + Src{pos}.applyFee);                
                profitRate = (gain-cost)/manager.initAsset;
                               
                if isOk == 2
                    dailyRes( resultTable.zjRatePlus ) = dailyRes( resultTable.zjRatePlus ) + profitRate;  % 指二倍折价策略比一倍折价策略多出的收益？
                end
                if isOk > 0    %判断是否可以作zhe价操作 1或者2
                    zjNum = isOk;   
                    % 两倍折价
                    if zjType == 2
                        if isOk == 1 && node.disRate < -0.01   
                            zjNum = 2;
                            resDetial( rDetialTable.FHRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                            resDetial( rDetialTable.HbRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                        end
                    end
                    
                    used( pos ) = 1;
                    manager.doZj(Src{pos}.name, cost, gain, zjNum);  % zjNum == 2 不表示可以做2倍折价，而是该折价操作后，T+1天拥有2倍持仓
                    dailyRes( resultTable.zjNum ) = dailyRes( resultTable.zjNum )+1;
                    dailyRes( resultTable.zjRate ) = dailyRes( resultTable.zjRate ) + profitRate*isOk;
                    resDetial( rDetialTable.ZjSyRate , ResultRowCnt, rateTable.date+pos) = profitRate*isOk;
                     % log
                    format = [ '--(%d,%2d)赎回母基金 %d(pred%.2f %.2f) %d倍折价套利 \n' ...
                        '%12s买入分级A [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...
                        '%12s买入分级B [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...                    
                        '%12s花费 %.2f, 盈利(冻结) %.2f, 收益 %.2f 总现金 %.2f\n' ];
                    fprintf(format, date, node.time, node.code, node.netvalue, netvalue, isOk, ...
                        '', node.fjAVolume, node.fjAPrice, ... 
                        '', node.fjBVolume, node.fjBPrice, ... 
                        '', cost*isOk, gain*isOk, (gain-cost)*isOk, manager.validMoney);
                    
                elseif isOk < 0   % 现金不够，不能做折价
                    dailyRes( resultTable.nomoneyNum ) = dailyRes( resultTable.nomoneyNum ) + 1;
                    dailyRes( resultTable.zjRateLeft ) = dailyRes( resultTable.zjRateLeft ) - profitRate*isOk;
                    resDetial( rDetialTable.ZjKsRate , ResultRowCnt, rateTable.date+pos) = -1;  %表示现金不够不能做折价。
                else        % isOK == 0;前一天溢价，今天不能折价
                    resDetial( rDetialTable.ZjKsRate , ResultRowCnt, rateTable.date+pos) = profitRate;
                    dailyRes( resultTable.zjRateFail ) = dailyRes( resultTable.zjRateFail ) + profitRate;
                end                  
            end     
            startIdx = endIdx;
        end
        
        indexHs = find( zsHs300(:,idxDailyTable.date)==date);  
        zsHsClose  = zsHs300(indexHs, 2);
        if zsHsBgt == 0
            zsHsBgt = zsHsClose;
        end
        dailyRes(resultTable.date) = date;
        dailyRes(resultTable.zsRate) = zsHsClose / zsHsBgt; 
        % dailyRes(resultTable.vilidVar) = manager.typeNums;
        dailyRes(resultTable.validMoney) = manager.validMoney;
        % dailyRes(resultTable.regVar) = dailyRes(resultTable.regVar)/assetManager2.typeNums;            %必须每天标准化
        
        Result(ResultRowCnt,:) = dailyRes;
        Result(ResultRowCnt,resultTable.cumVar ) = Result(ResultRowCnt-1,resultTable.cumVar )+Result(ResultRowCnt,resultTable.cumVar );       
        ResultRowCnt= ResultRowCnt+1;
        
        manager.updateState();      %每日交易结束，模拟证券公司操作，更新资产状态       
    end
    manager.updateState();  % 回收最后一天冻结的资金
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
    figure1=figure();
    % subplot(211);
    hold on;
    x = Result(:,1)+693960;
    y = Result(:,resultTable.tlRate);
    plot(x,y+1, 'r');
    datetick('x',28);
    xmin = min(x);
    xmax = max(x);
    ymin = 0.5;
    ymax = 2.5;
    axis([xmin xmax ymin ymax]);
    if zjType == 2
        fTitle = '两倍折价';
    else
        fTitle = '一倍折价';
    end
    title(fTitle);
    inner = (ymax-ymin)/10;
    text(xmin+10,ymax-inner*1,['开始时间：',datestr(Result(1,resultTable.date)+693960,'yyyy-mm-dd'),'    ','结束时间：',datestr(Result(end,resultTable.date)+693960,'yyyy-mm-dd')],'FontSize',10);
    text(xmin+10,ymax-inner*2,['实际交易日：' num2str(tradeDays) '天      输入时间跨度：' num2str(timesDuration) '天    持仓品种数均值：' num2str(typeNumsM)],'FontSize',10);
    text(xmin+10,ymax-inner*3,['总收益率：' num2str(result(resultTable.tlRate)) '%    年化收益率：' num2str(resultY(resultTable.tlRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.tlRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*4,['折价总收益率：' num2str(result(resultTable.zjRate)) '%    折价年化收益率：' num2str(resultY(resultTable.zjRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.zjRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*5,['溢价总收益率：' num2str(result(resultTable.yjRate)) '%    溢价年化收益率：' num2str(resultY(resultTable.yjRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.yjRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*6,['折价额外总收益率：' num2str(result(resultTable.zjRatePlus)) '%    折价额外年化收益率：' num2str(resultY(resultTable.zjRatePlus)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*7,['折价剩余总收益率：' num2str(result(resultTable.zjRateLeft)) '%    折价剩余年化收益率：' num2str(resultY(resultTable.zjRateLeft)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*8,['溢价剩余总收益率：' num2str(result(resultTable.yjRateLeft)) '%    溢价剩余年化收益率：' num2str(resultY(resultTable.yjRateLeft)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*9,['溢价浪费总收益率：' num2str(result(resultTable.zjRateFail)) '%    溢价浪费年化收益率：' num2str(resultY(resultTable.zjRateFail)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*9.5,['涨跌停剩余总收益率：' num2str(result(resultTable.tradeLimitLeft)) '%    溢价浪费年化收益率：' num2str(resultY(resultTable.tradeLimitLeft)) '%'],'FontSize',10);
    plot(x,Result(:,resultTable.zsRate),'g');
    plot(x,Result(:,resultTable.tlRate) + Result(:,resultTable.zsRate),'b');
    plot(x,Result(:,resultTable.zjRateLeft)+1,'k');
    plot(x,Result(:,resultTable.zjRatePlus)+1,'y');
    plot(x,Result(:,resultTable.yjRateLeft)+1,'c');
    plot(x,Result(:,resultTable.tradeLimitLeft)+1,'m');
    legend('套利净值', '沪深300', '资金总净值', '折价套利剩余空间', '二倍折价额外收益', '二倍折价溢价减益','涨跌停剩余收益率', -1);


    configFile = 'config';
    saveDir = ['..\result\折溢价率\' configFile '_' num2str(slipRatio) '倍滑点_持仓比' num2str(handleRate(1)) '-' num2str(handleRate(2))];
    if exist(saveDir,'dir') == 0
        mkdir(saveDir);
    end
    figurePath = [saveDir '\' fTitle '_' num2str(year) '.bmp'];
    set(gcf,'outerposition',get(0,'screensize'));
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
