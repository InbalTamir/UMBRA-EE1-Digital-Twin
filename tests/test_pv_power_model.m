
%% EE-1 | PV Model Basic Verification Tests
% Model status: Mock / Uncalibrated

clear; clc;

% Locate project root and PV model
project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_root, 'models', 'pv'));

% Test inputs
G_test = [0, 200, 500, 800, 1000];

% Calculate PV output
P_test = pv_power_model(G_test, 0.60, 0.25, 0.95);

% Expected results
P_expected = [0, 28.5, 71.25, 114, 142.5];

% Verify results
assert(all(abs(P_test - P_expected) < 1e-10), ...
    'FAIL: PV power does not match expected values.');

assert(P_test(1) == 0, ...
    'FAIL: PV output must be zero at zero irradiance.');

assert(all(diff(P_test) >= 0), ...
    'FAIL: PV power must increase with irradiance.');

disp(table(G_test(:), P_test(:), ...
    'VariableNames', {'Irradiance_W_m2', 'PV_Power_W'}));

fprintf('PASS: All PV basic verification tests.\n');


%% PV Temperature Verification
% Mock temperature coefficient - not calibrated.

G = 800;
A = 0.60;
eta_pv = 0.25;
eta_mppt = 0.95;
gamma_p = -0.004;

P_25 = pv_power_model(G, A, eta_pv, eta_mppt, 25, gamma_p);
P_45 = pv_power_model(G, A, eta_pv, eta_mppt, 45, gamma_p);
P_60 = pv_power_model(G, A, eta_pv, eta_mppt, 60, gamma_p);

assert(abs(P_25 - 114.00) < 1e-10, ...
    'FAIL: Incorrect PV power at 25 C.');

assert(abs(P_45 - 104.88) < 1e-10, ...
    'FAIL: Incorrect PV power at 45 C.');

assert(abs(P_60 - 98.04) < 1e-10, ...
    'FAIL: Incorrect PV power at 60 C.');

assert(P_25 > P_45 && P_45 > P_60, ...
    'FAIL: PV power should decrease with rising temperature.');

fprintf('PASS: PV temperature verification tests.\n');
