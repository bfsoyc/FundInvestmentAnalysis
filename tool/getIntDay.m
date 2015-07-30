function [T] = getIntDay(ymd)
T = datenum(ymd);
T = T - 693960;
end