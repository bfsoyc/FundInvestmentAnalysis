%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �ú���������Ҫ����ּ�A��B�ķ��� leftA,leftB, �Լ��嵵�� AVolume,BVolume
% �����ÿ���������.
% ���������� sum(AVolume) <= leftA�� sum(BVolume) <= leftB���嵵���������
% ���µȺų���
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB )
    for j = 1:length( AVolume )
        AVolume(j) = min(AVolume(j), leftA);               
        leftA = leftA - AVolume(j);
        BVolume(j) = min(BVolume(j), leftB);               
        leftB = leftB - BVolume(j); 
    end
end