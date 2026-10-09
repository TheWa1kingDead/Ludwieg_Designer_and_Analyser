%% LUDWIEG TUBE / FREE-JET FACILITY DESIGN & ANALYSIS
% Sizes a Ludwieg tube wind tunnel with a free-jet test section for a
% given nozzle (exit Mach number and exit diameter): driver tube, vacuum
% dump tank, storage and pumping times, freestream conditions, usable
% test core (rhombus), maximum model size and blockage, Reynolds-number
% matching and the operating envelope with Reynolds-equivalent altitude.
%
% Requires: MATLAB R2021a or newer, Aerospace Toolbox (atmosisa).
% See README.md for a full description of inputs, method and outputs.
%
% MRK Reddy, 2026. MIT License, see LICENSE.

clear; clc; close all;

set(groot, 'defaultTextInterpreter',          'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter',        'latex');

%%  Sections:
%   1. User inputs (defaults)
%   2. Editable parameter dialog
%   3. Input checks
%   4. Derived tunnel quantities (isentropic flow, driver, vacuum tank)
%   5. Nozzle core-flow geometry: downstream + upstream rhombus (analytic)
%   6. Time array & quasi-steady driver conditions
%   7. Dump-tank pressure rise (transient fill)
%   8. Nozzle exit / back-pressure ratio vs time
%   9. Model sizing (rhombus-limited dimension)
%  10. Reynolds-number matching
%  11. Operating envelope: unit Re vs p0 with Reynolds-equivalent altitude
%  12. Visualization
%  13. Local functions


%% SECTION 1: USER INPUTS

P0_driver   = 10e5;         % Initial stagnation pressure    [Pa]
T0_driver   = 300;          % Initial stagnation temperature [K]
t_run       = 0.010;        % Target run time of LT          [s]
D_driver    = 3*25.4e-3;    % Driver tube inner diameter     [m]

P_vac       = 1e-3;         % Initial vacuum tank pressure   [Pa]
M_exit      = 6;            % Design exit Mach number
D_exit      = 0.100;        % Nozzle exit diameter           [m]
target_Re_L = 3e6;          % Target model-length Reynolds number

% Set use_dialog = false to run with the values above and skip the
% parameter dialog (batch runs, parameter sweeps).
use_dialog  = true;

% Facility infrastructure parameters
ambient_p     = 101325;     % Ambient pressure                        [Pa]
Q_vac_CMH     = 2*1000;     % Vacuum pump discharge rate               [m^3/hr]
Q_comp_CFM    = 100;        % Compressor discharge rate                [CFM]
V_comp        = 5;          % Compressor tank volume                   [m^3]
P_storage_i   = 30e5;       % HP storage/bottle-bank initial pressure  [Pa]
M_inlet_max   = 0.3;        % Maximum preferred inlet Mach number       [-]

% Model base type:
%   axisymmetric : circular model base
%   rectangular  : rectangular model base with user-defined spanwise width
model_mode  = 'axisymmetric';       % 'axisymmetric' or 'rectangular'
model_width = 40e-3;                % [m] only used for rectangular model

% Body length requirements:
%   Rectangular  : L_req = 2*h / (tand(alpha_upper) + tand(alpha_lower))
%   Axisymmetric : L_req = d / tand(alpha_axi)
alpha_upper = 15;
alpha_lower = 12;
alpha_axi   = 10;

% Sutherland constants
mu0  = 1.716e-5;     % Reference viscosity   [Pa.s]
T0_S = 273.15;       % Reference temperature [K]
S_C  = 110.4;        % Sutherland constant   [K]

% Gas parameters
g = 1.4;
R = 287.05;          % [J/(kg.K)]
n = 1.1;             % Polytropic index for tank-volume estimate


%% SECTION 2: EDITABLE PARAMETER DIALOG

paramBlocks = {
    {
    'Stagnation pressure [$p_0$, Pa]',              P0_driver
    'Stagnation temperature [$T_0$, K]',            T0_driver
    'Run time [$t_r$, s]',                          t_run
    'Mach number at exit [$M_e$, -]',               M_exit
    'Target Reynolds number [$Re_L$, -]',           target_Re_L
    }

    {
    'Vacuum pressure [$p_{vi}$, Pa]',               P_vac
    'Driver tube inner diameter [$D_d$, m]',        D_driver
    'Nozzle exit diameter [$D_e$, m]',              D_exit
    'Polytropic index [n, -]',                      n
    'Max preferred inlet Mach [$M_{i,max}$, -]',    M_inlet_max
    }

    {
    'Model type [axisymmetric/rectangular]',        model_mode
    'Model spanwise width [W, m]',                  model_width
    'Angle upper [${\alpha}_u$, deg]',              alpha_upper
    'Angle lower [${\alpha}_l$, deg]',              alpha_lower
    'Angle for axisymmetric [${\alpha}_a$, deg]',   alpha_axi
    }

    {
    'Reference viscosity at $T_{ref}$ [$\mu_0$, Pa.s]', mu0
    'Reference temperature [$T_{ref}$, K]',             T0_S
    'Sutherland temperature [$S$, K]',                  S_C
    'Gamma [$\gamma$, -]',                              g
    'Gas constant [$R$, J/(kg.K)]',                     R
    }

    {
    'Ambient pressure [$p_{amb}$, Pa]',                 ambient_p
    'Vacuum pump discharge rate [$Q_{vac}$, m$^3$/hr]',   Q_vac_CMH
    'Compressor discharge rate [$Q_{comp}$, CFM]',      Q_comp_CFM
    'Compressor tank volume [$V_{comp}$, $m^3$]',       V_comp
    'HP storage tank initial pressure [$P_{s,i}$, Pa]', P_storage_i
    }
};

if use_dialog

