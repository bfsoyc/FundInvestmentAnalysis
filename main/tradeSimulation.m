%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ģ��ʵ�ʽ���
% �����ǣ�ÿ��Ʒ����ĳ��ʱ�̿�����������£����ֲ���ȫ�����������룬�嵵�ҵ�����
% �����Զ�������ͬһ���ڣ���ͬ��Ʒ�����������ͬʱ�µ������������ۼ�����֮����Ҫ���5��.
% ͬһƷ�֣��ֱʽ���ʱ�����ν���ʱ����������15s
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ��ӹ���Ŀ¼
Files = dir(fullfile( '..\','*.*'));
for i = 1:length(Files)
    if( Files(i).isdir )
        addpath( ['..\' Files(i).name ])
    end
end
    
%% ��������
clear;     % ������һ��
bgtyear = 2015;
edtyear = 2015;
init();
global resultTable fjDailyTable rateTable tickTable muDailyTable idxDailyTable rDetialTable statList;

% �����ʱ�����õ�
filterT = [14 54 00; 14 57 00];
begT = getDoubleTime(filterT(1, :));    % ʵ�̲�����ʼʱ��
endT = getDoubleTime(filterT(2, :));

initMoney = 6e6;
handleRate = [2 3];%2/3��2/4�ֲ�
zjType =1;     %�ۼ����� һ������������
slipRatio = 0;  %N�������ʣ�0ʱ�������ǻ���

save_root = '..\result';
data_root = 'G:\datastore';
configFile = '\config7_30.csv';
[~,w] = getSelectionFund();
%w = [1 1 1];
w = w/sum(w);

%%  ��ȡ����
config = readcsv2(configFile, 12);   %
zsHs300 = csvread('G:\datastore\����1\SZ399300.csv');
tableLen = length(config{1});    
Src = cell(1,tableLen);
for k = 2:tableLen     %��һ���Ǳ�ͷ
    
    muName = config{statList.muName}{k};
    if( length(muName) < 8 )
        muName = ['OF' muName];
    end
    muCode = str2num(muName(3:end));
    
    fjAName = config{statList.fjAName}{k};      %�ӻ���A�����������SZ��ͷ
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
        %��ȡĸ������ּ�����A��B���Լ���Ӧָ����������ݣ�ÿ�վ�ֵ���Ƿ��ȵ�
        temp.data.muData = csvread(['G:\datastore\ĸ����1\' muName,'.csv']);
        temp.data.fjAData = csvread(['G:\datastore\����1\' fjAName  '.csv']);
        temp.data.fjBData = csvread(['G:\datastore\����1\' fjBName  '.csv']);      
        temp.data.zsData = csvread(['G:\datastore\����1\' zsName  '.csv']);
        temp.configInfo = ConfigInfo;
        temp.configInfo.name = muCode;  
        temp.configInfo.fjAName = fjAName;
        temp.configInfo.fjBName = fjBName;
        temp.configInfo.slipRate = 0.01;    %
        temp.configInfo.aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
        temp.configInfo.bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
        temp.configInfo.applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
        temp.configInfo.redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
        temp.configInfo.stockFee = 0.00025;    % �̶���
        temp.configInfo.YjThresholds = temp.configInfo.applyFee + 0.002;
        temp.configInfo.ZjThresholds = -temp.configInfo.redeemFee -0.002;
        Src(k) = {temp};
    catch ME
        disp([ME.message ' ' muName]);
        error('���ݲ�ȫ');
    end
    if exist([data_root '\ticks\' Src{k}.configInfo.fjAName],'dir') == 0    %������ݿ����Ƿ��иû���ķ�ʱ����
        error('û��%s�ķ�ʱ����',Src{k}.configInfo.fjAName);
    end
    if exist([data_root '\ticks\' Src{k}.configInfo.fjBName],'dir') == 0    %������ݿ����Ƿ��иû���ķ�ʱ����
        error('û��%s�ķ�ʱ����',Src{k}.configInfo.fjBName);
    end
end
% �����cell
emptyCell = cellfun( @isempty, Src ) ;
Src(emptyCell) = [];

%% ��ʼģ�⽻��
typeNum = size(Src,2);
% �������
for year = bgtyear:edtyear
    bgt = getIntDay([year, 1, 1]);
    edt = getIntDay([year, 12, 31]);
    
    diary off;
    delete([save_root '\log.txt']);
    diary([save_root '\log.txt']); %��־   
    manager = tradeSimulator(initMoney,handleRate(1)/handleRate(2));
    % �Ƚ���
    for i = 1:typeNum              
        muData = Src{i}.data.muData(Src{i}.data.muData(:, muDailyTable.date) >= bgt & Src{i}.data.muData(:, muDailyTable.date) < edt, : );
        idx = 1;       
        while( ~muData(idx, muDailyTable.netValue ) )
            idx = idx + 1;
        end
        manager.addTypes(Src{i}.configInfo, w(i), muData(idx, muDailyTable.netValue ) );
    end
    
    Result=zeros(1,resultTable.numOfEntries);  % Resultÿһ�м�¼��ÿһ�������յ���������ӯ��״���� �����ʼ����һ�С�
    
    resDetial = zeros( rDetialTable.numOfEntries,1,typeNum+1 ); % resDetial( :, i, j) ��¼�˵�i�������յ�j������Ʒ�ֵ���Ϣ�������ʵȵȣ�������ṹ�� rDetialtable,�ɵ�һ������ָ����, ����Ԥ�ȷ����ڴ档

    ResultRowCnt = 2;                %Result �����м����� �ӵڶ��п�ʼ
    zsHsBgt = 0;
    zsHsClose = 0;
     
    %���ռ���
    for date = bgt+1:edt % ȷ��ȡ�����վ�ֵ
        manager.date = date;
        referenceTime = date + begT;
        resDetial(:,ResultRowCnt, rateTable.date ) = date;
        dailyRes = zeros(1, resultTable.numOfEntries);  % result Table ��һ��.
        predictNetValue = zeros(1,typeNum);             % ��¼Ԥ�⾻ֵ.
        realNetValue = zeros(1,typeNum);                % ��¼��ʵ��ֵ.
        [Y, M, D] = getVectorDay( date );       
        constSec = 1/24/60/60;  % 1s�ĳ���
        for i = 1:typeNum    % ��ÿ��Ʒ�ַּ�����tick����ɸѡ��β��3���ӵĽ��׵����ݲ�����ʱ�䡣 
            timeListA{i} = [];      % ����timeListA �����ݲ������������������timeListA�Ƿ�Ϊ����Ϊ�������ݵı�׼,����������
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
            % ���ñ�������           
            muData = Src{i}.data.muData( indexMu , : );          %����ĸ��������
            prev_muData = Src{i}.data.muData( indexMu-1 , : );    %ǰһ������    
            zsData = Src{i}.data.zsData( indexZs, : ); 
            
            if muData(muDailyTable.netValue) == 0   % ������ĸ��������
                continue;
            end
            % ���ж��Ƿ���������           
            openPriceM = prev_muData(muDailyTable.netValue); % ǰһ��ľ�ֵ            
            closePriceM = muData(muDailyTable.netValue); % ����ľ�ֵ
            realNetValue(i) = closePriceM;
            
            changeM = closePriceM/openPriceM - 1;           
            if  changeM > 0.12
                fprintf(['--(' num2str(date) ')���� ' num2str(manager.funds(i).name) ' ��������\n']);
                continue;
            elseif changeM < -0.12
                fprintf(['--(' num2str(date) ')���� ' num2str(manager.funds(i).name) ' ��������\n']);
                continue;
            end
            
            %Ԥ�⵱�վ�ֵ
            zsChange = Src{i}.data.zsData(indexZs,3)/100;
            predictNetValue(i) = prev_muData(muDailyTable.netValue) * (1 + 0.95*zsChange);
            
            % ��A 
            fileDir = [data_root '\ticks\' manager.funds(i).fjAName];
            fileDir2 = [fileDir '\' manager.funds(i).fjAName '_' num2str(Y) '_' num2str(M)];     % ���붼��Ӧ���ڵ�Ŀ¼
            filename = [fileDir2 '\' manager.funds(i).fjAName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
            try
                ticks = csvread(filename);  % ��ȡ��ʱ����
            catch e
                continue;
            end
            range = ticks(:,tickTable.time) >= date+begT & ticks(:,tickTable.time) < date+endT; %ɸѡβ������
            StartIdx = find( range,1,'first');
            EndIdx = find( range,1,'last');
            if( isempty( StartIdx ) )   % ʵ����Ϊ������
                continue;
            end
            StartIdx = max( StartIdx, 2 );  % �±�Խ���飬��֤StartIdx-1 > 0
            ticksDataA{i} = ticks( StartIdx-1:EndIdx, : );     % ��Ҫһ��begT֮ǰ�Ľ������ݣ������������������������ݣ���begT����ֵĵ�һ�����������
            % ͬ���B
            fileDir = [data_root '\ticks\' manager.funds(i).fjBName];
            fileDir2 = [fileDir '\' manager.funds(i).fjBName '_' num2str(Y) '_' num2str(M)];     % ���붼��Ӧ���ڵ�Ŀ¼
            filename = [fileDir2 '\' manager.funds(i).fjBName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
            try
                ticks = csvread(filename);  % ��ȡ��ʱ����
            catch e
                continue;
            end
            range = ticks(:,tickTable.time) >= date+begT & ticks(:,tickTable.time) < date+endT; %ɸѡβ������
            StartIdx = find( range,1,'first');
            EndIdx = find( range,1,'last');
            if( isempty( StartIdx ) )   % ʵ����Ϊ������
                continue;
            end
            StartIdx = max( StartIdx, 2 );  % �±�Խ���飬ͬ��
            ticksDataB{i} = ticks( StartIdx-1:EndIdx, : );     % ��Ҫһ��begT֮ǰ�Ľ������ݣ�ͬ�ϡ�
            
            timeListA{i} = zeros(180,tickTable.maxEntry);  % ÿһ�д���β��3������ÿһ�������.
            timeListB{i} = zeros(180,tickTable.maxEntry);
            
            for j = 2:size(ticksDataA{i},1)    % ֪����һ��ֵ������referenceTime�ģ����ڳ�ʼ��curA
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
        previousZjTime = -6;    % ��¼������һ�����ۼ�������ʱ��
        % ģ��ÿһ��       
        for sec = 1:180
            if date == 42024
                pp = 1;
            end
            manager.referTime = sec;

            % �ж��Ƿ����
            for j = 1:typeNum
                if predictNetValue(j)==0 || isempty(timeListA{j}) || isempty(timeListB{j})
                    continue;
                end                   
                if timeListA{j}(sec,1)   % ��һ��ּ�A�н��׼�¼�����µ�ǰA������
                    curA{j} = timeListA{j}(sec,:);  
                end
                if timeListB{j}(sec,1)           
                    
                    curB{j} = timeListB{j}(sec,:);
                end
                [premRate, tradeVol] = manager.calPremRate( j, curA{j}(tickTable.buyPrice), curB{j}(tickTable.buyPrice), curA{j}(tickTable.buyVolume)', curB{j}(tickTable.buyVolume)', predictNetValue(j) );
                if premRate <= 0 
                    continue;
                end
%                 if zjType==2 && manager.funds(j).holdingStatus == 1  % ��Ҫ���
%                     manager.splitFund(j);
%                 end
                if  premRate > manager.funds(j).YjThresholds % ���Խ����������
                    manager.doYj(j, premRate, tradeVol, predictNetValue(j));
                end
            end
              
            % �ж��Ƿ��ۼ�( ע��1s��ֻ��һ���ۼ� )
            if sec < previousZjTime + 5
                continue;
            end
            disStruct.rate = 0;     % ����ṹ���¼�ۼ����������Ʒ��
            disStruct.margin = 0;
            disStruct.tradeVol = 0;
            disStruct.idx = 1;
            for j = 1:typeNum
                if predictNetValue(j)==0 || isempty(timeListA{j}) || isempty(timeListB{j})
                    continue;
                end                   
                % �����Ѿ����¹��� ���ﲻ���ظ�               
                [disRate, tradeVol] = manager.calDisRate( j, curA{j}(tickTable.salePrice), curB{j}(tickTable.salePrice), curA{j}(tickTable.saleVolume)', curB{j}(tickTable.saleVolume)', predictNetValue(j) );
                if disRate - manager.funds(j).ZjThresholds < disStruct.margin % ����ά�������ۼ���,����ά������ռ����
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
            if disStruct.rate  < manager.funds(disStruct.idx).ZjThresholds      % �ۼ�����
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
        
        manager.updateState(realNetValue);      %ÿ�ս��׽�����ģ��֤ȯ��˾�����������ʲ�״̬   
        manager.dispHolding();
    end
    manager.updateState();  % �������һ�춳����ʽ�
    manager.dispHolding();
    diary off;
    
    Result(:,resultTable.tlRate) = Result(:,resultTable.yjRate) + Result(:,resultTable.zjRate); %totalTlRate = yjRate + zjRate; �ܵ������ʵ�����������ʼ����ۼ������� 
    Result(:,resultTable.opNum) = Result(:,resultTable.yjNum) + Result(:,resultTable.zjNum);    %opNum = yjNums + zjNums;       �ܵ�����������������������������ۼ���������
    Result(1,:) = []; %ɾ����һ��

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
    %%
    figure1=figure();
    set(gcf,'outerposition',get(0,'screensize'));   % ȫ��,���汣��Ϊbmp, �ɱ�����Ļ��ͼ�ĸ�ʽ����
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
        fTitle = '�����ۼ�';
    else
        fTitle = 'һ���ۼ�';
    end
    %title(fTitle);
    inner = (ymax-ymin)/10;
%     text(xmin+10,ymax-inner*1,['��ʼʱ�䣺',datestr(Result(1,resultTable.date)+693960,'yyyy-mm-dd'),'    ','����ʱ�䣺',datestr(Result(end,resultTable.date)+693960,'yyyy-mm-dd')],'FontSize',10);
%     text(xmin+10,ymax-inner*2,['ʵ�ʽ����գ�' num2str(tradeDays) '��      ����ʱ���ȣ�' num2str(timesDuration) '��    �ֲ�Ʒ������ֵ��' num2str(typeNumsM)],'FontSize',10);
    text(xmin+10,ymax-inner*3,['��Ͷ���ʽ�:' num2str(initMoney) ' �������ʣ�' num2str(result(resultTable.tlRate)) '%    �껯�����ʣ�' num2str(resultY(resultTable.tlRate)) '%' '    ƽ��ÿ��������' num2str(resultD(resultTable.tlRate)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*4,['�ۼ��������ʣ�' num2str(result(resultTable.zjRate)) '%    �ۼ��껯�����ʣ�' num2str(resultY(resultTable.zjRate)) '%' '    ƽ��ÿ��������' num2str(resultD(resultTable.zjRate)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*5,['����������ʣ�' num2str(result(resultTable.yjRate)) '%    ����껯�����ʣ�' num2str(resultY(resultTable.yjRate)) '%' '    ƽ��ÿ��������' num2str(resultD(resultTable.yjRate)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*6,['�ۼ۶����������ʣ�' num2str(result(resultTable.zjRatePlus)) '%    �ۼ۶����껯�����ʣ�' num2str(resultY(resultTable.zjRatePlus)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*7,['�ۼ�ʣ���������ʣ�' num2str(result(resultTable.zjRateLeft)) '%    �ۼ�ʣ���껯�����ʣ�' num2str(resultY(resultTable.zjRateLeft)) '%'],'FontSize',10);
    
%     text(xmin+10,ymax-inner*8,['���ʣ���������ʣ�' num2str(result(resultTable.yjRateLeft)) '%    ���ʣ���껯�����ʣ�' num2str(resultY(resultTable.yjRateLeft)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*9,['����˷��������ʣ�' num2str(result(resultTable.zjRateFail)) '%    ����˷��껯�����ʣ�' num2str(resultY(resultTable.zjRateFail)) '%'],'FontSize',10);
%     text(xmin+10,ymax-inner*9.5,['�ǵ�ͣʣ���������ʣ�' num2str(result(resultTable.tradeLimitLeft)) '%    �ǵ�ͣ�˷��껯�����ʣ�' num2str(resultY(resultTable.tradeLimitLeft)) '%'],'FontSize',10);
    plot(x,Result(:,resultTable.zsRate),'g');
%    plot(x,Result(:,resultTable.tlRate) + Result(:,resultTable.zsRate),'b');
%     plot(x,Result(:,resultTable.zjRateLeft)+1,'k');
%     plot(x,Result(:,resultTable.zjRatePlus)+1,'y');
%     plot(x,Result(:,resultTable.yjRateLeft)+1,'c');
%     plot(x,Result(:,resultTable.tradeLimitLeft)+1,'m');
%     plot(x,Result(:,resultTable.holdingValue)/(manager.initAsset*manager.handleRate),'Color',[0.6 0.2 0.4]);
%     legend('������ֵ', '����300', '�ʽ��ܾ�ֵ', '�ۼ�����ʣ��ռ�', '�����ۼ۶�������', '�����ۼ���ۼ���','�ǵ�ͣʣ��������','�ֲ־�ֵ����', -1);
    legend('������ֵ', '����300', -1);

    configFile = configFile(1:end-4); % ȥ����չ��
    saveDir = ['..\result\��ʱ����ģ��' configFile '_' num2str(slipRatio) '������_�ֱֲ�' num2str(handleRate(1)) '-' num2str(handleRate(2))];
    if exist(saveDir,'dir') == 0
        mkdir(saveDir);
    end
    figurePath = [saveDir '\' fTitle '_' num2str(year) '.bmp'];
    saveas( gcf, figurePath );
    save_path = [saveDir '\' num2str(year) 'Result'];
    sheet = 1;   
    xlswrite( save_path, resultTable.listHeader, sheet);   % ȷ���ļ����в������ַ�'.'
    startE = 'A2';
    xlswrite( save_path, Result, sheet, startE);
    %csvwrite([saveDir '\' num2str(year) 'Result.csv'], Result );
    
    csvwrite([saveDir '\' num2str(year) '�������.csv'], squeeze(resDetial( rDetialTable.ZYRate,:,:)) );
    csvwrite([saveDir '\' num2str(year) '�ۼ���.csv'], squeeze(resDetial( rDetialTable.ZjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�����.csv'], squeeze(resDetial( rDetialTable.YjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ۼ�������.csv'], squeeze(resDetial( rDetialTable.ZjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ۼۿ�����.csv'], squeeze(resDetial( rDetialTable.ZjKsRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '���������.csv'], squeeze(resDetial( rDetialTable.YjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ֲ�ϲ��������.csv'], squeeze(resDetial( rDetialTable.FHRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ֲ������.csv'], squeeze(resDetial( rDetialTable.FcRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ϲ��ۼ���.csv'], squeeze(resDetial( rDetialTable.HbRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '�ǵ�ͣʱԤ��������.csv'], squeeze(resDetial( rDetialTable.TradeLimit,:,:)));

end
