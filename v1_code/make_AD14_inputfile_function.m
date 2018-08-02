function [input] = make_AD14_inputfile_function(input)

% Note that something is hard coded
hub_radius_m = input.hub_m;

main_dir = pwd;

cd Tools
[convert_lbm2kg, convert_ft2m, convert_degR2degK] = englishtometric();

%% Get data from ftn021 file
[RHO_slugpft2] = str2double(findword('RHO','ftn021.dat',main_dir,' '));
[HUB] = str2double(findword('HUB','ftn021.dat',main_dir,' '));
[R_ft] = str2double(findword('RD','ftn021.dat',main_dir,' '));
R_m = round(R_ft * convert_ft2m,3);
[AIRFOIL_FAMILY_NUM] = str2double(findword('AIRFOIL_FAMILY','ftn021.dat',main_dir,' '));
cd ..

% Read chord and twist
fid = fopen('ftn021.dat','r');
ch_tw = textscan(fid,'%f%f','Headerlines',4);
fclose(fid);
r_R = (0.05:0.1:0.95)'; % setup of chord and twist distribution
c_R = ch_tw{1};
tw_deg = ch_tw{2};

c_m = c_R .* R_m;
r_m = r_R .* R_m;

% Hub Location
c_hub_m = interp1(r_m,c_m,hub_radius_m,'linear','extrap');

%% MOD DESIGN
fid = fopen('ftn021.dat','r');
affam = textscan(fid,'%f%f%f','Headerlines',37);
fclose(fid);

r_R_af = affam{1};
af_fam_num = affam{2};

% For AeroDynv14 file
r_R_af(2) = ((0.1*R_m - hub_radius_m)/2 + hub_radius_m)/R_m;
RNodes = round(r_R_af(2:end-1),5)*R_m;
AeroTwst = interp1(r_m,tw_deg,RNodes,'linear','extrap');
Chord = interp1(r_m,c_m,RNodes,'linear','extrap');
NFoil = af_fam_num(2:end-1);

for ii = 1:numel(RNodes)
    if ii == 1
        DRNodes(ii) = (RNodes(ii)-hub_radius_m)*2;
    else
        DRNodes(ii) = (RNodes(ii) - sum(DRNodes)- hub_radius_m)*2;
    end
end
        
% for ii = 1:numel(RNodes)
%     if ii == 1
%         DRNodes(ii) = 0.1*R_m-hub_radius_m;
%     else
%         DRNodes(ii) = (r_R_af(5)-r_R_af(4))*R_m;
%     end
% end

% figure(2)
% set(gcf, 'Position', [50 100 1000 400]);
% hold on
% plot(r_m,c_m,'b-','LineWidth',1.5)
% plot([hub_radius_m hub_radius_m],[0 c_hub_m],'k','LineWidth',1.5)
% plot(RNodes,Chord/2,'go')
% % plot(r_seg_end_m,c_seg_end_m/2,'g^')
% grid on
% set(gca,'GridLineStyle','-');
% ylim([0 20]);
% xlim([0 110]);
% daspect([0.3/20*110/2 1 1]);
% legend('Original Design','Hub','Node Centers New (v14)')

%% Make Aerodyne Blade File
fid = fopen(sprintf('%s.ipt',input.filename(1:end-3)),'w');
fprintf(fid,'--------- AeroDyn v14.04.* INPUT FILE -------------------------------------------------------------------------\n');
fprintf(fid,sprintf('%s aerodynamic parameters\n',input.filename));
fprintf(fid,'"STEADY"      StallMod     - Dynamic stall included [BEDDOES or STEADY] (unquoted string)\n');
fprintf(fid,'"NO_CM"       UseCm        - Use aerodynamic pitching moment model? [USE_CM or NO_CM] (unquoted string)\n');
fprintf(fid,'"EQUIL"       InfModel     - Inflow model [DYNIN or EQUIL] (unquoted string)\n');
fprintf(fid,'"SWIRL"       IndModel     - Induction-factor model [NONE or WAKE or SWIRL] (unquoted string)\n');
fprintf(fid,'      0.005   AToler       - Induction-factor tolerance (convergence criteria) (-)\n');
fprintf(fid,'"PRANDtl"     TLModel      - Tip-loss model (EQUIL only) [PRANDtl, GTECH, or NONE] (unquoted string)\n');
fprintf(fid,'"PRANDtl"     HLModel      - Hub-loss model (EQUIL only) [PRANdtl or NONE] (unquoted string)\n');
fprintf(fid,'          0   TwrShad      - Tower-shadow velocity deficit (-)\n');
fprintf(fid,'     9999.9   ShadHWid     - Tower-shadow half width (m)\n');
fprintf(fid,'     9999.9   T_Shad_Refpt - Tower-shadow reference point (m)\n');
fprintf(fid,'1.2083406445    AirDens      - Air density (kg/m^3)\n');
fprintf(fid,'1.47715854E-05    KinVisc      - Kinematic air viscosity [CURRENTLY IGNORED] (m^2/sec)\n');
fprintf(fid,'"default"     DTAero       - Time interval for aerodynamic calculations (sec)\n');
fprintf(fid,'          10   NumFoil      - Number of airfoil files (-)\n');
fprintf(fid,'"AeroData/F1_SUMR-25/cylinder_type4.dat"    AFNames            - Airfoil file names (NumAFfiles lines) (quoted strings)\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-4846-1226_cylinder_blend.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-4846-1226.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-3856-0738.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-2655-0262_F1-3856-0738_blend.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-2655-0262.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-2040-0087_F1-2655-0262_blend.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-2040-0087.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-1882-0041_F1-2040-0087_blend.dat"\n');
fprintf(fid,'"AeroData/F1_SUMR-25/F1-1882-0041.dat"\n');
fprintf(fid,'         %2.0f   BldNodes    - Number of blade nodes used for analysis (-)\n',numel(RNodes));
fprintf(fid,'RNodes         AeroTwst       DRNodes        Chord          NFoil          PrnElm\n');

for ii = 1:numel(RNodes)       
    fprintf(fid,'%12.5f  %12.8f  %12.5f  %12.8f  %12d\t\tNOPRINT\n',...
        RNodes(ii), AeroTwst(ii), DRNodes(ii),...
        Chord(ii), NFoil(ii));
end
fclose(fid);

Design_R_m = R_m

input.AD14_R_m = sum(DRNodes)+hub_radius_m;

movefile(sprintf('%s\\%s.ipt',pwd,input.filename(1:end-3)),sprintf('%s\\OutputFiles',pwd))

