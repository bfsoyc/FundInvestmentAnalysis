%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ģ��ʵ�ʽ���
% �����ǣ�ÿ��Ʒ����ĳ��ʱ�̿�����������£����ֲ���ȫ�����������룬�嵵�ҵ�����
% �����Զ�������ͬһ���ڣ����������ͬʱ�µ������������ۼ�����֮����Ҫ���5��
% ����β��ʱ���ȳ����ǵ�ͣ���ܽ��ף����ж�Ϊ���첻�ܽ���
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
    manager = TradeManager(initMoney,handleRate(1)/handleRate(2));
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
    for date = 42160:edt
    %for date = bgt+1:edt % ȷ��ȡ�����վ�ֵ
        resDetial(:,ResultRowCnt, rateTable.date ) = date;
        dailyRes = zeros(1, resultTable.numOfEntries);  % result Table ��һ��.
        [Y, M, D] = getVectorDay( date );
        allTicks = [];
        for i = 1:typeNum    % ��ÿ��Ʒ�ַּ�����tick����ɸѡ��β��3���ӵĽ��׵����ݲ�����������ʡ�  ˳��ͳ�ƽ������гֲֻ�����ܾ�ֵ
            indexMu = find( Src{i}.data.muData(:,muDailyTable.date)==date);   
            indexFjA = find( Src{i}.data.fjAData(:,fjDailyTable.date)==date);
            indexFjB = find( Src{i}.data.fjBData(:,fjDailyTable.date)==date);
            indexZs = find( Src{i}.data.zsData(:,idxDailyTable.date)==date);
            indexHs = find( zsHs300(:,idxDailyTable.date)==date);  
            
            if ~isempty(indexMu)        % ͳ�Ƴֲֻ�����ܾ�ֵ
                dailyRes( resultTable.holdingValue ) = dailyRes( resultTable.holdingValue ) +  Src{i}.data.muData( indexMu , muDailyTable.netValue ) * manager.holdings(i) * 2;
            end
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
            
            changeM = closePriceM/openPriceM - 1;           
            if  changeM > 0.12
                fprintf(['--(' num2str(date) ')���� ' num2str(manager.Info(i).name) ' ��������\n']);
                continue;
            elseif changeM < -0.12
                fprintf(['--(' num2str(date) ')���� ' num2str(manager.Info(i).name) ' ��������\n']);
                continue;
            end
            
            %����ʵ���ۼ���
            %Ԥ�⵱�վ�ֵ
            zsChange = Src{i}.data.zsData(indexZs,3)/100;
            predictNetValue = prev_muData(muDailyTable.netValue) * (1 + 0.95*zsChange);
            
            % ��A 
            fileDir = [data_root '\ticks\' manager.Info(i).fjAName];
            fileDir2 = [fileDir '\' manager.Info(i).fjAName '_' num2str(Y) '_' num2str(M)];     % ���붼��Ӧ���ڵ�Ŀ¼
            filename = [fileDir2 '\' manager.Info(i).fjAName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
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
            fileDir = [data_root '\ticks\' manager.Info(i).fjBName];
            fileDir2 = [fileDir '\' manager.Info(i).fjBName '_' num2str(Y) '_' num2str(M)];     % ���붼��Ӧ���ڵ�Ŀ¼
            filename = [fileDir2 '\' manager.Info(i).fjBName '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];  
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
            if date == 42024
                pp = 1;
            end
            tickNodes = extractTickNode( ticksDataA, ticksDataB, predictNetValue, manager, i, date+begT );
            allTicks = [allTicks; tickNodes ];
        end
        if isempty(allTicks)    % ����û�п��������Ŀռ�
            continue;
        end
        [~, idx] = sort([allTicks.time]);   % �Ȱ�ʱ������
        allTicks = allTicks(idx);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        used = zeros(typeNum,1);         % ����Ƿ�ʹ�ù�
        numOfTicks = length( allTicks );
        startIdx = 1;
        prevOpTime = -10;
        while( startIdx <= numOfTicks )
            endIdx = startIdx+1;
            while( endIdx <= numOfTicks && allTicks(endIdx).time == allTicks(startIdx).time )
                endIdx = endIdx+1;
            end
            secNodes = allTicks( startIdx:endIdx-1 ); % ��ȡ��ÿһ�������еĿ�ӯ���Ľ��׷���            
            % �ȴ�����۵�. premium
            preNodes =  secNodes([secNodes.rate] > 0);
            for j = 1:length(preNodes)
                node = preNodes(j);
                [isOk, pos] = manager.canDoYj(node.code);
                if used(pos)
                    continue;
                end          
                used(pos) = 1;
                % ����������
                indexMu = find( Src{pos}.data.muData(:,muDailyTable.date)==date);
                netvalue = Src{pos}.data.muData(indexMu,muDailyTable.netValue);      % ȡ������ĸ������ʵ��ֵ��
                applyFee = manager.Info(pos).applyFee;  % ����
                cost = netvalue * manager.holdings(pos) * (1 + applyFee);
                stockFee = manager.Info(i).stockFee;    
                slipRatio = manager.Info(i).slipRate*slipRatio; 
                gain = ( node.fjAPrice*node.fjAVolume + node.fjBPrice*node.fjBVolume )*(1 - stockFee - slipRatio);   % ���棬������Ҫ��
                profitRate = (gain-cost)/manager.initAsset;
                       
                resDetial( rDetialTable.YjRate , ResultRowCnt, rateTable.date+pos) = node.rate;
                if node.tradeLimitFlag == 1 % ������ǵ�ͣ
                    resDetial( rDetialTable.TradeLimit, ResultRowCnt, rateTable.date+i) = profitRate;  
                    dailyRes( resultTable.tradeLimitLeft ) = dailyRes( resultTable.tradeLimitLeft ) + profitRate;
                    fprintf('--(%d,%2d)ĸ���� %d ��Ӧ�ķּ���������ǵ�ͣ\n', date, node.time, node.code ); 
                    continue;
                end               
                % �����ۼ�ʱ ������ڲ��
                YjThresolds = manager.Info(pos).YjThresholds;
                if isOk == 2    % ����ǻ������������ģ�Ψһ���������������û���ӻ���A,B�ĳֲ֣�ǰһ��Ϊ���������ۼ۶���ϲ���ĸ����
                    if node.rate > 0% ��ʵ��������ж��Ƕ������Ϊ��ۿ϶�����0��
                        manager.doSpl(node.code);    % �������£�����ĸ������Ҫ��֡�
                        resDetial( rDetialTable.FHRate , ResultRowCnt, rateTable.date+pos) = node.rate;
                        resDetial( rDetialTable.FcRate , ResultRowCnt, rateTable.date+pos) = node.rate;
                    end
                    if node.rate > YjThresolds    
                        dailyRes( resultTable.yjRateLeft ) = dailyRes( resultTable.yjRateLeft ) + profitRate;  % ������ֵ���������������������û���ӻ�������ܲ��������ʣ�������ۼӼӡ�                       
                    end
                elseif isOk == 1 && node.rate > YjThresolds %  
                    manager.doYj(node.code, gain-cost);  %%����TODO����ʵʱ�����������ʲ�״̬�仯
                    dailyRes( resultTable.yjNum ) = dailyRes( resultTable.yjNum )+1;
                    dailyRes( resultTable.yjRate ) = dailyRes( resultTable.yjRate ) + profitRate;        % �������ۼ�
                    resDetial( rDetialTable.YjSyRate , ResultRowCnt, rateTable.date+pos) = profitRate;
                    % log
                    format = [ '--(%d,%2d)�깺ĸ���� %d(%.3f pred:%.3f) \n' ...
                        '%12s�����ּ�A [%d %d %d %d %d][%.3f %.3f %.3f %.3f %.3f] \n' ...
                        '%12s�����ּ�B [%d %d %d %d %d][%.3f %.3f %.3f %.3f %.3f] \n' ...                    
                        '%12s���� %.2f, ӯ�� %.2f, ���� %.2f ���ֽ� %.2f\n' ];
                    fprintf(format, date, node.time, node.code, netvalue, node.netvalue, ...
                        '', node.fjAVolume, node.fjAPrice, ... 
                        '', node.fjBVolume, node.fjBPrice, ... 
                        '', cost, gain, gain-cost, manager.validMoney);
                else
                    used(pos) = 0;  % û���κβ�����������0��֤��Ӱ���Ʒ�ֵ������ʱ�̵Ĳ���  ������ isOk == 1 && node.rate <= Yjtheresolds
                end                
            end
            
            if date == 42024
                pp = 1;
            end
            
            % �ٴ����ۼ۵�. discount ( ���⴦����һ�������ۼ�Ҫ5s��������ڶ��� )
            disNodes =  secNodes([secNodes.rate] < 0);
            
            [~,idx] = sort( [disNodes.margin] );   % ���ۼ���(����ֵ)�Ӵ�С����.
            disNodes = disNodes( idx );
            
            for j = 1:length(disNodes)                
                node = disNodes(j);
                if node.time < prevOpTime + 5    % ������һ���ۼ۲�������5��
                    break;
                end
                stockFee = manager.Info(i).stockFee;    % ����
                slipRatio = manager.Info(i).slipRate*slipRatio; % ����
                cost = ( node.fjAPrice*node.fjAVolume + node.fjBPrice*node.fjBVolume )*(1 + stockFee + slipRatio );   % ����,������Ҫ��
                [isOk, pos] = manager.canDoZj(node.code,cost);
                if used( pos )
                    continue;
                end
                used( pos ) = 1;
                % ����������
                indexMu = find( Src{pos}.data.muData(:,muDailyTable.date)==date);
                netvalue = Src{pos}.data.muData(indexMu,muDailyTable.netValue);      % ȡ������ĸ������ʵ��ֵ��
                redeemFee = manager.Info(pos).redeemFee;
                gain = netvalue * manager.holdings(pos) * (1 - redeemFee);                
                profitRate = (gain-cost)/manager.initAsset;
                                   
                if node.tradeLimitFlag == 1 % ������ǵ�ͣ
                    resDetial( rDetialTable.TradeLimit, ResultRowCnt, rateTable.date+i) = profitRate;  
                    dailyRes( resultTable.tradeLimitLeft ) = dailyRes( resultTable.tradeLimitLeft ) + profitRate;
                    fprintf('--(%d,%2d)ĸ���� %d ��Ӧ�ķּ���������ǵ�ͣ\n', date, node.time, node.code ); 
                    continue;
                end     
                if isOk == 2
                    dailyRes( resultTable.zjRatePlus ) = dailyRes( resultTable.zjRatePlus ) + profitRate;  % ָ�����ۼ۲��Ա�һ���ۼ۲��Զ�������棿
                end
                if isOk > 0    %�ж��Ƿ������zhe�۲��� 1����2                    
                    zjNum = isOk;   
                    % �����ۼ�
                    if zjType == 2
                        if isOk == 1 && node.rate < -0.01   
                            zjNum = 2;
                            resDetial( rDetialTable.FHRate , ResultRowCnt, rateTable.date+pos) = node.rate;
                            resDetial( rDetialTable.HbRate , ResultRowCnt, rateTable.date+pos) = node.rate;
                            % log
                            fprintf('--ĸ���� %d �ϲ�\n', node.code ); 
                        end
                    end
                    
                    used( pos ) = 1;
                    manager.doZj(node.code, cost, gain, zjNum);  % zjNum == 2 ����ʾ������2���ۼۣ����Ǹ��ۼ۲�����T+1��ӵ��2���ֲ�
                    dailyRes( resultTable.zjNum ) = dailyRes( resultTable.zjNum )+1;
                    dailyRes( resultTable.zjRate ) = dailyRes( resultTable.zjRate ) + profitRate*isOk;
                    resDetial( rDetialTable.ZjRate , ResultRowCnt, rateTable.date+pos) = node.rate;
                    resDetial( rDetialTable.ZjSyRate , ResultRowCnt, rateTable.date+pos) = profitRate*isOk;
                     % log
                    format = [ '--(%d,%2d)���ĸ���� %d(%.3f pred:%.3f) %d���ۼ����� \n' ...
                        '%12s����ּ�A [%d %d %d %d %d][%.3f %.3f %.3f %.3f %.3f] \n' ...
                        '%12s����ּ�B [%d %d %d %d %d][%.3f %.3f %.3f %.3f %.3f] \n' ...                    
                        '%12s���� %.2f, ӯ��(����) %.2f, ���� %.2f ���ֽ� %.2f\n' ];
                    fprintf(format, date, node.time, node.code, netvalue, node.netvalue, isOk, ...
                        '', node.fjAVolume, node.fjAPrice, ... 
                        '', node.fjBVolume, node.fjBPrice, ... 
                        '', cost*isOk, gain*isOk, (gain-cost)*isOk, manager.validMoney);
                    prevOpTime = node.time;     % �������һ�����ۼ۵�ʱ��
                    break;  % һs��ֻ����һ���ۼ�
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
        dailyRes(resultTable.validMoney) = manager.validMoney;
        
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
