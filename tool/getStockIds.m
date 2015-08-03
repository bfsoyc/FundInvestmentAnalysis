function [S] = getStockIds(file, columns, index)
    fid = fopen(file);
    format = [];
    for i = 1:columns
        format = [format '%s '];
    end
	cells = textscan(fid, format, 'delimiter', ',');
    fclose(fid);
    R = cells{index};
    S = unique(R(2:size(R, 1)));
end