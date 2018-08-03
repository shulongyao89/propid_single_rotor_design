function [input] = make_AD15_inputfile_function(input)

hub_radius_m = input.hub_m;
R_m = input.AD14_R_m;
blade_radius_m = R_m - hub_radius_m;

main_dir = pwd;

cd Tools
[convert_lbm2kg, convert_ft2m, convert_degR2degK] = englishtometric();

[RHO_slugpft2] = str2double(findword('RHO','ftn021.dat',main_dir,' '));
[HUB] = str2double(findword('HUB','ftn021.dat',main_dir,' '));
[R_ft] = str2double(findword('RD','ftn021.dat',main_dir,' '));
[AIRFOIL_FAMILY_NUM] = str2double(findword('AIRFOIL_FAMILY','ftn021.dat',main_dir,' '));
cd ..

% Read chord and twist
fid = fopen('ftn021.dat','r');
ch_tw = textscan(fid,'%f%f','Headerlines',4);
r_R = (0.05:0.1:0.95)';
r_R(1) = hub_radius_m/R_m;
c_R = ch_tw{1};
tw_deg = ch_tw{2};

c_m = c_R .* R_m;
r_m = r_R .* R_m;
fclose(fid);

% Read airfoil family
fid = fopen('ftn021.dat','r');
affam = textscan(fid,'%f%f%f','Headerlines',37);
fclose(fid);

r_R_af = affam{1};
af_fam_num = affam{2};

r_af_m = r_R_af .* R_m;
c_af_m = interp1(r_m,c_m,r_af_m,'linear','extrap');
tw_af_deg = interp1(r_m,tw_deg,r_af_m,'linear','extrap');
% keyboard
%% FIX FOR ROOT LOCATION OF PROPID VS AERODYN
r_af_m = r_af_m - hub_radius_m;
r_af_m(2) = 0.0;
r_af_m(end) = blade_radius_m;
%% Make Aerodyne Blade File
fid = fopen(sprintf('%s_AeroDyn_blade.dat',input.filename(1:end-3)),'w');
fprintf(fid,'------- AERODYN v15.00.* BLADE DEFINITION INPUT FILE -------------------------------------\n');
fprintf(fid,sprintf('%s blade aerodynamic parameters\n',input.filename(1:end-3)));
fprintf(fid,'======  Blade Properties =================================================================\n');
fprintf(fid,'         %2.0f   NumBlNds           - Number of blade nodes used in the analysis (-)\n',numel(c_af_m)-1);
fprintf(fid,'  BlSpn        BlCrvAC        BlSwpAC        BlCrvAng       BlTwist        BlChord          BlAFID\n');
fprintf(fid,'   (m)           (m)            (m)            (deg)         (deg)           (m)              (-)\n');

for ii = 2:numel(c_af_m)
    fprintf(fid,'%010.8f\t\t%10.8f\t\t%10.8f\t\t%10.8f\t\t%10.8f\t\t%10.8f\t\t%d\n',...
        r_af_m(ii),0,0,0,tw_af_deg(ii),c_af_m(ii),af_fam_num(ii));
end
fclose(fid);

movefile(sprintf('%s\\%s_AeroDyn_blade.dat',pwd,input.filename(1:end-3)),...
    sprintf('%s\\OutputFiles\\%s',pwd,input.filename(1:end-3)))


% figure(1)
% plot(r_m,c_m,'--b','LineWidth',2)
% hold on
% plot(r_af_m,c_af_m,'--r','LineWidth',2)
% grid on
% axis equal

