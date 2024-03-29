!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!                                                                   !!
!!                   GNU General Public License                      !!
!!                                                                   !!
!! This file is part of the Flexible Modeling System (FMS).          !!
!!                                                                   !!
!! FMS is free software; you can redistribute it and/or modify       !!
!! it and are expected to follow the terms of the GNU General Public !!
!! License as published by the Free Software Foundation.             !!
!!                                                                   !!
!! FMS is distributed in the hope that it will be useful,            !!
!! but WITHOUT ANY WARRANTY; without even the implied warranty of    !!
!! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     !!
!! GNU General Public License for more details.                      !!
!!                                                                   !!
!! You should have received a copy of the GNU General Public License !!
!! along with FMS; if not, write to:                                 !!
!!          Free Software Foundation, Inc.                           !!
!!          59 Temple Place, Suite 330                               !!
!!          Boston, MA  02111-1307  USA                              !!
!! or see:                                                           !!
!!          http://www.gnu.org/licenses/gpl.txt                      !!
!!                                                                   !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module shallow_dynamics_mod

use               fms_mod, only: open_namelist_file,   &
                                 open_restart_file,    &
                                 file_exist,           &
                                 check_nml_error,      &
                                 error_mesg,           &
                                 FATAL,                &
                                 write_version_number, &
                                 mpp_pe,               &
                                 mpp_root_pe,          &
                                 read_data,            &
                                 write_data,           &
                                 set_domain,           &
                                 close_file,           &
                                 stdlog

use    time_manager_mod,  only : time_type,      &
                                 get_time,       &
                                 operator(==),   &
                                 operator(-)

use       constants_mod,  only : radius, omega

use         transforms_mod, only: transforms_init,         transforms_end,          &
                                  get_grid_boundaries,     horizontal_advection,    &
                                  trans_spherical_to_grid, trans_grid_to_spherical, &  
                                  compute_laplacian,       get_eigen_laplacian,     &
                                  get_sin_lat,             get_cos_lat,             &
                                  get_deg_lon,             get_deg_lat,             &
                                  get_grid_domain,         get_spec_domain,         &
                                  spectral_domain,         grid_domain,             &
                                  vor_div_from_uv_grid,    uv_grid_from_vor_div

use   spectral_damping_mod, only: spectral_damping_init,   compute_spectral_damping

use           leapfrog_mod, only: leapfrog

use       fv_advection_mod, only : fv_advection_init, a_grid_horiz_advection

!======================================================================================
implicit none
private
!======================================================================================

public :: shallow_dynamics_init, shallow_dynamics, shallow_dynamics_end, &
          dynamics_type, grid_type, spectral_type, tendency_type


! version information 
!===================================================================
character(len=128) :: version = '$Id: shallow_dynamics.f90,v 10.0 2003/10/27 23:31:04 arl Exp $'
character(len=128) :: tagname = '$Name:  $'
!===================================================================

type grid_type
   real, pointer, dimension(:,:,:) :: u=>NULL(), v=>NULL(), vor=>NULL(), div=>NULL(), h=>NULL(), trs=>NULL(), tr=>NULL()
   real, pointer, dimension(:,:)   :: stream=>NULL(), pv=>NULL()
end type
type spectral_type
   complex, pointer, dimension(:,:,:) :: vor=>NULL(), div=>NULL(), h=>NULL(), trs=>NULL()
end type
type tendency_type
   real, pointer, dimension(:,:) :: u=>NULL(), v=>NULL(), h=>NULL(), trs=>NULL(), tr=>NULL()
end type
type dynamics_type
   type(grid_type)     :: grid
   type(spectral_type) :: spec
   type(tendency_type) :: tend
   integer             :: num_lon, num_lat
   logical             :: grid_tracer, spec_tracer
end type



integer, parameter :: num_time_levels = 2

integer :: is, ie, js, je, ms, me, ns, ne

logical :: module_is_initialized = .false.

real,  allocatable, dimension(:) :: sin_lat, cos_lat, rad_lat, deg_lat, deg_lon, &
                                    coriolis

real,  allocatable, dimension(:,:) :: eigen

integer :: pe, npes


! namelist parameters with default values

integer :: num_lon            = 256 
integer :: num_lat            = 128
integer :: num_fourier        = 85
integer :: num_spherical      = 86
integer :: fourier_inc         = 1
! (these define a standard T85 model)

logical :: check_fourier_imag = .false.
logical :: south_to_north     = .true.
logical :: triang_trunc   = .true.

