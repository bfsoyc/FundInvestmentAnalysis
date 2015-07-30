function [T] = readcsv2(file, columns)
    fid = fopen(file);
    format = [];
    for i = 1:columns
        format = [format '%s '];
    end
	T = textscan(fid, format, 'delimiter', ',');
    fclose(fid);
end