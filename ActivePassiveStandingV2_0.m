%% ActivPAL Standing Analysis v2.0
% May 15th 2025
%
% Author: Sophie Rayner

% Before Beginning:
    % Make sure you have PAL analysis v9
    % Ensure sleep and wake times are correctly inputted (see view
    % selection, 'time in bed adjustment' to edit times
% Necessary Files (under Exports):
% 1. ActivPAL Raw Acceleration (Accelerometer) file
    % Under 'Sensor Data Reports', 'Accelerometer' as 'csv file' 
    % 'Uncompressed' 'g format' with daily validation
% 2. ActivPAL Custom Epochs file
    % Under Epoch exports, 'Custom duration epoch' 
    % MUST BE SET TO 5 SECONDS
% 3. ActivPAL Daily Time in Bed file
    % See 'Container Exports'
% 4. ActivPAL Extended events

% Place these files in a folder for each participant, and put each of these
% folders into a main folder.
% When you run the code, select the main folder with all the participant
% folders within
 
% See the READ ME file for instructions on utilizing this code

%%
%Prep the workspace
clearvars;

%Select the folder that contains each participants individual folders
mainfolder = uigetdir(pwd, 'Select the main folder');
subfolders = dir(mainfolder);

%get the names of the subfolders to loop
isSubfolder = [subfolders.isdir]; 
subfolderNames = {subfolders(isSubfolder).name}; 
subfolderNames = subfolderNames(~ismember(subfolderNames, {'.', '..'})); 

maxParticipantsPerLine = 20;

%function for bout analysis
function tempBouts = categorizeBouts(Duration)
    tempBouts.Less10min = Duration(Duration < 600);
    tempBouts.Less15min = Duration(Duration < 900);
    tempBouts.Btwn10_20min = Duration(Duration >= 600 & Duration < 1200);
    tempBouts.Btwn20_30min = Duration(Duration >= 1200 & Duration < 1800);
    tempBouts.Btwn30_40min = Duration(Duration >= 1800 & Duration < 2400);
    tempBouts.Btwn40_50min = Duration(Duration >= 2400 & Duration < 3000);
    tempBouts.Btwn50_60min = Duration(Duration >= 3000 & Duration < 3600);
    tempBouts.Btwn1_2hr = Duration(Duration >= 3600 & Duration < 7200);
    tempBouts.Btwn2_3hr = Duration(Duration >= 7200 & Duration < 14400);
    tempBouts.Btwn3_4hr = Duration(Duration >= 14400 & Duration < 21600);
    tempBouts.Grtr4hr = Duration(Duration >= 21600);
    tempBouts.Less30min = Duration(Duration <= 1800);
    tempBouts.Grtr30min = Duration(Duration > 1800);
    tempBouts.Total = Duration;
end

% Create a cell array of strings where each string is a line of participants
lines = {};
for i = 1:ceil(length(subfolderNames) / maxParticipantsPerLine)
    startIdx = (i - 1) * maxParticipantsPerLine + 1;
    endIdx = min(i * maxParticipantsPerLine, length(subfolderNames));
    lines{end + 1} = strjoin(subfolderNames(startIdx:endIdx), '  ');  % Separate with two spaces
end

% Combine all lines into one string with line breaks
messageText = strjoin(lines, '\n');

% Create and display the message box with the formatted list
Check = msgbox(['Confirm participants being analyzed:' char(10) messageText]);
uiwait(Check);

%User input whether there is valid sleep times (bed ridden = N, young
%healthy or sleep log filled = Y)
SleepCheck = inputdlg("Is there valid sleep time? Y/N, if N, then entire 24hrs will be used");

%add a progress bar
Wait = waitbar(0, 'Processing...');

%----------------------------------------------------------------------%
%% Opening the Files

%create the loop that goes over each subfolder (each participant)
for i = 1:length(subfolderNames)
    progress = (i-1) / length(subfolderNames);
    waitbar(progress, Wait, sprintf('Progress: %d%%', round(progress * 100)));
    
    % Construct full path to the subfolder
    currentSubfolder = fullfile(mainfolder, subfolderNames{i});
    
    % Display the current folder being processed
    fprintf('Processing folder: %s\n', currentSubfolder);


if currentSubfolder ~= 0 
    % Change MATLAB's current directory to the folder
    cd(currentSubfolder);
    fprintf('Current directory changed to: %s\n', currentSubfolder);
    

% Define how each filename should look
AccelFilePattern = fullfile(currentSubfolder, '*Accelerometer.csv');
EpochFilePattern = fullfile(currentSubfolder, '*Epochs5s.csv');
BedFilePattern = fullfile(currentSubfolder, '*DailyTimeInBed.csv');
EventsFilePattern = fullfile(currentSubfolder, '*EventsEx.csv');

% Search for files matching the patterns within the current directory
    AccelFiles = dir(AccelFilePattern);
    EpochFiles = dir(EpochFilePattern);
    BedFiles = dir(BedFilePattern);
    EventsFiles = dir(EventsFilePattern);
    
% Display and load each type of file if found
    if ~isempty(AccelFiles)
        fprintf('Found Accelerometer file:\n');
        for k = 1:length(AccelFiles)
            accelData = readtable(fullfile(currentSubfolder, AccelFiles(k).name),...
                'Delimiter', ';', ...
                'FileType', 'text');
            fprintf('Loaded %s\n', AccelFiles(k).name);
        end
    else
        msgbox(sprintf('No Accelerometer files found in %s\n', currentSubfolder));
    end

    if ~isempty(EpochFiles)
        fprintf('Found Epoch file:\n');
        for k = 1:length(EpochFiles)
            EpochData = readtable(fullfile(currentSubfolder, EpochFiles(k).name),...
                'Delimiter', ';', ...
                'FileType', 'text');
            fprintf('Loaded %s\n', EpochFiles(k).name);
        end
    else
        msgbox(sprintf('No Epoch files found in %s\n Ensure epoch file is 5s averaged.', currentSubfolder));
    end

    if ~isempty(BedFiles)
        fprintf('Found Daily Time In Bed file:\n');
        for k = 1:length(BedFiles)
            bedData = readtable(fullfile(currentSubfolder, BedFiles(k).name),...
                'Delimiter', ';', ...
                'FileType', 'text');
            fprintf('Loaded %s\n', BedFiles(k).name);
        end
    else
        msgbox(sprintf('No Daily Time In Bed files found in %s\n', currentSubfolder));
    end
   
    if ~isempty(EventsFiles)
        fprintf('Found Events file:\n');
        for k = 1:length(EventsFiles)
            EventsData = readtable(fullfile(currentSubfolder, EventsFiles(k).name),...
                'Delimiter', ';', ...
                'FileType', 'text');
            fprintf('Loaded %s\n', EventsFiles(k).name);
        end
    else
        msgbox(sprintf('No Events files found in %s\n', currentSubfolder));
    end

    
else
    msgbox('Folder selection canceled.');
end

%Check variable names for Time in Bed file and convert to standard
newVarNames = {'Var6','Var7', 'Var8' 'Var9', 'Var10', 'Var11', 'Var12', 'Var13', 'Var14'};
bedData.Properties.VariableNames(6:14) = newVarNames;


for j = 1:height(bedData)
    val = bedData{j, 10};
    
    if ~isempty(val) && ~(ischar(val) && strcmp(val, '')) && ~(isstring(val) && strlength(val) == 0)
        break;  % Found a non-empty value; exit loop
    end
end

%Shift the TIB file so wake and sleep times for the same day are on the
%same line
bedData.Var11(j:end-1) = bedData.Var11(j+1:end);
bedData.Var11(end) = {''};
bedData.Var10(j:end-1) = bedData.Var10(j+1:end);
bedData.Var10(end) = {''};

% Add values to participants with no time in bed
if upper(SleepCheck) == "N"
    bedData.Var11(j:end) = {'23:59:59'};  
    bedData.Var13(j:end) = {'00:00:00'}; 
    bedData(j:end, [10]) = bedData(j:end, [7]);
    bedData(j:end, [12]) = bedData(j:end,[7]);
end

%--------------------------------------------------------------------%
% Count the valid days and assign day starts and ends
validdays = bedData(bedData.Var9 == 1, :);

dayscount = sum(validdays{:,9});

% Create cell arrays for the wake and sleep times and days
WakeDays = cell(dayscount,1);
WakeTimes = cell(dayscount,1);
SleepDays = cell(dayscount,1);
SleepTimes = cell(dayscount,1);

%check for multiple empty rows in validdays
columnData = validdays{:,'Var11'}; 
for i = 1:height(validdays)
    if upper(SleepCheck{1}) == "Y" && ismissing(validdays{i,11})
        validdays{i,11} = duration(23,59,59);
        validdays{i,10} = validdays{i,12};
    end
end


%define sleep and wake times
    for i = 1:dayscount
   WakeDays{i,1} = datestr(validdays{i,12}, 'dd mmm yyyy');
   SleepDays{i,1} = datestr(validdays{i,10}, 'dd mmm yyyy');
   WakeTimes{i,1} = char(validdays{i,13}); 
   SleepTimes{i,1} = char(validdays{i,11}); 
    end


%Convert time to the floating format for wake...
WakeDateTime = strcat(WakeDays, {' '}, WakeTimes);
FloatWakeTime = datenum(WakeDateTime, 'dd mmm yyyy HH:MM:SS');
SerialWake = FloatWakeTime - datenum('30-Dec-1899');

%...and sleep
SleepDateTime = strcat(SleepDays, {' '}, SleepTimes);
FloatSleepTime = datenum(SleepDateTime, 'dd mmm yyyy HH:MM:SS');
SerialSleep = FloatSleepTime - datenum('30-Dec-1899');

fprintf(['' ...
    'Sleep and Wake times identified \n']);

% Rename the columns of EpochData'
EpochData.Properties.VariableNames{1} = 'Time';
EpochData.Properties.VariableNames{3} = 'StepCount';
EpochData.Properties.VariableNames{4} = 'ActivityScore_MET_s)';
EpochData.Properties.VariableNames{5} = 'SedentaryTime_s_';
EpochData.Properties.VariableNames{6} = 'UprightTime_s_';
EpochData.Properties.VariableNames{7} = 'SteppingTime_s_';
EpochData.Properties.VariableNames{8} = 'CyclingTime_s_';

%-------------------------------------------------------------------%
% Divide data into these valid days
for i = 1:dayscount
    % Find awake period in accelData
    DayStartIdx = find(accelData.Time >= SerialWake(i), 1, 'first');
    DayEndIdx = find(accelData.Time <= SerialSleep(min(i, dayscount)), 1, 'last');

    % Ensure indices are found
    if isempty(DayStartIdx) || isempty(DayEndIdx)
        warning('Skipping day %d: No matching time found in accelData.', i);
        subsetDayAccel{i} = [];
    else
        subsetDayAccel{i} = accelData(DayStartIdx:DayEndIdx, :);
    end

    % Find awake period in EpochData
    DayStartIdx = find(EpochData.Time >= SerialWake(i), 1, 'first');
    DayEndIdx = find(EpochData.Time <= SerialSleep(min((i), dayscount)), 1, 'last');

    % Ensure indices are found
    if isempty(DayStartIdx) || isempty(DayEndIdx)
        warning('Skipping day %d: No matching time found in EpochData.', i);
        subsetDayEpoch{i} = [];
    else
        subsetDayEpoch{i} = EpochData(DayStartIdx:DayEndIdx, :);
        columnNames = subsetDayEpoch{i}.Properties.VariableNames;
        % Check if the column exists before deleting
        if ismember('Time_approx_', subsetDayEpoch{i}.Properties.VariableNames)
            subsetDayEpoch{i}(:, 'Time_approx_') = [];
        end
    end

    DayStartIdx = find(EventsData.Time >= SerialWake(i), 1, 'first');
    DayEndIdx = find(EventsData.Time <= SerialSleep(min((i), dayscount)), 1, 'last');

    % Ensure indices are found
    if isempty(DayStartIdx) || isempty(DayEndIdx)
        warning('Skipping day %d: No matching time found in EventsData.', i);
        subsetDayEvents{i} = [];
    else
        subsetDayEvents{i} = EventsData(DayStartIdx:DayEndIdx, :);

        % Check if the column exists before deleting
        if ismember('Time_approx_', subsetDayEvents{i}.Properties.VariableNames)
            subsetDayEvents{i}(:, 'Time_approx_') = [];
        end
    end
end

fprintf('Data successfully split by days.\n');
%-----------------------------------------------------------------%
% Filter Acceleration Data

%Lowpass butterworth filter (zeroshift) of the accel data
Fs = 20;  % Sampling rate in Hz 
fc = 0.1; % Cutoff frequency in Hz

% Design a second-order Butterworth low-pass filter
[b, a] = butter(2, fc / (Fs / 2), 'low');

% Apply the filter to each axis (column) for each day (sheet)
for i = 1:length(subsetDayAccel)
    for col = 3:5
    filteredData = filtfilt(b, a, table2array(subsetDayAccel{1, i}(:, col)));
    subsetDayAccel{1, i}.(col) = filteredData;
    end
end

%----------------------------------------------------------------------%
% Prolonged Sedentary Bout Analysis
% Categorize Bouts

for i=1:dayscount;
       
% Extract EventType column
col3 = subsetDayEvents{1, i}.EventType;

% Filter sedentary bouts based on EventType values
SedBout = subsetDayEvents{1, i}(ismember(col3, [0, 3.1, 3.2]), :);
StandBout = subsetDayEvents{1,i}(ismember(col3, [1]), :);

Duration = SedBout.Duration_s_; 

tempBouts = categorizeBouts(SedBout.Duration_s_);
SedBouts.Sorted(i) = {tempBouts};

Duration = StandBout.Duration_s_; 

tempBouts = categorizeBouts(StandBout.Duration_s_);
StandBouts.Sorted(i) = {tempBouts};
end
%----------------------------------------------------------------------%
% Grouping Values by Standing Epochs

% Initialize the output cell array
subsetDayEpochArray = cell(size(subsetDayEpoch));

% Loop through days and convert each table to an array
for i = 1:numel(subsetDayEpoch)
    % Extract the table from the cell and convert to array
    if istable(subsetDayEpoch{i})
       if isdatetime(subsetDayEpoch{i}.(2))
        subsetDayEpoch{i}.(2) = datenum(subsetDayEpoch{i}.(2)); % Convert datetime to double
       end
       subsetDayEpochArray{i} = table2array(subsetDayEpoch{i});
    else
        warning('Skipping invalid content at index %d (Type: %s).', i, class(subsetDayEpoch{i}));
    end
end


% Pre-allocate StandingDayEpoch
StandingDayEpoch = cell(size(subsetDayEpoch));

for i = 1:numel(subsetDayEpoch)
    varNames = subsetDayEpoch{i}.Properties.VariableNames;
    StandingDayEpoch{i} = cell2table(cell(height(subsetDayEpoch{i}), width(subsetDayEpoch{i})), ...
                                     'VariableNames', varNames);
end

% Apply the filtering to each array in subsetDayEpochArray (upright = 5s,
% stepping = 0)
for i = 1:numel(subsetDayEpoch)
    tempTable = subsetDayEpoch{i};
    StandingDayEpoch{i} = tempTable(tempTable.UprightTime_s_ == 5 & ...
                                     tempTable.SteppingTime_s_ == 0 & ...
                                     tempTable.CyclingTime_s_ == 0, :);
end


StandingTreeData = cell(1,dayscount);
varNames = {'Time', 'MeanAP', 'MeanML', 'MeanSI', 'SD_AP', 'SD_ML', 'SD_SI'};

%outer loop: number of days
for j = 1:dayscount
    epochTable = StandingDayEpoch{j};
    accelTable = subsetDayAccel{j};
    accelTimes = table2array(accelTable(:,1));

    numEpochs = height(epochTable);
    StandingTreeData{j} = array2table(nan(numEpochs, 7), 'VariableNames', varNames);

    % Inner loop: iterate through standing epochs
    for i = 1:numEpochs
        % Find the index in subsetDayAccel that matches the epoch time
        Time = epochTable{i,1};
        TempStartIdx = find(accelTimes >= Time, 1, 'first');
        
        % Ensure a valid index is found
        if isempty(TempStartIdx)
            warning('Skipping i = %d, j = %d: No matching index found in subsetDayAccel.', i, j);
            continue;
        end
        
        % Compute TempEndIdx (ensuring it does not exceed available data)
        TempEndIdx = min(TempStartIdx + 100, height(accelTable));

        % Extract acceleration data (ensuring index does not exceed bounds
        TempArray = table2array(accelTable(TempStartIdx:TempEndIdx, :));
     
       
        % Store results in StandingTreeData (example structure)
        StandingTreeData{j}.Time(i) = epochTable{i,1};
        StandingTreeData{j}{i,2} = mean(abs(TempArray(:,3))); % Mean AP
        StandingTreeData{j}{i,3} = mean(abs(TempArray(:,4))); % Mean ML
        StandingTreeData{j}{i,4} = mean(abs(TempArray(:,5))); % Mean SI
        StandingTreeData{j}{i,5} = std(abs(TempArray(:,3)));  % SD AP
        StandingTreeData{j}{i,6} = std(abs(TempArray(:,4)));  % SD ML
        StandingTreeData{j}{i,7} = std(abs(TempArray(:,5)));  % SD SI
    end
end
fprintf(['' ...
    'Decision tree processing... \n'])
%---------------------------------------------------------------------%
% Decision Tree Model 

%create new output value
ActivePassiveStandEpochs = cell(1,width(StandingTreeData));

%needs to run for each value
for j = 1:width(StandingTreeData)
    ActivePassiveStandEpochs{1,j} = zeros(height(StandingTreeData{1,j}), 2);
    for i = 1:height(StandingTreeData{1,j}) 
      
      ActivePassiveStandEpochs{1,j}(i,1) = StandingDayEpoch{1,j}{i,1};

      if StandingTreeData{1,j}{i,2} <= 0.096
            if StandingTreeData{1,j}{i,3} <= 0.101
                ActivePassiveStandEpochs{1,j}(i,2) = 0; %passive
            else
                if StandingTreeData{1,j}{i,2} <= 0.087
                ActivePassiveStandEpochs{1,j}(i,2) = 1; %active
                else 
                    ActivePassiveStandEpochs{1,j}(i,2) = 0; %passive
                end
            end
        elseif StandingTreeData{1,j}{i,3} <= 0.027
            if StandingTreeData{1,j}{i,6} <= 0.023
            ActivePassiveStandEpochs{1,j}(i,2) = 0; %passive
            else
            ActivePassiveStandEpochs{1,j}(i,2) = 1; %active
            end
        elseif StandingTreeData{1,j}{i,5} <= 0.923
            ActivePassiveStandEpochs{1,j}(i,2) = 1; %active
            else
            ActivePassiveStandEpochs{1,j}(i,2) = 0; %passive
        end
    end
end
    

%-------------------------------------------------------------------%
% Add sedentary time, stadning time, walking time, cycling time, etc.

% Pre-allocate StandingDayEpoch
ActivityTimes = table();
SedT = table();
SedN = table();
StandT = table();
StandN = table();

% Count time with each activity type

% Apply the filtering to each array in subsetDayEpochArray
for j = 1:dayscount
    temp = subsetDayEpoch{j};

    colData = subsetDayEvents{1,j}{:,3};  % Extract numeric column

% Apply your logic
sed_condition = ismember(colData(1:end-1), [0, 3.1, 3.2, 5]);
up_condition = ismember(colData(2:end), [1, 2, 2.1]);
matches = sed_condition & up_condition;
STS{j} = sum(matches);

    
% Extract the data from specific columns as numeric arrays
UpTimes = sum(temp{:, 'UprightTime_s_'}) / 60;
StepTimes = sum(temp{:, 'SteppingTime_s_'}) / 60;
StepCount = sum(temp{:, 'StepCount'});
CycleTimes = sum(temp{:, 'CyclingTime_s_'}) / 60;

ActivityTimes = [ActivityTimes; table(j, UpTimes, StepTimes, StepCount, CycleTimes, ...
'VariableNames', {'Day', 'Upright time', 'Stepping time', 'Step Count', 'Cycling time'})];
    
% Swapping the left and right sides of the assignments
if upper(SleepCheck) == "N"
Hour1 = subsetDayEpoch{j}(1:720, :);      % First hour
Hour2 = subsetDayEpoch{j}(721:1440, :);    % Second hour
Hour3 = subsetDayEpoch{j}(1441:2160, :); % Third hour
Hour4 = subsetDayEpoch{j}(2161:2880, :);  % Fourth hour
Hour5 = subsetDayEpoch{j}(2881:3600, :);  % Fifth hour
Hour6 = subsetDayEpoch{j}(3601:4320, :);   % Sixth hour
Hour7 = subsetDayEpoch{j}(4321:5040, :); % Seventh hour
Hour8 = subsetDayEpoch{j}(5041:5760, :); % Eighth hour
Hour9 = subsetDayEpoch{j}(5761:6480, :);  % Ninth hour
Hour10 = subsetDayEpoch{j}(6481:7200, :);   % Tenth hour
Hour11 = subsetDayEpoch{j}(7201:7920, :); % Eleventh hour
Hour12 = subsetDayEpoch{j}(7921:8640, :); % Twelfth hour
Hour13 = subsetDayEpoch{j}(8641:9360, :); % Thirteenth hour
Hour14 = subsetDayEpoch{j}(9361:10080, :); % Fourteenth hour
Hour15 = subsetDayEpoch{j}(10081:10800, :); % Fifteenth hour
Hour16 = subsetDayEpoch{j}(10801:11520, :); % Sixteenth hour
Hour17 = subsetDayEpoch{j}(11521:12240, :); % Seventeenth hour
Hour18 = subsetDayEpoch{j}(12241:12960, :); % Eighteenth hour
Hour19 = subsetDayEpoch{j}(12961:13680, :); % Nineteenth hour
Hour20 = subsetDayEpoch{j}(13681:14400, :); % Twentieth hour
Hour21 = subsetDayEpoch{j}(14401:15120, :); % Twenty-first hour
Hour22 = subsetDayEpoch{j}(15121:15840, :); % Twenty-second hour
Hour23 = subsetDayEpoch{j}(15841:16560, :); % Twenty-third hour
Hour24 = subsetDayEpoch{j}(16561:17280, :); % Twenty-fourth hour

   
   for hour = 1:24
    hour_name = sprintf('Hour%d', hour);  % Dynamically generate the hour name
    SedData = eval([hour_name, '.SedentaryTime_s_']); 
    PrimaryLyingData = eval([hour_name, '.PrimaryLyingTime_s_']);
    SecondaryLyingData = eval([hour_name, '.SecondaryLyingTime_s_']);
    SeatedTransData = eval([hour_name, '.SeatedTransportTime_s_']);

    % Sum all and convert to minutes
    HrSedTimes(hour) = sum(SedData + PrimaryLyingData + SecondaryLyingData + SeatedTransData) / 60;
    upData = eval([hour_name, '.UprightTime_s_']); 
    HrUpTimes(hour) = sum(upData) / 60;
    stepData = eval([hour_name, '.SteppingTime_s_']);
    HrStepTimes(hour) = sum(stepData) / 60;
    stepCountData = eval([hour_name, '.StepCount']);
    HrStepCount(hour) = sum(stepCountData);
    cycleData = eval([hour_name, '.CyclingTime_s_']);
    HrCycleTimes(hour) = sum(cycleData) / 60;
   end

% table to store the results
HourStats = table(HrSedTimes', HrUpTimes', HrStepTimes', HrStepCount', HrCycleTimes', ...
              'VariableNames', {'SedentaryTime_s_', 'UprightTime_s_', 'SteppingTime_s_', 'StepCount', 'CyclingTime_s_'});

AllHourStats{j} = HourStats;

combinedTable = table(); % Initialize empty table

for i = 1:length(AllHourStats)
    dayTable = AllHourStats{i};
    dayTable.Day = repmat(i, height(dayTable), 1);  % Add a Day column
    combinedTable = [combinedTable; dayTable];      % Append
end

% Reorder columns to put "Day" first, optional
combinedTable = movevars(combinedTable, 'Day', 'Before', 1);
rowsPerDay = 24; 
totalRows = height(combinedTable);
combinedTable.Hour = repmat((1:rowsPerDay)', totalRows / rowsPerDay, 1);
combinedTable = movevars(combinedTable, 'Hour', 'Before', 2);
% Calculate averages
averageRow = varfun(@mean, combinedTable, ...
    'InputVariables', {'SedentaryTime_s_', 'UprightTime_s_', ...
    'SteppingTime_s_', 'StepCount', 'CyclingTime_s_'}, ...
    'GroupingVariables', 'Hour');
averageRow.Properties.VariableNames = {'Hour', 'Day','SedentaryTime_s_', 'UprightTime_s_', ...
    'SteppingTime_s_', 'StepCount', 'CyclingTime_s_'};

% Convert averageRow to match combinedTable format
averageRow.Day = repmat("Mean", height(averageRow), 1);  % Add as string array
averageRow = movevars(averageRow, 'Day', 'Before', 'Hour');  % Put Day before Hour

averageRow = struct2table(table2struct(averageRow));  % For display compatibility

% Append average row to combinedTable
combinedTable.Day = string(combinedTable.Day);  % Convert to string for row compatibility
combinedTable = [combinedTable; averageRow];
end


% Define all the bout categories to loop through
categories = {'Less10min', 'Less15min', 'Less30min', 'Grtr30min', ...
              'Btwn10_20min', 'Btwn20_30min', 'Btwn30_40min', 'Btwn40_50min', ...
              'Btwn50_60min', 'Btwn1_2hr', 'Btwn2_3hr', 'Btwn3_4hr', 'Grtr4hr', 'Total'};

% Preallocate tables
SedT = table(); SedN = table();
StandT = table(); StandN = table();

for j = 1:dayscount
    % --- Sedentary Time ---
    SedRow = struct();
    SedRow.Day = j;
    SedRow.TotSed = sum(SedBouts.Sorted{j}.Total) / 60;

    for c = 1:numel(categories)
        cat = categories{c};
        SedRow.([cat 'SedT']) = sum(SedBouts.Sorted{j}.(cat)) / 60;
        SedRow.([cat 'SedN']) = numel(SedBouts.Sorted{j}.(cat));
    end

    %--- Standing Time ---
    StandRow = struct();
    StandRow.Day = j;
    StandRow.TotStand = sum(StandBouts.Sorted{j}.Total) / 60;

    for c = 1:numel(categories)
        cat = categories{c};
        StandRow.([cat 'StandT']) = sum(StandBouts.Sorted{j}.(cat)) / 60;
        StandRow.([cat 'StandN']) = numel(StandBouts.Sorted{j}.(cat));
    end

    % Append to tables
    SedT = [SedT; struct2table(SedRow)];
    StandT = [StandT; struct2table(StandRow)];
end


ActivityRow = ActivityTimes(:,2:5);
SedTRow = SedT(:, 2:end);
SedNRow = SedN(:, 2:end);
StandTRow = StandT(:, 2:end);
StandNRow = StandN(:, 2:end);
end

%-------------------------------------------------------------------%
%Bout categorization



%-------------------------------------------------------------------%
% Organize Output

%create an output cell array (we will convert to table later)
SummarybyDay = {};

%sum the total standing minutes per day by counting epochs and *5 (each epoch is 5s)
for j = 1:(height(ActivityRow))

     
    %temp variables for day 
   innerCell = ActivePassiveStandEpochs{1, j};  
if isempty(innerCell)
    warning('Skipping j = %d: innerCell is empty.', j);
    continue;
end
   tmp = innerCell(:, 2); 

% Convert temp from cell array to numeric array
if isa(tmp, 'cell')
    tmp = cell2mat(tmp); 
end
    numActive(j) = sum(tmp == 1) * 5 / 60;    % Count occurrences of 1
    numPassive(j) = sum(tmp == 0) * 5 / 60;   % Count occurrences of 0


%isolate other activity times to add
UprightTime = ActivityRow{j, 'Upright time'};     % Extract Upright Time
SteppingTime = ActivityRow{j, 'Stepping time'};   % Extract Stepping Time
StepCounts = ActivityRow{j, 'Step Count'};
CyclingTime = ActivityRow{j, 'Cycling time'};
STSnum = STS{j}; 

TotSed = SedT{j,'TotSed'};
Less10minSedT = SedT{j, 'Less10minSedT'};
Less15minSedT = SedT{j, 'Less15minSedT'};
Less30minSedT = SedT{j, 'Less30minSedT'};
Grtr30minSedT = SedT{j, 'Grtr30minSedT'};
Btw10_20minSedT = SedT{j, 'Btwn10_20minSedT'};
Btw20_30minSedT = SedT{j, 'Btwn20_30minSedT'};
Btw30_40minSedT = SedT{j, 'Btwn30_40minSedT'};
Btw40_50minSedT = SedT{j, 'Btwn40_50minSedT'};
Btw50_60minSedT = SedT{j, 'Btwn50_60minSedT'};
Btw1_2hrSedT = SedT{j, 'Btwn1_2hrSedT'};
Btw2_3hrSedT = SedT{j, 'Btwn2_3hrSedT'};
Btw3_4hrSedT = SedT{j, 'Btwn3_4hrSedT'};
Grtr4hrSedT = SedT{j, 'Grtr4hrSedT'};

Less10minSedN = SedT{j, 'Less10minSedN'};
Less15minSedN = SedT{j, 'Less15minSedN'};
Less30minSedN = SedT{j, 'Less30minSedN'};
Grtr30minSedN = SedT{j, 'Grtr30minSedN'};
Btw10_20minSedN = SedT{j, 'Btwn10_20minSedN'};
Btw20_30minSedN = SedT{j, 'Btwn20_30minSedN'};
Btw30_40minSedN = SedT{j, 'Btwn30_40minSedN'};
Btw40_50minSedN = SedT{j, 'Btwn40_50minSedN'};
Btw50_60minSedN = SedT{j, 'Btwn50_60minSedN'};
Btw1_2hrSedN = SedT{j, 'Btwn1_2hrSedN'};
Btw2_3hrSedN = SedT{j, 'Btwn2_3hrSedN'};
Btw3_4hrSedN = SedT{j, 'Btwn3_4hrSedN'};
Grtr4hrSedN = SedT{j, 'Grtr4hrSedN'};

TotStand = StandT{j, 'TotStand'};
Less10minStandT = StandT{j, 'Less10minStandT'};
Less15minStandT = StandT{j, 'Less15minStandT'};
Less30minStandT = StandT{j, 'Less30minStandT'};
Grtr30minStandT = StandT{j, 'Grtr30minStandT'};
Btw10_20minStandT = StandT{j, 'Btwn10_20minStandT'};
Btw20_30minStandT = StandT{j, 'Btwn20_30minStandT'};
Btw30_40minStandT = StandT{j, 'Btwn30_40minStandT'};
Btw40_50minStandT = StandT{j, 'Btwn40_50minStandT'};
Btw50_60minStandT = StandT{j, 'Btwn50_60minStandT'};
Btw1_2hrStandT = StandT{j, 'Btwn1_2hrStandT'};
Btw2_3hrStandT = StandT{j, 'Btwn2_3hrStandT'};
Btw3_4hrStandT = StandT{j, 'Btwn3_4hrStandT'};
Grtr4hrStandT = StandT{j, 'Grtr4hrStandT'};

Less10minStandN = StandT{j, 'Less10minStandN'};
Less15minStandN = StandT{j, 'Less15minStandN'};
Less30minStandN = StandT{j, 'Less30minStandN'};
Grtr30minStandN = StandT{j, 'Grtr30minStandN'};
Btw10_20minStandN = StandT{j, 'Btwn10_20minStandN'};
Btw20_30minStandN = StandT{j, 'Btwn20_30minStandN'};
Btw30_40minStandN = StandT{j, 'Btwn30_40minStandN'};
Btw40_50minStandN = StandT{j, 'Btwn40_50minStandN'};
Btw50_60minStandN = StandT{j, 'Btwn50_60minStandN'};
Btw1_2hrStandN = StandT{j, 'Btwn1_2hrStandN'};
Btw2_3hrStandN = StandT{j, 'Btwn2_3hrStandN'};
Btw3_4hrStandN = StandT{j, 'Btwn3_4hrStandN'};
Grtr4hrStandN = StandT{j, 'Grtr4hrStandN'};


    
    %figure out how much time was spent standing that wasn't an entire
    %epoch
    ExcludedStanding =  (TotStand - (numActive + numPassive));

    %add active/passive standing ratio
    Ratio(j) = numActive(j)/numPassive(j);

  
    %create the summary table
    SummarybyDay{j, 1} = j;
    SummarybyDay{j, 2} = TotSed;
    SummarybyDay{j, 3} = UprightTime;
    SummarybyDay{j, 4} = TotStand;
    SummarybyDay{j, 5} = SteppingTime;
    SummarybyDay{j, 6} = CyclingTime; 
    SummarybyDay{j, 7} = StepCounts;
    SummarybyDay{j, 8} = STS{j};
    SummarybyDay{j, 9} = numActive(j);
    SummarybyDay{j, 10} = numPassive(j);
    SummarybyDay{j, 11} = ExcludedStanding(j);
    SummarybyDay{j, 12} = Ratio(j);

    SedBoutsbyDay{j, 1} = j;
    SedBoutsbyDay{j, 2} = Less10minSedT;
    SedBoutsbyDay{j, 3} = Less15minSedT;
    SedBoutsbyDay{j, 4} = Less30minSedT;
    SedBoutsbyDay{j, 5} = Grtr30minSedT;
    SedBoutsbyDay{j, 6} = Btw10_20minSedT;
    SedBoutsbyDay{j, 7} = Btw20_30minSedT;
    SedBoutsbyDay{j, 8} = Btw30_40minSedT;
    SedBoutsbyDay{j, 9} = Btw40_50minSedT;
    SedBoutsbyDay{j, 10} = Btw50_60minSedT;
    SedBoutsbyDay{j, 11} = Btw1_2hrSedT;
    SedBoutsbyDay{j, 12} = Btw2_3hrSedT;
    SedBoutsbyDay{j, 13} = Btw3_4hrSedT;
    SedBoutsbyDay{j, 14} = Grtr4hrSedT;
    SedBoutsbyDay{j, 15} = Less10minSedN;
    SedBoutsbyDay{j, 16} = Less15minSedN;
    SedBoutsbyDay{j, 17} = Less30minSedN;
    SedBoutsbyDay{j, 18} = Grtr30minSedN;
    SedBoutsbyDay{j, 19} = Btw10_20minSedN;
    SedBoutsbyDay{j, 20} = Btw20_30minSedN;
    SedBoutsbyDay{j, 21} = Btw30_40minSedN;
    SedBoutsbyDay{j, 22} = Btw40_50minSedN;
    SedBoutsbyDay{j, 23} = Btw50_60minSedN;
    SedBoutsbyDay{j, 24} = Btw1_2hrSedN;
    SedBoutsbyDay{j, 25} = Btw2_3hrSedN;
    SedBoutsbyDay{j, 26} = Btw3_4hrSedN;
    SedBoutsbyDay{j, 27} = Grtr4hrSedN;
 
    StandBoutsbyDay{j, 1} = j;
    StandBoutsbyDay{j, 2} = Less10minStandT;
    StandBoutsbyDay{j, 3} = Less15minStandT;
    StandBoutsbyDay{j, 4} = Less30minStandT;
    StandBoutsbyDay{j, 5} = Grtr30minStandT;
    StandBoutsbyDay{j, 6} = Btw10_20minStandT;
    StandBoutsbyDay{j, 7} = Btw20_30minStandT;
    StandBoutsbyDay{j, 8} = Btw30_40minStandT;
    StandBoutsbyDay{j, 9} = Btw40_50minStandT;
    StandBoutsbyDay{j, 10} = Btw50_60minStandT;
    StandBoutsbyDay{j, 11} = Btw1_2hrStandT;
    StandBoutsbyDay{j, 12} = Btw2_3hrStandT;
    StandBoutsbyDay{j, 13} = Btw3_4hrStandT;
    StandBoutsbyDay{j, 14} = Grtr4hrStandT;
    StandBoutsbyDay{j, 15} = Less10minStandN;
    StandBoutsbyDay{j, 16} = Less15minStandN;
    StandBoutsbyDay{j, 17} = Less30minStandN;
    StandBoutsbyDay{j, 18} = Grtr30minStandN;
    StandBoutsbyDay{j, 19} = Btw10_20minStandN;
    StandBoutsbyDay{j, 20} = Btw20_30minStandN;
    StandBoutsbyDay{j, 21} = Btw30_40minStandN;
    StandBoutsbyDay{j, 22} = Btw40_50minStandN;
    StandBoutsbyDay{j, 23} = Btw50_60minStandN;
    StandBoutsbyDay{j, 24} = Btw1_2hrStandN;
    StandBoutsbyDay{j, 25} = Btw2_3hrStandN;
    StandBoutsbyDay{j, 26} = Btw3_4hrStandN;
    StandBoutsbyDay{j, 27} = Grtr4hrStandN; 
end

%calculate means, SD, and average real variability for each column
temp = cell2mat(SummarybyDay);
Means = mean(temp(:, 2:12), 1);
Means = num2cell(Means);
SDs = std(temp(:,2:12), 1);
SDs = num2cell(SDs);
differences = abs(diff(temp(:,2:12)));
  ARV = mean(differences);
    ARV = num2cell(ARV);
if ~iscell(Means)
   Means = num2cell(Means);  % Convert numeric array to cell array
end

if ~iscell(SDs)
    SDs = num2cell(SDs);  % Convert numeric array to cell array
end
if ~iscell(ARV)
   ARV = num2cell(ARV);  % Convert numeric array to cell array
end

[SummarybyDay{dayscount+2,2:end}] = Means{:};
[SummarybyDay{dayscount+3,2:end}] = SDs{:};
if dayscount >= 3
    % Perform ARV assignment if dayscount is greater than or equal to 3
    [SummarybyDay{dayscount+4, 2:end}] = ARV{:};
    SummarybyDay{dayscount+2,1} = 'Mean';
    SummarybyDay{dayscount+3,1} = 'StDev';
    SummarybyDay{dayscount+4,1} = 'ARV';
else
    disp('Insufficient dayscount (< 3), skipping ARV assignment...');
    SummarybyDay{dayscount+2,1} = 'Mean';
    SummarybyDay{dayscount+3,1} = 'StDev';
end

temp = cell2mat(SedBoutsbyDay);
Means = mean(temp(:, 2:27), 1);
Means = num2cell(Means);
SDs = std(temp(:,2:27), 1);
SDs = num2cell(SDs);
differences = abs(diff(temp(:,2:27)));
  ARV = mean(differences);
    ARV = num2cell(ARV);
if ~iscell(Means)
   Means = num2cell(Means);  % Convert numeric array to cell array
end

if ~iscell(SDs)
    SDs = num2cell(SDs);  % Convert numeric array to cell array
end
if ~iscell(ARV)
   ARV = num2cell(ARV);  % Convert numeric array to cell array
end

[SedBoutsbyDay{dayscount+2,2:end}] = Means{:};
[SedBoutsbyDay{dayscount+3,2:end}] = SDs{:};
if dayscount >= 3
    % Perform ARV assignment if dayscount is greater than or equal to 3
    [SedBoutsbyDay{dayscount+4, 2:end}] = ARV{:};
    SedBoutsbyDay{dayscount+2,1} = 'Mean';
    SedBoutsbyDay{dayscount+3,1} = 'StDev';
    SedBoutsbyDay{dayscount+4,1} = 'ARV';
else
    disp('Insufficient dayscount (< 3), skipping ARV assignment...');
    SedBoutsbyDay{dayscount+2,1} = 'Mean';
    SedBoutsbyDay{dayscount+3,1} = 'StDev';
end
    
temp = cell2mat(StandBoutsbyDay);
Means = mean(temp(:, 2:27), 1);
Means = num2cell(Means);
SDs = std(temp(:,2:27), 1);
SDs = num2cell(SDs);

differences = abs(diff(temp(:,2:27)));
  ARV = mean(differences);
    ARV = num2cell(ARV);
if ~iscell(Means)
   Means = num2cell(Means);  % Convert numeric array to cell array
end

if ~iscell(SDs)
    SDs = num2cell(SDs);  % Convert numeric array to cell array
end
if ~iscell(ARV)
   ARV = num2cell(ARV);  % Convert numeric array to cell array
end

[StandBoutsbyDay{dayscount+2,2:end}] = Means{:};
[StandBoutsbyDay{dayscount+3,2:end}] = SDs{:};
if dayscount >= 3
    % Perform ARV assignment if dayscount is greater than or equal to 3
    [StandBoutsbyDay{dayscount+4, 2:end}] = ARV{:};
    StandBoutsbyDay{dayscount+2,1} = 'Mean';
    StandBoutsbyDay{dayscount+3,1} = 'StDev';
    StandBoutsbyDay{dayscount+4,1} = 'ARV';
else
    disp('Insufficient dayscount (< 3), skipping ARV assignment...');
    StandBoutsbyDay{dayscount+2,1} = 'Mean';
    StandBoutsbyDay{dayscount+3,1} = 'StDev';
end

%convert to table for excel export
ExportP1 = cell2table(SummarybyDay, 'VariableNames', {'Day', 'Total Sedentary (m/day)', ...
    'Total Upright (m/day)', 'Total Standing (m/day)', 'Total Stepping (m/day)',...
    'Total Cycling (m/day)', 'Step Count','Sit-to-stand transitions','ActiveStand m/day', ...
    'PassiveStand m/day', 'ShortStand m/day', 'Active/Passive Ratio'});
   
ExportP2 = cell2table(SedBoutsbyDay, 'VariableNames', {'Day', 'Less10minSedT',...
    'Less15minSedT', 'Less30minSedT', 'Ovr30minSedT', 'Btw10_20minSedT', ...
    'Btw20_30minSedT', 'Btw30_40minSedT','Btw40_50minSedT', 'Btw50_60minSedT',...
    'Btw1_2hrSedT', 'Btw2_3hrSedT','Btw3_4hrSedT', 'Ovr4hrSedT','Less10minSedN',...
    'Less15minSedN','Less30minSedN', 'Ovr30minSedN', 'Btw10_20minSedN', 'Btw20_30minSedN', ...
   'Btw30_40minSedN', 'Btw40_50minSedN', 'Btw50_60minSedN', 'Btw1_2hrSedN', ...
   'Btw2_3hrSedN', 'Btw3_4hrSedN', 'Ovr4hrSedN'});

ExportP3 = cell2table(StandBoutsbyDay, 'VariableNames', {'Day',  'Less10minStandT',...
    'Less15minStandT', 'Less30minStandT', 'Ovr30minStandT', 'Btw10_20minStandT',...
   'Btw20_30minStandT', 'Btw30_40minStandT', 'Btw40_50minStandT', 'Btw50_60minStandT', ...
   'Btw1_2hrStandT', 'Btw2_3hrStandT', 'Btw3_4hrStandT', 'Ovr4hrStandT', ...
   'Less10minStandN', 'Less15minStandN', 'Less30minStandN', 'Ovr30minStandN',...
   'Btw10_20minStandN', 'Btw20_30minStandN', 'Btw30_40minStandN', 'Btw40_50minStandN',...
   'Btw50_60minStandN', 'Btw1_2hrStandN', 'Btw2_3hrStandN', 'Btw3_4hrStandN', 'Ovr4HrStandN'});

 %-------------------------------------------------------------------%
% Write Output Files

Participantcode = table2cell(validdays(1,4));

Filename = sprintf('%s_ActivPAL_CompleteBreakdown.xlsx', Participantcode{1});

clearvars Participantcode 

Filepath = fullfile(mainfolder, Filename);


writetable(ExportP1, Filename, 'Sheet', 'Summary_Data');
writetable(ExportP2, Filename, 'Sheet', 'Sedentary_Bouts');
writetable(ExportP3, Filename, 'Sheet', 'Standing_Bouts');
fprintf(['' ...
    'Saved file: %s\n'], Filepath);

%clearvars -except SleepCheck mainfolder filepath subfolders subfolderNames Wait
if upper(SleepCheck) == "N"
Participantcode = table2cell(validdays(1,4));
Filename = sprintf('%s_ActivPAL_HourlyBreakdown.csv', Participantcode{1});
Filepath = fullfile(mainfolder, Filename);
    writetable(combinedTable,Filename);
end
end

%finish up
close(Wait);
Done = msgbox('Analysis Complete');




