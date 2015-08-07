function init()
global erateTable;
global resultTable;
global rateTable;
global configTable;
global muDailyTable;
global fjDailyTable;
global idxDailyTable;
global rDetialTable;
global statList;
global estimate;
global meanTHeader;
global tickTable;
global turnoverTHeader;
%%%%%%%%%%%%%%%% 误差估计表头 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    estimate.muCode = 1;
    estimate.eps = 2;
    estimate.predict = 3;
    estimate.realNetValue = 4;
    estimate.epsPercent = 5;
    estimate.disRate = 6;
    estimate.zjFlag = 7;
    estimate.thrFlag = 8;
    estimate.predAIncrease = 9;
    estimate.FundAeps = 10;
    estimate.predBIncrease = 11;
    estimate.FundBeps = 12;
    estimate.predIdxIncrease = 13;
    estimate.IndexEps = 14;
    
    estimate.numOfEntries = 14;
    % 需要保存的数据表头（请按照上述顺序)
    estimate.listHeader = {'母基金代码','误差','预测净值','真实净值','误差百分比','折溢价率','折价标志','超过阈值标志'...
        '分级A预估涨幅','分级A预估误差','分级B预估涨幅','分级B预估误差','指数预估涨幅','指数预估误差'};
    
    % 常数定义
    estimate.Predict_Mode = 1;  % 分析母基金的预测净值误差分布
    estimate.Index_Mode = 2;    % 分析指数预测收盘价误差分布
    estimate.FundA_Mode = 4;
    estimate.FundB_Mode = 8;
%%%%%%%%%%%%%%%%%%%%%均值表头%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 用误差均值估算滑点率。
    meanTHeader.muCode = 1;
    meanTHeader.netValuePerc = 2;
    meanTHeader.zjNetValuePerc = 3;
    meanTHeader.yjNetValuePerc = 4;
    meanTHeader.fundAIncrease = 5;
    meanTHeader.zjFundAIncrease = 6;
    meanTHeader.yjFundAIncrease = 7;
    meanTHeader.fundBIncrease = 8;
    meanTHeader.zjFundBIncrease = 9;
    meanTHeader.yjFundBIncrease = 10;
    meanTHeader.indexIncrease = 11;
    meanTHeader.zjIndexIncrease = 12;
    meanTHeader.yjIndexIncrease = 13;
    meanTHeader.numOfEntries = 13;
    % 下面每个列表里面的顺序很重要
    meanTHeader.muMean = [meanTHeader.netValuePerc meanTHeader.zjNetValuePerc meanTHeader.yjNetValuePerc];
    meanTHeader.fundAMean = [meanTHeader.fundAIncrease meanTHeader.zjFundAIncrease meanTHeader.yjFundAIncrease];
    meanTHeader.fundBMean = [meanTHeader.fundBIncrease meanTHeader.zjFundBIncrease meanTHeader.yjFundBIncrease];
    meanTHeader.indexMean = [meanTHeader.indexIncrease meanTHeader.zjIndexIncrease meanTHeader.yjIndexIncrease];
    meanTHeader.listHeader = {'母基金代码','母基金预测净值涨幅误差','折价净值涨幅误差','溢价净值涨幅误差','分级A预测涨幅误差','折价涨幅误差','溢价涨幅误差',...
        '分级B预测涨幅误差','折价涨幅误差','溢价涨幅误差','指数预测涨幅误差','折价涨幅误差','溢价涨幅误差'};
%%%%%%%%%%%%%%%%%%%%%尾盘交易额百分比统计值表头%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    turnoverTHeader.muCode = 1;
    turnoverTHeader.fundAMean = 2;
    turnoverTHeader.fundAPeak = 3;
    turnoverTHeader.fundAMedian = 4;
    turnoverTHeader.fundBMean = 5;
    turnoverTHeader.fundBPeak = 6;
    turnoverTHeader.fundBMedian = 7;
    
    turnoverTHeader.numOfEntries = 7;
    turnoverTHeader.listHeader = {'母基金代码','分级A比重均值','分级A最大概率比重','分级A比重中位数','分级B比重均值','分级B最大概率比重','分级B比重中位数'};
%%%%%%%%%%%%%%%%需要统计的基金列表表头%%%%%%%%%%%%%%%%%%%%%%
    statList.muName = 1;
    statList.zsName = 3;
    statList.fjAName = 5;
    statList.fjBName = 7;
    statList.aShare = 9;
    statList.bShare = 10;
    statList.applyFee = 11;
    statList.redeemFee = 12;