nCols = numel(paramBlocks);
nRows = max(cellfun(@(c) size(c,1), paramBlocks));

figDlg = uifigure('Name','Edit Analysis Parameters', 'Position',[150 120 1750 420]);

mainGrid = uigridlayout(figDlg, [nRows+1, nCols]);
mainGrid.RowHeight = [repmat({'fit'},1,nRows), {'fit'}];
mainGrid.ColumnWidth = repmat({'1x'},1,nCols);
mainGrid.Padding = [15 15 15 15];
mainGrid.RowSpacing = 8;
mainGrid.ColumnSpacing = 20;

fields = cell(nCols, nRows);

for col = 1:nCols
    thisBlock = paramBlocks{col};

    for row = 1:size(thisBlock,1)
        subGrid = uigridlayout(mainGrid, [2,1]);
        subGrid.Layout.Row = row;
        subGrid.Layout.Column = col;
        subGrid.RowHeight = {'fit','fit'};
        subGrid.Padding = [0 0 0 0];

        uilabel(subGrid, ...
            'Text', thisBlock{row,1}, ...
            'Interpreter', 'latex', ...
            'FontSize', 13);

        fields{col,row} = uieditfield(subGrid, 'text', ...
            'Value', char(string(thisBlock{row,2})), ...
            'FontName', 'Times New Roman', ...
            'FontSize', 12);
    end
end

btn = uibutton(mainGrid, ...
    'Text','OK', ...
    'ButtonPushedFcn', @(src,event) uiresume(figDlg));
btn.Layout.Row = nRows + 1;
btn.Layout.Column = [1 nCols];

uiwait(figDlg);

if ~isvalid(figDlg)
    error('User closed parameter dialog.');
end

getval = @(col,row) string(fields{col,row}.Value);

P0_driver   = str2double(getval(1,1));
T0_driver   = str2double(getval(1,2));
t_run       = str2double(getval(1,3));
M_exit      = str2double(getval(1,4));
target_Re_L = str2double(getval(1,5));

P_vac       = str2double(getval(2,1));
D_driver    = str2double(getval(2,2));
D_exit      = str2double(getval(2,3));
n           = str2double(getval(2,4));
M_inlet_max = str2double(getval(2,5));

model_mode  = lower(strtrim(char(getval(3,1))));
model_width = str2double(getval(3,2));
alpha_upper = str2double(getval(3,3));
alpha_lower = str2double(getval(3,4));
alpha_axi   = str2double(getval(3,5));

mu0         = str2double(getval(4,1));
T0_S        = str2double(getval(4,2));
S_C         = str2double(getval(4,3));
g           = str2double(getval(4,4));
R           = str2double(getval(4,5));

ambient_p   = str2double(getval(5,1));
Q_vac_CMH   = str2double(getval(5,2));
Q_comp_CFM  = str2double(getval(5,3));
V_comp      = str2double(getval(5,4));
P_storage_i = str2double(getval(5,5));

delete(figDlg);

end


%% SECTION 3: INPUT CHECKS

if ~ismember(model_mode, {'axisymmetric','rectangular'})
    error('model_mode must be either axisymmetric or rectangular.');
end

num_values = [
    P0_driver, T0_driver, t_run, D_driver, ...
    P_vac, M_exit, D_exit, target_Re_L, ...
    model_width, ...
    alpha_upper, alpha_lower, alpha_axi, ...
    mu0, T0_S, S_C, g, R, n, ...
    ambient_p, Q_vac_CMH, Q_comp_CFM, V_comp, P_storage_i, M_inlet_max
];

if any(isnan(num_values))
    error('One or more numeric inputs are invalid.');
end

if any([P0_driver, T0_driver, t_run, D_driver, P_vac, M_exit, D_exit, g, R, n, ...
        ambient_p, Q_vac_CMH, Q_comp_CFM, V_comp, P_storage_i, M_inlet_max] <= 0)
    error('Pressures, temperatures, diameters, Mach number, gas constants, and facility parameters must be positive.');
end

if strcmp(model_mode, 'rectangular') && model_width <= 0
    error('model_width must be positive for rectangular model mode.');
end


%% SECTION 4: DERIVED TUNNEL QUANTITIES

P_comp_final  = P_storage_i + 1e5;                 % Compressor final pressure, absolute [Pa]
P_comp_init   = ambient_p;                         % Compressor initial pressure, absolute [Pa]
cp = g*R/(g-1);
cv = R/(g-1);

a0_drv = sqrt(g*R*T0_driver);                      % Driver stagnation sound speed [m/s]
r_exit = D_exit/2;                                 % Nozzle exit radius [m]
A_exit = pi/4*D_exit^2;                            % Circular nozzle exit area [m^2]

% Isentropic ratios at M_exit (relative to stagnation conditions).
[T_rat, P_rat, rho_rat, A_rat] = isentropic_ratios(g, M_exit);
PR_v = 1/P_rat;

T_exit   = T0_driver*T_rat;
P_exit   = P0_driver*P_rat;
rho0     = P0_driver/(R*T0_driver);
rho_exit = rho0*rho_rat;
a_exit   = sqrt(g*R*T_exit);
U_exit   = M_exit*a_exit;
mu_exit  = sutherland_mu(T_exit, mu0, T0_S, S_C);
Re_unit  = rho_exit*U_exit/mu_exit;

A_throat     = A_exit/A_rat;
D_throat_eq  = sqrt(4*A_throat/pi);
mdot_c       = A_throat*sqrt(g/R)*(2/(g+1))^((g+1)/(2*(g-1)));
mdot_choked  = mdot_c*P0_driver/sqrt(T0_driver);

% Required inlet/driver diameter estimate for a selected maximum inlet Mach.
[~, ~, ~, A_rat_Mi] = isentropic_ratios(g, M_inlet_max);
D_driver_min = sqrt(4*A_throat*A_rat_Mi/pi);

