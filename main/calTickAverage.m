%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 给出基金代号，日期等，计算从begT 到endT 时间段内的数据均值
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ Mean ] = calTickAverage(root, date, stockId, begT, endT, xIndex)
    Mean = 0;
    result = zeros(1,3);
    dir = [root '\ticks\' stockId];
    if exist(dir,'dir') == 0 
        disp([dir ' not found']);
        return;
    end

    [Y, M, D] = getVectorDay( date );
    dir2 = [dir '\' stockId '_' num2str(Y) '_' num2str(M)];
    filename = [dir2 '\' stockId '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];
%     if exist(filename,'file') == 0
%        return;
%     end
    try
        ticks = csvread(filename);
    catch e
        disp(e);
        return;
    end
 
    ticksRange = ticks(ticks(:,1)>=date+begT & ticks(:,1)<date+endT,:);
    if size(ticksRange, 1) == 0
        disp([num2str(Y) '.' num2str(M) '.' num2str(D) ' no valid range']);
        return;
    end

    ave = mean(ticksRange, 1);
    if size(ave) < 2
        return;
    end

    result(1) = date;
    result(2) = ave(1, xIndex);
    result(3) = ave(1, xIndex + 1);
    
    Mean = result(3);

end