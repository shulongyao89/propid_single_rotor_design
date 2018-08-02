function [value] = findword(name,filename,folder,token)

current_folder = pwd;

if isempty(folder)==0   
    cd (folder);
end

%%%%%%%%%%%%%%%%%%%%%%%
clc;

fid = fopen(filename,'r');

tline = fgetl(fid);
jj=0;
while ischar(tline)
    jj=jj+1;
    line_string = sprintf('%s',tline);
    if isempty(strfind(line_string, name))==0
        [token, remain]=strtok(line_string,token);
        
        value = remain(3:end);
        break;
      
    end    
    tline = fgetl(fid); %go to next line
end
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(folder)==0  
    cd (current_folder)
end