L_driver     = t_run*a0_drv/2;                  % Single-pass driver length [m]
A_driver     = pi/4*D_driver^2;                 % User-specified driver tube area [m^2]
V_driver     = A_driver*L_driver;               % User-specified driver volume [m^3]
m_driver     = rho0*V_driver;                   % User-specified driver mass [kg]
V_driver_min = pi/4*D_driver_min^2*L_driver;    % Minimum driver volume from inlet-Mach estimate [m^3]
m_driver_min = rho0*V_driver_min;               % Minimum driver mass [kg]

PR_available = P0_driver/P_vac;

% Minimum vacuum tank volume from the indraft-tunnel sizing correlation
% (Pope & Goin, High-Speed Wind Tunnel Testing, 1965).
V_dump = indraft_vacuum_volume(A_throat, T_exit, t_run, PR_v, T0_driver, P_vac, P_exit, n);

% Pumping / compressor time estimates.
t_vac_pump = (V_dump/Q_vac_CMH)*log(ambient_p/P_vac)*60*60;         % [s], pump-down at constant volumetric speed
t_comp_min = ((V_comp*35.3147)/(14.7*Q_comp_CFM))* ...
             ((P_comp_final*0.000145038) - (P_comp_init*0.000145038)); % [min]

% Minimum HP storage-tank volume so that the storage pressure stays at or
% above 1.2*P0_driver while choked flow through A_throat is drawn for
% t_run (isothermal blowdown, P_s(t) = P_s,i*exp(-0.5787*A*a0*t/V)).
V_storage_min = -(0.5787*A_throat*sqrt(g*R*T0_driver)*t_run)/(log(1.2*P0_driver/P_storage_i));

if PR_available >= PR_v
    fprintf('Driver/Vacuum Conditions Appropriate for M=%.2f run\n', M_exit);
else
    fprintf('****ERROR****: Drive/Vacuum pressure ratio is insufficient for M = %.2f run\n', M_exit);
end

fprintf('\nDERIVED TUNNEL PARAMETERS\n')
fprintf('  P0 = %.2f bar | T0 = %.0f K | M_exit = %.2f\n', P0_driver/1e5, T0_driver, M_exit)
fprintf('  Run time                          : %.2f ms\n', t_run*1e3)
fprintf('  Driver length, single pass        : %.2f m\n', L_driver)
fprintf('  User driver diameter              : %.4f m\n', D_driver)
fprintf('  Min driver/inlet diameter @ Mi=%.2f: %.4f m\n', M_inlet_max, D_driver_min)
fprintf('  User driver mass                  : %.5f kg\n', m_driver)
fprintf('  Min-estimated driver mass         : %.5f kg\n', m_driver_min)
fprintf('  Exit area                         : %.4e m^2\n', A_exit)
fprintf('  Throat area                       : %.4e m^2\n', A_throat)
fprintf('  Equivalent throat diameter        : %.5f m\n', D_throat_eq)
fprintf('  Area ratio A_e/A*                 : %.4f\n', A_rat)
fprintf('  Required pressure ratio P0/Pe     : %.4f\n', PR_v)
fprintf('  Available pressure ratio P0/Pvac  : %.4e\n', PR_available)
fprintf('  Maximum choked mass flow          : %.5f kg/s\n', mdot_choked)
fprintf('  Minimum vacuum tank volume        : %.3f m^3\n', V_dump)
fprintf('  Vacuum pumping time estimate      : %.2f s\n', t_vac_pump)
fprintf('  Compressor pumping time estimate  : %.2f min\n', t_comp_min)
fprintf('  Minimum HP storage-tank volume    : %.3f m^3\n', V_storage_min)

fprintf('\nFREESTREAM CONDITIONS DURING RUN\n')
fprintf('  Freestream total pressure p0      : %.4e Pa\n', P0_driver)
fprintf('  Freestream static pressure p_inf  : %.4f Pa\n', P_exit)
fprintf('  Freestream total density rho0     : %.4f kg/m^3\n', rho0)
fprintf('  Freestream static density rho_inf : %.4f kg/m^3\n', rho_exit)
fprintf('  Freestream static temperature     : %.4f K\n', T_exit)
fprintf('  Freestream sound speed a_inf      : %.4f m/s\n', a_exit)
fprintf('  Freestream velocity u_inf         : %.4f m/s\n', U_exit)
fprintf('  Freestream viscosity mu_inf       : %.4e Pa.s\n', mu_exit)
fprintf('  Freestream unit Reynolds number   : %.4e 1/m\n\n', Re_unit)


%% SECTION 5: NOZZLE CORE-FLOW GEOMETRY (DOWNSTREAM + UPSTREAM RHOMBUS)
%
% DOWNSTREAM rhombus: the uniform test core in the free jet downstream of
% the nozzle exit is bounded by the simple Mach waves radiating from the
% nozzle lip, converging on the axis a distance L_down beyond the exit:
%     L_down = r_exit / tan(mu_exit),   mu_exit = asin(1/M_exit)
%
% UPSTREAM rhombus: an equivalent uniform-flow diamond also exists just
% inside/at the nozzle exit, bounded by the LAST characteristic of the
% method-of-characteristics (MOC) design (from the last point on the axis
% to the exit lip). this last characteristic is itself a straight Mach line,
% and by the same geometry it is EXACTLY as long as the downstream rhombus:
%     L_up = r_exit / tan(mu_exit) = L_down
% (Verified directly against a NASA-MOC characteristics-net output: the
% MOC-derived length matched this formula to within 0.001%.) No MOC file
% is needed at run time - this closed-form result is used directly.

mu_deg        = asind(1/M_exit);
L_rhombus_geo = r_exit/tand(mu_deg);   % downstream rhombus length [m]
L_rhombus_up  = L_rhombus_geo;         % upstream rhombus = downstream (see derivation above)

