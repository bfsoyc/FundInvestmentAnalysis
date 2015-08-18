function tickNodes = extractTickNode(ticksDataA,ticksDataB, netvalue, manager, i, referenceTime )
   
    % 变量别名
    muCode = manager.Info(i).name;
    holding = manager.holdings(i);
    shareA = manager.Info(i).aShare;
    shareB = manager.Info(i).bShare;
    ZjThresholds = manager.Info(i).ZjThresholds;
    
    % 定义常量
    constSec = 1/24/60/60;
    global tickTable;
    fjAHolding = holding*shareA;      % 基金A持仓量
    fjBHolding = holding*shareB;
    
    timeListA = zeros(180,tickTable.maxEntry);  % 每一行代表尾盘3分钟内每一秒的行情.
    timeListB = zeros(180,tickTable.maxEntry);
    for i = 2:size(ticksDataA,1)    % 传入参数时知道第一个值是早于referenceTime的，用于初始化
        t = round( (ticksDataA(i,tickTable.time) - referenceTime)/constSec);
        timeListA( t+1,: ) = ticksDataA( i, 1:tickTable.maxEntry );
    end
    for i = 2:size(ticksDataB,1)
        t = round( (ticksDataB(i,tickTable.time) - referenceTime)/constSec);
        timeListB( t+1,: ) = ticksDataB( i, 1:tickTable.maxEntry );
    end   
    
    % 判断每一秒是否有套利空间
    tickNodes = [];
    curA =  ticksDataA(1,1:tickTable.maxEntry);    % 当前A的行情 
    curB =  ticksDataB(1,1:tickTable.maxEntry);
    for sec = 1:180
        if timeListA(sec,1)   % 这一秒分级A有交易记录，更新当前A的行情
            curA = timeListA(sec,:);  
        end
        if timeListB(sec,1)           
            curB = timeListB(sec,:);
        end
        % 判断是否可以做溢价
        node = TickNode;
        buyAVolume = curA( tickTable.buyVolume )';  % 向量默认为列向量
        buyBVolume = curB( tickTable.buyVolume )';
        buyAPrice = curA(tickTable.buyPrice);
        buyBPrice = curB(tickTable.buyPrice);
        if( sum( buyAVolume ) < fjAHolding || sum( buyBVolume ) < fjBHolding )  % 五档挂牌量不够
            if sum( buyAVolume ) == 0   % A没有买入挂牌，说明A跌停
                buyAVolume = tickTable.INFVolume;
                buyAPrice = curA(tickTable.salePrice); % 跌停时用卖一价来替代原来的买一价。
                if buyAPrice(1) == 0    % 这个数据都没有就没辙了
                    continue;
                end
            elseif sum( buyBVolume ) == 0 % 没有卖出挂牌，说明跌停
                buyBVolume = tickTable.INFVolume;
                buyBPrice = curB(tickTable.salePrice); % 跌停时用卖一价来替代原来的买一价。
                if buyBPrice(1) == 0    % 这个数据都没有就没辙了
                    continue;
                end
            else
                continue;
            end
            node.tradeLimitFlag = 1;
        end
        idx = 1;
        leftA = fjAHolding;     % leftA 是基金A仍需要购入的份数
        while( idx < 6 )
            buyAVolume(idx) = min(buyAVolume(idx), leftA);
            leftA = leftA -  buyAVolume(idx);
            idx = idx + 1;
        end
        idx = 1;
        leftB = fjBHolding;
        while( idx < 6 )
            buyBVolume(idx) = min(buyBVolume(idx), leftB);
            leftB = leftB -  buyBVolume(idx);
            idx = idx + 1;
        end
        buyA = buyAVolume/fjAHolding; % 归一化
        buyB = buyBVolume/fjBHolding;
        preRate = buyAPrice*buyA*shareA + buyBPrice*buyB*shareB - netvalue ;  % 等效折溢价率
        if preRate > 0 % 大于0而不是大于YjThresholds 是因为要确定拆分时机
            
            node.code = muCode;
            node.netvalue = netvalue;
            node.fjAPrice = buyAPrice;
            node.fjAVolume = buyAVolume;
            node.fjBPrice = buyBPrice;
            node.fjBVolume = buyBVolume;
            node.time = sec;
            node.rate = preRate;
            tickNodes = [tickNodes; node];
            continue;   % 可以做溢价就不可能做折价了,进入下一秒的判断
        end
        %profit = curA(tickTable.buyPrice)*buyAVolume + curB(tickTable.buyPrice)*buyBVolume - netvalue*holding ;
        
        % 判断是否可以做折价
        node = TickNode;
        saleAVolume = curA( tickTable.saleVolume )';  % 向量默认为列向量
        saleBVolume = curB( tickTable.saleVolume )';
        saleAPrice = curA(tickTable.salePrice);
        saleBPrice = curB(tickTable.salePrice);
        if( sum( saleAVolume ) < fjAHolding || sum( saleBVolume ) < fjBHolding )  % 五档挂牌量不够
            if sum( saleAVolume ) == 0   % A没有卖出挂牌，说明A涨停
                saleAVolume = tickTable.INFVolume;
                saleAPrice = curA(tickTable.buyPrice); % 跌停时用卖一价来替代原来的买一价。
                if saleAPrice(1) == 0    % 这个数据都没有就没辙了
                    continue;
                end
            elseif sum( saleBVolume ) == 0 % 没有卖出挂牌，说明跌停
                saleBVolume = tickTable.INFVolume;
                saleBPrice = curB(tickTable.buyPrice); % 跌停时用卖一价来替代原来的买一价。
                if saleBPrice(1) == 0    % 这个数据都没有就没辙了
                    continue;
                end
            else
                continue;               % 实在是交易量不足，放弃。
            end
            node.tradeLimitFlag = 1;
        end
        idx = 1;
        leftA = fjAHolding;
        while( idx < 6 )
            saleAVolume(idx) = min(saleAVolume(idx), leftA);

            leftA = leftA -  saleAVolume(idx);
            idx = idx + 1;
        end
        idx = 1;
        leftB = fjBHolding;
        while( idx < 6 )
            saleBVolume(idx) = min(saleBVolume(idx), leftB);
            leftB = leftB -  saleBVolume(idx);
            idx = idx + 1;
        end
        saleA = saleAVolume/fjAHolding; % 归一化
        saleB = saleBVolume/fjBHolding;
        disRate = saleAPrice*saleA*shareA + saleBPrice*saleB*shareB - netvalue ;  % 等效折溢价率
        if disRate < ZjThresholds   % 可以做折价
            node.code = muCode;
            node.netvalue = netvalue;
            node.fjAPrice = saleAPrice;
            node.fjAVolume = saleAVolume;
            node.fjBPrice = saleBPrice;
            node.fjBVolume = saleBVolume;
            node.time = sec;
            node.rate = disRate;
            tickNodes = [tickNodes; node];
        end        
    end        
            
end           
    
