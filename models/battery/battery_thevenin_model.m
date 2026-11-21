
function [SOC_next, V_terminal, V_RC_next] = battery_thevenin_model(SOC, V_RC, I_batt, dt, params)
% BATTERY_THEVENIN_MODEL
% First-order Thevenin battery model (Mock parameters).
%
% Sign convention:
% I_batt > 0 : battery charging
% I_batt < 0 : battery discharging
%
% SOC is represented as a fraction between 0 and 1.
% V_RC is the RC polarization voltage in volts.

% Read battery parameters
Q_Ah = params.capacity_Ah;
R0 = params.R0_ohm;
R1 = params.R1_ohm;
C1 = params.C1_F;

% Initial OCV approximation (Mock, not calibrated)
OCV = params.OCV_min_V + ...
    (params.OCV_max_V - params.OCV_min_V) * SOC;

% Update SOC using Coulomb Counting
SOC_next = SOC + (I_batt * dt) / (Q_Ah * 3600);
SOC_next = min(1, max(0, SOC_next));

% Update RC branch voltage
tau = R1 * C1;
alpha = exp(-dt / tau);

% Positive V_RC represents discharge polarization
V_RC_next = alpha * V_RC - R1 * (1 - alpha) * I_batt;

% Calculate terminal voltage at the updated state
OCV_next = params.OCV_min_V + ...
    (params.OCV_max_V - params.OCV_min_V) * SOC_next;

V_terminal = OCV_next + I_batt * R0 - V_RC_next;

end
