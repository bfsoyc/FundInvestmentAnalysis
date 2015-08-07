%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 给出基金代号，日期等，计算从begT 到endT 时间段内的数据均值
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ Mean ] = calTickAverage(root, date, stockId, begT, endT)
    global tickTable;
    Mean = 0;
    dir = [root '\ticks\' stockId];
    if exist(dir,'dir') == 0 
        disp([dir ' not found']);
        return;
    end

    [Y, M, D] = getVectorDay( date );
    dir2 = [dir '\' stockId '_' num2str(Y) '_' num2str(M)];
    filename = [dir2 '\' stockId '_' num2str(Y) '_' num2str(M) '_' num2str(D) '.csv'];
    try
        ticks = csvread(filename);
    catch e
        disp(e);
        return;
    end
 
    ticksRange = ticks(ticks(:,tickTable.time)>=date+begT & ticks(:,tickTable.time)<date+endT,:);
    if size(ticksRange, 1) == 0
        disp([num2str(Y) '.' num2str(M) '.' num2str(D) ' no valid range']);
        return;
    end
    Mean = mean(ticksRange(:, tickTable.increase));
end