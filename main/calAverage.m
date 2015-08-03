function [actualBeg actualEnd Sample Mean Variance Standard] = calAverage(root, dstDir, stockId, begY, endY, begT, endT, filterAmount, filterIndex, xIndex, aIndex)
    actualBeg = '0';
    actualEnd = '0';
    Sample = 0;
    Mean = 0;
    Variance = 0;
    Standard = 0;

    begM = 1;
    endM = 12;
    begD = 1;
    endD = 31;
    result = zeros(1,3);
    row = 0;
    dir = [root '\ticks\' stockId];
    if exist(dir,'dir') == 0 
        disp([dir ' not found']);
        return;
    end
    for year = begY:endY
        for month = begM:endM
            dir2 = [dir '\' stockId '_' num2str(year) '_' num2str(month)];
            for day = begD:endD
                filename = [dir2 '\' stockId '_' num2str(year) '_' num2str(month) '_' num2str(day) '.csv'];
                if exist(filename,'file') == 0
                    continue;
                end
                try
                    ticks = csvread(filename);
                catch e
                    disp(e);
                    continue;
                end
                d = floor(ticks(1, 1));
                ticksRange = ticks(ticks(:,1)>=d+begT & ticks(:,1)<d+endT,:);
                if size(ticksRange, 1) == 0
                    disp([num2str(year) '.' num2str(month) '.' num2str(day) ' no valid range']);
                    continue;
                end

                if actualBeg == '0'
                    actualBeg = [num2str(year) '.' num2str(month) '.' num2str(day)];
                end
                actualEnd = [num2str(year) '.' num2str(month) '.' num2str(day)];

                ave = mean(ticksRange, 1);
                if size(ave) < 2
                    disp([stockId actualEnd]);
                    continue;
                end
                row = row + 1;
                result(row, 1) = d;
                result(row, 2) = ave(1, xIndex);
                result(row, 3) = ave(1, xIndex + 1);
            end
        end
    end
    if row < 10
        disp([stockId ' has no enough(>=10) data']);
        return;
    end
    filename = [dstDir '\' stockId '_average.csv'];
    dlmwrite(filename, result, 'precision', 8, 'delimiter', ',');

    analyzeResult = zeros(1, 3);
    src = csvread([dir '\' stockId '.csv']);

    aRow = 0;
    for i = 1:row
        t = result(i, 1);
        j = find(src(:,1) == t);
        if (isempty(j))
            disp([t 'can not found']);
            continue;
        end
        if src(j, filterIndex) < filterAmount
            continue;
        end
        aRow = aRow + 1;
        analyzeResult(aRow, 1) = t;
        analyzeResult(aRow, 2) = src(j, filterIndex); 
        analyzeResult(aRow, 3) = src(j, 3) - result(i, 3);
    end
    if aRow < 10
        disp([stockId ' has no enough(>=10) data']);
        return;
    end
    filename = [dstDir '\' stockId '_std.csv'];
    dlmwrite(filename, analyzeResult, 'precision', 8, 'delimiter', ',');

    tagRestul = analyzeResult(:,3);
    Sample = aRow;
    Mean = mean(tagRestul);
    Variance = var(tagRestul,1);
    Standard = std(tagRestul);

    xMin = min(tagRestul);
    xMax = max(tagRestul);
    x = xMin:(xMax-xMin)/100:xMax;
    f = ksdensity(tagRestul, x);  %画概率密度分布

    figure1=figure();
    plot(x,f);
    fTitle = [stockId '-' actualBeg '-' actualEnd];
    title(fTitle);

    maxY = max(f);
    text(Mean, maxY * 0.7, ['Sample = ' num2str(Sample)]);
    text(Mean, maxY * 0.6, ['Mean = ' num2str(Mean)]);
    text(Mean, maxY * 0.5, ['Variance = ' num2str(Variance)]);
    text(Mean, maxY * 0.4, ['Standard = ' num2str(Standard)]);
    figurePath = [dstDir '\' fTitle '.jpeg'];
    print(figure1,'-djpeg', figurePath); 
    close(figure1);

    disp(['save ' figurePath]);
end