fprintf('CORE RHOMBUS LENGTHS (mu = %.2f deg)\n', mu_deg)
fprintf('  Downstream (free-jet) rhombus length : %.1f mm\n', L_rhombus_geo*1e3)
fprintf('  Upstream rhombus length               : %.1f mm\n', L_rhombus_up*1e3)

L_core_total = L_rhombus_up + L_rhombus_geo;
fprintf('  Total uniform-core extent (up+down)   : %.1f mm\n\n', L_core_total*1e3)


%% SECTION 6: TIME ARRAY & QUASI-STEADY DRIVER CONDITIONS

N    = 3000;
t    = linspace(0, t_run, N);
dt   = t(2) - t(1);
t_ms = t*1e3;

% Stagnation conditions at the nozzle entrance are quasi-steady over the
% run window (the run time is short compared to the driver-tube wave transit time).
P0_t = P0_driver*ones(1, N);
T0_t = T0_driver*ones(1, N);


%% SECTION 7: DUMP TANK PRESSURE RISE

% The dump tank is treated as a rigid adiabatic control volume.
% Incoming flow carries stagnation enthalpy h_in = cp*T0.
% Mass balance  : dm/dt   = mdot
% Energy balance: m*dT/dt = mdot*(gamma*T0 - T_dump)
% Adiabatic equilibrium temperature tends toward gamma*T0.

m_dump = zeros(1,N);
T_dump = zeros(1,N);
P_dump = zeros(1,N);

m_dump(1) = P_vac*V_dump/(R*T0_driver);
if m_dump(1) < 1e-5
    m_dump(1) = 1e-4;   % guard against a nonsensical first integration step
end
T_dump(1) = T0_driver;
P_dump(1) = P_vac;

for i = 1:N-1
    mdot_i      = mdot_c*P0_t(i)/sqrt(T0_t(i));
    dm          = mdot_i*dt;
    dT          = mdot_i*(g*T0_t(i) - T_dump(i))/m_dump(i)*dt;
    m_dump(i+1) = m_dump(i) + dm;
    T_dump(i+1) = T_dump(i) + dT;
    P_dump(i+1) = m_dump(i+1)*R*T_dump(i+1)/V_dump;
end


%% SECTION 8: NOZZLE EXIT CONDITIONS & PRESSURE RATIO vs TIME

Pe = P0_t.*P_rat;     % Nozzle exit static pressure, fixed-M isentropic assumption
Pb = P_dump;          % Back pressure = dump tank pressure
PR = Pe./Pb;          % >1 underexpanded | =1 perfect | <1 overexpanded

[~, idx_perf] = min(abs(PR - 1.0));
t_perf = t(idx_perf);


%% SECTION 9: MODEL SIZING (RHOMBUS-LIMITED DIMENSION)
%
% Model rule:
%   Axisymmetric : A_front = pi/4*d_model^2
%   Rectangular  : A_front = model_width*h_model
%
% The available core radius/height at any axial station x downstream of
% the exit is bounded by the downstream rhombus. The maximum model dimension
% is set purely by the geometric intersection of the model's nose-growth line
% with the rhombus boundary line.

D_avail = @(x) 2*max(0, r_exit - x.*tand(mu_deg));

if strcmp(model_mode, 'axisymmetric')
    L_from_dim    = @(d) d/tand(alpha_axi);        % model length [m]
    dim_label     = 'Diameter';
else
    L_from_dim    = @(h) 2*h/(tand(alpha_upper) + tand(alpha_lower));
    dim_label     = 'Height';
end

% Rhombus fit constraint at the model base:
%   dimension = available diameter/height at x = L_from_dim(dim)
f_rhombus = @(dim) dim - D_avail(L_from_dim(dim));

d_lo = 0;
d_hi = D_exit;   % generous upper bound - model dimension cannot exceed the exit diameter

if f_rhombus(d_lo) >= 0
    warning('Model does not fit rhombus even near zero size. Check inputs.');
    dim_final = 0;
elseif f_rhombus(d_hi) <= 0
    warning('Rhombus/model-line intersection not found within search bounds. Check inputs.');
    dim_final = d_hi;
else
    dim_final = fzero(f_rhombus, [d_lo, d_hi]);
end

L_req = L_from_dim(dim_final);

if strcmp(model_mode, 'axisymmetric')
    A_front_final = pi/4*dim_final^2;
else
    A_front_final = model_width*dim_final;
end
blockage_pct = A_front_final/A_exit*100;

fprintf('CORE GEOMETRY & MODEL SIZING\n')
fprintf('  Perfect expansion at : t = %.2f ms  (%.1f%% of run)\n', ...
        t_perf*1e3, t_perf/t_run*100)
fprintf('  Downstream rhombus length : %.1f mm\n', L_rhombus_geo*1e3)
fprintf('  Mach angle mu              : %.2f deg\n\n', mu_deg)

fprintf('MODEL SIZING (%s base)\n', model_mode)
if strcmp(model_mode, 'rectangular')
    fprintf('  Model width (fixed)   : %.1f mm\n', model_width*1e3)
    fprintf('  Max height (rhombus)  : %.2f mm\n', dim_final*1e3)
else
    fprintf('  Max diameter (rhombus): %.2f mm\n', dim_final*1e3)
end
fprintf('  Required model length : %.1f mm\n', L_req*1e3)
fprintf('  Resulting blockage     : %.2f%%\n\n', blockage_pct)


%% SECTION 10: REYNOLDS NUMBER MATCHING

% Given the fitted (rhombus-limited) model length L_req and a target Re_L, find the stagnation 
% pressure P0 that would be required to hit that target Re_L for a model of length L_req.

mu_ts = mu_exit;
a_ts  = a_exit;

