classdef Fund < handle
    properties
        % 基本信息
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
        
        % 持仓量
        holding = 0        % 母基金持仓份额
        freezHolding = 0    % 被冻结的母基金(前一天申购，暂时不能赎回的部分,可拆分)
        cfHolding = 0      % 申请拆分的母基金
        applyMoney = 0     % 用于申购的金额
        redeemHolding = 0  % 赎回的份额
        Aholding = 0
        hbAholding = 0     % 申请合并的分级A      
        Bholding = 0
        hbBholding = 0     % 申请合并的分级B
        OPStatus = 0              % 当该状态为0时，基金才可自由操作.比如该基金经过拆分操作后不能进行其他操作
        holdingStatus = 0         % 0即未经2倍折价的合并.
        
        lastOPTime = -180     % 上一次交易时间，用于控制分笔交易的间隔时间
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
    