real    :: robert_coeff        = 0.04
real    :: robert_coeff_tracer = 0.04
real    :: longitude_origin    = 0.0

character(len=64) :: damping_option = 'resolution_dependent'
integer :: damping_order       = 4
real    :: damping_coeff       = 1.e-04
real    :: h_0                 = 3.e04

logical :: spec_tracer      = .true.
logical :: grid_tracer      = .true.

real, dimension(2) :: valid_range_v = (/-1.e3,1.e3/)

namelist /shallow_dynamics_nml/ check_fourier_imag,          &
                          south_to_north, triang_trunc,      &
                          num_lon, num_lat, num_fourier,     &
                          num_spherical, fourier_inc,        &
                          longitude_origin, damping_option,  &
                          damping_order,     damping_coeff,  &
                          robert_coeff, robert_coeff_tracer, &
                          h_0, spec_tracer, grid_tracer,     &
                          valid_range_v

contains

!=======================================================================================

subroutine shallow_dynamics_init (Dyn,  Time, Time_init)

type(dynamics_type), intent(inout)  :: Dyn
type(time_type)    , intent(in)     :: Time, Time_init

integer :: i, j

real,    allocatable, dimension(:)   :: glon_bnd, glat_bnd
real :: xx, yy, dd

integer  :: ierr, io, unit
logical  :: root

! < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > 

call write_version_number (version, tagname)

pe   =  mpp_pe()
root = (pe == mpp_root_pe())

if (file_exist('input.nml')) then
  unit = open_namelist_file ()
  ierr=1
  do while (ierr /= 0)
    read  (unit, nml=shallow_dynamics_nml, iostat=io, end=10)
    ierr = check_nml_error (io, 'shallow_dynamics_nml')
  enddo
  10 call close_file (unit)
endif

if (root) write (stdlog(), nml=shallow_dynamics_nml)

call transforms_init(radius, num_lat, num_lon, num_fourier, fourier_inc, num_spherical, &
         south_to_north=south_to_north,   &
         triang_trunc=triang_trunc,       &
         longitude_origin=longitude_origin       )

call get_grid_domain(is,ie,js,je)
call get_spec_domain(ms,me,ns,ne)

Dyn%num_lon = num_lon
Dyn%num_lat = num_lat
Dyn%spec_tracer  = spec_tracer
Dyn%grid_tracer  = grid_tracer

allocate (sin_lat   (js:je))
allocate (cos_lat   (js:je))
allocate (deg_lat   (js:je))
allocate (deg_lon   (is:ie))
allocate (coriolis  (js:je))

call get_deg_lon (deg_lon)
call get_deg_lat (deg_lat)
call get_sin_lat (sin_lat)
call get_cos_lat (cos_lat)

allocate (glon_bnd  (num_lon + 1))
allocate (glat_bnd  (num_lat + 1))
call get_grid_boundaries (glon_bnd, glat_bnd, global=.true.)

coriolis = 2*omega*sin_lat

call spectral_damping_init(damping_coeff, damping_order, damping_option, num_fourier, num_spherical, 1, 0., 0., 0.)

allocate(eigen(ms:me,ns:ne))
call get_eigen_laplacian(eigen)

allocate (Dyn%spec%vor (ms:me, ns:ne, num_time_levels))
allocate (Dyn%spec%div (ms:me, ns:ne, num_time_levels))
allocate (Dyn%spec%h   (ms:me, ns:ne, num_time_levels))

allocate (Dyn%grid%u   (is:ie, js:je, num_time_levels))
allocate (Dyn%grid%v   (is:ie, js:je, num_time_levels))
allocate (Dyn%grid%vor (is:ie, js:je, num_time_levels))
allocate (Dyn%grid%div (is:ie, js:je, num_time_levels))
allocate (Dyn%grid%h   (is:ie, js:je, num_time_levels))

allocate (Dyn%tend%u        (is:ie, js:je))
allocate (Dyn%tend%v        (is:ie, js:je))
allocate (Dyn%tend%h        (is:ie, js:je))
allocate (Dyn%grid%stream   (is:ie, js:je))
allocate (Dyn%grid%pv       (is:ie, js:je))

call fv_advection_init(num_lon, num_lat, glat_bnd, 360./float(fourier_inc))
if(Dyn%grid_tracer) then
  allocate(Dyn%Grid%tr (is:ie, js:je, num_time_levels))
  allocate(Dyn%Tend%tr (is:ie, js:je))
endif

