function tickNodes = extractTickNode(ticksDataA,ticksDataB, netvalue, manager, i, referenceTime )
   
    % ��������
    muCode = manager.Info(i).name;
    holding = manager.holdings(i);
    shareA = manager.Info(i).aShare;
    shareB = manager.Info(i).bShare;
    ZjThresholds = manager.Info(i).ZjThresholds;
    
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
        node = TickNode;
        buyAVolume = curA( tickTable.buyVolume )';  % ����Ĭ��Ϊ������
        buyBVolume = curB( tickTable.buyVolume )';
        buyAPrice = curA(tickTable.buyPrice);
        buyBPrice = curB(tickTable.buyPrice);
        if( sum( buyAVolume ) < fjAHolding || sum( buyBVolume ) < fjBHolding )  % �嵵����������
            if sum( buyAVolume ) == 0   % Aû��������ƣ�˵��A��ͣ
                buyAVolume = tickTable.INFVolume;
                buyAPrice = curA(tickTable.salePrice); % ��ͣʱ����һ�������ԭ������һ�ۡ�
                if buyAPrice(1) == 0    % ������ݶ�û�о�û����
                    continue;
                end
            elseif sum( buyBVolume ) == 0 % û���������ƣ�˵����ͣ
                buyBVolume = tickTable.INFVolume;
                buyBPrice = curB(tickTable.salePrice); % ��ͣʱ����һ�������ԭ������һ�ۡ�
                if buyBPrice(1) == 0    % ������ݶ�û�о�û����
                    continue;
                end
            else
                continue;
            end
            node.tradeLimitFlag = 1;
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
        preRate = buyAPrice*buyA*shareA + buyBPrice*buyB*shareB - netvalue ;  % ��Ч�������
        if preRate > 0 % ����0�����Ǵ���YjThresholds ����ΪҪȷ�����ʱ��
            
            node.code = muCode;
            node.netvalue = netvalue;
            node.fjAPrice = buyAPrice;
            node.fjAVolume = buyAVolume;
            node.fjBPrice = buyBPrice;
            node.fjBVolume = buyBVolume;
            node.time = sec;
            node.rate = preRate;
            tickNodes = [tickNodes; node];
            continue;   % ��������۾Ͳ��������ۼ���,������һ����ж�
        end
        %profit = curA(tickTable.buyPrice)*buyAVolume + curB(tickTable.buyPrice)*buyBVolume - netvalue*holding ;
        
        % �ж��Ƿ�������ۼ�
        node = TickNode;
        saleAVolume = curA( tickTable.saleVolume )';  % ����Ĭ��Ϊ������
        saleBVolume = curB( tickTable.saleVolume )';
        saleAPrice = curA(tickTable.salePrice);
        saleBPrice = curB(tickTable.salePrice);
        if( sum( saleAVolume ) < fjAHolding || sum( saleBVolume ) < fjBHolding )  % �嵵����������
            if sum( saleAVolume ) == 0   % Aû���������ƣ�˵��A��ͣ
                saleAVolume = tickTable.INFVolume;
                saleAPrice = curA(tickTable.buyPrice); % ��ͣʱ����һ�������ԭ������һ�ۡ�
                if saleAPrice(1) == 0    % ������ݶ�û�о�û����
                    continue;
                end
            elseif sum( saleBVolume ) == 0 % û���������ƣ�˵����ͣ
                saleBVolume = tickTable.INFVolume;
                saleBPrice = curB(tickTable.buyPrice); % ��ͣʱ����һ�������ԭ������һ�ۡ�
                if saleBPrice(1) == 0    % ������ݶ�û�о�û����
                    continue;
                end
            else
                continue;               % ʵ���ǽ��������㣬������
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
        saleA = saleAVolume/fjAHolding; % ��һ��
        saleB = saleBVolume/fjBHolding;
        disRate = saleAPrice*saleA*shareA + saleBPrice*saleB*shareB - netvalue ;  % ��Ч�������
        if disRate < ZjThresholds   % �������ۼ�
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
    
