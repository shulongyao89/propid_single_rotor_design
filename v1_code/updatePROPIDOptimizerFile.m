function [input] = updatePROPIDOptimizerFile(filename,input,count)

%% Read old file
fid = fopen(filename,'r');
ii = 1;
while ~feof(fid)
    data{ii} = fgetl(fid);
    ii = ii + 1;
end
fclose(fid);

%% Read ftn021 file
fid2 =fopen('ftn021.dat','r');
ii = 1;
while ~feof(fid2)
    updated{ii} = fgetl(fid2);    
    ii = ii + 1;
end
fclose(fid2);

%% Read ftn082 file
fid3 = fopen('ftn082.dat','r');
ii = 1;
while ~feof(fid3)
    reportdata{ii} = fgetl(fid3);
    ii = ii + 1;    
end
fclose(fid3)

%Read ftn090 file (axial induction)
rR_aind = importdata('ftn090.dat');       % Import data from output file
aind_vec = rR_aind(:,2);             % Chord distribution

%Read ftn045 file (Cp)
TSR_Cp= importdata('ftn045.dat');       % Import data from output file
TSR = TSR_Cp(:,1)*cosd(input.cone_deg);             % TSR
Cp = TSR_Cp(:,2);%*cosd(input.cone_deg) ^ 2;             % Cp
input.Cp_at_TSRdes = interp1(TSR,Cp,input.TSR);

% Read ftn011 file
fid4 = fopen('ftn011.dat','r');
ii = 1;
while ~feof(fid4)
    ftn11data{ii} = fgetl(fid4);
    ii = ii + 1;    
end
fclose(fid4)
ratedcond_info = strsplit(ftn11data{end});


% update moment and power
try
    input.moment_diff = input.moment_ftlb - str2double(ratedcond_info(end-2));
catch
    keyboard
end
input.a_diff = abs(input.axialind - mean(aind_vec(5:end,1)));
input.moment_input_ftlb = str2double(ratedcond_info(end-2));
input.thrust_at_rated_lb = str2double(ratedcond_info(end-3));
input.torque_at_rated_lb = str2double(ratedcond_info(end-1));
input.power_at_rated_kW = str2num(reportdata{6}(28:41));
if input.fixedmoment_flag == 1
    input.power_kW = input.power_at_rated_kW;
    input.moment_input_ftlb =str2double(ratedcond_info(end-2)) + input.moment_diff * input.multiplier;
end
input.b_area_ft2 = str2num(reportdata{3}(28:41));
input.solidity = str2num(reportdata{4}(28:41));

% Get new radius and moment
input.R_ft = str2num(updated{3}(3:end));
input.R_m = input.R_ft / 3.28084;
input.hubR_frac = input.hub_ft/input.R_ft;
input.tol1 = str2num(data{86}(7:end));
input.tol2 = str2num(data{87}(7:end));

% Calculate power at rated
input.power_at_rated_calc_kW = 0.5 * input.rho_slugspft3 * ...
    (pi * (input.R_ft * cosd(input.cone_deg)) ^ 2) * input.Vrated_ftps ^ 3 *...
    input.Cp_at_TSRdes * 0.001355817948331;

% Calculate AEP
cd Tools
input = calcAEP(input);
cd ..

%Read gaep.dat
V_gaep = importdata('gaep.dat');
input.gaep_MWhr = V_gaep(:,2)/1000;


if input.fixedmoment_flag == 1 && input.a_diff < 0.01 && input.tol_restart_flag ==0
    input.tol_restart_flag = 1;
    input.tol1 = 2;
    input.multiplier = 0.95;
end

if input.tol_restart_flag == 1 && input.tol2 > 0.001
    input.tol1 = 5;
end
% input.tol1 = 5;
% Write updated file
fid = fopen(filename,'w');
for ii = 1:numel(data)
    if ii == 20
        fprintf(fid,'HUB     %10.9f\n',input.hubR_frac);
    elseif ii > 20 && ii < 33
        fprintf(fid,'%s\n',updated{ii-18});
    elseif ii == 57
        fprintf(fid,'    %10.9f   1    %5.4f\n',(input.hubR_frac + 0.1)/2, 1 - (input.hubR_frac + 0.1)/2);
    elseif ii == 75
        fprintf(fid,'%s\n',updated{51});
    elseif ii == 76
        fprintf(fid,'%s\n',updated{52});
    elseif ii == 86        
        fprintf(fid,'TOLSP1 %6.5f\n',input.tol1 * input.multiplier);
    elseif ii == 87
        fprintf(fid,'TOLSP2 %6.5f\n',input.tol2 * input.multiplier);
    elseif (ii == 111 || ii == 112 || ii == 119 || ii == 120) && input.fixedmoment_flag == 1 && input.a_diff < 0.01
        if ii == 111
            fprintf(fid,'NEWT1IDP 203 %12.3f 2 1 2  1 7 999 0.7\n',input.moment_input_ftlb);            
        elseif ii == 112
            fprintf(fid,'IDES\n');
        elseif ii == 119
            fprintf(fid,'#NEWT1IDP 200  %9.2f 2 1 2     1 1 999    1.05\n',...
                input.power_kW);
        else
            fprintf(fid,'#IDES\n');
        end
    else 
        fprintf(fid,'%s\n',data{ii});
    end                
end
fclose(fid);

    