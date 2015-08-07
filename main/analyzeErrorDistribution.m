%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �ú���������ֵ����(���ڹ�������ĸ����ֵ)�����ֲ�,�ּ������ָ�����Ƿ���
% β�̾�ֵ���ơ�
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyzeErrorDistribution()
%% ��ӹ���Ŀ¼
    Files = dir(fullfile( '..\','*.*'));
    for i = 1:length(Files)
        if( Files(i).isdir )
            addpath( ['..\' Files(i).name ])
        end
    end

%% ��������
    save_root = '..\result';
    data_root = 'G:\datastore';
    configFile = '\config��������.csv'; %�������Ը���
    year = 2015;    % ����ͳ�Ʋ�������;
    filterD = [year 01 06; year 12 31]; %���ÿ�ʼ�������������
    begD = getIntDay(filterD(1, :));
    endD = getIntDay(filterD(2, :));
    
    % �����ʱ���ݲ��õ�
    filterT = [14 54 00; 14 57 00];
    begT = getDoubleTime(filterT(1, :));    % ʵ�̿�ʼʱ��
    endT = getDoubleTime(filterT(2, :));
    % ���ñ���Ŀ¼
    save_dir = [ save_root '\estimateResult' configFile(1:end-4) '\' num2str(year)];
    if ~exist(save_dir,'dir')
        mkdir( save_dir );
    end
    init();
    global muDailyTable idxDailyTable resultTable statList fjDailyTable estimate meanTHeader;
    
    configT = {1,'ĸ����ֲ�',0; 3,'�Ƿ�����ֲ�',0; 5,'�ּ�A����ֲ�',2000000; 7,'�ּ�B����ֲ�',10000000};
    IfilterAmount = configT{2,3};
    AfilterAmount = configT{3,3};
    BfilterAmount = configT{4,3};
    
    estiMode = 0;
    estiMode = bitor( estiMode, estimate.FundA_Mode );
    estiMode = bitor( estiMode, estimate.FundB_Mode );
    estiMode = bitor( estiMode, estimate.Index_Mode );
    estiMode = bitor( estiMode, estimate.Predict_Mode);
    
%% ����
    % �������ļ�(�洢��Ҫ�����Ļ�����Ϣ)
    config = readcsv2(configFile, 12);   
    tableLen = length(config{1});  

    meanTable = zeros(tableLen,meanTHeader.numOfEntries);   % ͳ��ÿ��Ʒ�־�ֵ��
    for k = 2:tableLen
        muName = config{statList.muName}{k};
        % �����ļ��л�����Ų��淶�����ܲ���������8λ��������Ҫ����ж�
        if( length(muName) < 8 )
            muName = ['OF' muName];
        end
        muCode = str2num(muName(3:end));
        meanTable(k,meanTHeader.muCode) = muCode;
               
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
        disp([num2str(k) ]);
        try
            %��ȡĸ������ּ�����A��B���Լ���Ӧָ����������ݣ�ÿ�վ�ֵ���Ƿ��ȵ�
            mValues = csvread([data_root '\ĸ����1\' muName '.csv']);
            fjAData = csvread([data_root '\����1\' fjAName '.csv']);
            fjBData = csvread([data_root '\����1\' fjBName '.csv']);         
            
            
            aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
            bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
            applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
            redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
            YjThresholds = applyFee + 0.002;
            ZjThresholds = -redeemFee -0.002;
        catch ME
            disp([ME.message ' ' muName]);
            continue ;
        end   

        mValueRange = mValues(mValues(:,muDailyTable.date)>=begD & mValues(:,muDailyTable.date)<endD & mValues(:,muDailyTable.netValue)>0,:);

        iChanges = csvread([data_root '\����1\' zsName '.csv']);
        iChangeRange = iChanges(iChanges(:,idxDailyTable.date)>=begD & iChanges(:,idxDailyTable.date)<endD,:);

        mNum = size(mValueRange,1);
        resTable = zeros( mNum, estimate.numOfEntries);
        resTable(:,resultTable.date) = mValueRange(:,muDailyTable.date);   %����������

        if mNum == 0
            continue;
        end

        lastValue = mValueRange(1, muDailyTable.netValue);
        for i = 2:mNum
            day = mValueRange(i, muDailyTable.date);
            value = mValueRange(i, muDailyTable.netValue);

            fjAIdx = find( fjAData(:,fjDailyTable.date)==day);
            fjBIdx = find( fjBData(:,fjDailyTable.date)==day);
            iIndex = find(iChangeRange(:,idxDailyTable.date)==day);

            if ( isempty(fjAIdx) || isempty(fjBIdx) || isempty(iIndex) || iIndex == 1)
                % ����Ƿ�ȱ����
                continue;
            end

            if (value-lastValue)/lastValue>0.1      %����
                disp([muName ' ���� ' num2str(value)]);
            elseif (value-lastValue)/lastValue<-0.1   %����
                disp([muName ' ���� ' num2str(value)]);
            else
                
                change = (iChangeRange(iIndex,2)-iChangeRange(iIndex-1,2))/iChangeRange(iIndex-1,2)*100;     %Ҫ����100
                calValue = getPreValue(lastValue, change);
                disRate = (fjAData(fjAIdx,fjDailyTable.closingPrice)*aShare+fjBData(fjBIdx,fjDailyTable.closingPrice)*bShare - calValue)/calValue;

                if( disRate < 0 )   % ˵�����ۼ�
                    resTable(i,estimate.zjFlag) = 1;  
                    if( disRate < ZjThresholds )    % ˵��������ֵ
                        resTable(i,estimate.thrFlag) = 1;
                    end
                else                % ˵��ֻ���
                    if( disRate > YjThresholds )
                        resTable(i,estimate.thrFlag) = 1;
                    end
                end
                
                
                if bitand( estiMode, estimate.Index_Mode )  % ָ���Ƿ�û����ֵ����
                    tickIncreaseMean = calTickAverage( data_root, day, zsName, begT,endT );
                    resTable(i,estimate.predIdxIncrease) = tickIncreaseMean;
                    realIncrease = change;  %����ǰ���Ѿ����,����chagne
                    resTable(i,estimate.IndexEps) = realIncrease - tickIncreaseMean;
                end
                if bitand( estiMode, estimate.FundA_Mode )
                    if( fjAData(fjAIdx, fjDailyTable.turnover) > AfilterAmount ) % ���콻�������������趨����ֵ�ż��㡣
                        tickIncreaseMean = calTickAverage( data_root, day, fjAName, begT,endT );
                        resTable(i,estimate.predAIncrease) = tickIncreaseMean;
                        realIncrease = fjAData(fjAIdx, fjDailyTable.increase);
                        resTable(i,estimate.FundAeps) = realIncrease - tickIncreaseMean;
                    end
                end
                if bitand( estiMode, estimate.FundB_Mode )
                    if( fjBData(fjBIdx, fjDailyTable.turnover) > BfilterAmount ) % ���콻�������������趨����ֵ�ż��㡣
                        tickIncreaseMean = calTickAverage( data_root, day, fjBName, begT,endT );
                        resTable(i,estimate.predBIncrease) = tickIncreaseMean;
                        realIncrease = fjBData(fjBIdx, fjDailyTable.increase);
                        resTable(i,estimate.FundBeps) = realIncrease - tickIncreaseMean;
                    end
                end
                
                resTable(i,estimate.predict) = calValue; 
                resTable(i,estimate.realNetValue) = value;
                resTable(i,estimate.eps) = calValue-value;
                resTable(i,estimate.disRate) = disRate;
                resTable(i,estimate.epsPercent) = (calValue-value)/value;
            end

            lastValue = value;
        end
        %resTable( resTable(:,estimate.epsPercent)== 0,: ) = [];
        
        if bitand( estiMode, estimate.Predict_Mode)     % Ԥ����ֵԤ��������
            % ��ȫ�����ڵ����ֲ� 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.epsPercent)~= 0,:); %�ӱ�ɸѡ��Ԥ����ֵ��Ϊ0�ģ������������ݵġ�
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, muName, estimate.Predict_Mode );
            if status == 0
                close(figure1);
                continue;
            end           
            % ������������ڵ����ֲ�
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, muName, estimate.Predict_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.muMean) = meanVec;
            subDir = [save_dir '\ĸ����Ԥ�⾻ֵ���ֲ�'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        
        if bitand( estiMode, estimate.Index_Mode)     % ָ���Ƿ�Ԥ��������
            % ��ȫ�����ڵ����ֲ� 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.predIdxIncrease)~= 0,:); %�ӱ�ɸѡ��Ԥ���Ƿ���Ϊ0�ģ������������ݵġ�
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, zsName, estimate.Index_Mode );
            if status == 0
                close(figure1);
                continue;
            end           
            % ������������ڵ����ֲ�
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, zsName, estimate.Index_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.indexMean) = meanVec;
            subDir = [save_dir '\ָ��Ԥ���Ƿ����ֲ�'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        
        if bitand( estiMode, estimate.FundA_Mode)     % ����A�Ƿ�Ԥ��������
            % ��ȫ�����ڵ����ֲ� 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.predAIncrease)~= 0,:); %�ӱ�ɸѡ��Ԥ���Ƿ���Ϊ0�ģ������������ݵġ�
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status, meanVec ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, fjAName, estimate.FundA_Mode );
            if status == 0
                close(figure1);
                continue;
            end            
            % ������������ڵ����ֲ�
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, fjAName, estimate.FundA_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.fundAMean) = meanVec;
            subDir = [save_dir '\�ּ�����AԤ���Ƿ����ֲ�'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        
        if bitand( estiMode, estimate.FundB_Mode)     % ����B�Ƿ�Ԥ��������
            % ��ȫ�����ڵ����ֲ� 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            subResTalbe = resTable( resTable(:,estimate.predBIncrease)~= 0,:); %�ӱ�ɸѡ��Ԥ���Ƿ���Ϊ0�ģ������������ݵġ�
            zjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==1,:);
            yjEps = subResTalbe( subResTalbe(:,estimate.zjFlag)==0,:);
            totalEps = [zjEps;yjEps];  
            subplot(1,2,1);
            [status ] = plotKsDensity( totalEps, zjEps, yjEps, filterD, fjBName, estimate.FundB_Mode );
            if status == 0
                close(figure1);
                continue;
            end                      
            % ������������ڵ����ֲ�
            zyEpsThr = subResTalbe( subResTalbe(:,estimate.thrFlag)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,estimate.zjFlag)==0,:);

            subplot(1,2,2);
            [status,meanVec, fTitle ] = plotKsDensity( zyEpsThr, zjEpsThr, yjEpsThr, filterD, fjBName, estimate.FundB_Mode );
            if status == 0
                close(figure1);
                continue;
            end
            meanTable(k,meanTHeader.fundBMean) = meanVec;
            subDir = [save_dir '\�ּ�����BԤ���Ƿ����ֲ�'];
            if ~exist(subDir,'dir')
                mkdir( subDir );
            end
            figurePath = [subDir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            hold off;
            close(figure1);
        end
        % save resTable
        fTitle = [muName '-' list2str(filterD(1,:))  list2str(filterD(2,:))];
        fTitle = strrep( fTitle,'.','-');
        
        save_path = [save_dir '\' fTitle ];
        sheet = 1;   
        xlswrite( save_path, estimate.listHeader, sheet);   % ������ȷ�������ļ����в������ַ�'.'
        startE = 'A2';
        xlswrite( save_path, resTable, sheet, startE);
        %csvwrite( save_path, resTable );
        
        
    end
    meanTable(1,:) = [];
    filename = [save_dir  '\' num2str(year) '�����ָ��Ԥ��ֵ����ֵͳ�Ʊ�' ];
    sheet = 1;   
    xlswrite( filename, meanTHeader.listHeader, sheet);
    startE = 'A2';
    xlswrite( filename, meanTable, sheet, startE);
    
end
