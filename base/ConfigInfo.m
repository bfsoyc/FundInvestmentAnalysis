classdef ConfigInfo < handle
    properties
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
        map2Src
    end
    
    methods
        function obj = ConfigInfo()
            obj.name = 0;
            obj.fjAName = 0;
            obj.fjBName = 0;
            obj.slipRate = 0;
            obj.aShare = 0;
            obj.bShare = 0;
            obj.applyFee = 0;
            obj.redeemFee = 0;
            obj.stockFee = 0;
            obj.YjThresholds = 0;         
            obj.ZjThresholds = 0;            
            obj.map2Src = 0;
        end
        
        function obj = copyObj( obj, copyObj )
            obj.name = copyObj.name;
            obj.fjAName = copyObj.fjAName;
            obj.fjBName = copyObj.fjBName;
            obj.slipRate = copyObj.slipRate;
            obj.aShare = copyObj.aShare;
            obj.bShare = copyObj.bShare;
            obj.applyFee = copyObj.applyFee;
            obj.redeemFee = copyObj.redeemFee;
            obj.stockFee = copyObj.stockFee;
            obj.YjThresholds = copyObj.YjThresholds;         
            obj.ZjThresholds = copyObj.ZjThresholds;            
            obj.map2Src = copyObj.map2Src;
        end
    end
end
        
       