if(Dyn%spec_tracer) then
  allocate(Dyn%Grid%trs (is:ie, js:je, num_time_levels))
  allocate(Dyn%Tend%trs (is:ie, js:je))
  allocate(Dyn%Spec%trs (ms:me, ns:ne, num_time_levels))
endif

if(Time == Time_init) then

  Dyn%Grid%vor(:,:,1) = 0.0
  Dyn%Grid%div(:,:,1) = 0.0
  Dyn%Grid%h  (:,:,1) = h_0
    
  call trans_grid_to_spherical(Dyn%Grid%vor(:,:,1), Dyn%Spec%vor(:,:,1))
  call trans_grid_to_spherical(Dyn%Grid%div(:,:,1), Dyn%Spec%div(:,:,1))
  call trans_grid_to_spherical(Dyn%Grid%h  (:,:,1), Dyn%Spec%h  (:,:,1))

  call uv_grid_from_vor_div   (Dyn%Spec%vor(:,:,1), Dyn%Spec%div(:,:,1),  &
                               Dyn%Grid%u  (:,:,1), Dyn%Grid%v  (:,:,1))
  
  if(Dyn%grid_tracer) then
    Dyn%Grid%tr = 0.0
    do j = js, je
      if(deg_lat(j) > 10.0 .and. deg_lat(j) < 20.0) Dyn%Grid%tr(:,j,1) =  1.0
      if(deg_lat(j) > 70.0 )                        Dyn%Grid%tr(:,j,1) = -1.0
    end do
  endif
  
  if(Dyn%spec_tracer) then
    Dyn%Grid%trs = 0.0
    do j = js, je
      if(deg_lat(j) > 10.0 .and. deg_lat(j) < 20.0) Dyn%Grid%trs(:,j,1) =  1.0
      if(deg_lat(j) > 70.0 )                        Dyn%Grid%trs(:,j,1) = -1.0
    end do
    call trans_grid_to_spherical(Dyn%Grid%trs(:,:,1), Dyn%Spec%trs(:,:,1))
  endif
  
else

  call read_restart(Dyn)
  
endif

module_is_initialized = .true.

return
end subroutine shallow_dynamics_init

!========================================================================================

subroutine shallow_dynamics(Time, Time_init, Dyn, previous, current, future, delta_t)

type(time_type)    , intent(in)    :: Time, Time_init
type(dynamics_type), intent(inout) :: Dyn
integer, intent(in   )  :: previous, current, future
real,    intent(in   )  :: delta_t

! < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < >

complex, dimension(ms:me, ns:ne)  :: dt_vors, dt_divs, dt_hs, stream, bs, work
real,    dimension(is:ie, js:je)  :: vorg, bg, h_future, h_dt, dt_vorg
integer :: j

! < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > < > 

if(.not.module_is_initialized) then
  call error_mesg('shallow_dynamics','dynamics has not been initialized ', FATAL)
endif


do j = js,je
  vorg(:,j) = Dyn%Grid%vor(:,j,current) + coriolis(j) 
end do
Dyn%Tend%u = Dyn%Tend%u + vorg*Dyn%Grid%v(:,:,current)
Dyn%Tend%v = Dyn%Tend%v - vorg*Dyn%Grid%u(:,:,current)

call vor_div_from_uv_grid (Dyn%Tend%u, Dyn%Tend%v, dt_vors, dt_divs)

call horizontal_advection (Dyn%Spec%h(:,:,current),   &
         Dyn%Grid%u(:,:,current), Dyn%Grid%v(:,:,current), Dyn%Tend%h)

Dyn%Tend%h = Dyn%Tend%h - Dyn%Grid%h(:,:,current)*Dyn%Grid%div(:,:,current)

call trans_grid_to_spherical (Dyn%Tend%h, dt_hs)

bg = (Dyn%Grid%h(:,:,current) + &
   0.5*(Dyn%Grid%u(:,:,current)**2 + Dyn%Grid%v(:,:,current)**2))

call trans_grid_to_spherical(bg, bs)
dt_divs = dt_divs - compute_laplacian(bs)

call implicit_correction (dt_divs, dt_hs, Dyn%Spec%div, Dyn%Spec%h, &
                            delta_t, previous, current)

call compute_spectral_damping(Dyn%Spec%vor(:,:,previous), dt_vors, delta_t)
call compute_spectral_damping(Dyn%Spec%div(:,:,previous), dt_divs, delta_t)
call compute_spectral_damping(Dyn%Spec%h  (:,:,previous), dt_hs  , delta_t)

