-- Copyright (C) 2023 NORCE
----------------------------------------------------------------------------
RUNSPEC
----------------------------------------------------------------------------
DIMENS 
${dic['noCells'][0]} ${dic['noCells'][1]} ${dic['noCells'][2]} /

EQLDIMS
/

TABDIMS
${dic['noSands']} 1* ${dic['tabdims']} /

% if dic["co2store"] == "gaswater":
WATER
% else:
OIL
% endif
GAS
CO2STORE
% if dic['model'] == 'complete':
% if dic["co2store"] == "gaswater":
DISGASW
VAPWAT
% if dic["flow_version"] != "2023.10" and (dic["diffusion"][0] + dic["diffusion"][1]) > 0:
DIFFUSE
% endif
% else:
DISGAS
VAPOIL
% if (dic["diffusion"][0] + dic["diffusion"][1]) > 0:
DIFFUSE
% endif
% endif
THERMAL
% endif

METRIC

START
1 'JAN' 2025 /

WELLDIMS
${len(dic['wellijk'])} ${1+max(dic['wellijkf'][0][1]-dic['wellijk'][0][1], dic['wellijkf'][1][1]-dic['wellijk'][1][1])} ${len(dic['wellijk'])} ${len(dic['wellijk'])} /

UNIFIN
UNIFOUT
----------------------------------------------------------------------------
GRID
----------------------------------------------------------------------------
INIT

INCLUDE
'GRID.INC' /

INCLUDE
'PERMX.INC' /

COPY 
PERMX PERMY /
PERMX PERMZ /
/

% if dic["kzMult"] > 0:
MULTIPLY
PERMZ ${dic["kzMult"]} /
/
% endif

INCLUDE
'PORO.INC' /

% if dic['model'] == 'complete':
INCLUDE
'THCONR.INC' /
% endif

% if dic["version"] == "master" and dic["dispersion"] > 0 and dic["flow_version"] != "2023.10":
DISPERC 
${dic['noCells'][0]*dic['noCells'][1]*dic['noCells'][2]}*${dic["dispersion"]} /
% endif
----------------------------------------------------------------------------
PROPS
----------------------------------------------------------------------------
INCLUDE
'TABLES.INC' /

% if dic['model'] == 'complete':
% if dic["co2store"] == "gaswater":
% if dic["flow_version"] != "2023.10" and (dic["diffusion"][0] + dic["diffusion"][1]) > 0:
DIFFCWAT
${dic["diffusion"][0]} ${dic["diffusion"][0]} /

DIFFCGAS
${dic["diffusion"][1]} ${dic["diffusion"][1]} /
% endif
% else:
% if (dic["diffusion"][0] + dic["diffusion"][1]) > 0:
DIFFC
1 1 ${dic["diffusion"][1]} ${dic["diffusion"][1]} ${dic["diffusion"][0]} ${dic["diffusion"][0]} / --The molecular weights are set to 1 since the diffusion coefficients are given for mass fractions
% endif
% endif

SPECROCK
% for i in range(dic['noSands']): 
${dic["temperature"][1]} ${dic["rockExtra"][0]}
${dic["temperature"][0]} ${dic["rockExtra"][0]} /
% endfor
% endif
----------------------------------------------------------------------------
REGIONS
----------------------------------------------------------------------------
INCLUDE
'SATNUM.INC' /
INCLUDE
'FIPNUM.INC' /
----------------------------------------------------------------------------
SOLUTION
---------------------------------------------------------------------------
EQUIL
0 ${dic['pressure']/1.E5} ${0 if dic["co2store"] == "gaswater" else dic['dims'][2]} 0 0 0 1 1 0 /

RPTRST
% if dic['model'] == 'immiscible': 
'BASIC=2' FLOWS FLORES DEN/
% else:
'BASIC=2' DEN KRG/
%endif

% if dic['model'] == 'complete':
% if dic["co2store"] == "gasoil":
RSVD
0   0.0
${dic['dims'][2]} 0.0 /

RVVD
0   0.0
${dic['dims'][2]} 0.0 /
% endif

RTEMPVD
0   ${dic["temperature"][1]}
${dic['dims'][2] + dic['elevation']} ${dic["temperature"][0]} /
% endif
----------------------------------------------------------------------------
SUMMARY
----------------------------------------------------------------------------
PERFORMA
FGIP
FGIR
FGIT
WBHP
/
WGIR
/
WGIT
/
----------------------------------------------------------------------------
SCHEDULE
----------------------------------------------------------------------------
RPTRST
% if dic['model'] == 'immiscible': 
'BASIC=2' FLOWS FLORES DEN/
% else:
'BASIC=2' DEN KRG/
%endif

WELSPECS
% for i in range(len(dic['wellijk'])):
'INJ${i}' 'G1' ${dic['wellijk'][i][0]} ${dic['wellijk'][i][1]} 1* 'GAS' ${dic['radius'][i]}/
% endfor
/
COMPDAT
% for i in range(len(dic['wellijk'])):
% for j in range(1+dic['wellijkf'][i][1]-dic['wellijk'][i][1]):
% if i==0:
'INJ${i}' ${dic['wellijk'][i][0]} ${dic['wellijk'][i][1]+j} ${dic['wellijk'][i][2]}	${dic['wellijk'][i][2]}	'OPEN' 1* 1* ${2.*dic['radius'][i]} /
% else:
'INJ${i}' ${dic['wellijk'][i][0]} ${dic['wellijk'][i][1]+j}	${dic['wellkh'][j]} ${dic['wellkh'][j]} 'OPEN' 1* 1* ${2.*dic['radius'][i]} /
%endif
% endfor
% endfor
/

% for j in range(len(dic['inj'])):
TUNING
1e-2 ${dic['inj'][j][2] / 86400.} 1e-10 2* 1e-12/
/
/
WCONINJE
% for i in range(len(dic['wellijk'])):
% if dic['inj'][j][3+3*i] > 0:
'INJ${i}' 'GAS' ${'OPEN' if dic['inj'][j][4+3*i] > 0 else 'SHUT'}
'RATE' ${f"{dic['inj'][j][4+3*i] * 86400 / 1.86843 : E}"}  1* 400/
% else:
'INJ${i}' ${'WATER' if dic['co2store'] == 'gaswater' else 'OIL'} ${'OPEN' if dic['inj'][j][4+3*i] > 0 else 'SHUT'}
'RATE' ${f"{dic['inj'][j][4+3*i] * 86400 / 998.108 : E}"}  1* 400/
%endif
% endfor
/
% if dic['model'] == 'complete':
WTEMP
% for i in range(len(dic['wellijk'])):
'INJ${i}' ${dic['inj'][j][5+3*i]} /
% endfor
/
%endif
TSTEP
${round(dic['inj'][j][0]/dic['inj'][j][1])}*${dic['inj'][j][1] / 86400.}
/
% endfor