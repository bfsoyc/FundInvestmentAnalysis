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
%%%%%%%%%%%%%%%% �����Ʊ�ͷ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    % ��Ҫ��������ݱ�ͷ���밴������˳��)
    estimate.listHeader = {'ĸ�������','���','Ԥ�⾻ֵ','��ʵ��ֵ','���ٷֱ�','�������','�ۼ۱�־','������ֵ��־'...
        '�ּ�AԤ���Ƿ�','�ּ�AԤ�����','�ּ�BԤ���Ƿ�','�ּ�BԤ�����','ָ��Ԥ���Ƿ�','ָ��Ԥ�����'};
    
    % ��������
    estimate.Predict_Mode = 1;  % ����ĸ�����Ԥ�⾻ֵ���ֲ�
    estimate.Index_Mode = 2;    % ����ָ��Ԥ�����̼����ֲ�
    estimate.FundA_Mode = 4;
    estimate.FundB_Mode = 8;
%%%%%%%%%%%%%%%%%%%%%��ֵ��ͷ%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ������ֵ���㻬���ʡ�
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
    % ����ÿ���б������˳�����Ҫ
    meanTHeader.muMean = [meanTHeader.netValuePerc meanTHeader.zjNetValuePerc meanTHeader.yjNetValuePerc];
    meanTHeader.fundAMean = [meanTHeader.fundAIncrease meanTHeader.zjFundAIncrease meanTHeader.yjFundAIncrease];
    meanTHeader.fundBMean = [meanTHeader.fundBIncrease meanTHeader.zjFundBIncrease meanTHeader.yjFundBIncrease];
    meanTHeader.indexMean = [meanTHeader.indexIncrease meanTHeader.zjIndexIncrease meanTHeader.yjIndexIncrease];
    meanTHeader.listHeader = {'ĸ�������','ĸ����Ԥ�⾻ֵ�Ƿ����','�ۼ۾�ֵ�Ƿ����','��۾�ֵ�Ƿ����','�ּ�AԤ���Ƿ����','�ۼ��Ƿ����','����Ƿ����',...
        '�ּ�BԤ���Ƿ����','�ۼ��Ƿ����','����Ƿ����','ָ��Ԥ���Ƿ����','�ۼ��Ƿ����','����Ƿ����'};
%%%%%%%%%%%%%%%%%%%%%β�̽��׶�ٷֱ�ͳ��ֵ��ͷ%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    turnoverTHeader.muCode = 1;
    turnoverTHeader.fundAMean = 2;
    turnoverTHeader.fundAPeak = 3;
    turnoverTHeader.fundAMedian = 4;
    turnoverTHeader.fundBMean = 5;
    turnoverTHeader.fundBPeak = 6;
    turnoverTHeader.fundBMedian = 7;
    
    turnoverTHeader.numOfEntries = 7;
    turnoverTHeader.listHeader = {'ĸ�������','�ּ�A���ؾ�ֵ','�ּ�A�����ʱ���','�ּ�A������λ��','�ּ�B���ؾ�ֵ','�ּ�B�����ʱ���','�ּ�B������λ��'};
%%%%%%%%%%%%%%%%��Ҫͳ�ƵĻ����б��ͷ%%%%%%%%%%%%%%%%%%%%%%
    statList.muName = 1;
    statList.zsName = 3;
    statList.fjAName = 5;
    statList.fjBName = 7;
    statList.aShare = 9;
    statList.bShare = 10;
    statList.applyFee = 11;
    statList.redeemFee = 12;
%%%%%%%%%%%%%%%%ERate�ı�ͷ����%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    erateTable.date = 1;        %ʱ��
    erateTable.zhejialv = 2;    %�ۼ���
    erateTable.cost = 3;        %����ɱ�
    erateTable.netValue = 4;    %��ֵ
    erateTable.indexRise = 5;   %ָ���Ƿ�
    erateTable.expectReturn = 6;%Ԥ��������
    erateTable.actualReturn = 7;%ʵ��������
    erateTable.riskReturn = 8;   %���ܵķ�������
    erateTable.netYield	 = 9;    %������
    erateTable.mark = 10;        %0 û������ 1 ��ʾ�ۼ�������2 ��ʾ�������
    erateTable.fjAclosepri = 11; %�ּ�A�����̼�
    erateTable.fjBclosepri = 12; %�ּ�B�����̼� 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%�깺��طݶ����ģ���ͷ%%%%%%%%%%%%%%%%%%%%%
    configTable.muName = 2;         %ĸ�������
    configTable.fjAName = 3;        %�ӻ���A����
    configTable.fjBName = 4;        %�ӻ���B����
    configTable.zsName = 5;         %ָ����
    configTable.aShare = 6;         %�ӻ���A�ݶ�(������10)
    configTable.bShare = 7;         %�ӻ���B�ݶ�
    configTable.applyFee = 8;       %�깺�����룩��ĸ����������ѣ�һ��ǧ��֮�壩
    configTable.redeemFee = 9;      %��أ����ۣ���ĸ����������ѣ�һ��ǧ��֮�ģ�
    configTable.YjThresholds = 10;  %����ʱ�׼�����ڸ���ʱ�Ž��п���
    configTable.ZjThresholds = 11;  %�ۼ��ʱ�׼��С�ڸ���ʱ�Ž��п���
    configTable.slipRate = 12;      % �����ʣ���ҪӰ��Ϊ�ۼ�ʱ��ͬʱ����A��B��������̫��Ծ������ɵĻ�����Ի�ϴ󣬵���Ϊ�˴��õ������̼ۣ��������з�������ۼ���ʱ�ļ۸񣬹ʿ���Ϊ0