call leapfrog(Dyn%Spec%vor , dt_vors  , previous, current, future, delta_t, robert_coeff)
call leapfrog(Dyn%Spec%div , dt_divs  , previous, current, future, delta_t, robert_coeff)
call leapfrog(Dyn%Spec%h   , dt_hs    , previous, current, future, delta_t, robert_coeff)

call trans_spherical_to_grid(Dyn%Spec%vor(:,:,future), Dyn%Grid%vor(:,:,future))
call trans_spherical_to_grid(Dyn%Spec%div(:,:,future), Dyn%Grid%div(:,:,future))
  

call uv_grid_from_vor_div  (Dyn%Spec%vor (:,:,future),  Dyn%Spec%div(:,:,future), &
                            Dyn%Grid%u   (:,:,future),  Dyn%Grid%v  (:,:,future))

call trans_spherical_to_grid (Dyn%Spec%h (:,:,future),  Dyn%Grid%h(:,:,future))

if(minval(Dyn%Grid%v) < valid_range_v(1) .or. maxval(Dyn%Grid%v) > valid_range_v(2)) then
  call error_mesg('shallow_dynamics','meridional wind out of valid range', FATAL)
endif

if(Dyn%spec_tracer) call update_spec_tracer(Dyn%Spec%trs, Dyn%Grid%trs, Dyn%Tend%trs, &
                         Dyn%Grid%u, Dyn%Grid%v, previous, current, future, delta_t)

if(Dyn%grid_tracer) call update_grid_tracer(Dyn%Grid%tr, Dyn%Tend%tr, &
                         Dyn%Grid%u, Dyn%Grid%v, previous, current, future, delta_t)


!  for diagnostics

stream = compute_laplacian(Dyn%Spec%vor(:,:,current), -1) ! for diagnostic purposes
call trans_spherical_to_grid(stream, Dyn%grid%stream)

Dyn%Grid%pv = vorg/Dyn%Grid%h(:,:,current)

return
end subroutine shallow_dynamics
!================================================================================

subroutine implicit_correction(dt_divs, dt_hs, divs, hs, delta_t, previous, current)

complex, intent(inout), dimension(ms:,ns:)   :: dt_divs, dt_hs
complex, intent(in),    dimension(ms:,ns:,:) :: divs, hs
real   , intent(in)                          :: delta_t
integer, intent(in)                          :: previous, current

real :: xi, mu, mu2

xi    = 0.5 ! centered implicit   (for backwards implicit, set xi = 1.0)

mu  = xi*delta_t
mu2 = mu*mu

dt_hs   = dt_hs + h_0*(divs(:,:,current) - divs(:,:,previous))
dt_divs = dt_divs - eigen*(hs(:,:,current) - hs(:,:,previous))

dt_divs = (dt_divs + mu*eigen*dt_hs)/(1.0 + mu2*eigen*h_0)
dt_hs   =  dt_hs - mu*h_0*dt_divs

return
end subroutine implicit_correction 

!===================================================================================

subroutine update_spec_tracer(tr_spec, tr_grid, dt_tr, ug, vg, &
                              previous, current, future, delta_t)

complex, intent(inout), dimension(ms:me, ns:ne, num_time_levels) :: tr_spec
real   , intent(inout), dimension(is:ie, js:je, num_time_levels) :: tr_grid
real   , intent(inout), dimension(is:ie, js:je                 ) :: dt_tr
real   , intent(in   ), dimension(is:ie, js:je, num_time_levels) :: ug, vg  
real   , intent(in   )  :: delta_t
integer, intent(in   )  :: previous, current, future

complex, dimension(ms:me, ns:ne) :: dt_trs

call horizontal_advection     (tr_spec(:,:,current), ug(:,:,current), vg(:,:,current), dt_tr)
call trans_grid_to_spherical  (dt_tr, dt_trs)
call compute_spectral_damping (tr_spec(:,:,previous), dt_trs, delta_t)
call leapfrog                 (tr_spec, dt_trs, previous, current, future, delta_t, robert_coeff)
call trans_spherical_to_grid  (tr_spec(:,:,future), tr_grid(:,:,future))

return
end subroutine update_spec_tracer
!==========================================================================

subroutine update_grid_tracer(tr_grid, dt_tr_grid, ug, vg, &
                              previous, current, future, delta_t)

real   , intent(inout), dimension(is:ie, js:je, num_time_levels) :: tr_grid
real   , intent(inout), dimension(is:ie, js:je                 ) :: dt_tr_grid
real   , intent(in   ), dimension(is:ie, js:je, num_time_levels) :: ug, vg

