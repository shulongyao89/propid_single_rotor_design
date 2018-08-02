function [input] = calcAEP(input)

% V_mps = input.Vcutin_mps:0.5:input.Vcutout_mps;
V_mps = 0:0.25:30;
V_ftps = V_mps * 3.28084;

P_kW = 0.5 .* input.rho_slugspft3 .* ...
    (pi .* (input.R_ft .* cosd(input.cone_deg)) .^ 2) .* (V_ftps) .^ 3 .*...
    input.Cp_at_TSRdes .* 0.001355817948331;

dV_mps = 0.25;
Weibull_k = 2.167;
Vavg_at_50m_mps = 7.87;
alpha = 0.1;
HH_m = 145.6;

Vavg_at_HH_mps = Vavg_at_50m_mps * (HH_m/50)^alpha;% + 1.5;
Weibull_lambda = Vavg_at_HH_mps / gamma(1 + 1/ Weibull_k);
% Weibull_lambda = 1 / gamma(1 + 1/ Weibull_k);

for ii = 1:numel(V_mps)
    binProbs(ii)  = wblcdf(V_mps(ii) + dV_mps/2, Weibull_lambda,Weibull_k) - ...
        wblcdf(V_mps(ii) - dV_mps/2, Weibull_lambda, Weibull_k);
    
    if P_kW(ii) > input.Pdes_kW
        P_kW(ii) = input.Pdes_kW;
    end
    
    if V_mps(ii) < input.Vcutin_mps
        P_kW(ii) = 0;
    elseif V_mps(ii) > input.Vcutout_mps
        P_kW(ii) = 0;
    end
end

input.gaep_calc_MWhr = sum(binProbs .* P_kW) * 8760 / 1000;
% keyboard
% figure(1)
% plot(V_mps,binProbs,'-','LineWidth',1.5)