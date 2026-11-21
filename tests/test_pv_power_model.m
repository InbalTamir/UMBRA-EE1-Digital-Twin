
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
