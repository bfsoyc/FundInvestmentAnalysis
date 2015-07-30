%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �ú���������ֵ���������ֲ�
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
    root = '..\result';
    filterD = [2015 01 06; 2015 12 31]; %���ÿ�ʼ�������������
    begD = getIntDay(filterD(1, :));
    endD = getIntDay(filterD(2, :));
    % ���ñ���Ŀ¼
    root_dir = [root '\Ԥ����ֵ�ֲ�'];
    if exist(root_dir,'dir') == 0
        disp(['mkdir ' root_dir]);
        mkdir(root_dir);
    end

    init2();
    global statList fjDailyTable;

%% ����
    % �������ļ�(�洢��Ҫ�����Ļ�����Ϣ)
    T = readcsv2('\config.csv', 12);   
    num = size(T{:,1});

    mi = 1;%ĸ��������к�
    ii = 3;%ָ�������к�
    mcs = T{mi};
    ics = T{ii};

    for index = 2:num
        muCode = mcs{index};
        zsName = ics{index};
        fjAName = T{statList.fjAName}{index};      %�ӻ���A�����������SZ��ͷ
        fjBName = T{statList.fjBName}{index};
        disp([num2str(index) ]);
        try
            %��ȡĸ������ּ�����A��B���Լ���Ӧָ����������ݣ�ÿ�վ�ֵ���Ƿ��ȵ�
            mValues = csvread(['G:\datastore\ĸ����1\' muCode '.csv']);
            fjAData = csvread(['G:\datastore\����1\' fjAName '.csv']);
            fjBData = csvread(['G:\datastore\����1\' fjBName '.csv']);
            aShare = str2double(cell2mat( T{statList.aShare}(index) ))/10;   
            bShare = str2double(cell2mat( T{statList.bShare}(index) ))/10;   
            applyFee = str2double(cell2mat( T{statList.applyFee}(index) ));     
            redeemFee = str2double(cell2mat( T{statList.redeemFee}(index) ));  
            YjThresholds = applyFee + 0.002;
            ZjThresholds = -redeemFee -0.002;
        catch ME
            disp([ME.message ' ' muCode]);
            continue ;
        end   

        mValueRange = mValues(mValues(:,1)>=begD & mValues(:,1)<endD & mValues(:,2)>0,:);

        iChanges = csvread(['G:\datastore\����1\' zsName '.csv']);
        iChangeRange = iChanges(iChanges(:,1)>=begD & iChanges(:,1)<endD,:);

        mNum = size(mValueRange,1);
        resTable = zeros( mNum, 5);
        resTable(:,1) = mValueRange(:,1);   %����������

        if mNum == 0
            continue;
        end

        lastValue = mValueRange(1, 2);
        for i = 2:mNum
            day = mValueRange(i, 1);
            value = mValueRange(i, 2);

            fjAIdx = find( fjAData(:,fjDailyTable.date)==day);
            fjBIdx = find( fjBData(:,fjDailyTable.date)==day);
            iIndex = find(iChangeRange(:,1)==day);

            if ( isempty(fjAIdx) || isempty(fjBIdx) || isempty(iIndex) )
                continue;
            end

            if (value-lastValue)/lastValue>0.4      %����
                disp([muCode ' ���� ' num2str(value)]);
            elseif (value-lastValue)/lastValue<-0.4   %����
                disp([muCode ' ���� ' num2str(value)]);
            else


                change = iChangeRange(iIndex, 3);

                calValue = getPreValue(lastValue, change);
                disRate = (fjAData(fjAIdx,fjDailyTable.closingPrice)*aShare+fjBData(fjBIdx,fjDailyTable.closingPrice)*bShare - calValue)/calValue;

                if( disRate < 0 )   % ˵�����ۼ�
                    resTable(i,4) = 1;  
                    if( disRate < ZjThresholds )    % ˵��������ֵ
                        resTable(i,5) = 1;
                    end
                else                % ˵��ֻ���
                    if( disRate > YjThresholds )
                        resTable(i,5) = 1;
                    end
                end

                resTable(i,3) = disRate;
                resTable(i,2) = (calValue-value)/value;
            end

            lastValue = value;
        end
        resTable( resTable(:,2)== 0,: ) = [];
        
        % ��ȫ�����ڵ����ֲ� 
            figure1=figure();
            set(gcf,'outerposition',get(0,'screensize'));
            
            zjEps = resTable( resTable(:,4)==1,:);
            yjEps = resTable( resTable(:,4)==0,:);
            totalEps = [zjEps;yjEps];

            xMin = min(totalEps(:,3));
            xMax = max(totalEps(:,3));
            x = xMin:(xMax-xMin)/100:xMax;
            if length(x) < 1    % ��Ȼû��������˵û������
                continue;
            end          
            % �������ܶȷֲ�
            f1 = ksdensity(totalEps(:,3), x);   % �ܵ�            
            f2 = ksdensity(zjEps(:,3), x);      % �ۼ۵�
            f3 = ksdensity(yjEps(:,3), x);      % ��۵�
            
            subplot(1,2,1);
            fTitle = {[muCode '-' list2str(filterD(1,:))  list2str(filterD(2,:))];['ȫ���ڷ�Χ�����ʷֲ�']};
            title(fTitle);
            hold on;
            plot(x,f1);      
            plot(x,f2,'r');
            plot(x,f3,'g');
            legend('ȫ�����ڷ�Χ', '�ۼ����ڷ�Χ', '������ڷ�Χ');
            % ��ӡ������ͼ
            Mean = mean(totalEps(:,3));
            Variance1 = var(totalEps(:,3));
            Standard1 = std(totalEps(:,3));
            YRange = get(gca,'Ylim'); %y�᷶Χ
            maxY = YRange(2);
            text(Mean, maxY * 0.96, ['\fontsize{8}\color{blue}Sample = ' num2str(size(totalEps,1))]);
            text(Mean, maxY * 0.88, ['\fontsize{8}\color{blue}Mean = ' num2str(Mean)]);
            text(Mean, maxY * 0.80, ['\fontsize{8}\color{blue}Variance = ' num2str(Variance1)]);
            text(Mean, maxY * 0.72, ['\fontsize{8}\color{blue}Standard = ' num2str(Standard1)]);
            Mean2 = mean(zjEps(:,3));
            Variance2 = var(zjEps(:,3));
            Standard2 = std(zjEps(:,3));
            %maxY = max(f2);
            text(Mean2, maxY * 0.64, ['\fontsize{8}\color{red}Sample = ' num2str((size(zjEps,1)))]);
            text(Mean2, maxY * 0.56, ['\fontsize{8}\color{red}Mean = ' num2str(Mean2)]);
            text(Mean2, maxY * 0.48, ['\fontsize{8}\color{red}Variance = ' num2str(Variance2)]);
            text(Mean2, maxY * 0.40, ['\fontsize{8}\color{red}Standard = ' num2str(Standard2)]);  
            Mean3 = mean(yjEps(:,3));
            Variance3 = var(yjEps(:,3));
            Standard3 = std(yjEps(:,3));
            %maxY = max(f2);
            text(Mean3, maxY * 0.32, ['\fontsize{8}\color{green}Sample = ' num2str((size(yjEps,1)))]);
            text(Mean3, maxY * 0.24, ['\fontsize{8}\color{green}Mean = ' num2str(Mean3)]);
            text(Mean3, maxY * 0.16, ['\fontsize{8}\color{green}Variance = ' num2str(Variance3)]);
            text(Mean3, maxY * 0.08, ['\fontsize{8}\color{green}Standard = ' num2str(Standard3)]);  
            
        % ������������ڵ����ֲ�
            zyEpsThr = resTable( resTable(:,5)==1,:);
            zjEpsThr = zyEpsThr( zyEpsThr(:,4)==1,:);
            yjEpsThr = zyEpsThr( zyEpsThr(:,4)==0,:);
            
            xMin = min(zyEpsThr(:,3));
            xMax = max(zyEpsThr(:,3));
            x = xMin:(xMax-xMin)/100:xMax;
            if length(x) < 1    % ��Ȼû��������˵û������
                continue;
            end          
            % �������ܶȷֲ�
            f1 = ksdensity(zyEpsThr(:,3), x);   % �ܵ�            
            f2 = ksdensity(zjEpsThr(:,3), x);      % �ۼ۵�
            f3 = ksdensity(yjEpsThr(:,3), x);      % ��۵�
            
            subplot(1,2,2);
            fTitle = {[muCode '-' list2str(filterD(1,:))  list2str(filterD(2,:))];['Ԥ����ӯ�������ڷ�Χ�����ʷֲ�']};
            title(fTitle);
            hold on;
            plot(x,f1);      
            plot(x,f2,'r');
            plot(x,f3,'g');
            legend('ȫ�����ڷ�Χ', '�ۼ����ڷ�Χ', '������ڷ�Χ');
            % ��ӡ������ͼ
            Mean = mean(zyEpsThr(:,3));
            Variance1 = var(zyEpsThr(:,3));
            Standard1 = std(zyEpsThr(:,3));
            YRange = get(gca,'Ylim'); %y�᷶Χ
            maxY = YRange(2);
            text(Mean, maxY * 0.96, ['\fontsize{8}\color{blue}Sample = ' num2str(size(zyEpsThr,1))]);
            text(Mean, maxY * 0.88, ['\fontsize{8}\color{blue}Mean = ' num2str(Mean)]);
            text(Mean, maxY * 0.80, ['\fontsize{8}\color{blue}Variance = ' num2str(Variance1)]);
            text(Mean, maxY * 0.72, ['\fontsize{8}\color{blue}Standard = ' num2str(Standard1)]);
            Mean2 = mean(zjEpsThr(:,3));
            Variance2 = var(zjEpsThr(:,3));
            Standard2 = std(zjEpsThr(:,3));
            %maxY = max(f2);
            text(Mean2, maxY * 0.64, ['\fontsize{8}\color{red}Sample = ' num2str((size(zjEpsThr,1)))]);
            text(Mean2, maxY * 0.56, ['\fontsize{8}\color{red}Mean = ' num2str(Mean2)]);
            text(Mean2, maxY * 0.48, ['\fontsize{8}\color{red}Variance = ' num2str(Variance2)]);
            text(Mean2, maxY * 0.40, ['\fontsize{8}\color{red}Standard = ' num2str(Standard2)]);  
            Mean3 = mean(yjEpsThr(:,3));
            Variance3 = var(yjEpsThr(:,3));
            Standard3 = std(yjEpsThr(:,3));
            %maxY = max(f2);
            text(Mean3, maxY * 0.32, ['\fontsize{8}\color{green}Sample = ' num2str((size(yjEpsThr,1)))]);
            text(Mean3, maxY * 0.24, ['\fontsize{8}\color{green}Mean = ' num2str(Mean3)]);
            text(Mean3, maxY * 0.16, ['\fontsize{8}\color{green}Variance = ' num2str(Variance3)]);
            text(Mean3, maxY * 0.08, ['\fontsize{8}\color{green}Standard = ' num2str(Standard3)]);   
            
            
            figurePath = [root_dir '\' fTitle{1} '.bmp'];
            
            saveas( gcf, figurePath );
            close(figure1);

        % save resTable
        save_dir = [ '..\result\estimateResult\'];
        mkdir( save_dir );
        save_path = [save_dir fTitle{1} '.csv'];

        csvwrite( save_path, resTable );
    end

end
