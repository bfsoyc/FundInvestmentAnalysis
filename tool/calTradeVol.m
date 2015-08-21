%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 该函数给出需要买入分级A、B的份数 leftA,leftB, 以及五档量 AVolume,BVolume
% 计算出每档购入的量.
% 计算结果总有 sum(AVolume) <= leftA， sum(BVolume) <= leftB，五档量充足的情
% 况下等号成立
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB )
    for j = 1:length( AVolume )
        AVolume(j) = min(AVolume(j), leftA);               
        leftA = leftA - AVolume(j);
        BVolume(j) = min(BVolume(j), leftB);               
        leftB = leftB - BVolume(j); 
    end
end