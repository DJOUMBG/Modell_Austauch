function [] = CyclePreprocessing(varargin)
% CyclePreprocessing <loads a road dataset to DIVe env_roadair_time_* module>
% <the road dataset must be specified in the input arguments>
%
%
% Syntax:  [] = CyclePreprocessing(varargin)
%
% Inputs:
%    varargin - [<Unit>] <argument value pair for arguemnt 'cPathDataVariant'>
%                           (Path to the desired road dataset)
%
% Outputs:
%     -
%
% Example:
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also:
%
% Author: bhoefla
% Date:   12-Aug-2016
%


%% ------------- BEGIN CODE --------------
%% read input arguments:
if mod(nargin,2)==0
    for k=1:nargin/2
        if strcmp( varargin{2*k-1},'cPathDataVariant' )
            sDataPath_envRoad = varargin{2*k};
        elseif false
        elseif false
        end
    end
else
    error('number of arguments not even --> use argument/value pairs')
end

%% get sMP structure from base workspace
sMP = evalin('base','sMP');

%% get variables
tim = sMP.bdry.env.CYC.t;
vel = sMP.bdry.env.CYC.v;
gra = sMP.bdry.env.CYC.grade;

%% Detection of height and distance vector in CYC.hgt structure
if isfield(sMP.bdry.env.CYC,'hgt')
	% get distance and altirude vectors from struct
	alt = sMP.bdry.env.CYC.hgt.hgt;
	dis = sMP.bdry.env.CYC.hgt.dis;
	% calculate gradient vector (& overwrite existing grade vector)
    gra = [0; atan(diff(alt)./diff(dis))];
	
else % road data with only: t, v, grade
	% Calculation of distance vector
	t_diff = [0;diff(tim)];
	s_diff = (t_diff.*vel);
	dis = cumsum(s_diff);
end

% calculate slope and altitude
slo = tan(gra)*100; % unit conversion: rad --> percent
alt = cumsum( sin(atan( [0; slo(1:end-1)]/100)) .* [0;diff(dis)] );

%--- make distance vector unique (else: lookup tables won't work)
% find idx, where position doesn't change ( & always leave first point)
idx = ([1; diff(dis)] < 0.0001);
% delete entries at idx --> vectors now shorter than, v-t-grade
dis(idx) = []; 
alt(idx) = []; 
slo(idx) = []; 

%--- write variables to output data structure
% sMP.bdry.env.CYC.t          = tim; % [s]
% sMP.bdry.env.CYC.v          = vel; % [m/s]
% sMP.bdry.env.CYC.grade      = gra; % [radiant]
sMP.bdry.env.CYC.s          = dis; % [m]
sMP.bdry.env.CYC.Altitude   = alt; % [m]
sMP.bdry.env.CYC.pct_slope  = slo; % [%]

% minimal source data : CYC: t, v, grade --> same column length
% optional source data: CYC.hgt: hgt, dis
% calculated data     : CYC: s, Altitude, pct_slope --> same column length, but different to "t"

% set variables, if they not yet exist
if ~isfield(sMP.bdry.env,'altitude_abs_startPos_m')
	sMP.bdry.env.altitude_abs_startPos_m = 0;
end
if ~isfield(sMP.bdry.env,'altitude_offset_m')
	sMP.bdry.env.altitude_offset_m = 0;
end

%% Get Road Name
name_str = char(sDataPath_envRoad(2));
k_index = strfind(name_str,'road_time\');
sMP.bdry.env.CYC.name = name_str((k_index+(length('road_time\')):end));
sMP.bdry.env.road.name = sMP.bdry.env.CYC.name;

%% Add missing params for roadair\time
sMP.human.drv.cyc.track.m_Way = dis(end); % workaround for simInfo
sMP.bdry.env.road.m_Way = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Repetition of distance vector
if sMP.bdry.env.NumOfRepetation_DriveCycle > 1
    s=sMP.bdry.env.CYC.s(2:end)/1e3;
    temp1=sMP.bdry.env.CYC.s(1);
    temp2=s;
    for i=2:sMP.bdry.env.NumOfRepetation_DriveCycle
        temp2=[temp2;s+s(end)*(i-1)*ones(length(s),1)];
    end
    sMP.bdry.env.CYC.s=[temp1;temp2]*1e3;
    sMP.bdry.env.CYC.LengthTrack = sMP.bdry.env.CYC.s(end);
    
    %% Repetition of gradient vector
    sMP.bdry.env.CYC.grade=repmat(sMP.bdry.env.CYC.grade,sMP.bdry.env.NumOfRepetation_DriveCycle,1);
    
    temp=sMP.bdry.env.CYC.pct_slope(1);
    sMP.bdry.env.CYC.pct_slope=repmat(sMP.bdry.env.CYC.pct_slope(2:end),sMP.bdry.env.NumOfRepetation_DriveCycle,1);%%drive cycle repation grade  profile
    sMP.bdry.env.CYC.pct_slope=[temp;sMP.bdry.env.CYC.pct_slope];
    
    temp=sMP.bdry.env.CYC.Altitude(1);
    sMP.bdry.env.CYC.Altitude=repmat(sMP.bdry.env.CYC.Altitude(2:end),sMP.bdry.env.NumOfRepetation_DriveCycle,1);
    sMP.bdry.env.CYC.Altitude=[temp;sMP.bdry.env.CYC.Altitude];
    
    % x=2;
    % while x<= size(sMP.bdry.env.CYC.s,1)
    % if sMP.bdry.env.CYC.s(x) == sMP.bdry.env.CYC.s(x-1)
    % sMP.bdry.env.CYC.s(x) = [];
    % sMP.bdry.env.CYC.pct_slope(x) = [];
    % sMP.bdry.env.CYC.Altitude(x) = [];
    % else
    %     x=x+1;
    % end
    % end
    
    %% Repetition of velocity profile and time vector
    sMP.bdry.env.CYC.v=repmat(sMP.bdry.env.CYC.v,sMP.bdry.env.NumOfRepetation_DriveCycle,1);
    t=sMP.bdry.env.CYC.t;
    temp=zeros((sMP.bdry.env.NumOfRepetation_DriveCycle)*length(t),1);
    for i=1:sMP.bdry.env.NumOfRepetation_DriveCycle
        temp((i-1)*length(t)+1:i*length(t))=t+(t(end)+(t(2)-t(1)))*(i-1);
    end
    sMP.bdry.env.CYC.t=temp;
    
    
    %% Repetition of Measurment Aux Power vector
    if isfield(sMP,'bdry')
        if isfield(sMP.bdry,'env')
            if isfield(sMP.bdry.env,'CYC')
                if isfield(sMP.bdry.env.CYC,'aux_power')
                    if (sMP.bdry.env.CYC.aux_power(1)==0)
                        %%do nothing
                    else
                        sMP.bdry.env.CYC.aux_power(1)=0;
                    end
                else
                    sMP.bdry.env.CYC.aux_power=zeros(size(sMP.bdry.env.CYC.t));
                end
            end
        end
    else
        %do nothing
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% update sMP structure in base workspace
assignin('base','sMP',sMP);