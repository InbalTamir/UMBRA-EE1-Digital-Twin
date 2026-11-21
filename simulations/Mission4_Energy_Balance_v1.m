%% UMBRA 1.5 / UMBRA-3 | Team EE-1
% Mission 4: 24-Hour Energy Balance & SOC Simulation (Baseline SRR)
clear; clc; close all;

%% Load Scenario Configuration
project_root = fileparts(fileparts(mfilename('fullpath')));

scenario_path = fullfile(project_root, 'scenarios', ...
    'SCN-01_Initial_24h_Mock.json');

scenario = jsondecode(fileread(scenario_path));

fprintf('Loaded scenario: %s (version %s)\n', ...
    scenario.id, scenario.version);


addpath(fullfile(project_root, 'models', 'pv'));

%% Load EE-2 and EE-4 Mock Interfaces

interface_path = fullfile(project_root, ...
    'docs', 'interfaces', 'EE1_Mock_Interfaces.m');

run(interface_path);

% Check consistency with SCN-01
assert(EE2.battery_energy_Wh == scenario.battery.nominal_energy_Wh, ...
    'EE-2 battery energy does not match SCN-01');

assert(abs(EE2.initial_SOC * 100 - scenario.battery.initial_soc_pct) < 1e-9, ...
    'EE-2 initial SOC does not match SCN-01');

assert(EE4.avionics_power_W == scenario.loads.avionics_W, ...
    'EE-4 avionics power does not match SCN-01');

assert(EE4.auxiliary_power_W == scenario.loads.auxiliary_W, ...
    'EE-4 auxiliary power does not match SCN-01');

fprintf('PASS: EE-2 / EE-4 Mock interface consistency check.\n');
%% 1. Scenario Parameters (SCN-01 Mock)

% Simulation
dt = scenario.simulation.dt_s;
duration_h = scenario.simulation.duration_s / 3600;
t_hours = 0:(dt/3600):duration_h;
N = length(t_hours);

% PV and MPPT
A_pv = scenario.pv.area_m2;
eta_pv = scenario.pv.efficiency;
eta_mppt = scenario.pv.mppt_efficiency;

% Battery parameters received from EE-2 Mock interface
E_bat_nom = EE2.battery_energy_Wh;
SOC_init = EE2.initial_SOC * 100;

% Mission reserve threshold remains defined by SCN-01
SOC_reserve = scenario.battery.reserve_soc_pct;

% Electrical loads
P_prop_cruise = scenario.loads.propulsion_W;
% Electrical loads received from EE-4 Mock interface
P_avionics = EE4.avionics_power_W;
P_aux = EE4.auxiliary_power_W;


%% 2. Solar Irradiance Profile (24-Hour Synthetic Clear-Sky Day)
% Sunrise at 06:00, Solar Noon at 12:00 (Peak 950 W/m^2), Sunset at 18:00

% Solar irradiance parameters from scenario
sunrise_h = scenario.environment.sunrise_h;
sunset_h = scenario.environment.sunset_h;
peak_G = scenario.environment.peak_irradiance_W_m2;

% Synthetic clear-sky irradiance profile
G_irradiance = zeros(1, N);

day_idx = (t_hours >= sunrise_h) & (t_hours <= sunset_h);

G_irradiance(day_idx) = peak_G * ...
    sin(pi * (t_hours(day_idx) - sunrise_h) / ...
    (sunset_h - sunrise_h));

%% 3. Power Balance & State Integration

T_cell_C = scenario.pv.cell_temperature_C;
gamma_p = scenario.pv.temperature_coefficient_per_C;

P_PV = pv_power_model(G_irradiance, A_pv, eta_pv, eta_mppt, T_cell_C, gamma_p);

P_load = (P_prop_cruise + P_avionics + P_aux) * ones(1, N); % [W] Total load
P_net = P_PV - P_load;                            % [W] Net power balance

% Cumulative Energy & SOC Integration (Trapezoidal / Euler at 10 Hz)
E_net_Wh = cumtrapz(t_hours, P_net);              % [Wh] Net cumulative energy
E_bat_Wh = zeros(1, N);
E_bat_Wh(1) = E_bat_nom * (SOC_init / 100);


%% Battery Energy Integration with Physical Limits
P_unserved = zeros(1, N);
P_curtailed = zeros(1, N);

for k = 2:N
    dE_requested = P_net(k) * (dt / 3600);
    E_requested = E_bat_Wh(k-1) + dE_requested;

    E_bat_Wh(k) = min(E_bat_nom, max(0, E_requested));

    if E_requested < 0
        P_unserved(k) = -E_requested * 3600 / dt;
    elseif E_requested > E_bat_nom
        P_curtailed(k) = (E_requested - E_bat_nom) * 3600 / dt;
    end
end


%% Energy Deficit Detection
% Detect when the battery is empty and PV cannot supply the load.
SOC = (E_bat_Wh / E_bat_nom) * 100;


