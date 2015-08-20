%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ����ģ�����������˸�����������۲�������
%   method:
%       ����Ʒ��
%       pos = addTypes(obj, configInfo, w , netvalue )
%           configInfo: ����ĸ�������Ϣ.
%           w: ��һ��Ȩ��
%           netvalue: ���ֵ���ĸ����ֵ
%           ����ֵ:
%           pos ��Ʒ�ֲ��뵽��λ��
%
%       ��ѯָ��Ʒ���ڽṹ���е�λ��
%       function pos = find(obj,NameStr)
%           NameStr: ĸ������ŵ��ַ�����
%
%       �ж��ܷ����ۼ�
%       [isOk,pos] = canDoZj(obj, OF, cost)
%           
%           cost: ��Ҫ���ʽ�
%
%       �����ۼ۲���
%       doZj(obj, OF, cost, retrive, num)
%           retrive: ���ĸ������յ��ʽ�
%           num: Ϊ1ʱ���ۼ۲�������һ��ĸ���𣬷���ϲ��չ���ķּ������һ��ĸ����ֲ�
%       
%       �ж��ܷ������
%       [isOk, pos] = canDoYj(obj, OF)
%           OF: ֱ��ʹ�ô�����øú���ʱ�����ַ�����
%               �����ø�ĸ�����ڽṹ���ڵ�λ�á�
%           ����ֵ: 
%           isOk = 1Ϊ����������������� = 2 Ϊ��û�зּ�A��B�ĳֲֶ��޷�������
%
%       ������۲���
%       doYj(obj, OF, profit)
%           profit: ���β�����ӯ��� profit = gain - cost
%
%       ���ĸ���𣬵� canDoYj(obj,OF) ���ص�isOKΪ2ʱ����Ӧ���øú������в�ֲ���
%       doSpl(obj,OF)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef tradeSimulator < handle   %ά��ĸ����ͷּ��ʽ��״̬����������ʽ������ۼ�ʱ��������2/3���ʽ�ֱ�ӳֲ�ĸ�����������
    properties
        funds           % ��Ż�����Ϣ����
        handleRate      % �ֱֲ�
        initAsset       % ��ʼͶ����ʽ�
        typeNums        % ����Ʒ����
        redeemMoney     % ��صĽ�Ǯ
        freezMoney      % ������ʽ�(���ĸ������ʽ������̵���)
        validMoney      % �����ʽ�     
        
        % ʱ����Ϣ�� �û�����ÿ���ֶ�����)
        date
        referTime       % ���ʱ��
    end    
    
    methods
        function obj = tradeSimulator(initAsset,handleRate)
            obj.initAsset = initAsset;
            obj.validMoney = initAsset;
            obj.handleRate = handleRate;
            obj.typeNums = 0;
            obj.freezMoney = 0;
            obj.redeemMoney = 0;
            obj.funds = [];
            % log 
            fprintf('-��ʼ�� Ͷ���ʽ� %d.\n', obj.validMoney );
        end
        
        function pos = addTypes(obj, configInfo, w , netvalue )
            holding = obj.initAsset * obj.handleRate * w / 2 / netvalue;      % ���㹺��ķݶ�

            % ȷ��3�ֱֲֳ��� 5:5 6:4 7:3 �� ����ĸ�������ʵ�ݶ� holding
            if configInfo.aShare*5 == configInfo.bShare*5   % 5:5
                M = mod( holding,200 );
                holding = holding - M;
            elseif configInfo.aShare*4 == configInfo.bShare*6  % 6:4
                M = mod( holding,500 );
                holding = holding - M;
            elseif configInfo.aShare*3 == configInfo.bShare*7  % 7:3
                M = mod( holding,1000 );
                holding = holding - M;
            else
                error('δ֪����,���龫������');
            end
            
            fund = Fund;
            fund.copyConfig( configInfo );
            fund.holding = holding;
            fund.Aholding = holding*fund.aShare;
            fund.Bholding = holding*fund.bShare;
            obj.funds = [obj.funds fund];
            
            obj.validMoney = obj.validMoney - netvalue * holding * 2;            
            obj.typeNums = obj.typeNums + 1;
            pos = obj.typeNums;             
            % log 
            fprintf('--���ֹ��� %d��Ȩ�أ�%.2f�� %d �ݣ���ֵ%f��, ʣ���ֽ� %f .\n', configInfo.name,w, holding, netvalue, obj.validMoney );
        end        
            
        function  updateState(obj,netValue)     % ÿ�ս��׽�����״̬����
            fprintf('-�����ս���\n');
            for i = 1:obj.typeNums 
                fund = obj.funds(i);
                fund.lastOPTime = -180;         % 
                fund.freezHolding = 0;    % ����
                % ������������                
                if fund.cfHolding > 0
                    holding = floor(fund.applyMoney/netValue(i)/(1+fund.applyFee)); 
                    charge = fund.applyMoney - netValue(i)*holding*(1+fund.applyFee);
                    % log
                    fprintf('--ʵ���깺ĸ���� %d(%.3f) %d ��,���� %.2f \n',fund.name, netValue(i), holding, charge);
                    
                    obj.validMoney = obj.validMoney + charge;
                    % ���³ֲ�
                    fund.holding = fund.holding + holding;
                    fund.freezHolding = holding;    % ���첻����صķݶ����������깺�ݶ�
                    fund.Aholding = fund.Aholding + fund.cfHolding*fund.aShare;
                    fund.Bholding = fund.Bholding + fund.cfHolding*fund.bShare;
                    
                    fund.cfHolding = 0;
                    fund.applyMoney = 0;
                end
                
                % ������ۼ�����
                if fund.hbAholding > 0
                    gain = netValue(i)*fund.redeemHolding*(1-fund.redeemFee);
                    % log
                    fprintf('--���ĸ���� %d(%.3f) %d ��,ʵ�ʻ��� %.2f .\n',fund.name, netValue(i), fund.redeemHolding, gain);
                    
                    obj.redeemMoney = obj.redeemMoney + gain;
                    
                    % ���³ֲ�
                    fund.holding = fund.holding + fund.hbAholding/fund.aShare;
                    
                    fund.redeemHolding = 0;
                    fund.hbAholding = 0;
                    fund.hbBholding = 0;
                end                
            end
            
            obj.validMoney = obj.validMoney + obj.freezMoney;
            % log
            fprintf('-���춳���ʽ� %.2f, �ⶳ�ʽ� %.2f �����ֽ� %.2f \n\n', obj.redeemMoney, obj.freezMoney, obj.validMoney );    
            
            obj.freezMoney = obj.redeemMoney;
            obj.redeemMoney = 0;  
        end
        
        function dispHolding(obj)
            for i = 1:obj.typeNums
                fund = obj.funds(i);
                fprintf('* ĸ���� %d �ֲ֣� %d, �ּ�A %s �ֲ֣�%d, �ּ�B %s �ֲ֣� %d \n',...
                    fund.name, fund.holding, fund.fjAName, fund.Aholding, fund.fjBName, fund.Bholding );
            end
        end
        % �뱣��APrice, BPrice, AVolume, BVolume ����һ��
        function [premRate, tradeVol, pos] = calPremRate( obj, OF, APrice, BPrice, AVolume, BVolume, predNetvalue )
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('�����ڵ�ĸ����');
            end
            fund = obj.funds(pos);
            if obj.referTime < fund.lastOPTime + 15  % �û��������һ�β���ʱ����С��15s
                premRate = 0;
                tradeVol = 0;
                return;
            end
            % �������
            if ~isrow(APrice) || ~isrow(BPrice)
                error('APrice �� BPricce ������������');
            end
            if ~iscolumn(AVolume) || ~iscolumn(BVolume)
                error('AVoluem �� BVolume ������������');
            end
            
            %  !!ĸ������ּ�����ĳֱֲ�������ʱ����䶯
            % ���
            tradeVol =  fund.Aholding/fund.aShare;  % �������������ȡ����ּ�����ĳֲ�
