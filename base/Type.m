classdef Type < handle
    properties
        lastOp
        curOp
        OFName
    end
    properties (Constant)
        NONE1 = 0;    %ĸ����ABͬ�ȳֲ������ ʲô��û��
        YIJIA1 = 1;   %ĸ����ABͬ�ȳֲ������ �������
        ZHEJIA1 = 2;  %ĸ����ABͬ�ȳֲ������ �ۼ�����
        
        NONE2 = 3;    %ĸ����ֲ������ ʲô��û��
        YIJIA2 = 4;   %ĸ����ֲ������ �ֲ�һ��ĸ���𣬲�����
        ZHEJIA2 = 5;  %ĸ����ֲ������ �ۼ�����
    end
    methods
        function obj = Type(arg)
            obj.OFName = arg;
            obj.lastOp = obj.NONE1;
            obj.curOp = obj.NONE1;
        end
    end
end
        
       