rho_req     = target_Re_L*mu_ts/(M_exit*a_ts*L_req);
Ps_req      = rho_req*R*T_exit;
P0_required = Ps_req/P_rat;

rho_actual = (P0_driver*P_rat)/(R*T_exit);
Re_actual  = rho_actual*M_exit*a_ts*L_req/mu_ts;

V_dump_new = indraft_vacuum_volume(A_throat, T_exit, t_run, PR_v, T0_driver, P_vac, Ps_req, n);

% Reverse problem: at the ACTUAL/user-input driver conditions (P0_driver, T0_driver), what model 
% length/dimension would hit the target Re_L exactly? This is independent of the rhombus-fit sizing in
% Section 9, and is overlaid as a separate reference point on the model envelope trade curve and frontal-view plots.

L_ReL = target_Re_L*mu_ts/(rho_actual*M_exit*a_ts);   % model length hitting target_Re_L at actual P0 [m]

if strcmp(model_mode, 'axisymmetric')
    dim_ReL = L_ReL*tand(alpha_axi);
    A_front_ReL = pi/4*dim_ReL^2;
else
    dim_ReL = L_ReL*(tand(alpha_upper) + tand(alpha_lower))/2;
    A_front_ReL = model_width*dim_ReL;
end
blockage_pct_ReL = A_front_ReL/A_exit*100;

fprintf('REYNOLDS NUMBER MATCHING\n')
fprintf('  Target Re_L          : %.4e\n', target_Re_L)
fprintf('  Model length L_req   : %.1f mm\n', L_req*1e3)
fprintf('  User input P0_driver : %.2f bar\n', P0_driver/1e5)
fprintf('  Estimated P0 required: %.2f bar\n', P0_required/1e5)
fprintf('  Unit Re in tunnel    : %.4e 1/m\n', Re_actual/L_req)
fprintf('  New vacuum volume    : %.3f m^3\n\n', V_dump_new)

fprintf('MODEL SIZE FROM Re_L MATCHING (at actual P0_driver)\n')
if strcmp(model_mode, 'rectangular')
    fprintf('  Model width (fixed)  : %.1f mm\n', model_width*1e3)
    fprintf('  Height for Re_L match: %.2f mm\n', dim_ReL*1e3)
else
    fprintf('  Diameter for Re_L match: %.2f mm\n', dim_ReL*1e3)
end
fprintf('  Model length for Re_L match : %.1f mm\n', L_ReL*1e3)
fprintf('  Resulting blockage          : %.2f%%\n\n', blockage_pct_ReL)


%% SECTION 11: LUDWIEG OPERATING ENVELOPE - Re/m vs p0 WITH REYNOLDS-EQUIVALENT ALTITUDE
%
% This operating envelope is better suited for a fixed-Mach Ludwieg-style
% tunnel because, once the nozzle Mach number, gas, and stagnation
% temperature are fixed, the main operating variable is the driver/
% stagnation pressure p0.
%
% Left axis:
%   Unit Reynolds number, Re' = rho_inf*u_inf/mu_inf, as a function of p0.
%
% Right axis:
%   Reynolds-equivalent altitude at the same Mach number, i.e. the altitude
%   in a standard Earth atmosphere where:
%
%       Re'_flight(h, M_exit) = Re'_tunnel(p0, M_exit)
%
% No nozzle-start cutoff is applied here.

P0_env_bar = linspace(3, 100, 700);     % operating range [bar]
P0_env     = P0_env_bar * 1e5;          % [Pa]

% Tunnel freestream properties for fixed M_exit and T0_driver
[T_rat_env, P_rat_env, ~, ~] = isentropic_ratios(g, M_exit);

T_env   = T0_driver * T_rat_env;        % fixed for fixed M and T0
P_env   = P0_env * P_rat_env;
rho_env = P_env ./ (R*T_env);
a_env   = sqrt(g*R*T_env);
U_env   = M_exit*a_env;
mu_env  = sutherland_mu(T_env, mu0, T0_S, S_C);

Re_unit_env = rho_env .* U_env ./ mu_env;       % [1/m]
Re_L_env    = Re_unit_env * L_req;              % [-]

% Reynolds-equivalent altitude calculation
% The atmosphere side is treated as standard Earth air even if the tunnel
% gas is changed. This keeps the altitude-equivalence interpretation tied to
% normal flight in air.
atm_g     = 1.4;
atm_R     = 287.05;       % [J/(kg.K)]
atm_mu0   = 1.716e-5;     % [Pa.s]
atm_T0_S  = 273.15;       % [K]
atm_S_C   = 110.4;        % [K]

% Use MATLAB Aerospace Toolbox ISA model for atmosphere-side data.
% atmosisa is valid over the ISA altitude range used here.
h_min  = 0;           % [m]
h_max  = 84852;       % [m], upper ISA limit used by atmosisa
h_grid = linspace(h_min, h_max, 4000);

[T_atm, a_atm, P_atm, rho_atm] = atmosisa(h_grid);

U_atm  = M_exit .* a_atm;
mu_atm = atm_mu0*(T_atm/atm_T0_S).^1.5.*(atm_T0_S + atm_S_C)./(T_atm + atm_S_C);

Re_unit_atm = rho_atm .* U_atm ./ mu_atm;       % [1/m]

% Re_unit_atm generally decreases with altitude, but atmosisa/numerical
% roundoff can create repeated sample values. interp1 requires unique sample
% points, so sort by Re' and collapse duplicate Re' values before interpolation.
valid_atm = isfinite(Re_unit_atm) & isfinite(h_grid) & Re_unit_atm > 0;

Re_interp_raw = Re_unit_atm(valid_atm).';
h_interp_raw  = h_grid(valid_atm).';

[Re_interp_sort, sort_id] = sort(Re_interp_raw, 'ascend');
h_interp_sort = h_interp_raw(sort_id);

