function [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB )
    for j = 1:length( AVolume )
        AVolume(j) = min(AVolume(j), leftA);               
        leftA = leftA - AVolume(j);
        BVolume(j) = min(BVolume(j), leftB);               
        leftB = leftB - BVolume(j); 
    end
end