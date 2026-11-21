
function P_PV = pv_power_model(G_irradiance, A_pv, eta_pv, eta_mppt, T_cell_C, gamma_p)
% PV_POWER_MODEL - Simplified PV model with optional temperature correction
%
% Inputs:
%   G_irradiance [W/m^2] - Solar irradiance
%   A_pv         [m^2]   - Active PV area
%   eta_pv       [-]     - PV efficiency at reference temperature
%   eta_mppt     [-]     - MPPT and wiring efficiency
%   T_cell_C     [degC]  - PV cell temperature (optional)
%   gamma_p      [1/degC]- Relative power temperature coefficient (optional)
%
% Output:
%   P_PV         [W]     - Available DC power after MPPT
%
% Status: Preliminary / Uncalibrated
% Reference temperature: 25 degC
% gamma_p should come from PV datasheet or EE-2 measurements.

% Backward compatibility with the original four-input model
if nargin < 5 || isempty(T_cell_C)
    T_cell_C = 25;
end

if nargin < 6 || isempty(gamma_p)
    gamma_p = 0;
end

validateattributes(G_irradiance, {'numeric'}, ...
    {'real', 'finite', 'nonnegative'});

validateattributes(A_pv, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

validateattributes(eta_pv, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 1});

validateattributes(eta_mppt, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 1});

validateattributes(T_cell_C, {'numeric'}, ...
    {'real', 'finite'});

validateattributes(gamma_p, {'numeric'}, ...
    {'scalar', 'real', 'finite'});

% Temperature correction relative to 25 degC
temperature_factor = 1 + gamma_p .* (T_cell_C - 25);
temperature_factor = max(0, temperature_factor);

% PV electrical output after MPPT
P_PV = G_irradiance .* A_pv .* eta_pv .* ...
    eta_mppt .* temperature_factor;
end
