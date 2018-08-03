%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SINGLE DESIGN ROTOR CODE
% --> See readme file
% Inputs
%  - Design Power at rated speed
%  - Average wind speed
%  - Rated wind speed
%  - Constant coning angle at rated speed
%  - Axial induction at design tip speed ratio
%  - Design tip speed ratio
%  - Number of blades
%  - Design Cl at 75% chord location
%  - Hub radius
%  - Hub height
%  - Cut in wind speed
%  - Cut out wind speed
%
% Outputs
%  - All data is stored in the output flder in the folders associated with
%  the filenames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all

tic
input.filename = 'SUMR-25_v3.in';

% Change propid.in file
fid = fopen('propid.in','w');
fprintf(fid,input.filename);
fclose(fid);

%% Design conditions
input.Pdes_kW = 25000;              % design power after rated speed
input.Vavg_mps = 9.0;               % average operating wind speed 
input.Vrated_mps = 10.5;            % rated speed  --> Note that 10.5 allows AeroDyn to hit rated power at 11.3
input.cone_deg = 22.5;              % design cone angle
input.axialind = 0.225;             % design axial induction
input.TSR = 9.25;                   % tip speed ratio
input.blades = 2;                   % blades
input.Cl_rR75pct = 1.25;            % design Cl at the 75% chord location --> input from aero
input.hub_m = 3.75;                 % hub radius
input.hub_height_m = 500;           % hub height
input.Vcutin_mps = 5;               % cut in wind speed
input.Vcutout_mps = 25;             % cout out wind speed

input.fixedmoment_flag = 0;         % 0 - dont fix moments; 1 - fix root moments
input.moment_ftlb = 5.000e7 / cosd(input.cone_deg) ^ 2;     % Moments to fix

input.power_kW = input.Pdes_kW / cosd(input.cone_deg) ^ 3;

cd Tools
[input.rho_slugspft3,a,T,P,nu,z] = atmos(input.hub_height_m,'units','US');
cd ..

input.Vavg_mph = input.Vavg_mps * 2.23694;
input.Vrated_mph = input.Vrated_mps * 2.23694;
input.Vcutin_mph = input.Vcutin_mps * 2.23694;
input.Vcutout_mph = input.Vcutout_mps * 2.23694;
input.Vavg_ftps = input.Vavg_mps * 3.28084;
input.Vrated_ftps = input.Vrated_mps * 3.28084;
input.Vavg_tip_mps = input.TSR / (cosd(input.cone_deg)) * input.Vavg_mps;
input.Vrated_tip_mps = input.TSR / (cosd(input.cone_deg)) * input.Vrated_mps;
input.Vavg_tip_ftps = input.TSR / (cosd(input.cone_deg)) * input.Vavg_mps * 3.28084;
input.Vrated_tip_ftps = input.TSR / (cosd(input.cone_deg)) * input.Vrated_mps * 3.28084;
input.hub_ft = input.hub_m * 3.28084;
input.tol1 = 1;
input.tol2 = 1;
input.tol_restart_flag = 0;
input.multiplier = 0.95;

createPROPIDOptimizerFile(input.filename,input);
count = 0;
while input.tol1 > 0.002
    count = count + 1;
    dos('propid54-64bit.exe');                  % runs PROPID with 50 iterations
    input = updatePROPIDOptimizerFile(input.filename,input,count);

    input
    
    % Break criteria
    if input.fixedmoment_flag == 1
        if (abs(input.moment_diff) < 0.1 && abs(input.a_diff) <  0.01)
            break;
        end
    else
        if abs(input.a_diff) <  0.001
            break;
        end
    end
end
count
fclose('all')

sprintf('Calculation Time: %f mins', toc / 60)

[input] = make_AD14_inputfile_function(input);
[input] = make_AD15_inputfile_function(input);

%% SAVE FILES INTO SPECIFIC FOLDERS
mkdir(sprintf('%s\\OutputFiles\\%s',pwd,input.filename(1:end-3)))
mkdir(sprintf('%s\\OutputFiles\\%s\\PROPIDOutput',pwd,input.filename(1:end-3)))

%%% Move propid files into the created blade folder
files_to_move = dir('ftn*');
for ii = 1:numel(files_to_move)
    try
        movefile(sprintf('%s\\%s',pwd,files_to_move(ii).name),...
            sprintf('%s\\OutputFiles\\%s\\PROPIDOutput\\',pwd,input.filename(1:end-3)))
    catch
        
    end
end
movefile(sprintf('%s\\gaep.dat',pwd),sprintf('%s\\OutputFiles\\%s\\PROPIDOutput\\',pwd,input.filename(1:end-3)));
movefile(sprintf('%s\\%s',pwd,input.filename),sprintf('%s\\OutputFiles\\%s',pwd,input.filename(1:end-3)));

save(sprintf('%s\\OutputFiles\\%s\\KeyData',pwd,input.filename(1:end-3)),'input')

disp(sprintf('CONGRATULATIONS YOU HAVE DESIGNED A NEW ROTOR'))
disp(sprintf('Key Parameters:'))
disp(sprintf('R = %5.4f',input.AD14_R_m))
disp(sprintf('Rotation Rate (at avg. wind speed) = %5.4f RPM',input.omega_avg_RPM))
disp(sprintf('Rotation Rate (at rated wind speed) = %5.4f RPM',input.omega_rated_RPM))
disp(sprintf('Pitch = %5.4f deg',input.pitch_deg))

