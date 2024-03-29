clear all;close all;clc;
tic
% this will take the model output  and interpolate from sigma levels onto
% pressure levels and saves in a file called u_interp_the number of the
% file
%load axis_stuff_64; % load the values for latitude, longitude etc for the T42 hybrid model setup

% sigma interpolation values
b = [0 0.0000189 .0000472 .000102 .000199 .000358 ...
     .000606 .001 .0015 .0023 .0033 .0046 .0064 ...
     .0086 .0115 .0150 .0194 .0248 .0312 .0390 .0483 ...
     .0592 .0720 .0870 .1044 .1244 .1473 .1736 .2035 ...
     .2373 .2755 .3185 .3666 .4205 .4805 .5471 .6209 ...
     .7025 .7925 .8914 1.0];
reference_press=100000.0000000000;
a=zeros(1,41); 
a=reference_press*a;
P_inter1=[0.0212    0.0330    0.0746    0.1505    0.2785    0.4820    0.8030    1.2500    1.9000    2.8000    3.9500    5.5000    7.5000 ...
 10.0500   13.2500   17.2000   22.1000   28.0000   35.1000   43.6500   53.7500   65.6000   79.5000   95.7000  114.4000  135.8500 ...
 160.4500  188.5500  220.4000  256.4000  297.0000  342.5500  393.5500  450.5000  513.8000  584.0000  661.7000  747.5000  841.9500 925.0000];
P_inter=P_inter1';

u=ncread('./apr1/01_atmos_daily.nc','ucomp');
'interpolating u'
[tt jj kk ll]=size(u);
u_interp=squeeze(zeros(tt,jj,kk,ll));
ps=ncread('./apr1/01_atmos_daily.nc','ps');
bk=ncread('./apr1/01_atmos_daily.nc','bk');
sig=diff(bk)/2+bk(1:end-1);

for t=1:tt
      for l=1:ll
        for j = 1:jj
          ps1=squeeze(ps(t,j,l));
		Pr=(a+b.*ps1)./100;Prr=diff(Pr)/2+Pr(1:end-1);
          	u_interp(t,j,:,l)=interp1(Prr,squeeze(u(t,j,:,l)),P_inter,'spline');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is to Nan data that is "in" the mountain

if max(Pr)<max(P_inter)
	mtn=find(max(Pr)<P_inter);
	u_interp(t,j,mtn,l)=NaN;
end
clear mtn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
      end
%t
end
clear u
u_interp_01=u_interp;
save('./apr1/u_interp_01','u_interp_01');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% interpolate v
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
v=ncread('./apr1/01_atmos_daily.nc','vcomp');
'interpolating v'
[tt jj kk ll]=size(v);
v_interp=squeeze(zeros(tt,jj,kk,ll));
for t=1:tt
      for l=1:ll
        for j = 1:jj
          ps1=squeeze(ps(t,j,l));
          	Pr=(a+b.*ps1)./100;Prr=diff(Pr)/2+Pr(1:end-1);
		v_interp(t,j,:,l)=interp1(Prr,squeeze(v(t,j,:,l)),P_inter,'spline');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is to Nan data that is "in" the mountain

if max(Pr)<max(P_inter)
  mtn=find(max(Pr)<P_inter);
v_interp(t,j,mtn,l)=NaN;
end
clear mtn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
      end
%t
end
clear v
v_interp_01=v_interp;
save('./apr1/v_interp_01','v_interp_01');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% interpolate T
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T=ncread('./apr1/01_atmos_daily.nc','temp');
[tt jj kk ll]=size(T);
'interpolating T'
T_interp=squeeze(zeros(tt,jj,kk,ll));
for t=1:tt
      for l=1:ll
        for j = 1:jj
          ps1=squeeze(ps(t,j,l));
          	Pr=(a+b.*ps1)./100;Prr=diff(Pr)/2+Pr(1:end-1);
            T_interp(t,j,:,l)=interp1(Prr,squeeze(T(t,j,:,l)),P_inter,'spline');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is to Nan data that is "in" the mountain
if max(Pr)<max(P_inter)
  mtn=find(max(Pr)<P_inter);
T_interp(t,j,mtn,l)=NaN;
end
clear mtn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
      end
%t
end
clear T
T_interp_01=T_interp;
save('./apr1/T_interp_01','T_interp_01');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% interpolate geopotential height
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
geopot=ncread('./apr1/01_atmos_daily.nc','height');
'interpolating h'
[tt jj kk ll]=size(geopot);
h_interp=squeeze(zeros(tt,jj,kk,ll));
for t=1:tt
      for l=1:ll
        for j = 1:jj
          ps1=squeeze(ps(t,j,l));
 		Pr=(a+b.*ps1)./100; Prr=diff(Pr)/2+Pr(1:end-1);
          h_interp(t,j,:,l)=interp1(Prr,squeeze(geopot(t,j,:,l)),P_inter,'spline');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is to Nan data that is "in" the mountain

if max(Pr)<max(P_inter)
  mtn=find(max(Pr)<P_inter);
h_interp(t,j,mtn,l)=NaN;
end
clear mtn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
      end
%t
end

clear geopot
h_interp_01=h_interp;
save('./apr1/h_interp_01','h_interp_01');
toc
