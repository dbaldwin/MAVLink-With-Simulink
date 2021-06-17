function create_sfun_decode(filenames, sys_id, comp_id)
% CREATE_SFUN_DECODE: Create and compile the S-function to decode MAVLink
% messages from an incoming MAVLink stream
%
% Inputs:
%   filenames: strings containing the full path to the MAVLink messages
%             header file names. These files must be created as a part of a
%             single MAVLink dialect, and must reside in the directory 
%             structure of the corresponding dialect. In other words, the
%             directory containing this message file must also contain the
%             "mavlink.h" file, and its parent directory must contain the
%             other commond mavlink files such as "protocol.h".
% 
%             NOTE: To ensure compiler independence, provide the full paths
%                   of the message files, and not relative paths.
% 
%   sys_id:   MAVLink SYSID to be used for Simulink (default 100)
%   comp_id:  MAVLink COMPID to be used for Simulink (default 200)
%
% Output:
%   This function creates the Simulink buses, the s-function header files,
%   the s-function source file, and finally compiles the s-function.
%
%Part of the Simulink MAVLink package.
%(c) Aditya Joshi, November 2017


%% Parse inputs

if ~iscell(filenames), filenames = {filenames}; end

disp('*** Running create_sfun_decode:')

if nargin < 2, sys_id = 100; end
if nargin < 3, comp_id = 200; end

pathname = fileparts(mfilename('fullpath'));
sfun_include_dir = fullfile(pathname,'include');
mavlink_dialect_dir = fileparts(filenames{1});


%% Create message header files

mavlink_msg_names = cell(length(filenames));
for i = 1:length(filenames)
    mavlink_msg_names{i} = create_sfun_header(filenames{i});
end


%% Create decode header file

fprintf('Creating s-function header file... ')

header_filename = fullfile(sfun_include_dir,'sfun_decode_mavlink.h');
fid = fopen(header_filename,'w');

% Write header
fprintf(fid,'%s\n','/*');
fprintf(fid,'%s\n','DO NOT EDIT.');
fprintf(fid,'%s\n',['This file was automatically created by the Matlab function ''create_sfun_decode'' on ' datestr(now)]);
fprintf(fid,'%s\n','as part of Simulink MAVLink library.');
fprintf(fid,'%s\n','*/');
fprintf(fid,'%s\n','');

% Include sfun headers
for i = 1:length(filenames)
    fprintf(fid,'%s\n',['#include "' sfun_include_dir filesep 'sfun_mavlink_msg_' mavlink_msg_names{i} '.h"']);
end

% Define NFIELDS_OUTPUT_BUS
fprintf(fid,'%s\n','');
fprintf(fid,'%s',['#define NFIELDS_OUTPUT_BUS (NFIELDS_BUS_' upper(mavlink_msg_names{1})]);
if length(filenames) > 1
    for i = 2:length(filenames)
        fprintf(fid,'%s',[' + NFIELDS_BUS_' upper(mavlink_msg_names{i})]);
    end
end
fprintf(fid,'%s\n',')');

% calculate bus offsets for each message
fprintf(fid,'%s\n','');
fprintf(fid,'%s\n',['#define OFFSET_' upper(mavlink_msg_names{1}) ' 0']);
if length(filenames) > 1
    for i = 2:length(filenames)
        lin = ['#define OFFSET_' upper(mavlink_msg_names{i}) ' 2*('];
        for j = i-1:-1:1
            lin = [lin 'NFIELDS_BUS_' upper(mavlink_msg_names{j}) '+'];
        end
        lin(end) = ')';
        fprintf(fid,'%s\n',lin);
    end
end

% Write decode_mavlink_msg function
fprintf(fid,'%s\n','');
fprintf(fid,'%s\n','/*');
fprintf(fid,'%s\n','Decode the incoming MAVLink message');
fprintf(fid,'%s\n','*/');
fprintf(fid,'%s\n','static inline void decode_mavlink_msg (SimStruct *S, const mavlink_message_t *msg)');
fprintf(fid,'%s\n','{');
fprintf(fid,'\t%s\n','int_T *busInfo = (int_T *) ssGetUserData(S);');
fprintf(fid,'%s\n','');
for i = 1:length(filenames)
    fprintf(fid,'\t%s\n',['char* yvec' num2str(i-1) ' = (char *) ssGetOutputPortRealSignal(S, ' num2str(i-1) ');']);
end
fprintf(fid,'\t%s\n','switch (msg->msgid) {');
for i = 1:length(filenames)
    fprintf(fid,'%s\n','');
    fprintf(fid,'\t\t%s\n',['case MAVLINK_MSG_ID_' upper(mavlink_msg_names{i}) ':']);
    fprintf(fid,'\t\t\t%s\n',['decode_msg_' mavlink_msg_names{i} '(msg, busInfo, yvec' num2str(i-1) ', OFFSET_' upper(mavlink_msg_names{i}) ');']); 
    fprintf(fid,'\t\t\t%s\n','break;');