%% Energy Accounting Summary
E_unserved_Wh = sum(P_unserved) * dt / 3600;
E_curtailed_Wh = sum(P_curtailed) * dt / 3600;

fprintf('\nTotal unserved energy: %.2f Wh\n', E_unserved_Wh);
fprintf('Total curtailed PV energy: %.2f Wh\n', E_curtailed_Wh);


%% Energy Conservation Check
E_PV_total = trapz(t_hours, P_PV);
E_load_total = trapz(t_hours, P_load);

E_initial = E_bat_nom * SOC_init / 100;
E_final = E_bat_Wh(end);

energy_residual = E_PV_total + E_initial + E_unserved_Wh ...
    - E_load_total - E_final - E_curtailed_Wh;

fprintf('Energy conservation residual: %.6f Wh\n', energy_residual);

if abs(energy_residual) < 0.1
    fprintf('PASS: Energy conservation check.\n');
else
    fprintf('WARNING: Energy conservation check failed.\n');
end


energy_failure = (SOC <= 0) & (P_net < 0);

if any(energy_failure)
    first_failure_idx = find(energy_failure, 1, 'first');

    fprintf('\nWARNING: Energy supply failure detected!\n');
    fprintf('First failure at t = %.2f hours\n', ...
        t_hours(first_failure_idx));
    fprintf('Unmet power demand at failure = %.2f W\n', ...
        -P_net(first_failure_idx));
else
    fprintf('\nNo energy supply failure detected.\n');
end
Energy_Margin_Wh = E_bat_Wh - (E_bat_nom * (SOC_reserve / 100)); % [Wh]

%% Initial SIL Scenario Acceptance Checks
% SCN-01 is a synthetic 24-hour stress-test scenario.
% Supply failure is an expected result, not a MATLAB execution failure.

assert(all(isfinite(SOC)), ...
    'FAIL: SOC contains non-finite values');

assert(all(SOC >= -1e-9 & SOC <= 100 + 1e-9), ...
    'FAIL: SOC outside physical bounds');

assert(abs(energy_residual) < 0.1, ...
    'FAIL: Energy conservation residual exceeds tolerance');

assert(any(energy_failure), ...
    'FAIL: Expected energy shortage was not detected');

fprintf('PASS: SCN-01 initial SIL acceptance checks.\n');

%% 4. Console Summary for Milestone Review
fprintf('=== EE-1 Mission 4 (24h Baseline Simulation) Summary ===\n');
fprintf('Total PV Energy Generated:   %.2f Wh\n', trapz(t_hours, P_PV));
fprintf('Total Energy Consumed:       %.2f Wh\n', trapz(t_hours, P_load));
fprintf('Minimum SOC Reached:         %.2f %% (at t = %.2f h)\n', min(SOC), t_hours(find(SOC == min(SOC), 1)));
fprintf('Final SOC (at t = 24h):      %.2f %%\n', SOC(end));
fprintf('Minimum Energy Margin:       %.2f Wh\n', min(Energy_Margin_Wh));

%% 5. Visualization (3-Subplot Dashboard)
figure('Name', 'UMBRA EE-1 | 24h Energy Balance Simulation', 'Color', 'w', 'Position', [100, 100, 1000, 720]);

% Subplot 1: PV Generation vs. Load Consumption
subplot(3,1,1);
plot(t_hours, P_PV, 'Color', [0.93 0.69 0.13], 'LineWidth', 2); hold on;
plot(t_hours, P_load, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.8);
ylabel('Power [W]');
title('UMBRA EE-1: 24-Hour Power Generation (P_{PV}) vs. Total Load (P_{load})');
legend('P_{PV} (Solar Output)', 'P_{load} (Prop + Avionics + Aux)', 'Location', 'northeast');
grid on; xlim([0 24]); xticks(0:2:24);

% Subplot 2: Net Power Balance (P_net)
subplot(3,1,2);
plot(t_hours, P_net, 'Color', [0.00 0.45 0.74], 'LineWidth', 1.8); hold on;
yline(0, 'k--', 'LineWidth', 1);
ylabel('P_{net} [W]');
title('Instantaneous Net Power Balance (P_{net} = P_{PV} - P_{load})');
legend('P_{net}', 'Zero Balance Line', 'Location', 'northeast');
grid on; xlim([0 24]); xticks(0:2:24);

% Subplot 3: Battery State of Charge (SOC) & Reserve Margin
subplot(3,1,3);
plot(t_hours, SOC, 'Color', [0.18 0.55 0.34], 'LineWidth', 2.2); hold on;
yline(SOC_reserve, 'r--', 'LineWidth', 1.5);
ylabel('SOC [%]'); xlabel('Mission Time [hours]');
title('Battery State of Charge (SOC) vs. Minimum Safety Reserve (20%)');
legend('SOC [%]', 'Safety Reserve Threshold (20%)', 'Location', 'southwest');
ylim([0 105]); grid on; xlim([0 24]); xticks(0:2:24);