real   , intent(in   )  :: delta_t
integer, intent(in   )  :: previous, current, future

real, dimension(is:ie,js:je) :: tr_current, tr_future

tr_future = tr_grid(:,:,previous) + delta_t*dt_tr_grid
dt_tr_grid = 0.0
call a_grid_horiz_advection (ug(:,:,current), vg(:,:,current), tr_future, delta_t, dt_tr_grid)
tr_future = tr_future + delta_t*dt_tr_grid
tr_current = tr_grid(:,:,current) + &
    robert_coeff_tracer*(tr_grid(:,:,previous) + tr_future - 2.0*tr_grid(:,:,current))
tr_grid(:,:,current) = tr_current
tr_grid(:,:,future)  = tr_future

return
end subroutine update_grid_tracer

!==========================================================================

subroutine read_restart(Dyn)

type(dynamics_type), intent(inout)  :: Dyn

integer :: unit, m, n, nt
real, dimension(ms:me, ns:ne) :: real_part, imag_part

if(file_exist('INPUT/shallow_dynamics.res.nc')) then
  do nt = 1, 2
    call read_data('INPUT/shallow_dynamics.res.nc', 'vors_real', real_part, spectral_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'vors_imag', imag_part, spectral_domain, timelevel=nt)
    do n=ns,ne
      do m=ms,me
        Dyn%Spec%vor(m,n,nt) = cmplx(real_part(m,n),imag_part(m,n))
      end do
    end do
    call read_data('INPUT/shallow_dynamics.res.nc', 'divs_real', real_part, spectral_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'divs_imag', imag_part, spectral_domain, timelevel=nt)
    do n=ns,ne
      do m=ms,me
        Dyn%Spec%div(m,n,nt) = cmplx(real_part(m,n),imag_part(m,n))
      end do
    end do
    call read_data('INPUT/shallow_dynamics.res.nc', 'hs_real', real_part, spectral_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'hs_imag', imag_part, spectral_domain, timelevel=nt)
    do n=ns,ne
      do m=ms,me
        Dyn%Spec%h(m,n,nt) = cmplx(real_part(m,n),imag_part(m,n))
      end do
    end do
    if(Dyn%spec_tracer) then
      call read_data('INPUT/shallow_dynamics.res.nc', 'trs_real', real_part, spectral_domain, timelevel=nt)
      call read_data('INPUT/shallow_dynamics.res.nc', 'trs_imag', imag_part, spectral_domain, timelevel=nt)
      do n=ns,ne
        do m=ms,me
          Dyn%Spec%trs(m,n,nt) = cmplx(real_part(m,n),imag_part(m,n))
        end do
      end do
    endif
    call read_data('INPUT/shallow_dynamics.res.nc', 'u',   Dyn%Grid%u  (:,:,nt), grid_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'v',   Dyn%Grid%v  (:,:,nt), grid_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'vor', Dyn%Grid%vor(:,:,nt), grid_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'div', Dyn%Grid%div(:,:,nt), grid_domain, timelevel=nt)
    call read_data('INPUT/shallow_dynamics.res.nc', 'h',   Dyn%Grid%h  (:,:,nt), grid_domain, timelevel=nt)
    if(Dyn%spec_tracer) then
      call read_data('INPUT/shallow_dynamics.res.nc', 'trs', Dyn%Grid%trs(:,:,nt), grid_domain, timelevel=nt)
    endif
    if(Dyn%grid_tracer) then
      call read_data('INPUT/shallow_dynamics.res.nc', 'tr', Dyn%Grid%tr(:,:,nt), grid_domain, timelevel=nt)
    endif
  end do
else if(file_exist('INPUT/shallow_dynamics.res')) then
  unit = open_restart_file(file='INPUT/shallow_dynamics.res',action='read')

  do nt = 1, 2
    call set_domain(spectral_domain)
    call read_data(unit,Dyn%Spec%vor(:,:, nt))
    call read_data(unit,Dyn%Spec%div(:,:, nt))
    call read_data(unit,Dyn%Spec%h  (:,:, nt))
    if(Dyn%spec_tracer) call read_data(unit,Dyn%Spec%trs(:,:, nt))

    call set_domain(grid_domain)
    call read_data(unit,Dyn%Grid%u   (:,:, nt))
    call read_data(unit,Dyn%Grid%v   (:,:, nt))
    call read_data(unit,Dyn%Grid%vor (:,:, nt))
    call read_data(unit,Dyn%Grid%div (:,:, nt))
    call read_data(unit,Dyn%Grid%h   (:,:, nt))
    if(Dyn%spec_tracer) call read_data(unit,Dyn%Grid%trs(:,:, nt))
    if(Dyn%grid_tracer) call read_data(unit,Dyn%Grid%tr (:,:, nt))
    
  end do
  call close_file(unit)
  
