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
    fjDailyTable.highPrice = 3;         %��߼�
    fjDailyTable.lowPrice = 4;          %��ͼ�
    fjDailyTable.closingPrice = 2;      %���̼�
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
    resultTable.numOfInstance = 15;     %�ñ�����¼result��������
    %��¼�����ۼӵı���accumulation variable :��ֱ��ͳ�����������±���opNum
    resultTable.accVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail ]; 
    %��¼������Ҫ��׼���ı�����������assetManager2.typeNums�� regularization variable;
    resultTable.regVar = [ resultTable.yjRate resultTable.zjRate resultTable.zjRateLeft resultTable.zjRatePlus resultTable.yjRateLeft resultTable.zjRateFail  ];
    %��¼������Ҫ�����껯�Լ��վ�ֵ�ı��� transform variable
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

%%%%%%%%%%%%%%%%%%%%%%%�ּ����������ʱ�ͷ����%%%%%%%%%%%%%%%%%%
    rateTable.date = 1;
    rateTable.of = [];