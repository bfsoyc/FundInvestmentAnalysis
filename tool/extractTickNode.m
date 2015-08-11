function tickNodes = extractTickNode(ticksDataA,ticksDataB, muCode, netvalue, holding, shareA, shareB, YjThresholds, ZjThresholds, referenceTime )
    % ���峣��
    constSec = 1/24/60/60;
    global tickTable;
    fjAHolding = holding*shareA;      % ����A�ֲ���
    fjBHolding = holding*shareB;
    
    timeListA = zeros(180,tickTable.maxEntry);  % ÿһ�д���β��3������ÿһ�������.
    timeListB = zeros(180,tickTable.maxEntry);
    for i = 2:size(ticksDataA,1)    % �������ʱ֪����һ��ֵ������referenceTime�ģ����ڳ�ʼ��
        t = round( (ticksDataA(i,tickTable.time) - referenceTime)/constSec);
        timeListA( t+1,: ) = ticksDataA( i, 1:tickTable.maxEntry );
    end
    for i = 2:size(ticksDataB,1)
        t = round( (ticksDataB(i,tickTable.time) - referenceTime)/constSec);
        timeListB( t+1,: ) = ticksDataB( i, 1:tickTable.maxEntry );
    end   
    
    % �ж�ÿһ���Ƿ��������ռ�
    tickNodes = [];
    curA =  ticksDataA(1,1:tickTable.maxEntry);    % ��ǰA������ 
    curB =  ticksDataB(1,1:tickTable.maxEntry);
    for sec = 1:180
        if timeListA(sec,1)   % ��һ��ּ�A�н��׼�¼�����µ�ǰA������
            curA = timeListA(sec,:);  
        end
        if timeListB(sec,1)
            curB = timeListB(sec,:);
        end
        % �ж��Ƿ���������
        buyAVolume = curA( tickTable.buyVolume )';  % ����Ĭ��Ϊ������
        buyBVolume = curB( tickTable.buyVolume )';
        if( sum( buyAVolume ) < fjAHolding || sum( buyBVolume ) < fjBHolding )  % �嵵����������
            continue;
        end
        idx = 1;
        leftA = fjAHolding;     % leftA �ǻ���A����Ҫ����ķ���
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
        buyA = buyAVolume/fjAHolding; % ��һ��
        buyB = buyBVolume/fjBHolding;
        disRate = curA(tickTable.buyPrice)*buyA*shareA + curB(tickTable.buyPrice)*buyB*shareB - netvalue ;  % ��Ч�������
        if disRate > YjThresholds   % ���������
            node = TickNode;
            node.code = muCode;
            node.netvalue = netvalue;
            node.fjAPrice = curA(tickTable.buyPrice);
            node.fjAVolume = buyAVolume;
            node.fjBPrice = curB(tickTable.buyPrice);
            node.fjBVolume = buyBVolume;
            node.time = sec;
            node.disRate = disRate;
            tickNodes = [tickNodes; node];
            continue;   % ��������۾Ͳ��������ۼ���,������һ����ж�
        end
        %profit = curA(tickTable.buyPrice)*buyAVolume + curB(tickTable.buyPrice)*buyBVolume - netvalue*holding ;
        
        % �ж��Ƿ�������ۼ�
        saleAVolume = curA( tickTable.saleVolume )';  % ����Ĭ��Ϊ������
        saleBVolume = curB( tickTable.saleVolume )';
        if( sum( saleAVolume ) < fjAHolding || sum( saleBVolume ) < fjBHolding )  % �嵵����������
            continue;
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
        saleA = saleAVolume/fjAHolding; % ��һ��
        saleB = saleBVolume/fjBHolding;
        disRate = curA(tickTable.salePrice)*saleA*shareA + curB(tickTable.salePrice)*saleB*shareB - netvalue ;  % ��Ч�������
        if disRate < ZjThresholds   % ���������
            node = TickNode;
            node.code = muCode;
            node.netvalue = netvalue;
            node.fjAPrice = curA(tickTable.salePrice);
            node.fjAVolume = saleAVolume;
            node.fjBPrice = curB(tickTable.salePrice);
            node.fjBVolume = saleBVolume;
            node.time = sec;
            node.disRate = disRate;
            tickNodes = [tickNodes; node];
        end        
    end        
            
end           
    