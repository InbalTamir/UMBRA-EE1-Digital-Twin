%% fetch_tomorrow_weather.m
% Script to fetch 24-hour weather forecast data from Tomorrow.io
% and save it as a CSV input file for the Digital Twin simulation.

clear; clc;

% --- 1. User Configuration ---
apiKey = 'YOUR_API_KEY_HERE'; % Tomorrow.io API key
lat = 32.1133;                                % Latitude (Tel Aviv University)
lon = 34.8044;                                % Longitude                                % Longitude
scenarioName = 'weather_nominal_24h.csv';     % Output CSV filename

% --- 2. Fetch Data from Tomorrow.io API ---
baseUrl = 'https://api.tomorrow.io/v4/weather/forecast';
url = sprintf('%s?location=%.4f,%.4f&timesteps=1h&units=metric&apikey=%s', ...
    baseUrl, lat, lon, apiKey);

fprintf('Fetching weather data from Tomorrow.io...\n');
options = weboptions('Timeout', 30);
rawData = webread(url, options);

% --- 3. Parse and Process 24-Hour Data ---
hourlyList = rawData.timelines.hourly;
numHours = min(24, length(hourlyList));

Time_UTC    = strings(numHours, 1);
Time_Hours  = (0:numHours-1)';
GHI_Wm2     = zeros(numHours, 1);
Temp_C      = zeros(numHours, 1);
Cloud_Pct   = zeros(numHours, 1);
Wind_ms     = zeros(numHours, 1);
Wind_Dir    = zeros(numHours, 1);

for i = 1:numHours
    entry = hourlyList(i);
    vals  = entry.values;

    Time_UTC(i)  = string(entry.time);
    Temp_C(i)    = getFieldSafe(vals, 'temperature');
    Cloud_Pct(i) = getFieldSafe(vals, 'cloudCover');
    Wind_ms(i)   = getFieldSafe(vals, 'windSpeed');
    Wind_Dir(i)  = getFieldSafe(vals, 'windDirection');

    % Check if solar GHI is returned by the API; if unavailable (Free Tier),
    % estimate GHI from local solar time and cloud cover percentage.
    ghiApi = getFieldSafe(vals, 'solarGHI');
    if ghiApi > 0
        GHI_Wm2(i) = ghiApi;
    else
        % Convert UTC timestamp to local Israel time
        dt = datetime(entry.time(1:19), 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss', 'TimeZone', 'UTC');
        dt.TimeZone = 'Asia/Jerusalem';
        hr = hour(dt) + minute(dt)/60;

        % Clear-sky diurnal irradiance model (Sunrise ~06:30, Sunset ~17:00, Peak ~650 W/m^2)
        if hr > 6.5 && hr < 17.0
            clearSkyGHI = 650 * sin(pi * (hr - 6.5) / (17.0 - 6.5));
            % Attenuate irradiance based on cloud cover percentage
            cloudFactor = 1 - 0.75 * (Cloud_Pct(i) / 100)^1.5;
            GHI_Wm2(i) = clearSkyGHI * cloudFactor;
        else
            GHI_Wm2(i) = 0;
        end
    end
end

% --- 4. Build Table and Export to CSV ---
T = table(Time_Hours, Time_UTC, GHI_Wm2, Temp_C, Cloud_Pct, Wind_ms, Wind_Dir);

outputFolder = fullfile('data', 'weather');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

outputPath = fullfile(outputFolder, scenarioName);
writetable(T, outputPath);

fprintf('Success! Weather file saved to: %s\n', outputPath);
disp(T(1:6, :)); % Display first 6 rows for verification

%% Helper Function: Safe Struct Field Extraction
function val = getFieldSafe(s, fieldName)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    val = double(s.(fieldName));
else
    val = 0;
end
end