[Re_interp_unique, ~, grp_id] = unique(Re_interp_sort, 'stable');
h_interp_unique = accumarray(grp_id, h_interp_sort, [], @mean).';

h_eq    = interp1(Re_interp_unique, h_interp_unique, Re_unit_env, 'linear', NaN);
h_eq_km = h_eq / 1000;

if any(isnan(h_eq_km))
    alt_note = 'Some p0 points exceed sea-level flight Re/m at the same Mach';
else
    alt_note = 'Full p0 range mapped within the atmosisa altitude range';
end

fprintf('LUDWIEG OPERATING ENVELOPE WITH REYNOLDS-EQUIVALENT ALTITUDE\n')
fprintf('  p0 sweep range                  : %.1f to %.1f bar\n', min(P0_env_bar), max(P0_env_bar))
fprintf('  Re/m at %.1f bar                : %.4e 1/m\n', P0_driver/1e5, Re_unit)
fprintf('  Equivalent altitude at %.1f bar : %.3f km\n\n', P0_driver/1e5, interp1(P0_env_bar, h_eq_km, P0_driver/1e5, 'linear', NaN))


%% SECTION 12: VISUALIZATION

fig = figure('Position', [20 20 1800 850], 'Color', 'w');
% fig = figure;
tl  = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');


% Pressure ratio (log) vs time 
nexttile(tl)
semilogy(t_ms, PR, 'k-', 'LineWidth', 1.8); hold on
xline(t_ms(idx_perf), 'k--', 'LineWidth', 1.2)
xlabel('Time [ms]', 'Interpreter','latex'); ylabel('$P_e/P_b$ (log)', 'Interpreter','latex')
legend('Pressure ratio', 'Perfect expansion', 'Location', 'best', 'FontSize', 8, 'Interpreter','latex')
title('Pressure Ratio vs Time', 'Interpreter','latex'); grid on; box on

% Model envelope trade curve 
nexttile(tl)
L_trade_max = max([L_rhombus_geo, L_ReL*1.1]);
L_trade = linspace(0, L_trade_max, 500);
D_trade = D_avail(L_trade);

hold on
fill([L_trade, fliplr(L_trade)]*1e3, [D_trade, zeros(1,500)]*1e3, ...
     [0.75 0.88 1], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'DisplayName', 'Usable test section')
plot(L_trade*1e3, D_trade*1e3, 'b-', 'LineWidth', 2, 'DisplayName', 'Rhombus boundary (full core)')

if strcmp(model_mode, 'axisymmetric')
    d_model_curve = L_trade*tand(alpha_axi);
    plot(L_trade*1e3, d_model_curve*1e3, 'r-', 'LineWidth', 1.8, ...
         'DisplayName', sprintf('Axi model nose ($\\alpha=%.1f^{\\circ}$)', alpha_axi))
else
    h_model_curve = L_trade*(tand(alpha_upper)+tand(alpha_lower))/2;
    plot(L_trade*1e3, h_model_curve*1e3, 'r-', 'LineWidth', 1.8, ...
         'DisplayName', sprintf('Rect model nose ($\\alpha=%.1f^{\\circ}/%.1f^{\\circ}$)', alpha_upper, alpha_lower))
end
plot(L_req*1e3, dim_final*1e3, 'k.', 'MarkerSize', 20, 'LineWidth', 2, ...
     'DisplayName', sprintf('Max fit: %.1f mm, $L=%.1f$ mm', dim_final*1e3, L_req*1e3))
plot(L_ReL*1e3, dim_ReL*1e3, 'g.', 'MarkerSize', 20, 'MarkerFaceColor', 'g', 'LineWidth', 1.5, ...
     'DisplayName', sprintf('$Re_L$ match: %.1f mm, $L=%.1f$ mm', dim_ReL*1e3, L_ReL*1e3))

xlabel('Model Length [mm]', 'Interpreter','latex'); ylabel(sprintf('Model %s [mm]', dim_label), 'Interpreter','latex')
title('Model Envelope Trade Curve', 'Interpreter','latex')
legend('Location', 'northeast', 'FontSize', 7, 'Interpreter','latex'); grid on; box on

% Frontal view at nozzle exit plane 
nexttile(tl)
ang_circ = linspace(0, 2*pi, 360);
plot(r_exit*1e3*cos(ang_circ), r_exit*1e3*sin(ang_circ), ...
     'k-', 'LineWidth', 2, 'DisplayName', sprintf('Nozzle exit ($D=%.0f$ mm)', D_exit*1e3))
hold on

% Rhombus-fit maximum model (intersection of the red model-nose line and
% the blue rhombus-boundary line on the model envelope trade curve).
if strcmp(model_mode, 'axisymmetric')
    r_opt = dim_final/2;
    fill(r_opt*1e3*cos(ang_circ), r_opt*1e3*sin(ang_circ), ...
         [1 0.6 0.6], 'FaceAlpha', 0.5, 'EdgeColor', [0.8 0 0], 'LineWidth', 1.8, ...
         'DisplayName', sprintf('Max model (rhombus-fit) $d=%.1f$ mm', dim_final*1e3))
else
    hw_b = model_width/2;
    hh_o = dim_final/2;
    fill([-hw_b hw_b hw_b -hw_b -hw_b]*1e3, [-hh_o -hh_o hh_o hh_o -hh_o]*1e3, ...
         [1 0.6 0.6], 'FaceAlpha', 0.5, 'EdgeColor', [0.8 0 0], 'LineWidth', 1.8, ...
         'DisplayName', sprintf('Max model (rhombus-fit) $h=%.1f$ mm', dim_final*1e3))
end

