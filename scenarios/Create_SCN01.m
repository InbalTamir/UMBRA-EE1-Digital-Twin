
%% EE-1 | Create Initial Scenario Configuration
% Synthetic 24-hour development scenario.
% Reference parameters are preliminary and not calibrated.

scenario = struct();

scenario.id = 'SCN-01';
scenario.name = 'Initial_24h_Energy_Balance';
scenario.version = '0.1';
scenario.status = 'Mock';

% Simulation settings
scenario.simulation.duration_s = 24 * 3600;
scenario.simulation.dt_s = 0.1;

% PV system
scenario.pv.area_m2 = 0.60;
scenario.pv.efficiency = 0.25;
scenario.pv.mppt_efficiency = 0.95;

% Battery
scenario.battery.nominal_energy_Wh = 400;
scenario.battery.initial_soc_pct = 100;
scenario.battery.reserve_soc_pct = 20;

% Synthetic solar irradiance profile
scenario.environment.sunrise_h = 6;
scenario.environment.solar_noon_h = 12;
scenario.environment.sunset_h = 18;
scenario.environment.peak_irradiance_W_m2 = 950;

% Constant mock electrical loads
scenario.loads.propulsion_W = 55.48;
scenario.loads.avionics_W = 35;
scenario.loads.auxiliary_W = 5;

% Data provenance
scenario.provenance.pv_area = 'UMBRA-3 reference range; midpoint';
scenario.provenance.battery_energy = 'UMBRA-3 reference range; midpoint';
scenario.provenance.other_parameters = 'Synthetic / uncalibrated';

jsonText = jsonencode(scenario, PrettyPrint=true);

fid = fopen('SCN-01_Initial_24h_Mock.json', 'w');
assert(fid ~= -1, 'Could not create scenario file.');
fprintf(fid, '%s\n', jsonText);
fclose(fid);

disp('Scenario file created successfully.');
