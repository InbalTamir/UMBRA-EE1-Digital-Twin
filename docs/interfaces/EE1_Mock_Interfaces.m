
%% EE-1 Mock Interface Definitions
% UMBRA-3 Mission Energy Digital Twin
% Status: MOCK - Not validated against team measurements
%
% EE-2 -> EE-1: Battery-related inputs
% EE-4 -> EE-1: Avionics and electrical load inputs
%
% Interface definitions for initial SIL demonstration.
% These values are placeholders, not approved ICD data.

%% EE-2 Battery Interface
EE2.battery_energy_Wh = 400;
EE2.nominal_voltage_V = 22.2;
EE2.initial_SOC = 1.0;
EE2.cell_temperature_C = 25;

% Thevenin parameters - Mock
EE2.R0_ohm = 0.05;
EE2.R1_ohm = 0.02;
EE2.C1_F = 2000;

%% EE-4 Avionics Interface
EE4.avionics_power_W = 35;
EE4.auxiliary_power_W = 5;

%% Interface metadata
interface_status = 'Mock';
interface_version = '0.1';

disp('EE-2 and EE-4 Mock interfaces loaded successfully');
