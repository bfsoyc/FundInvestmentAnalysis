%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ģ��ʵ�ʽ���
% �����ǣ�ÿ��Ʒ����ĳ��ʱ�̿�����������£����ֲ���ȫ�����������룬�嵵�ҵ�����
% �����Զ�������
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ��ӹ���Ŀ¼
Files = dir(fullfile( '..\','*.*'));
for i = 1:length(Files)
    if( Files(i).isdir )
        addpath( ['..\' Files(i).name ])
    end
end
    
%% ��������
bgtyear = 2015;
edtyear = 2015;
init();
global resultTable fjDailyTable rateTable tickTable muDailyTable idxDailyTable rDetialTable statList;

% �����ʱ�����õ�
filterT = [14 54 00; 14 57 00];
begT = getDoubleTime(filterT(1, :));    % ʵ�̲�����ʼʱ��
endT = getDoubleTime(filterT(2, :));

initMoney = 1e6;
handleRate = [2 4];%2/3��2/4�ֲ�
zjType =2;     %�ۼ����� һ������������
slipRatio = 0;  %N�������ʣ�0ʱ�������ǻ���

save_root = '..\result';
data_root = 'G:\datastore';
configFile = '\config7_30.csv';
[selectFund,w] = getSelectionFund();
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
        temp.muData = csvread(['G:\datastore\ĸ����1\' muName,'.csv']);
        temp.fjAData = csvread(['G:\datastore\����1\' fjAName  '.csv']);
        temp.fjBData = csvread(['G:\datastore\����1\' fjBName  '.csv']);
        temp.zsData = csvread(['G:\datastore\����1\' zsName  '.csv']);
        temp.name = muCode;  
        temp.fjAName = fjAName;
        temp.fjBName = fjBName;
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
        error('���ݲ�ȫ');
    end
    if exist([data_root '\ticks\' Src{k}.fjAName],'dir') == 0    %������ݿ����Ƿ��иû���ķ�ʱ����
        error('û��%s�ķ�ʱ����',Src{k}.fjAName);
    end
    if exist([data_root '\ticks\' Src{k}.fjBName],'dir') == 0    %������ݿ����Ƿ��иû���ķ�ʱ����
        error('û��%s�ķ�ʱ����',Src{k}.fjBName);
    end
end
% �����cell
emptyCell = cellfun( @isempty, Src ) ;
Src(emptyCell) = [];

%% ��ʼģ�⽻��
srclen = size(Src,2);
% �������
for year = bgtyear:edtyear
    bgt = getIntDay([year, 1, 1]);
    edt = getIntDay([year, 12, 31]);
    
    diary off;
    delete([save_root '\log.txt']);
    diary([save_root '\log.txt']); %��־   
    manager = AssetManagerQQQ(initMoney,handleRate(1)/handleRate(2));
    % �Ƚ���
    for i = 1:srclen              
        muData = Src{i}.muData(Src{i}.muData(:, muDailyTable.date) >= bgt & Src{i}.muData(:, muDailyTable.date) < edt, : );
        idx = 1;       
        while( ~muData(idx, muDailyTable.netValue ) )
            idx = idx + 1;
        end
        manager.addTypes(Src{i}.name,w(i), muData(idx, muDailyTable.netValue ) );
    end
    
    Result=zeros(1,resultTable.numOfEntries);  % Resultÿһ�м�¼��ÿһ�������յ���������ӯ��״���� �����ʼ����һ�С�
    
    resDetial = zeros( rDetialTable.numOfEntries,1,srclen+1 ); % resDetial( :, i, j) ��¼�˵�i�������յ�j������Ʒ�ֵ���Ϣ�������ʵȵȣ�������ṹ�� rDetialtable,�ɵ�һ������ָ����, ����Ԥ�ȷ����ڴ档

    ResultRowCnt = 2;                %Result �����м����� �ӵڶ��п�ʼ
    zsHsBgt = 0;
    zsHsClose = 0;
    
    
    
    %���ռ���
    for date = bgt+1:edt % ȷ��ȡ�����վ�ֵ
        resDetial(:,ResultRowCnt, rateTable.date ) = date;
        [Y, M, D] = getVectorDay( date );
        allTicks = [];
        for i = 1:srclen    % ��ÿ��Ʒ�ַּ�����tick����ɸѡ��β��3���ӵĽ��׵����ݲ�����������ʡ�
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
            % ���ñ�������           
            muData = Src{i}.muData( indexMu , : );          %����ĸ��������
            prev_muData = Src{i}.muData( indexMu-1 , : );    %ǰһ������                   
            zsData = Src{i}.zsData( indexZs, : ); 
            
            if muData(muDailyTable.netValue) == 0   % ������ĸ��������
                continue;
            end
            % ���ж��Ƿ���������           
            openPriceM = prev_muData(muDailyTable.netValue); % ǰһ��ľ�ֵ            
            closePriceM = muData(muDailyTable.netValue); % ����ľ�ֵ
            changeM = closePriceM/openPriceM - 1;           
            if  changeM > 0.12
                fprintf(['--(' num2str(date) ')���� ' num2str(Src{i}.name) ' ��������\n']);
                continue;
            elseif changeM < -0.12
                fprintf(['--(' num2str(date) ')���� ' num2str(Src{i}.name) ' ��������\n']);
                continue;
            end
            
            %����ʵ���ۼ���
            %Ԥ�⵱�վ�ֵ
            predictNetValue = prev_muData(muDailyTable.netValue)*(1+0.95*Src{i}.zsData(indexZs,3)/100);
            
            % ��A 
            fileDir = [data_root '\ticks\' Src{i}.fjAName];
            fileDir2 = [fileDir '\' Src{i}.fjAName '_' num2str(Y) '_' num2str(M)];     % ���붼��Ӧ���ڵ�Ŀ¼
            filename = [fileDir2 '\' Src{i}.fjAName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
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
            ticksDataA = ticks( StartIdx-1:EndIdx, : );     % ��Ҫһ��begT֮ǰ�Ľ������ݣ������������������������ݣ���begT����ֵĵ�һ�����������
            % ͬ���B
            fileDir = [data_root '\ticks\' Src{i}.fjBName];
            fileDir2 = [fileDir '\' Src{i}.fjBName '_' num2str(Y) '_' num2str(M)];     % ���붼��Ӧ���ڵ�Ŀ¼
            filename = [fileDir2 '\' Src{i}.fjBName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
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
            ticksDataB = ticks( StartIdx-1:EndIdx, : );     % ��Ҫһ��begT֮ǰ�Ľ������ݣ�ͬ�ϡ�
            
            tickNodes = extractTickNode( ticksDataA, ticksDataB, Src{i}.name, predictNetValue, manager.holdings(i),Src{i}.aShare, Src{i}.bShare, Src{i}.YjThresholds, Src{i}.ZjThresholds, date+begT );
            allTicks = [allTicks; tickNodes ];
        end
        if isempty(allTicks)    % ����û�п��������Ŀռ�
            continue;
        end
        [~, idx] = sort([allTicks.time]);   % �Ȱ�ʱ������
        allTicks = allTicks(idx);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        used = zeros(srclen,1);         % ����Ƿ�ʹ�ù�
        dailyRes = zeros(1, resultTable.numOfEntries);  % result Table ��һ��.
        numOfTicks = length( allTicks );
        startIdx = 1;
        while( startIdx <= numOfTicks )
            endIdx = startIdx+1;
            while( endIdx <= numOfTicks && allTicks(endIdx).time == allTicks(startIdx).time )
                endIdx = endIdx+1;
            end
            secNodes = allTicks( startIdx:endIdx-1 ); % ��ȡ��ÿһ�������еĿ�ӯ���Ľ��׷���            
            % �ȴ�����۵�. premium
            preNodes =  secNodes([secNodes.disRate] > 0);
            for j = 1:length(preNodes)
                node = preNodes(j);
                [isOk, pos] = manager.canDoYj(node.code);
                if used(pos)
                    continue;
                end          
                used(pos) = 1;
                % ����������
                indexMu = find( Src{pos}.muData(:,muDailyTable.date)==date);
                netvalue = Src{pos}.muData(indexMu,muDailyTable.netValue);      % ȡ������ĸ������ʵ��ֵ��
                cost = netvalue * manager.holdings(pos) * (1 + Src{pos}.applyFee);
                gain = ( node.fjAPrice*node.fjAVolume + node.fjBPrice*node.fjBVolume )*(1-Src{i}.stockFee-Src{i}.slipRate*slipRatio);
                profitRate = (gain-cost)/manager.initAsset;
                               
                % �����ۼ�ʱ ������ڲ�֣����ﻹ��Ҫ����
                if isOk == 2    % ����ǻ������������ģ�Ψһ���������������û���ӻ���A,B�ĳֲ֣�ǰһ��Ϊ���������ۼ۶���ϲ���ĸ����
                    if node.disRate > 0% ��ʵ��������ж��Ƕ������Ϊ��ۿ϶�����0��
                        manager.doSpl(node.code);    % �������£�����ĸ������Ҫ��֡�
                        resDetial( rDetialTable.FHRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                        resDetial( rDetialTable.FcRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                    end
                    if node.disRate > Src{pos}.YjThresholds    % ��������ж�Ҳ�Ƕ���ģ���Ϊǰ���Ǵ�����ֵ�ű���������  
                        dailyRes( resultTable.yjRateLeft ) = dailyRes( resultTable.yjRateLeft ) + profitRate;  % ������ֵ���������������������û���ӻ�������ܲ��������ʣ�������ۼӼӡ�                       
                    end
                elseif isOk == 1 % ���������������Ͳ��ж��� && item.rate > Src{item.pos}.YjThresholds  
                    manager.doYj(node.code, gain-cost);  %%����TODO����ʵʱ�����������ʲ�״̬�仯
                    dailyRes( resultTable.yjNum ) = dailyRes( resultTable.yjNum )+1;
                    dailyRes( resultTable.yjRate ) = dailyRes( resultTable.yjRate ) + profitRate;        % �������ۼ�
                    resDetial( rDetialTable.YjSyRate , ResultRowCnt, rateTable.date+pos) = profitRate;
                    % log
                    format = [ '--(%d,%2d)�깺ĸ���� %d(pred%.2f %.2f) \n' ...
                        '%12s�����ּ�A [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...
                        '%12s�����ּ�B [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...                    
                        '%12s���� %.2f, ӯ�� %.2f, ���� %.2f ���ֽ� %.2f\n' ];
                    fprintf(format, date, node.time, node.code, netvalue, node.netvalue, ...
                        '', node.fjAVolume, node.fjAPrice, ... 
                        '', node.fjBVolume, node.fjBPrice, ... 
                        '', cost, gain, gain-cost, manager.validMoney);
                end                
            end
            
            % �ٴ����ۼ۵�. discount
            disNodes =  secNodes([secNodes.disRate] < 0);
            [~,idx] = sort( [disNodes.disRate] );   % ���ۼ���(����ֵ)�Ӵ�С����.
            disNodes = disNodes( idx );
            for j = 1:length(disNodes)                
                node = disNodes(j);
                cost = ( node.fjAPrice*node.fjAVolume + node.fjBPrice*node.fjBVolume )*(1-Src{i}.stockFee-Src{i}.slipRate*slipRatio);   % ����
                [isOk, pos] = manager.canDoZj(node.code,cost);
                if used( pos )
                    continue;
                end
                % ����������
                indexMu = find( Src{pos}.muData(:,muDailyTable.date)==date);
                netvalue = Src{pos}.muData(indexMu,muDailyTable.netValue);      % ȡ������ĸ������ʵ��ֵ��
                gain = netvalue * manager.holdings(pos) * (1 + Src{pos}.applyFee);                
                profitRate = (gain-cost)/manager.initAsset;
                               
                if isOk == 2
                    dailyRes( resultTable.zjRatePlus ) = dailyRes( resultTable.zjRatePlus ) + profitRate;  % ָ�����ۼ۲��Ա�һ���ۼ۲��Զ�������棿
                end
                if isOk > 0    %�ж��Ƿ������zhe�۲��� 1����2
                    zjNum = isOk;   
                    % �����ۼ�
                    if zjType == 2
                        if isOk == 1 && node.disRate < -0.01   
                            zjNum = 2;
                            resDetial( rDetialTable.FHRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                            resDetial( rDetialTable.HbRate , ResultRowCnt, rateTable.date+pos) = node.disRate;
                        end
                    end
                    
                    used( pos ) = 1;
                    manager.doZj(Src{pos}.name, cost, gain, zjNum);  % zjNum == 2 ����ʾ������2���ۼۣ����Ǹ��ۼ۲�����T+1��ӵ��2���ֲ�
                    dailyRes( resultTable.zjNum ) = dailyRes( resultTable.zjNum )+1;
                    dailyRes( resultTable.zjRate ) = dailyRes( resultTable.zjRate ) + profitRate*isOk;
                    resDetial( rDetialTable.ZjSyRate , ResultRowCnt, rateTable.date+pos) = profitRate*isOk;
                     % log
                    format = [ '--(%d,%2d)���ĸ���� %d(pred%.2f %.2f) %d���ۼ����� \n' ...
                        '%12s����ּ�A [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...
                        '%12s����ּ�B [%d %d %d %d %d][%.2f %.2f %.2f %.2f %.2f] \n' ...                    
                        '%12s���� %.2f, ӯ��(����) %.2f, ���� %.2f ���ֽ� %.2f\n' ];
                    fprintf(format, date, node.time, node.code, node.netvalue, netvalue, isOk, ...
                        '', node.fjAVolume, node.fjAPrice, ... 
                        '', node.fjBVolume, node.fjBPrice, ... 
                        '', cost*isOk, gain*isOk, (gain-cost)*isOk, manager.validMoney);
                    
                elseif isOk < 0   % �ֽ𲻹����������ۼ�
                    dailyRes( resultTable.nomoneyNum ) = dailyRes( resultTable.nomoneyNum ) + 1;
                    dailyRes( resultTable.zjRateLeft ) = dailyRes( resultTable.zjRateLeft ) - profitRate*isOk;
                    resDetial( rDetialTable.ZjKsRate , ResultRowCnt, rateTable.date+pos) = -1;  %��ʾ�ֽ𲻹��������ۼۡ�
                else        % isOK == 0;ǰһ����ۣ����첻���ۼ�
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
        % dailyRes(resultTable.regVar) = dailyRes(resultTable.regVar)/assetManager2.typeNums;            %����ÿ���׼��
        
        Result(ResultRowCnt,:) = dailyRes;
        Result(ResultRowCnt,resultTable.cumVar ) = Result(ResultRowCnt-1,resultTable.cumVar )+Result(ResultRowCnt,resultTable.cumVar );       
        ResultRowCnt= ResultRowCnt+1;
        
        manager.updateState();      %ÿ�ս��׽�����ģ��֤ȯ��˾�����������ʲ�״̬       
    end
    manager.updateState();  % �������һ�춳����ʽ�
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
    text(xmin+10,ymax-inner*9.5,['�ǵ�ͣʣ���������ʣ�' num2str(result(resultTable.tradeLimitLeft)) '%    ����˷��껯�����ʣ�' num2str(resultY(resultTable.tradeLimitLeft)) '%'],'FontSize',10);
    plot(x,Result(:,resultTable.zsRate),'g');
    plot(x,Result(:,resultTable.tlRate) + Result(:,resultTable.zsRate),'b');
    plot(x,Result(:,resultTable.zjRateLeft)+1,'k');
    plot(x,Result(:,resultTable.zjRatePlus)+1,'y');
    plot(x,Result(:,resultTable.yjRateLeft)+1,'c');
    plot(x,Result(:,resultTable.tradeLimitLeft)+1,'m');
    legend('������ֵ', '����300', '�ʽ��ܾ�ֵ', '�ۼ�����ʣ��ռ�', '�����ۼ۶�������', '�����ۼ���ۼ���','�ǵ�ͣʣ��������', -1);


    configFile = 'config';
    saveDir = ['..\result\�������\' configFile '_' num2str(slipRatio) '������_�ֱֲ�' num2str(handleRate(1)) '-' num2str(handleRate(2))];
    if exist(saveDir,'dir') == 0
        mkdir(saveDir);
    end
    figurePath = [saveDir '\' fTitle '_' num2str(year) '.bmp'];
    set(gcf,'outerposition',get(0,'screensize'));
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