% Overlay: model size that hits the target Re_L at the actual P0_driver
% (from Section 10). Shown as an unfilled outline so both can be compared.
if strcmp(model_mode, 'axisymmetric')
    r_ReL = dim_ReL/2;
    plot(r_ReL*1e3*cos(ang_circ), r_ReL*1e3*sin(ang_circ), ...
         'g--', 'LineWidth', 2, 'DisplayName', sprintf('$Re_L$ match $d=%.1f$ mm', dim_ReL*1e3))
else
    hh_r = dim_ReL/2;
    plot([-hw_b hw_b hw_b -hw_b -hw_b]*1e3, [-hh_r -hh_r hh_r hh_r -hh_r]*1e3, ...
         'g--', 'LineWidth', 2, 'DisplayName', sprintf('$Re_L$ match $h=%.1f$ mm', dim_ReL*1e3))
end

axis equal; grid on; box on
xlabel('$y$ [mm]', 'Interpreter','latex'); ylabel('$z$ [mm]', 'Interpreter','latex')
title('Frontal View -- Nozzle Exit Plane', 'Interpreter','latex')
legend('Location', 'best', 'FontSize', 8, 'Interpreter','latex')
text(0, r_exit*1e3*0.15, sprintf('Maximum fit: %.1f\\%%', blockage_pct), 'HorizontalAlignment', 'center', ...
     'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.6 0 0], 'Interpreter','latex')
text(0, -r_exit*1e3*0.15, sprintf('$Re_L$ match: %.1f\\%%', blockage_pct_ReL), 'HorizontalAlignment', 'center', ...
     'FontSize', 9, 'FontWeight', 'bold', 'Color', [0 0.45 0], 'Interpreter','latex')
% xlim([-r_exit, r_exit]);

% Full core-geometry side view 
nexttile(tl)
hold on

% Downstream (free-jet) rhombus + model overlay
x_down = linspace(0, L_rhombus_geo, 300);
r_down = max(0, r_exit - x_down*tand(mu_deg));
fill([x_down, fliplr(x_down)]*1e3, [r_down, -fliplr(r_down)]*1e3, ...
     [0.8 0.92 1], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', 'Downstream usable test section')
plot(x_down*1e3,  r_down*1e3, 'b-', 'LineWidth', 2, 'DisplayName', 'Downstream rhombus boundary')
plot(x_down*1e3, -r_down*1e3, 'b-', 'LineWidth', 2, 'HandleVisibility', 'off')

% Upstream rhombus (analytic mirror of the downstream one, see Section 5)
x_up = linspace(-L_rhombus_up, 0, 100);
r_up = (x_up + L_rhombus_up)*tand(mu_deg);
fill([x_up, fliplr(x_up)]*1e3, [r_up, -fliplr(r_up)]*1e3, ...
     [1 0.9 0.75], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', 'Upstream usable test section')
plot(x_up*1e3,  r_up*1e3, '-', 'Color', [0.85 0.5 0], 'LineWidth', 2, 'DisplayName', 'Upstream rhombus boundary')
plot(x_up*1e3, -r_up*1e3, '-', 'Color', [0.85 0.5 0], 'LineWidth', 2, 'HandleVisibility', 'off')

% Model overlay
if strcmp(model_mode, 'axisymmetric')
    half_dim = dim_final/2;
    fill([0, L_req, L_req, 0]*1e3, [0, half_dim, -half_dim, 0]*1e3, ...
         [1 0.6 0.6], 'FaceAlpha', 0.8, 'EdgeColor', [0.7 0 0], 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Model ($d=%.0f$ mm, $L=%.0f$ mm)', dim_final*1e3, L_req*1e3))
else
    half_h = dim_final/2;
    fill([0, L_req, L_req, 0]*1e3, [0, half_h, half_h, 0]*1e3, [1 0.6 0.6], ...
         'FaceAlpha', 0.8, 'EdgeColor', [0.7 0 0], 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Model ($h=%.0f$ mm, $L=%.0f$ mm)', dim_final*1e3, L_req*1e3))
    fill([0, L_req, L_req, 0]*1e3, -[0, half_h, half_h, 0]*1e3, [1 0.6 0.6], ...
         'FaceAlpha', 0.8, 'EdgeColor', [0.7 0 0], 'LineWidth', 1.5, 'HandleVisibility', 'off')
end

% Re_L-matched model overlay (Section 10): model size/length that hits
% target_Re_L at the actual/user-input P0_driver. Drawn as an unfilled
% green outline so it can be compared directly against the rhombus-fit
% model (filled red) above.
if strcmp(model_mode, 'axisymmetric')
    half_dim_ReL = dim_ReL/2;
    plot([0, L_ReL, L_ReL, 0, 0]*1e3, [0, half_dim_ReL, -half_dim_ReL, 0, 0]*1e3, ...
         'g--', 'LineWidth', 1.8, ...
         'DisplayName', sprintf('$Re_L$ match ($d=%.0f$ mm, $L=%.0f$ mm)', dim_ReL*1e3, L_ReL*1e3))
else
    half_h_ReL = dim_ReL/2;
    plot([0, L_ReL, L_ReL, 0, 0]*1e3, [0, half_h_ReL, half_h_ReL, 0, 0]*1e3, ...
         'g--', 'LineWidth', 1.8, ...
         'DisplayName', sprintf('$Re_L$ match ($h=%.0f$ mm, $L=%.0f$ mm)', dim_ReL*1e3, L_ReL*1e3))
    plot([0, L_ReL, L_ReL, 0, 0]*1e3, -[0, half_h_ReL, half_h_ReL, 0, 0]*1e3, ...
         'g--', 'LineWidth', 1.8, 'HandleVisibility', 'off')
end

xline(0, 'k-', 'LineWidth', 1, 'DisplayName', 'Nozzle exit plane')
yline(0, 'k:', 'LineWidth', 0.6, 'HandleVisibility', 'off')
xlabel('Axial distance from nozzle exit [mm]', 'Interpreter','latex')
ylabel('Radial / half-height [mm]', 'Interpreter','latex')
% daspect([1.5 1 1])
title(sprintf('Core Flow Geometry ($\\mu=%.1f^{\\circ}$)', mu_deg), 'Interpreter','latex')
legend('Location', 'northeast', 'FontSize', 7, 'Interpreter','latex'); grid on; box on
y_half_max = max([r_exit*1.5, dim_final/2*1.2, dim_ReL/2*1.2]);
ylim([-y_half_max y_half_max]*1e3)


% Operating envelope: Re/m vs p0 with Reynolds-equivalent altitude
nexttile(tl)
hold on
box on
grid on

yyaxis left
plot(P0_env_bar, Re_unit_env/1e6, 'k-', 'LineWidth', 2.0, 'DisplayName', 'Unit Reynolds number, $Re^{\prime}$')
ylabel('Unit Reynolds Number, $Re^{\prime}$ [$10^6$/m]', 'Interpreter','latex')

if exist('P0_required','var') && isfinite(P0_required)
    if P0_required/1e5 >= min(P0_env_bar) && P0_required/1e5 <= max(P0_env_bar)
        xline(P0_required/1e5, 'k--', 'LineWidth', 1.2, 'DisplayName', '$p_0$ required for target $Re_L$');
    end
end

if exist('target_Re_L','var') && exist('L_req','var') && L_req > 0
    Re_unit_target = target_Re_L / L_req;
    yline(Re_unit_target/1e6, 'k:', 'LineWidth', 1.2, 'DisplayName', 'Target $Re_L/L_{req}$');
end

yyaxis right
plot(P0_env_bar, h_eq_km, '-', 'LineWidth', 1.6, ...
     'DisplayName', 'Reynolds-equivalent altitude')
ylabel('Reynolds-equivalent altitude [km]', 'Interpreter','latex')

xlabel('Stagnation Pressure, $p_0$ [bar]', 'Interpreter','latex')
title(sprintf('Operating Envelope: $Re/m$ vs $p_0$ - $M=%.2f$', M_exit), 'Interpreter','latex')
legend('Location', 'best', 'FontSize', 7, 'Interpreter','latex')

% Summary text box 
nexttile(tl)
axis off
summary_str = {
    '\bf Core Flow Geometry'
    sprintf('Downstream rhombus : %.1f mm', L_rhombus_geo*1e3)
    sprintf('Upstream rhombus   : %.1f mm', L_rhombus_up*1e3)
    sprintf('Total core extent  : %.1f mm', L_core_total*1e3)
    ' '
    '\bf Model Sizing'
    sprintf('Mode              : %s', model_mode)
    sprintf('%s-max : %.1f mm', dim_label, dim_final*1e3)
    sprintf('L_{req}             : %.1f mm', L_req*1e3)
    sprintf('Blockage          : %.2f%%', blockage_pct)
    ' '
    '\bf Re_L Matching'
    sprintf('Target Re_L       : %.2e', target_Re_L)
    sprintf('P0-required (@L_{req}) : %.3f bar', P0_required/1e5)
    sprintf('New dump vol      : %.3f m^3', V_dump_new)
    sprintf('%s @ target Re_L: %.1f mm', dim_label, dim_ReL*1e3)
    sprintf('L @ target Re_L   : %.1f mm', L_ReL*1e3)
    sprintf('Blockage @ Re_L   : %.2f%%', blockage_pct_ReL)
};
text(0.03, 0.97, summary_str, ...
     'Units', 'normalized', 'VerticalAlignment', 'top', ...
     'FontSize', 9, 'FontName', 'FixedWidth', 'Interpreter', 'tex')

title(tl, sprintf( ...
    ['Ludwieg Tube Free Jet Analysis  :  $M=%.1f$  $\\vert$  ' '$D_e=%.0f$ mm  $\\vert$  $p_0=%.0f$ bar  $\\vert$  ' ...
     '$T_0=%.0f$ K  $\\vert$  $t_{run}=%.1f$ ms  $\\vert$  ' '$V_{dump}=%.2f$ m$^3$'], ...
    M_exit, D_exit*1e3, P0_driver/1e5, T0_driver, t_run*1e3, V_dump), ...
    'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'latex');


%% LOCAL FUNCTIONS

function [T_rat, P_rat, rho_rat, A_rat] = isentropic_ratios(g, M)
    % Ratios relative to stagnation condition and A/A* for a calorically perfect gas.
    T_rat   = 1/(1 + (g-1)/2*M^2);
    P_rat   = T_rat^(g/(g-1));
    rho_rat = T_rat^(1/(g-1));
    A_rat   = (1/M)*((2/(g+1))*(1 + (g-1)/2*M^2))^((g+1)/(2*(g-1)));
end

function mu = sutherland_mu(T, mu0, T0_S, S_C)
    % Dynamic viscosity from Sutherland's law [Pa.s].
    mu = mu0*(T/T0_S)^1.5*(T0_S + S_C)/(T + S_C);
end

function V_dump = indraft_vacuum_volume(A_throat, T_exit, t_run, PR_v, T0_driver, P_vac, P_exit, n)
    % Minimum vacuum tank volume from the indraft-tunnel sizing correlation
    % of Pope & Goin (1965), evaluated in imperial units and returned in m^3.
    dr = 1 - (P_vac/P_exit)^(1/n);
    if dr <= 0
        warning('Vacuum tank denominator <= 0. Check that P_vac << P_exit.');
        V_dump = NaN;
        return
    end

    V_dump = ((28.35*(A_throat*10.7639)*(T_exit*1.8)*t_run*PR_v) / ...
             (((T0_driver*1.8)^0.5)*dr))*0.0283168;
end