else
    call error_mesg('read_restart', 'restart does not exist', FATAL)
endif
  
return
end subroutine read_restart

!====================================================================

subroutine write_restart(Dyn, previous, current)

type(dynamics_type), intent(in)  :: Dyn
integer, intent(in) :: previous, current

integer :: unit, nt, nn

do nt = 1, 2
  if(nt == 1) nn = previous
  if(nt == 2) nn = current
  call write_data('RESTART/shallow_dynamics.res.nc', 'vors_real',  real(Dyn%Spec%vor(:,:,nn)), spectral_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'vors_imag', aimag(Dyn%Spec%vor(:,:,nn)), spectral_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'divs_real',  real(Dyn%Spec%div(:,:,nn)), spectral_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'divs_imag', aimag(Dyn%Spec%div(:,:,nn)), spectral_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'hs_real',    real(Dyn%Spec%h  (:,:,nn)), spectral_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'hs_imag',   aimag(Dyn%Spec%h  (:,:,nn)), spectral_domain)
  if(Dyn%spec_tracer) then
    call write_data('RESTART/shallow_dynamics.res.nc', 'trs_real',  real(Dyn%Spec%trs(:,:,nn)), spectral_domain)
    call write_data('RESTART/shallow_dynamics.res.nc', 'trs_imag', aimag(Dyn%Spec%trs(:,:,nn)), spectral_domain)
  endif
  call write_data('RESTART/shallow_dynamics.res.nc', 'u',   Dyn%Grid%u  (:,:,nn), grid_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'v',   Dyn%Grid%v  (:,:,nn), grid_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'vor', Dyn%Grid%vor(:,:,nn), grid_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'div', Dyn%Grid%div(:,:,nn), grid_domain)
  call write_data('RESTART/shallow_dynamics.res.nc', 'h',   Dyn%Grid%h  (:,:,nn), grid_domain)
  if(Dyn%spec_tracer) then
    call write_data('RESTART/shallow_dynamics.res.nc', 'trs', Dyn%Grid%trs(:,:,nn), grid_domain)
  endif
  if(Dyn%grid_tracer) then
    call write_data('RESTART/shallow_dynamics.res.nc', 'tr', Dyn%Grid%tr(:,:,nn), grid_domain)
  endif
enddo

!unit = open_restart_file(file='RESTART/shallow_dynamics.res', action='write')

!do n = 1, 2
!  if(n == 1) nn = previous
!  if(n == 2) nn = current
!  
!  call set_domain(spectral_domain)
!  call write_data(unit,Dyn%Spec%vor(:,:, nn))
!  call write_data(unit,Dyn%Spec%div(:,:, nn))
!  call write_data(unit,Dyn%Spec%h  (:,:, nn))
!  if(Dyn%spec_tracer) call write_data(unit,Dyn%Spec%trs(:,:, nn))
!
!  call set_domain(grid_domain)
!  call write_data(unit,Dyn%Grid%u   (:,:, nn))
!  call write_data(unit,Dyn%Grid%v   (:,:, nn))
!  call write_data(unit,Dyn%Grid%vor (:,:, nn))
!  call write_data(unit,Dyn%Grid%div (:,:, nn))
!  call write_data(unit,Dyn%Grid%h   (:,:, nn))
!  if(Dyn%spec_tracer) call write_data(unit,Dyn%Grid%trs(:,:, nn))
!  if(Dyn%grid_tracer) call write_data(unit,Dyn%Grid%tr (:,:, nn))
!  
!end do

!call close_file(unit)

end subroutine write_restart

!====================================================================

subroutine shallow_dynamics_end (Dyn, previous, current)

type(dynamics_type), intent(inout)  :: Dyn
integer, intent(in) :: previous, current

if(.not.module_is_initialized) then
  call error_mesg('shallow_dynamics_end','dynamics has not been initialized ', FATAL)
endif

call write_restart (Dyn, previous, current)

call transforms_end

module_is_initialized = .false.

return
end subroutine shallow_dynamics_end
!===================================================================================

end module shallow_dynamics_mod
