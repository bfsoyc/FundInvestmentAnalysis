function init2()
global erateTable;
global resultTable;
global rateTable;
global configTable;
global muDailyTable;
global fjDailyTable;
global idxDailyTable;
global rDetialTable;
global statList;

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
    fjDailyTable.highPrice = 3;         %最高价
    fjDailyTable.lowPrice = 4;          %最低价
    fjDailyTable.closingPrice = 2;      %收盘价
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
    resultTable.numOfInstance = 15;     %该变量记录result表格的列数
    %记录所有累加的变量accumulation variable :非直接统计量不放在下表，如opNum
    resultTable.accVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail ]; 
    %记录所有需要标准化的变量（即除以assetManager2.typeNums） regularization variable;
    resultTable.regVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail  ];
    %记录所有需要计算年化以及日均值的变量 transform variable
    resultTable.transVar = [ resultTable.yjRate resultTable.zjRate resultTable.tlRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail ]; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rDetialTable.ZYRate = 1;
    rDetialTable.ZjRate = 2;
    rDetialTable.YjRate = 3;
    rDetialTable.ZjSyRate = 4;
    rDetialTable.ZjKsRate = 5;
    rDetialTable.YjSyRate = 6;
    rDetialTable.FHRate = 7;
    rDetialTable.FcRate = 8;
    rDetialTable.HbRate = 9;
    rDetialTable.numOfInstance = 9;

%%%%%%%%%%%%%%%%%%%%%%%分级基金套利率表头配置%%%%%%%%%%%%%%%%%%
    rateTable.date = 1;
    rateTable.of = [];