%%%%%%%%%%%%%%%%%%%ĸ�������߱�ͷ%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    muDailyTable.date = 1;          %����
    muDailyTable.netValue = 2;      %��ֵ


%%%%%%%%%%%%%%%%%%%%�ּ��������߱�ͷ����%%%%%%%%%%%%%%%%%%%%%%%%%
    fjDailyTable.date = 1;              %ʱ��
   % fjDailyTable.openingPrice = 2;      %���̼�
    fjDailyTable.increase = 3;
    %fjDailyTable.highPrice = 3;         %��߼�
    fjDailyTable.lowPrice = 4;          %��ͼ�
    fjDailyTable.closingPrice = 2;      %���̼�
    fjDailyTable.turnover = 7;        %���׶�
%%%%%%%%%%%%%%%%%%%%%%ָ�����߱�ͷ����%%%%%%%%%%%%%%%%%%%%%%
    idxDailyTable.date = 1;          %����
    idxDailyTable.netValue = 2;     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    resultTable.date = 1;
    resultTable.tlRate = 2;             %�ۼ�������
    resultTable.zsRate = 3;
    resultTable.vilidVar = 4;
    resultTable.opNum = 5;
    resultTable.yjNum = 6;
    resultTable.zjNum = 7;
    resultTable.nomoneyNum = 8;
    resultTable.zjRateLeft = 9;         %�ۼ�������ʣ���ֵ
    resultTable.zjRatePlus = 10;        %�����ۼ�������������
    resultTable.yjRateLeft = 11;        %�����ۼ�������ۼ���
    resultTable.zjRate = 12;
    resultTable.yjRate = 13;
    resultTable.zjRateFail = 14;        %������۵��½����޷��ۼ�
    resultTable.validMoney = 15;
    resultTable.tradeLimitLeft = 16;    % ��Ϊ�ǵ�ͣ���µ�ʣ���ֵ
    resultTable.numOfEntries = 16;     %�ñ�����¼result��������
    
    resultTable.listHeader = {'����','�ۼ���������','zsRate','��ǰƷ����','������','��۲�����','�ۼ۲�����','�ʽ�ȱ����',...
        '�ۼ�������ʣ���ֵ','�����ۼ�������������','�����ۼ�������ۼ���','�ۼ�������','���������','�ۼ�Fail',...
        '�ֽ���','�ǵ�ͣʣ���ֵ'};
    %��¼�����ۼӵı���cumulative variable :��ֱ��ͳ�����������±���opNum
    resultTable.cumVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail resultTable.tradeLimitLeft ]; 
    %��¼������Ҫ��׼���ı�����������assetManager2.typeNums�� regularization variable;
    resultTable.regVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail resultTable.tradeLimitLeft ];
    %��¼������Ҫ�����껯�Լ��վ�ֵ�ı��� transform variable
    resultTable.transVar = [ resultTable.yjRate resultTable.zjRate resultTable.tlRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail resultTable.tradeLimitLeft ]; 

%%%%%%%%%%%%%%%%%%%%%%��ʱ���ݱ�ͷ%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tickTable.time = 1;
    tickTable.increase = 3;
    tickTable.tradeVolume = 4;
    tickTable.turnover = 5;
    tickTable.buyPrice = [8 9 10 11 12];        % �����������г���������ļӼۣ������������ļ۸�
    tickTable.salePrice = [13 14 15 16 17];
    tickTable.buyVolume = [18 19 20 21 22];
    tickTable.saleVolume = [23 24 25 26 27];
    tickTable.maxEntry = 27;    % ���������±�

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

%%%%%%%%%%%%%%%%%%%%%%%�ּ����������ʱ�ͷ����%%%%%%%%%%%%%%%%%%
    rateTable.date = 1;
    rateTable.of = [];