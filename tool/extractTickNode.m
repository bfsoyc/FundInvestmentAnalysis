function tickNodes = extractTickNode(ticksDataA,ticksDataB, muName, netvalue, holding, shareA, shareB, YjThresholds, ZjThresholds, referenceTime )
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
        sumA = sum( buyAVolume );
        while( idx < 6 )
            buyAVolume(idx) = min(buyAVolume(idx), sumA);
            sumA = sumA -  buyAVolume(idx);
            idx = idx + 1;
        end
        idx = 1;
        sumB = sum( buyBVolume );
        while( idx < 6 )
            buyBVolume(idx) = min(buyBVolume(idx), sumB);
            sumB = sumB -  buyBVolume(idx);
            idx = idx + 1;
        end
        buyA = buyAVolume/fjAHolding; % ��һ��
        buyB = buyBVolume/fjBHolding;
        disRate = curA(tickTable.buyPrice)*buyA*shareA + curB(tickTable.buyPrice)*buyB*shareB - netvalue ;  % ��Ч�������
        if disRate > YjThresholds   % ���������
            node = TickNode;
        end
        %profit = curA(tickTable.buyPrice)*buyAVolume + curB(tickTable.buyPrice)*buyBVolume - netvalue*holding ;
        
    end
        
%     for i = 1:size(ticksData,1)
%         node.t = round( (ticksData(i,tickTable.time) - referenceTime)/constSec);
%         
%         buyVolumeA = ticksData(i,tickTable.buyVolume);
%         if( sum( buyVolume ) < fjHolding 
            
end           
    