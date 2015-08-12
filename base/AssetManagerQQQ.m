%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ��������ģ�⽻�׵��ʽ��������������۲��������з���
%   method:
%       ����Ʒ��
%       isOk = addTypes(obj, configInfo, w , netvalue )
%           configInfo: ����ĸ�������Ϣ.
%           w: ��һ��Ȩ��
%           netvalue: ���ֵ���ĸ����ֵ
%
%       �ж��ܷ����ۼ�
%       [isOk,pos] = canDoZj(obj, OF, cost)
%           cost: ��Ҫ���ʽ�
%
%       �����ۼ۲���
%       doZj(obj, OF, cost, retrive, num)
%           retrive: ���ĸ������յ��ʽ�
%           num: Ϊ1ʱ���ۼ۲�������һ��ĸ���𣬷���ϲ��չ���ķּ������һ��ĸ����ֲ�
%       
%       �ж��ܷ������
%       [isOk, pos] = canDoYj(obj, OF)
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

classdef AssetManagerQQQ < handle   %ά��ĸ����ͷּ��ʽ��״̬����������ʽ������ۼ�ʱ��������2/3���ʽ�ֱ�ӳֲ�ĸ�����������
    properties
        types           % ĸ����״̬���깺���깺�����С���ء���������С�����̬
        holdings        % �ֲַ���
        handleRate      % �ֱֲ�
        initAsset       % ��ʼͶ����ʽ�
        typeNums        % ����Ʒ����
        shMoney
        shMoneyFreez
        validMoney    %�����ʽ�
        
        Info            % Ʒ����Ϣ
    end
    
    properties( Dependent )
        netAsset
    end
    
    methods
        function obj = AssetManagerQQQ(initAsset,handleRate)
            obj.initAsset = initAsset;
            obj.validMoney = initAsset;
            obj.handleRate = handleRate;
            obj.holdings = [];
            obj.types = [];
            obj.Info = [];
            obj.typeNums = 0;
            obj.shMoneyFreez = 0;
            obj.shMoney = 0;
            % log 
            fprintf('-��ʼ�� Ͷ���ʽ� %d.\n', obj.validMoney );
        end
        
        function isOk = addTypes(obj, configInfo, w , netvalue )
            obj.types = [obj.types Type(configInfo.name)];
            obj.Info = [obj.Info configInfo];
            holding = obj.initAsset * obj.handleRate * w / 2 / netvalue;      % ���㹺��ķݶ�
            holding = bitset( floor( holding ),1,0);                          % �ݶ����������,������ż��, �����һλ��0
            obj.holdings = [obj.holdings holding];
            obj.validMoney = obj.validMoney - netvalue * holding * 2;            
            obj.typeNums = obj.typeNums + 1;
            isOk=1; 
            
            % log 
            fprintf('--���ֹ��� %d��Ȩ�أ�%.2f�� %d �ݣ���ֵ%f��, ʣ���ֽ� %f .\n', configInfo.name,w, holding, netvalue, obj.validMoney );
        end        
            
        %ÿ�ս��׽����󣬸���ĸ����״̬
        %�޲���
        function isOk = updateState(obj)     %ÿ�ս��׽�����״̬�ĳ���ָ����״̬�仯���ּ������ÿ���
            for i = 1:obj.typeNums 
                obj.types(i).lastOp = obj.types(i).curOp;
                if obj.types(i).lastOp == Type.NONE2 || obj.types(i).lastOp == Type.ZHEJIA2
                    obj.types(i).curOp = Type.NONE2;
                else
                    obj.types(i).curOp = Type.NONE1;
                end
            end
            % log
            fprintf('-�����ս���,�����ֽ� %.2f, �ⶳ�ʽ� %.2f �����ֽ� %.2f \n', obj.validMoney, obj.shMoney, obj.validMoney+obj.shMoney );
            obj.validMoney = obj.validMoney + obj.shMoney;
            obj.shMoney = obj.shMoneyFreez;
            obj.shMoneyFreez = 0;
            isOk = 1;    
        end
        
        function [isOk,pos] = canDoZj(obj, OF, cost)
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
                if obj.validMoney < cost   
                    isOk = -1;
                else
                    
                    isOk = 1;
                end
            else        %ʣ�������״̬ ���ǳ���2��ĸ�����״̬
                if obj.validMoney < 2*cost
                    isOk = -2;
                else
                    isOk = 2;
                end
            end
        end
        
        function  doZj(obj, OF, cost, retrive, num)   
            pos = obj.find(OF);
            if num == 1
                obj.validMoney = obj.validMoney - cost;%����ּ����𣬻��ѵ�һ���ʽ�
                obj.shMoneyFreez = obj.shMoneyFreez + retrive;
                obj.types(pos).curOp = Type.ZHEJIA1;
            else
                if obj.types(pos).lastOp == Type.NONE2 || obj.types(pos).lastOp == Type.ZHEJIA2   % �ֲ�2��ĸ��������
                    obj.validMoney = obj.validMoney - 2*cost;
                    obj.shMoneyFreez = obj.shMoneyFreez + 2*retrive;
                else
                    obj.validMoney = obj.validMoney - cost;
                    obj.shMoneyFreez = obj.shMoneyFreez + retrive;
                end
                obj.types(pos).curOp = Type.ZHEJIA2;%�ϲ�AB�ݶ�*2����������ֻ������һ��ĸ����Ҳ��������������ĸ���𣬵���ǰһ�����յľ������
                
            end
        end
        
        function [isOk, pos] = canDoYj(obj, OF)
            pos = obj.find(OF);
            if pos == -1;
                error(['û��ĸ���� %d' num2str(OF)]);
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
        
        function doYj(obj, OF, profit)  %%�����깺����ÿ�ս��׽�����ſ�ʼ�۷ѣ������ʽ�ûӰ��
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA1;
            obj.validMoney = obj.validMoney + profit;
        end
        
        function doSpl(obj,OF)  %%�ֲ�һ��ĸ����
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA2;
            % log
            fprintf('--ĸ���� %d ���\n', OF ); 
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
        
                    
            
                
                
            