end
fprintf(fid,'\t%s\n','}');
fprintf(fid,'%s\n','}');


fclose(fid);
disp('done')


%% Create cpp file

output_filename = 'sfun_decode_mavlink';
fprintf(['Creating the output file ' output_filename '.cpp ... ']);

fin = fopen('sfun_decode_mavlink_template.cpp','r');
fout = fopen([output_filename '.cpp'],'w');

% Write header
fprintf(fout,'%s\n','/*');
fprintf(fout,'%s\n','DO NOT EDIT.');
fprintf(fout,'%s\n',['This file was automatically created by the Matlab function ''create_sfun_decode'' on ' datestr(now)]);
fprintf(fout,'%s\n','as part of Simulink MAVLink library.');
fprintf(fout,'%s\n','*/');

% Skip header from template file
lin = fgetl(fin);
while ~contains(lin,'<BEGIN>')
    lin = fgetl(fin);
end
lin = fgetl(fin);

% Start writing editable lines
while ~contains(lin,'<END>')
    
    if contains(lin,'<EDIT>')
        idx = regexp(lin,'<(\d*)>','match');
        idx = idx{1};
        idx = str2double(erase(idx,{'<','>'}));
        
        switch idx
            case 1
                % define SYS_ID
                fprintf(fout,'%s\n',['#define SYS_ID ' num2str(sys_id)]);
                
            case 2
                % define COMP_ID
                fprintf(fout,'%s\n',['#define COMP_ID ' num2str(comp_id)]);
                
            case 3
                % include mavlink common header
                fprintf(fout,'%s\n',['#include "' mavlink_dialect_dir filesep 'mavlink.h"']);
                
            case 4
                % include header file
                fprintf(fout,'%s\n',['#include "' header_filename '"']);
                
            case 5
                % configure output ports
                fprintf(fout,'\t%s\n',['if (!ssSetNumOutputPorts(S, ' num2str(i) ')) return;']);
                fprintf(fout,'%s\n','');
                fprintf(fout,'\t%s\n','#if defined(MATLAB_MEX_FILE)');
                fprintf(fout,'\t%s\n','if (ssGetSimMode(S) != SS_SIMMODE_SIZES_CALL_ONLY)');
                fprintf(fout,'\t%s\n','{');
                for i = 1:length(filenames)
                    fprintf(fout,'\t\t%s\n',['DTypeId dataTypeIdReg' num2str(i-1) ';']);
                    fprintf(fout,'\t\t%s\n',['ssRegisterTypeFromNamedObject(S, BUS_NAME_' upper(mavlink_msg_names{i}) ', &dataTypeIdReg' num2str(i-1) ');']);
                    fprintf(fout,'\t\t%s\n',['if (dataTypeIdReg' num2str(i-1) ' == INVALID_DTYPE_ID) return;']);
                    fprintf(fout,'\t\t%s\n',['ssSetOutputPortDataType(S, ' num2str(i-1) ', dataTypeIdReg' num2str(i-1) ');']);
                    fprintf(fout,'%s\n','');
                end
                fprintf(fout,'\t%s\n','}');
                fprintf(fout,'\t%s\n','#endif');
                
                
                fprintf(fout,'%s\n','');
                for i = 1:length(filenames)
                    fprintf(fout,'\t%s\n',['ssSetBusOutputObjectName(S, ' num2str(i-1) ', (void *) BUS_NAME_' upper(mavlink_msg_names{i}) ');']);
                end
                                
                fprintf(fout,'%s\n','');
                for i = 1:length(filenames)
                    fprintf(fout,'\t%s\n',['ssSetOutputPortWidth(S, ' num2str(i-1) ', 1);']);
                end
                                
                fprintf(fout,'%s\n','');
                for i = 1:length(filenames)
                    fprintf(fout,'\t%s\n',['ssSetBusOutputAsStruct(S, ' num2str(i-1) ', 1);']);
                end
                                
                fprintf(fout,'%s\n','');
                for i = 1:length(filenames)
                    fprintf(fout,'\t%s\n',['ssSetOutputPortBusMode(S, ' num2str(i-1) ', SL_BUS_MODE);']);
                end
                
            case 6
                % encode_businfo for each message
                for i = 1:length(filenames)
                    fprintf(fout,'\t%s\n',['encode_businfo_' mavlink_msg_names{i} '(S, busInfo, OFFSET_' upper(mavlink_msg_names{i}) ');']);
                end
                
            otherwise
                error(['Unknown <EDIT> tag: ' num2str(idx)]);
            
        end
        
    else
        fprintf(fout,'%s\n',lin);
    end
    
    lin = fgetl(fin);
end

fclose(fin);
fclose(fout);
disp('done');


%% Compile cpp file

disp('Compiling the s-function...')
eval(['mex ' output_filename '.cpp']);

movefile([output_filename '.*'],'sfunctions');
disp('S-function source and compiled files are in the folder ''sfunctions''')

% Add the sfunctions directory to path
addpath(fullfile(pathname,'sfunctions'));

disp('***')