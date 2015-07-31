%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   �ð汾��ȡ config.csv�ļ�
%   ����ָ��Ʒ��(selectMode=1)�����Ҳ�֧��Ȩ������
%   �����ʼ��㷽ʽ��    ��Ҫ���Ե���Ļ���ֲ�Ʒ��������ÿ������ʲ��Ǻ㶨�ģ�ƽ�����䵽����Ʒ���С�
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function multiAnalyzeModel1()
%% ��ӹ���Ŀ¼
Files = dir(fullfile( '..\','*.*'));
for i = 1:length(Files)
    if( Files(i).isdir )
        addpath( ['..\' Files(i).name ])
    end
end
%% ��������
bgtyear = 2013;
edtyear = 2015;
init2();
global resultTable fjDailyTable rateTable configTable muDailyTable idxDailyTable rDetialTable statList;

handleRate = [2 3];%2/3��2/4�ֲ�
zjType = 2;     %�ۼ����� һ������������
slipRatio = 0;  %N�������ʣ�0ʱ�������ǻ���

[selectFund,weight] = getSelectionFund();
selectMode = 0;

%%  ��ȡ����
config = readcsv2('\config.csv', 12);
zsHs300 = csvread('G:\datastore\����1\SZ399300.csv');
tableLen = length(config{1});    
Src = cell(1,tableLen);
for k = 2:tableLen     %��һ���Ǳ�ͷ
    
    muName = config{statList.muName}{k};
    % ���û����Ƿ�Ҫ����
    muCode = str2num(muName(3:end));
    if( selectMode == 1)
        idx =  selectFund == muCode;
        if ( ~sum( idx  ) )
         continue;
        end
    end
    
    fjAName = config{statList.fjAName}{k};      %�ӻ���A�����������SZ��ͷ
    fjBName = config{statList.fjBName}{k};
    zsName = config{statList.zsName}{k};
    try
        %��ȡĸ������ּ�����A��B���Լ���Ӧָ����������ݣ�ÿ�վ�ֵ���Ƿ��ȵ�
        temp.muData = csvread(['G:\datastore\ĸ����1\' muName,'.csv']);
        temp.fjAData = csvread(['G:\datastore\����1\' fjAName  '.csv']);
        temp.fjBData = csvread(['G:\datastore\����1\' fjBName  '.csv']);
        temp.zsData = csvread(['G:\datastore\����1\' zsName  '.csv']);
        temp.name = muCode;  
        temp.slipRate = 0.01;    %
        temp.aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
        temp.bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
        temp.applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
        temp.redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
        temp.stockFee = 0.00025;    % �̶���
        temp.YjThresholds = temp.applyFee + 0.002;
        temp.ZjThresholds = -temp.redeemFee -0.002;
        Src(k) = {temp};
    catch ME
        disp([ME.message ' ' muName]);
        continue ;
    end
 
end
% �����cell
emptyCell = cellfun( @isempty, Src ) ;
Src(emptyCell) = [];
srclen = size(Src,2);

if( selectMode == 1 )
    if srclen~=length( selectFund )
     error('�еĻ������ݲ�����');
    end
end
%%
srclen = size(Src,2);
% �������
for year = bgtyear:edtyear
    bgt = getIntDay([year, 1, 1]);
    edt = getIntDay([year, 12, 31]);
    assetManager2 = AssetManager2(handleRate(1), handleRate(2));%2/3�ֲ�
    Result=zeros(1,resultTable.numOfInstance);  % Resultÿһ�м�¼��ÿһ�������յ���������ӯ��״���� �����ʼ����һ�С�
    
    resDetial = zeros( rDetialTable.numOfInstance,1,srclen+1 ); % resDetial( :, i, j) ��¼�˵�i�������յ�j������Ʒ�ֵ���Ϣ�������ʵȵȣ�������ṹ�� rDetialtable,�ɵ�һ������ָ����, ����Ԥ�ȷ����ڴ档

    ResultRowCnt = 2;                %Result �����м����� �ӵڶ��п�ʼ
    zsHsBgt = 0;
    zsHsClose = 0;
    RateRow = 0;
    %���ռ���
    for date = bgt+1:edt %%ȷ��ȡ�����վ�ֵ
        disEDay=[];     %��۵�����  ������ۣ������ֽ𲻹����ۼۣ����ۼ�ʱ�ȱ��棬��������ѡ��������
        yjEDay=[];      %�ۼ۵�����   
        dailyRes = zeros( 1, resultTable.numOfInstance );   %ÿ��Ľ��������Result�е�һ��
        isTrade = 0;
        RateRow = RateRow+1;
        resDetial(:,RateRow, rateTable.date ) = date;
        
        %����ÿһ������Ļ���
        for i = 1:srclen;
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
            
             % ���þֲ�����           
            muData = Src{i}.muData( indexMu , : );          %����ĸ��������
            prev_muData = Src{i}.muData( indexMu-1 , : );    %ǰһ������
            
            fjAData = Src{i}.fjAData( indexFjA , : );
            prev_fjAData = Src{i}.fjAData( indexFjA-1 , : );
            
            fjBData = Src{i}.fjBData( indexFjB, : );
            prev_fjBData = Src{i}.fjBData( indexFjB-1 , : );
            
            zsData = Src{i}.zsData( indexZs, : );
            
            
            if muData(muDailyTable.netValue) == 0
                continue;
            end
            isNew = assetManager2.find(Src{i}.name);
            if isNew == -1
                assetManager2.addTypes(Src{i}.name);
            end
            zsHsClose  = zsHs300(indexHs, 2);
            if zsHsBgt == 0
                zsHsBgt = zsHsClose;
            end
            if isequal(Src{i}.fjBData(indexFjB,2),Src{i}.fjBData(indexFjB,3),Src{i}.fjBData(indexFjB,4),Src{i}.fjBData(indexFjB,5))%����ΪʲôҪ����
               continue;  
            end
            isTrade = 1;    %�ж��ǽ�����
            %����ʵ���ۼ���
              %Ԥ�⵱�վ�ֵ
            predictNetValue = prev_muData(muDailyTable.netValue)*(1+0.95*Src{i}.zsData(indexZs,3)/100);
            %�����ۼ��ʣ��õ������̼�������
            disRate = (fjAData(fjDailyTable.closingPrice)*Src{i}.aShare+fjBData(fjDailyTable.closingPrice)*Src{i}.bShare - predictNetValue)/predictNetValue;
            
            % ǰһ��ľ�ֵ��Ϣ
            openPriceM = prev_muData(muDailyTable.netValue);
            openPriceA = prev_fjAData(fjDailyTable.closingPrice);
            openPriceB = prev_fjBData(fjDailyTable.closingPrice);
            % ����ľ�ֵ��Ϣ
            closePriceM = muData(muDailyTable.netValue);
            closePriceA = fjAData(fjDailyTable.closingPrice);
            closePriceB = fjBData(fjDailyTable.closingPrice);
            changeM = closePriceM/openPriceM - 1;
            
            if closePriceM == 1 %������
                if  changeM > 0.12
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' ����']);
                    continue;
                elseif changeM < -0.12
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' ����']);
                    continue;
                end
            end
            changeA = closePriceA/openPriceA - 1;
            changeB = closePriceB/openPriceB - 1;

            if disRate > 0 %����ȴ�����

                pre.rate = disRate;
                pre.pos = i;
                pre.cost = muData(muDailyTable.netValue)*(1+Src{i}.applyFee);
                pre.sy = (fjAData(fjDailyTable.closingPrice)*Src{i}.aShare+fjBData(fjDailyTable.closingPrice)*Src{i}.bShare)*(1-Src{i}.stockFee-Src{i}.slipRate*slipRatio);
                % ����ļ��㣬�������ӻ���A��B��ã� sy = ���ӻ���A��B����ֵ��*��1-��Ʊ����������-������*������ʣ�
                % ���������������������������ʲ�Ӧ��������ĸ��������
                pre.syRate = (pre.sy-pre.cost)/pre.cost * assetManager2.CcRate();
                
                if changeA < -0.0995 || changeB < -0.0995
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' A��B��ͣ']);
                    if changeA < -0.0995
                        resDetial( rDetialTable.TradeLimit, RateRow, rateTable.date+i) = pre.syRate;
                    end
                    if changeB < -0.0995
                        resDetial( rDetialTable.TradeLimit, RateRow, rateTable.date+i) = pre.syRate;
                    end
                    
                    continue;
                end               
                yjEDay = [yjEDay pre];
                resDetial( rDetialTable.ZYRate , RateRow, rateTable.date+i) = disRate;      %ֻҪ��۾ʹ�ZYRate
                if disRate > Src{i}.YjThresholds
                    resDetial( rDetialTable.YjRate , RateRow, rateTable.date+i) = disRate;  %ֻ�д�����ֵ���������Ŵ�YjRate
                end
            elseif disRate < Src{i}.ZjThresholds  %�ۼ��ȱ��棬���������
                if changeA > 0.0995 || changeB > 0.0995
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' A��B��ͣ']);
                    continue;
                end
                dis.rate = disRate;
                dis.rate_mins_thr = dis.rate - Src{i}.ZjThresholds;
                dis.pos = i;
                dis.cost = (fjAData(fjDailyTable.closingPrice)*Src{i}.aShare+fjBData(fjDailyTable.closingPrice)*Src{i}.bShare)*(1+Src{i}.stockFee+Src{i}.slipRate*slipRatio);
                dis.sy = muData(muDailyTable.netValue)*(1-Src{i}.redeemFee);
                dis.syRate = (dis.sy-dis.cost)/dis.cost * assetManager2.CcRate();
                disEDay = [disEDay dis];
                resDetial( rDetialTable.ZYRate , RateRow, rateTable.date+i) = disRate;      %ֻ�д�����ֵ���������Ŵ�ZYRate
                resDetial( rDetialTable.ZjRate , RateRow, rateTable.date+i) = disRate;
            else
                continue;
            end
        end

        if isTrade ~= 1 %������������ǽ�����,���ǽ�����������
            RateRow = RateRow - 1;
            continue;
        end
        
        if( date == 41904 )
            ppp = 1;
        end
        
        if ~isempty(yjEDay)
            for j = 1:size(yjEDay,2);
                item = yjEDay(j);
                isOk = assetManager2.canDoYj(Src{item.pos}.name);
                if isOk == 2    % ����ǻ������������ģ�Ψһ���������������û���ӻ���A,B�ĳֲ֣�ǰһ��Ϊ���������ۼ۶���ϲ���ĸ����
                    if item.rate > 0% ��ʵ��������ж��Ƕ���ģ���Ϊ yjEDay��Ŀ϶�����۵�
                        disp(['split ' num2str(Src{item.pos}.name)]);
                        assetManager2.doSpl(Src{item.pos}.name);    % �������£�����ĸ������Ҫ��֡�
                        resDetial( rDetialTable.FHRate , RateRow, rateTable.date+item.pos) = item.rate;
                        resDetial( rDetialTable.FcRate , RateRow, rateTable.date+item.pos) = item.rate;
                    end
                    if item.rate > Src{item.pos}.YjThresholds      
                        dailyRes( resultTable.yjRateLeft ) = dailyRes( resultTable.yjRateLeft ) + item.syRate;  % ������ֵ���������������������û���ӻ�������ܲ��������ʣ�������ۼӼӡ�
                        
                    end
                elseif isOk == 1 && item.rate > Src{item.pos}.YjThresholds  
                    assetManager2.doYj(Src{item.pos}.name);  %%����TODO����ʵʱ�����������ʲ�״̬�仯
                    dailyRes( resultTable.yjNum ) = dailyRes( resultTable.yjNum )+1;
                    dailyRes( resultTable.yjRate ) = dailyRes( resultTable.yjRate ) + item.syRate;        % �������ۼ�
                    resDetial( rDetialTable.YjSyRate , RateRow, rateTable.date+item.pos) = item.syRate;
                end
            end
        end

        if ~isempty(disEDay)    %���ۼۿ�����
            % ����Ĭ�ϰ�syRate������
            [ascendRate, idx] = sort([disEDay.rate_mins_thr]);
            disEDay = disEDay(idx);
            
            for j = 1:size(disEDay,2);  %������ֵ�жϣ�
                item = disEDay(j);
                isOk = assetManager2.canDoZj(Src{item.pos}.name);
                if isOk == 2
                    dailyRes( resultTable.zjRatePlus ) = dailyRes( resultTable.zjRatePlus ) + item.syRate;  % ָ�����ۼ۲��Ա�һ���ۼ۲��Զ�������棿
                end
                if isOk > 0    %�ж��Ƿ������zhe�۲��� 1����2
                    zjNum = isOk;   
                    % �����ۼ�
                    if zjType == 2
                        if isOk == 1 && item.rate < -0.01   
                            zjNum = 2;
                            resDetial( rDetialTable.FHRate , RateRow, rateTable.date+item.pos) = item.rate;
                            resDetial( rDetialTable.HbRate , RateRow, rateTable.date+item.pos) = item.rate;
                        end
                    end
                    
                    assetManager2.doZj(Src{item.pos}.name, zjNum);  % zjNum == 2 ����ʾ������2���ۼۣ����Ǹ��ۼ۲�����T+1��ӵ��2���ֲ�
                    dailyRes( resultTable.zjNum ) = dailyRes( resultTable.zjNum )+1;
                    dailyRes( resultTable.zjRate ) = dailyRes( resultTable.zjRate ) + item.syRate*isOk;
                    resDetial( rDetialTable.ZjSyRate , RateRow, rateTable.date+item.pos) = item.syRate*isOk;
                elseif isOk < 0   % �ֽ𲻹����������ۼ�
                    dailyRes( resultTable.nomoneyNum ) = dailyRes( resultTable.nomoneyNum ) + 1;
                    dailyRes( resultTable.zjRateLeft ) = dailyRes( resultTable.zjRateLeft ) - item.syRate*isOk;
                    resDetial( rDetialTable.ZjKsRate , RateRow, rateTable.date+item.pos) = -1;  %��ʾ�ֽ𲻹��������ۼۡ�
                else        % isOK == 0;
                    resDetial( rDetialTable.ZjKsRate , RateRow, rateTable.date+item.pos) = item.syRate;
                    dailyRes( resultTable.zjRateFail ) = dailyRes( resultTable.zjRateFail ) + item.syRate;
                end
            end
        end

        dailyRes(resultTable.date) = date;
        dailyRes(resultTable.zsRate) = zsHsClose / zsHsBgt; 
        dailyRes(resultTable.vilidVar) = assetManager2.typeNums;
        dailyRes(resultTable.validMoney) = assetManager2.validMoney;
        dailyRes(resultTable.regVar) = dailyRes(resultTable.regVar)/assetManager2.typeNums;            %����ÿ���׼��
        
        Result(ResultRowCnt,:) = dailyRes;
        Result(ResultRowCnt,resultTable.cumVar ) = Result(ResultRowCnt-1,resultTable.cumVar )+Result(ResultRowCnt,resultTable.cumVar );       
        ResultRowCnt= ResultRowCnt+1;
        
        assetManager2.updateState();      %ÿ�ս��׽�����ģ��֤ȯ��˾�����������ʲ�״̬
    end    
    Result(:,resultTable.tlRate) = Result(:,resultTable.yjRate) + Result(:,resultTable.zjRate); %totalTlRate = yjRate + zjRate; �ܵ������ʵ�����������ʼ����ۼ������� 
    Result(:,resultTable.opNum) = Result(:,resultTable.yjNum) + Result(:,resultTable.zjNum);    %opNum = yjNums + zjNums;       �ܵ�����������������������������ۼ���������
    Result(1,:) = []; %ɾ����һ��

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tradeDays = size(Result,1);
    timesDuration = Result(end,1)-bgt+1;
    result = Result(end,:)*100; 
    %�վ��ʼ���
    resultD = result;    
    resultD(resultTable.transVar) = resultD(resultTable.transVar)/tradeDays;
    %�껯�ʼ���
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
        fTitle = '�����ۼ�';
    else
        fTitle = 'һ���ۼ�';
    end
    title(fTitle);
    inner = (ymax-ymin)/10;
    text(xmin+10,ymax-inner*1,['��ʼʱ�䣺',datestr(Result(1,resultTable.date)+693960,'yyyy-mm-dd'),'    ','����ʱ�䣺',datestr(Result(end,resultTable.date)+693960,'yyyy-mm-dd')],'FontSize',10);
    text(xmin+10,ymax-inner*2,['ʵ�ʽ����գ�' num2str(tradeDays) '��      ����ʱ���ȣ�' num2str(timesDuration) '��    �ֲ�Ʒ������ֵ��' num2str(typeNumsM)],'FontSize',10);
    text(xmin+10,ymax-inner*3,['�������ʣ�' num2str(result(resultTable.tlRate)) '%    �껯�����ʣ�' num2str(resultY(resultTable.tlRate)) '%' '    ƽ��ÿ��������' num2str(resultD(resultTable.tlRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*4,['�ۼ��������ʣ�' num2str(result(resultTable.zjRate)) '%    �ۼ��껯�����ʣ�' num2str(resultY(resultTable.zjRate)) '%' '    ƽ��ÿ��������' num2str(resultD(resultTable.zjRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*5,['����������ʣ�' num2str(result(resultTable.yjRate)) '%    ����껯�����ʣ�' num2str(resultY(resultTable.yjRate)) '%' '    ƽ��ÿ��������' num2str(resultD(resultTable.yjRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*6,['�ۼ۶����������ʣ�' num2str(result(resultTable.zjRatePlus)) '%    �ۼ۶����껯�����ʣ�' num2str(resultY(resultTable.zjRatePlus)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*7,['�ۼ�ʣ���������ʣ�' num2str(result(resultTable.zjRateLeft)) '%    �ۼ�ʣ���껯�����ʣ�' num2str(resultY(resultTable.zjRateLeft)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*8,['���ʣ���������ʣ�' num2str(result(resultTable.yjRateLeft)) '%    ���ʣ���껯�����ʣ�' num2str(resultY(resultTable.yjRateLeft)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*9,['����˷��������ʣ�' num2str(result(resultTable.zjRateFail)) '%    ����˷��껯�����ʣ�' num2str(resultY(resultTable.zjRateFail)) '%'],'FontSize',10);
    plot(x,Result(:,resultTable.zsRate),'g');
    plot(x,Result(:,resultTable.tlRate) + Result(:,resultTable.zsRate),'b');
    plot(x,Result(:,resultTable.zjRateLeft)+1,'k');
    plot(x,Result(:,resultTable.zjRatePlus)+1,'y');
    plot(x,Result(:,resultTable.yjRateLeft)+1,'c');
    legend('������ֵ', '����300', '�ʽ��ܾ�ֵ', '�ۼ�����ʣ��ռ�', '�����ۼ۶�������', '�����ۼ���ۼ���', -1);


    configFile = 'config';
    saveDir = ['..\result\�������\' configFile '_' num2str(slipRatio) '������_�ֱֲ�' num2str(handleRate(1)) '-' num2str(handleRate(2))];
    if exist(saveDir,'dir') == 0
        mkdir(saveDir);
    end
    figurePath = [saveDir '\' fTitle '_' num2str(year) '.bmp'];
    set(gcf,'outerposition',get(0,'screensize'));
    saveas( gcf, figurePath );
    %RD = resDetial( rDetialTable.ZYRate,:,:);
    %RD = squeeze(RD);
    csvwrite([saveDir '\' num2str(year) 'Result.csv'], Result );
    csvwrite([saveDir '\' num2str(year) '�������.csv'], squeeze(resDetial( rDetialTable.ZYRate,:,:)) );
    csvwrite([saveDir '\' num2str(year) '�ۼ���.csv'], squeeze(resDetial( rDetialTable.ZjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�����.csv'], squeeze(resDetial( rDetialTable.YjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ۼ�������.csv'], squeeze(resDetial( rDetialTable.ZjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ۼۿ�����.csv'], squeeze(resDetial( rDetialTable.ZjKsRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '���������.csv'], squeeze(resDetial( rDetialTable.YjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ֲ�ϲ��������.csv'], squeeze(resDetial( rDetialTable.FHRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ֲ������.csv'], squeeze(resDetial( rDetialTable.FcRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ϲ��ۼ���.csv'], squeeze(resDetial( rDetialTable.HbRate,:,:)));

end
end