
%% EE-1 Battery Thevenin Model - Automated Tests
% Initial Mock model verification
% Positive current = charging
% Negative current = discharging

clear;
clc;
close all;

project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_root, 'models', 'battery'));

%% Mock parameters (not calibrated)
params.capacity_Ah = 400 / 22.2;
params.R0_ohm = 0.05;
params.R1_ohm = 0.02;
params.C1_F = 2000;
params.OCV_min_V = 18.0;
params.OCV_max_V = 25.2;

dt = 1;
SOC0 = 0.80;
V_RC0 = 0;

%% Test 1 - Discharge
[soc_dis, v_dis, rc_dis] = ...
    battery_thevenin_model(SOC0, V_RC0, -5, dt, params);

assert(abs(soc_dis - 0.799923) < 1e-6, ...
    'FAIL: Discharge SOC');
assert(abs(v_dis - 23.5070) < 1e-3, ...
    'FAIL: Discharge terminal voltage');
assert(rc_dis > 0, ...
    'FAIL: Discharge RC voltage sign');

fprintf('PASS: Test 1 - Discharge\n');

%% Test 2 - Charge
[soc_chg, v_chg, rc_chg] = ...
    battery_thevenin_model(SOC0, V_RC0, 5, dt, params);

assert(abs(soc_chg - 0.800077) < 1e-6, ...
    'FAIL: Charge SOC');
assert(abs(v_chg - 24.0130) < 1e-3, ...
    'FAIL: Charge terminal voltage');
assert(rc_chg < 0, ...
    'FAIL: Charge RC voltage sign');

fprintf('PASS: Test 2 - Charge\n');

%% Test 3 - Dynamic discharge/charge sequence
% 300 seconds discharge followed by 300 seconds charge

t = 0:dt:600;
N = numel(t);

SOC = SOC0;
V_RC = V_RC0;

SOC_history = zeros(1, N);
V_history = zeros(1, N);
I_history = zeros(1, N);

SOC_history(1) = SOC0;

for k = 1:N-1

    if t(k) < 300
        I_batt = -5;
    else
        I_batt = 5;
    end

    [SOC, V_terminal, V_RC] = ...
        battery_thevenin_model(SOC, V_RC, I_batt, dt, params);

    SOC_history(k+1) = SOC;
    V_history(k+1) = V_terminal;
    I_history(k) = I_batt;
end

I_history(end) = I_history(end-1);
V_history(1) = params.OCV_min_V + ...
    (params.OCV_max_V - params.OCV_min_V) * SOC0;

assert(abs(SOC - SOC0) < 1e-10, ...
    'FAIL: Final SOC did not return to initial value');

assert(SOC_history(301) < SOC0, ...
    'FAIL: SOC did not decrease during discharge');

assert(V_history(302) > V_history(301), ...
    'FAIL: Terminal voltage did not increase after charging');

fprintf('PASS: Test 3 - Dynamic sequence\n');

%% Test 4 - SOC boundaries
[soc_max, ~, ~] = ...
    battery_thevenin_model(1, 0, 5, dt, params);

[soc_min, ~, ~] = ...
    battery_thevenin_model(0, 0, -5, dt, params);

assert(soc_max == 1 && soc_min == 0, ...
    'FAIL: SOC boundaries');

fprintf('PASS: Test 4 - SOC boundaries\n');

%% Plot results
figure('Name', 'EE-1 Battery Thevenin - Mock Tests');

subplot(3,1,1);
stairs(t, I_history, 'LineWidth', 1.5);
ylabel('Current [A]');
title('Battery Thevenin Model - Mock Verification');
grid on;

subplot(3,1,2);
plot(t, SOC_history * 100, 'LineWidth', 1.5);
ylabel('SOC [%]');
grid on;

subplot(3,1,3);
plot(t, V_history, 'LineWidth', 1.5);
ylabel('Voltage [V]');
xlabel('Time [s]');
grid on;

fprintf('\nALL BATTERY TESTS PASSED\n');
fprintf('Final SOC: %.4f %%\n', SOC * 100);
