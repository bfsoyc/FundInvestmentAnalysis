function analyzeTickError()
%% ��ӹ���Ŀ¼
    Files = dir(fullfile( '..\','*.*'));
    for i = 1:length(Files)
        if( Files(i).isdir )
            addpath( ['..\' Files(i).name ])
        end
    end
    
%% ��������
    root = 'G:\datastore';
    begY = 2012;
    endY = 2012; 
    filterT = [14 54 00; 14 57 00];
    begT = getDoubleTime(filterT(1, :));
    endT = getDoubleTime(filterT(2, :));
    filterIndex = 8; % �ɽ�������

    %�ּ�A�ɽ���������200W, �ּ�B�ɽ���������1000W
    config = {1,'ĸ����ֲ�',0; 3,'�Ƿ�����ֲ�',0; 5,'�ּ�A����ֲ�',2000000; 7,'�ּ�B����ֲ�',10000000}

    for index = 2:4
        S = getStockIds('\config.csv', 12, config{index, 1});
        dirName = config{index, 2};
        filterAmount = config{index, 3};
        save_path = [root '\' num2str(begY) '-' num2str(endY) '\figure\' dirName '_' num2str(filterT(1, 1)) '.' num2str(filterT(1, 2)) '-' num2str(filterT(2, 1)) '.' num2str(filterT(2, 2))];
        if exist(save_path,'dir') == 0
            disp(['mkdir ' save_path]);
            mkdir(save_path);
        end

        results = cell(1, 7);
        row = 0;
        num = size(S, 1);
        for i = 1:num
            stockId = S(i, 1);
            stock = char(stockId);
            [actualBeg actualEnd Sample Mean Variance Standard] = calAverage(root, save_path, stock, begY, endY, begT, endT, filterAmount, filterIndex, 2, 0);

            if Sample == 0
                disp([stock ' has nothing valid']);
                continue;
            end

            row = row + 1;
            results{row, 1} = stock;
            results{row, 2} = actualBeg;
            results{row, 3} = actualEnd;
            results{row, 4} = Sample;
            results{row, 5} = Mean;
            results{row, 6} = Variance;
            results{row, 7} = Standard;
        end
        if row == 0
            return;
        end
        filename = [save_path '\result.xls'];
        xlswrite(filename, results);

        means = xlsread(filename);
        analyzeMean(means(:, 2), save_path);
    end
end
