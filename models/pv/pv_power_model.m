
function P_PV = pv_power_model(G_irradiance, A_pv, eta_pv, eta_mppt)
% PV_POWER_MODEL - Simplified PV and MPPT power model
%
% Inputs:
%   G_irradiance [W/m^2] - Solar irradiance
%   A_pv         [m^2]   - Active PV area
%   eta_pv       [-]     - PV efficiency
%   eta_mppt     [-]     - MPPT and wiring efficiency
%
% Output:
%   P_PV         [W]     - Available DC power after MPPT
%
% Model status: Mock / Uncalibrated
% Assumptions: Constant efficiencies, no temperature effects.

validateattributes(G_irradiance, {'numeric'}, ...
    {'real', 'finite', 'nonnegative'});

validateattributes(A_pv, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

validateattributes(eta_pv, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 1});

validateattributes(eta_mppt, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 1});

P_PV = G_irradiance .* A_pv .* eta_pv .* eta_mppt;
end