%%%%%%%%%%%%%%%%ERate的表头配置%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    erateTable.date = 1;        %时间
    erateTable.zhejialv = 2;    %折价率
    erateTable.cost = 3;        %购买成本
    erateTable.netValue = 4;    %净值
    erateTable.indexRise = 5;   %指数涨幅
    erateTable.expectReturn = 6;%预期收益率
    erateTable.actualReturn = 7;%实际收益率
    erateTable.riskReturn = 8;   %承受的风险收益
    erateTable.netYield	 = 9;    %净收益
    erateTable.mark = 10;        %0 没操作， 1 表示折价套利，2 表示溢价套利
    erateTable.fjAclosepri = 11; %分级A的收盘价
    erateTable.fjBclosepri = 12; %分级B的收盘价 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%申购赎回份额计算模板表头%%%%%%%%%%%%%%%%%%%%%
    configTable.muName = 2;         %母基金代号
    configTable.fjAName = 3;        %子基金A代号
    configTable.fjBName = 4;        %子基金B代号
    configTable.zsName = 5;         %指数名
    configTable.aShare = 6;         %子基金A份额(总数是10)
    configTable.bShare = 7;         %子基金B份额
    configTable.applyFee = 8;       %申购（买入）该母基金的手续费（一般千分之五）
    configTable.redeemFee = 9;      %赎回（出售）该母基金的手续费（一般千分之四）
    configTable.YjThresholds = 10;  %溢价率标准，大于该数时才进行开仓
    configTable.ZjThresholds = 11;  %折价率标准，小于该数时才进行开仓
    configTable.slipRate = 12;      % 滑点率，主要影响为折价时，同时买入A、B，若基金不太活跃，则造成的滑点相对会较大，但因为此处用的是收盘价，而非盘中发生最大折价率时的价格，故可设为0
%%%%%%%%%%%%%%%%%%%母基金日线表头%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    muDailyTable.date = 1;          %日期
    muDailyTable.netValue = 2;      %净值


%%%%%%%%%%%%%%%%%%%%分级基金日线表头配置%%%%%%%%%%%%%%%%%%%%%%%%%
    fjDailyTable.date = 1;              %时间
   % fjDailyTable.openingPrice = 2;      %开盘价
    fjDailyTable.increase = 3;
    %fjDailyTable.highPrice = 3;         %最高价
    fjDailyTable.lowPrice = 4;          %最低价
    fjDailyTable.closingPrice = 2;      %收盘价
    fjDailyTable.turnover = 7;        %交易额
%%%%%%%%%%%%%%%%%%%%%%指数日线表头配置%%%%%%%%%%%%%%%%%%%%%%
    idxDailyTable.date = 1;          %日期
    idxDailyTable.netValue = 2;     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    resultTable.date = 1;
    resultTable.tlRate = 2;             %累计套利率
    resultTable.zsRate = 3;
    resultTable.vilidVar = 4;
    resultTable.opNum = 5;
    resultTable.yjNum = 6;
    resultTable.zjNum = 7;
    resultTable.nomoneyNum = 8;
    resultTable.zjRateLeft = 9;         %累计套利率剩余价值
    resultTable.zjRatePlus = 10;        %二倍折价套利额外收益
    resultTable.yjRateLeft = 11;        %二倍折价套利溢价减益
    resultTable.zjRate = 12;
    resultTable.yjRate = 13;
    resultTable.zjRateFail = 14;        %昨日溢价导致今日无法折价
    resultTable.validMoney = 15;
    resultTable.tradeLimitLeft = 16;    % 因为涨跌停导致的剩余价值
    resultTable.numOfEntries = 16;     %该变量记录result表格的列数
    
    resultTable.listHeader = {'日期','累计总套利率','zsRate','当前品总数','操作数','溢价操作数','折价操作数','资金缺乏数',...
        '累计套利率剩余价值','二倍折价套利额外收益','二倍折价套利溢价减益','折价套利率','溢价套利率','折价Fail',...
        '现金数','涨跌停剩余价值'};
    %记录所有累加的变量cumulative variable :非直接统计量不放在下表，如opNum
    resultTable.cumVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail resultTable.tradeLimitLeft ]; 
    %记录所有需要标准化的变量（即除以assetManager2.typeNums） regularization variable;
    resultTable.regVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail resultTable.tradeLimitLeft ];
    %记录所有需要计算年化以及日均值的变量 transform variable
    resultTable.transVar = [ resultTable.yjRate resultTable.zjRate resultTable.tlRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail resultTable.tradeLimitLeft ]; 

%%%%%%%%%%%%%%%%%%%%%%分时数据表头%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tickTable.time = 1;
    tickTable.increase = 3;
    tickTable.tradeVolume = 4;
    tickTable.turnover = 5;
    tickTable.buyPrice = [8 9 10 11 12];        % 这个购入价是市场挂牌买入的加价，及我们卖出的价格。
    tickTable.salePrice = [13 14 15 16 17];
    tickTable.buyVolume = [18 19 20 21 22];
    tickTable.saleVolume = [23 24 25 26 27];
    tickTable.maxEntry = 27;    % 最大的索引下标

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rDetialTable.ZYRate = 1;
    rDetialTable.ZjRate = 2;
    rDetialTable.YjRate = 3;
    rDetialTable.ZjSyRate = 4;
    rDetialTable.ZjKsRate = 5;
    rDetialTable.YjSyRate = 6;
    rDetialTable.FHRate = 7;
    rDetialTable.FcRate = 8;
    rDetialTable.HbRate = 9;
    rDetialTable.TradeLimit = 10;
    rDetialTable.numOfEntries = 10;

%%%%%%%%%%%%%%%%%%%%%%%分级基金套利率表头配置%%%%%%%%%%%%%%%%%%
    rateTable.date = 1;
    rateTable.of = [];