%             if tradeVol == 0   % 2���ۼ� ���ּ�����ϲ���
%                 tradeVol = 10;    % ����tradeVol Ϊ��0ֵ���������ڼ�������ʡ�
%             end
            leftA = tradeVol*fund.aShare;
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            tradeVol = min( sum(AVolume)/fund.aShare, sum(BVolume)/fund.bShare );   % �п���A��B�嵵������
            if predNetvalue * tradeVol < 1e4    % �깺ĸ����Ľ��С��5w
                premRate = 0;
                tradeVol = 0;
                return;
            end
            leftA = tradeVol*fund.aShare;   % ������tradeVol, ��������һ��[AVolume, BVolume]
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            
            AVolume = AVolume/sum(AVolume); % ��һ��
            BVolume = BVolume/sum(BVolume);
            premRate = APrice*AVolume*fund.aShare + BPrice*BVolume*fund.bShare - predNetvalue ;  % ��Ч�����
            
            
        end
            
        function [disRate, tradeVol] = calDisRate( obj, OF, APrice, BPrice, AVolume, BVolume, predNetvalue )
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('�����ڵ�ĸ����');
            end
            fund = obj.funds(pos);
            if obj.referTime < fund.lastOPTime + 15  % �û��������һ�β���ʱ����С��15s
                disRate = 0;
                tradeVol = 0;
                return;
            end          
            
            % �������
            if ~isrow(APrice) || ~isrow(BPrice)
                error('APrice �� BPricce ������������');
            end
            if ~iscolumn(AVolume) || ~iscolumn(BVolume)
                error('AVoluem �� BVolume ������������');
            end
            
            % �ۼ۵�ʱ���ж�Ŀǰ�ʽ��㹻�����ٷ��ۼ������Ƚϸ���
            
            % ����۲�, !!ĸ������ּ�����ĳֱֲ�������ʱ����䶯
            % �ۼ�,�ж���ĸ����������������ĸ����
            tradeVol =  fund.holding - fund.freezHolding ;
            leftA = tradeVol*fund.aShare;
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            tradeVol = min( sum(AVolume)/fund.aShare, sum(BVolume)/fund.bShare );    % �п���A��B�嵵������,��������£�sum(AVolume) == leftA == tradeVol*fund.aShare
            leftA = tradeVol*fund.aShare;       % ������ tradeVol ������һ��
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            
            cost = APrice*AVolume + BPrice*BVolume;
            if cost < 1e4   % ���׶�С��5w �����ñʽ���
                disRate = 0;
                tradeVol = 0;
                return;
            end
            
            AVolume = AVolume/sum(AVolume); % ��һ�� ��ǰ���cost�ж��ô˴�������0Ϊ����)
            BVolume = BVolume/sum(BVolume);
            disRate = APrice*AVolume*fund.aShare + BPrice*BVolume*fund.bShare - predNetvalue ;  % ��Ч�ۼ���
        end
        
        function profit = doYj(obj, OF, premRate, tradeVol, predNetvalue)  
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('�����ڵ�ĸ����');
            end
            
            fund = obj.funds(pos);
            gain = (premRate+predNetvalue)*tradeVol*(1-fund.stockFee);
            cost = predNetvalue*tradeVol*(1+fund.applyFee);
            fund.applyMoney = fund.applyMoney + cost;
            profit = gain - cost;           
            obj.validMoney = obj.validMoney + gain - cost;
            % ���³ֲ�״̬
            fund.holding = fund.holding - tradeVol;
            fund.Aholding = fund.Aholding - tradeVol*fund.aShare;
            fund.Bholding = fund.Bholding - tradeVol*fund.bShare;
            fund.cfHolding = fund.cfHolding + tradeVol;
           
            fund.lastOPTime = obj.referTime;    % ���¸û������һ�β�����ʱ��
            
            % log
            format = [ '--(%d,%2d)�깺ĸ���� %d(pred:%.3f) Ԥ�� %d ��,���� %.2f \n' ...
                '%12s�����ּ�����ӯ�� %.2f \n' ...        
                '%12s���ֽ� %.2f\n' ];
            fprintf(format, obj.date, obj.referTime, fund.name, predNetvalue, tradeVol, cost, ...
                '', gain, ... 
                '', obj.validMoney);
            
        end
        
        function profit = doZj(obj, OF, disRate, tradeVol, predNetvalue)
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('�����ڵ�ĸ����');
            end
            fund = obj.funds(pos);
            cost = (disRate+predNetvalue)*tradeVol*(1+fund.stockFee);
            gain = predNetvalue*tradeVol*(1-fund.redeemFee);
            profit = gain-cost;
            fund.redeemHolding = fund.redeemHolding+tradeVol;       % �û�����صķݶ���ڵ������ʱ������ʵ����
            obj.validMoney = obj.validMoney - cost;
            % ���³ֲ�
            fund.holding = fund.holding - tradeVol;
            if fund.holding < 0
                error(['ĸ����' num2str(fund.name) '�ֲ�������Ҫ��Ľ����� ' num2str(tradeVol)])
            end

            fund.hbAholding = fund.hbAholding + tradeVol*fund.aShare;
            fund.hbBholding = fund.hbBholding + tradeVol*fund.bShare;
            
            fund.lastOPTime = obj.referTime;    % ���¸û������һ�β�����ʱ��
            
            % log
            format = [ '--(%d,%2d)���ĸ���� %d(pred:%.3f) %d ��,Ԥ��ӯ�� %.2f \n' ...
                '%12s����ּ����𻨷� %.2f \n' ...        
                '%12s���ֽ� %.2f\n' ];
            fprintf(format, obj.date, obj.referTime, fund.name, predNetvalue, tradeVol, gain, ...
                '', cost, ... 
                '', obj.validMoney);
        end
            
        function splitFund(obj,OF)  %%�ֲ�һ��ĸ����
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            obj.funds(pos).OPStatus = 1;
            M = mod(obj.funds(pos).holding/2,10); 
            cf = obj.funds(pos).holding/2-M;
            aAdd = cf*obj.funds(pos).aShare;
            bAdd = cf*obj.funds(pos).bShare;
            obj.funds(pos).Aholding = obj.funds(pos).Aholding + aAdd;
            obj.funds(pos).Bholding = obj.funds(pos).Bholding + bAdd;
            obj.funds(pos).holding = obj.funds(pos).holding - cf;            
            obj.funds(pos).holdingStatus = 0;            
            % log
            fprintf('--ĸ���� %d ���\n', obj.funds(pos).name ); 
        end
        
        function mergeFund(obj, OF)
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            fund = obj.funds(pos);
            % �ϲ�ȫ���ּ�����
            hb = fund.Aholding/fund.aShare;
            fund.holding = fund.holding + hb;
            fund.Aholding = 0;
            fund.Bholding = 0;
            % log
            fprintf('--ĸ���� %d ͨ���ϲ����� %d ��\n', obj.funds(pos).name, hb ); 
        end
       
        function pos = find(obj,NameStr)
            if ~ischar( NameStr )
                error('������ĸ���������ַ�����');
            end
            len = length(NameStr);
            if( len > 6 )
                NameStr = NameStr( end-6:end);
            end
            code = str2num( NameStr );
            pos = -1;
            for i = 1:obj.typeNums
                if obj.funds(i).name == code
                    pos = i;
                    return;
                end
            end
        end
        
    end
end
        
                    
            
                
                
            