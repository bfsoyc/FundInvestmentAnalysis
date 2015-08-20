classdef Fund < handle
    properties
        % ������Ϣ
        name 
        fjAName 
        fjBName 
        slipRate 
        aShare   
        bShare    
        applyFee     
        redeemFee 
        stockFee 
        YjThresholds
        ZjThresholds 
        
        % �ֲ���
        holding = 0        % ĸ����ֲַݶ�
        freezHolding = 0    % �������ĸ����(ǰһ���깺����ʱ������صĲ���,�ɲ��)
        cfHolding = 0      % �����ֵ�ĸ����
        applyMoney = 0     % �����깺�Ľ��
        redeemHolding = 0  % ��صķݶ�
        Aholding = 0
        hbAholding = 0     % ����ϲ��ķּ�A      
        Bholding = 0
        hbBholding = 0     % ����ϲ��ķּ�B
        OPStatus = 0              % ����״̬Ϊ0ʱ������ſ����ɲ���.����û��𾭹���ֲ������ܽ�����������
        holdingStatus = 0         % 0��δ��2���ۼ۵ĺϲ�.
        
        lastOPTime = -180     % ��һ�ν���ʱ�䣬���ڿ��Ʒֱʽ��׵ļ��ʱ��
    end
    
    methods
        function copyConfig( obj, configInfo )
            obj.name = configInfo.name;
            obj.fjAName = configInfo.fjAName;
            obj.fjBName = configInfo.fjBName;
            obj.slipRate = configInfo.slipRate;
            obj.aShare = configInfo.aShare;
            obj.bShare = configInfo.bShare;
            obj.applyFee = configInfo.applyFee;
            obj.redeemFee = configInfo.redeemFee;
            obj.stockFee = configInfo.stockFee;
            obj.YjThresholds = configInfo.YjThresholds;         
            obj.ZjThresholds = configInfo.ZjThresholds;                        
        end
    end
end
    