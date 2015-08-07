classdef AssetManager < handle   %ά��ĸ����ͷּ��ʽ��״̬����������ʽ������ۼ�ʱ��������2/3���ʽ�ֱ�ӳֲ�ĸ�����������
    properties
        types         %ĸ����״̬���깺���깺�����С���ء���������С�����̬
        typeNums
        shMoney
        shMoneyFreez
        handleRate
        totalRate
        validMoney    %�����ʽ�
        totalMoney    %���ʽ�
    end
    
    
    methods
        function obj = AssetManager(handle, total)
            obj.types=[];
            len = 0;
            obj.typeNums = len;
            obj.shMoney = 0;
            obj.shMoneyFreez = 0;
            obj.validMoney = len*(total-handle);
            obj.totalMoney = len*total;
            obj.handleRate = handle;
            obj.totalRate = total;
        end
        
        %���ڵ�ֻ����ÿ�������������ʽ�ʵ���ǳֲ��ʽ��һ�룬CcRate()���ظò����ʽ�ռ���ʽ�İٷֱȣ�������ռ��Ʒ�����ʽ�İٷֱȣ�
        function cc = CcRate(obj)
            cc = obj.handleRate/obj.totalRate/2;
        end
        
        %����Ʒ��
        %OF Ʒ�ִ��룬һά����
        function isOk = addTypes(obj,OF)
            tmp =[];
            len = size(OF,2);
            if len < 1
                isOk=-1; return;
            end

            if obj.typeNums >= 1                %%%%%%%%�������л���Ϊ��ʼ̬%%%%%%%�����Ե�����
                for i = 1:obj.typeNums
                    tmp = [tmp Type(obj.types(i).OFName)];
                end
            end
            
            for i=1:len;
                tmp = [tmp Type(OF(i))];
            end
            obj.types = tmp;
            obj.typeNums = obj.typeNums + len;
            obj.shMoney = 0;
            obj.validMoney = obj.typeNums*(obj.totalRate-obj.handleRate);
            obj.totalMoney = obj.typeNums*obj.totalRate;
            isOk=1;
        end
        
        %ÿ�ս��׽����󣬸���ĸ����״̬
        %�޲���
        function isOk = updateState(obj)     %ÿ�ս��׽�����״̬�ĳ���ָ����״̬�仯���ּ������ÿ���
            for i=1:obj.typeNums%%??����������
                obj.types(i).lastOp = obj.types(i).curOp;
                if obj.types(i).lastOp == Type.NONE2 || obj.types(i).lastOp == Type.ZHEJIA2
                    obj.types(i).curOp = Type.NONE2;
                else
                    obj.types(i).curOp = Type.NONE1;
                end
            end
            obj.validMoney = obj.validMoney + obj.shMoney;
            obj.shMoney = obj.shMoneyFreez;
            obj.shMoneyFreez = 0;
            isOk = 1;    
        end
        
        %�ж��Ƿ�����ۼ۲���
        %OF ĸ�������
        function isOk = canDoZj(obj,OF)
            isOk = 0;
            pos = obj.find(OF);
            if pos == 0;
                return;
            end
            if obj.types(pos).lastOp == Type.YIJIA1    %ǰһ��������ۣ����깺������ĸ������Բ�ֵ�����������أ� ���Բ����������ۼ�
                return;
            end
            if obj.types(pos).lastOp == Type.NONE1 || obj.types(pos).lastOp == Type.YIJIA2 || obj.types(pos).lastOp == Type.ZHEJIA1
                % YIJIA2 ʵ���Ͼ��ǻع鵽��ʼ״̬��
                if obj.validMoney < obj.handleRate/2    
                    isOk = -1;
                else
                    isOk = 1;
                end
            else        %ʣ�������״̬ ���ǳ���2��ĸ�����״̬
                if obj.validMoney < obj.handleRate
                    isOk = -2;
                else
                    isOk = 2;
                end
            end
        end
        
        %�ۼ۲���
        %OF ĸ�������
        function  doZj(obj,OF,num)
            pos = obj.find(OF);
            if num == 1
                obj.validMoney = obj.validMoney - obj.handleRate/2;%����ּ����𣬻��ѵ�һ���ʽ�
                obj.shMoneyFreez = obj.shMoneyFreez + obj.handleRate/2;
                obj.types(pos).curOp = Type.ZHEJIA1;
            else
                if obj.types(pos).lastOp == Type.NONE2 || obj.types(pos).lastOp == Type.ZHEJIA2   % �ֲ�2��ĸ��������
                    obj.validMoney = obj.validMoney - obj.handleRate;
                    obj.shMoneyFreez = obj.shMoneyFreez + obj.handleRate;
                else
                    obj.validMoney = obj.validMoney - obj.handleRate/2;
                    obj.shMoneyFreez = obj.shMoneyFreez + obj.handleRate/2;
                end
                obj.types(pos).curOp = Type.ZHEJIA2;%�ϲ�AB�ݶ�*2����������ֻ������һ��ĸ����Ҳ��������������ĸ���𣬵���ǰһ�����յľ������
            end
        end
        
        function isOk = canDoYj(obj,OF)
            isOk = 0;
            pos = obj.find(OF);
            if pos == -1;
                return;
            end
            lastOp = obj.types(pos).lastOp;
            %��������������ӻ���A��B��ͬʱ��ֲ��е�ĸ�����깺�µ���ͬ�ݶ��ĸ����
            %��Ϊ����ä������һ������£������������ÿ�������ճ������ϵؽ���
            if lastOp == Type.NONE1 || lastOp == Type.YIJIA1 || lastOp == Type.YIJIA2 || lastOp == Type.ZHEJIA1
                isOk = 1;
            else
                isOk = 2;
            end
        end
        
        function doYj(obj,OF)  %%�����깺����ÿ�ս��׽�����ſ�ʼ�۷ѣ������ʽ�ûӰ��
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA1;
        end
        
        function doSpl(obj,OF)  %%�ֲ�һ��ĸ����
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA2;
        end
        %��ѯָ��Ʒ����types�����е�λ��
        %OF ָ��Ʒ�ֵ�ĸ�������
        function pos = find(obj,OF)
            if obj.typeNums < 1;
                pos =-1;return 
            end
            for i = 1:obj.typeNums
                if obj.types(i).OFName == OF
                    pos = i;
                    return;
                end
            end
            pos =-1;return;
        end
        
    end
end
        
                    
            
                
                
            