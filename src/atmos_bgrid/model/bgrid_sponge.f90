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

module bgrid_sponge_mod

!-----------------------------------------------------------------------
!
!   Eddy damping of prognostic fields at the top level of the model
!
!   Damping is done using a 5-point Shapiro filter.
!   For temperature, tracers, and zonal wind the zonal mean is
!   removed before applying the filter.  For meridional wind,
!   the entire field is damped.
!
!-----------------------------------------------------------------------

 use bgrid_horiz_mod,       only: horiz_grid_type
 use bgrid_masks_mod,       only: grid_mask_type
 use bgrid_prog_var_mod,    only: prog_var_type
 use bgrid_change_grid_mod, only: change_grid, TEMP_GRID, WIND_GRID
 use bgrid_halo_mod,        only: update_halo, vel_flux_boundary, &
                                  TEMP, UWND, VWND, &
                                  NORTH, EAST, NOPOLE

 use         fms_mod, only: error_mesg, FATAL, write_version_number, &
                            file_exist, open_namelist_file, stdlog,  &
                            check_nml_error, close_file, mpp_pe,     &
                            mpp_npes, mpp_root_pe

 use mpp_domains_mod, only: domain2d, domain1d,         &
                            mpp_update_domains,         &
                            mpp_define_domains,         &
                            mpp_get_layout,             &
                            mpp_get_global_domain,      &
                            mpp_get_data_domain,        &
                            mpp_get_compute_domain,     &
                            mpp_get_compute_domains,    &
                            mpp_get_domain_components,  &
                            WUPDATE, EUPDATE,           &
                            CYCLIC_GLOBAL_DOMAIN

 implicit none
 private

 public   sponge_driver, sponge_init

!-----------------------------------------------------------------------
! namelist

!  num_sponge_levels   The number of uppermost model levels where 
!                      the sponge damping is applied.  Currently,
!                      this cannot exceed one level.   
!                         [integer, default = 0]
!
!  sponge_coeff_wind   Normalized [0,1] sponge damping coefficients
!  sponge_coeff_temp   for the top model level.
!  sponge_coeff_tracer    [real, default = 0.]
!

   integer   ::     num_sponge_levels = 0
   real      ::     sponge_coeff_wind   = 0.0
   real      ::     sponge_coeff_temp   = 0.0
   real      ::     sponge_coeff_tracer = 0.0

   namelist /bgrid_sponge_nml/ num_sponge_levels, sponge_coeff_wind, &
                               sponge_coeff_temp, sponge_coeff_tracer

!-----------------------------------------------------------------------

 character(len=128) :: version='$Id: bgrid_sponge.f90,v 10.0 2003/10/27 23:31:04 arl Exp $'
 character(len=128) :: tagname='$Name:  $'
 logical :: do_log  = .true.
 logical :: do_init = .true.

 real :: small = .000001  !  damping coefficients larger than this
                          !  activate the sponge

!--- module storage for computing exact/reproducible zonal means ---
  type zsum_type
     type(domain2d) :: Domain
     integer        :: is , ie , js , je , &
                       isd, ied, jsd, jed, &
                       isg, ieg, jsg, jeg, nlon
     integer, pointer :: order(:) => NULL()
  end type

!--- module storage for sponge control parameters ---
  type sponge_control_type
     real :: coeff_vel, coeff_tmp, coeff_trs
     integer :: numlev
     type(zsum_type) :: Zdomain_tmp, Zdomain_vel
  end type sponge_control_type

  type(sponge_control_type),save :: Control

!-----------------------------------------------------------------------

contains

!#######################################################################

 subroutine sponge_driver ( Hgrid, nplev, dt, dpde, Var, Var_dt )
 
!-----------------------------------------------------------------------
! Hgrid  = horizontal grid constants
! nplev  = number of "pure" pressure levels at the top of the model
! dt     = adjustment time step
! dpde   = pressure weight for model layers
! Var    = prognostic variables at the last updated time level
! Var_dt = tendency of prog variables since the last updated time level
!-----------------------------------------------------------------------
 type (horiz_grid_type), intent(inout) :: Hgrid
 integer,                intent(in)    :: nplev
 real,                   intent(in)    :: dt
 real,                   intent(in)    :: dpde(Hgrid%ilb:,Hgrid%jlb:,:)
 type  (prog_var_type),  intent(in)    :: Var
 type  (prog_var_type),  intent(inout) :: Var_dt
!-----------------------------------------------------------------------

 real, dimension(Hgrid%ilb:Hgrid%iub,Hgrid%jlb:Hgrid%jub,Control%numlev) :: dpxy
 integer :: n, np, nt

!-----------------------------------------------------------------------

   if (do_init) call error_mesg ('bgrid_sponge_mod',  &
                                 'initialization not called', FATAL)

   if ( Control%numlev == 0 ) return

!-----------------------------------------------------------------------

   n  = Control%numlev   ! number of sponge levels
   np = nplev    ! number of pressure levels at top of model

!---- temperature and tracers -----

   if ( Control%coeff_tmp > small .or. Control%coeff_trs > small ) then
       nt = Var_dt%ntrace
       call local_filter_mass ( Hgrid, np, dt, dpde(:,:,1:n),              &
                                Var   %t(:,:,1:n), Var   %r(:,:,1:n,1:nt), &
                                Var_dt%t(:,:,1:n), Var_dt%r(:,:,1:n,1:nt)  )
   endif

!---- momentum components -----

   if ( Control%coeff_vel > small ) then
      ! compute pressure weights at velocity points
        dpxy(:,:,:) = dpde(:,:,1:n)
        if (np < n) then
          call change_grid (Hgrid, TEMP_GRID, WIND_GRID, &
                            dpxy(:,:,np+1:n), dpxy(:,:,np+1:n))
          call update_halo (Hgrid, UWND, dpxy(:,:,np+1:n), &
                            halos=EAST+NORTH, flags=NOPOLE)
        endif

        call local_filter_vel ( Hgrid, np, dt, dpxy,                  &
                                Var   %u(:,:,1:n), Var   %v(:,:,1:n), &
                                Var_dt%u(:,:,1:n), Var_dt%v(:,:,1:n)  )
   endif

!-----------------------------------------------------------------------

 end subroutine sponge_driver

!#######################################################################

 subroutine sponge_init (Hgrid )
 type (horiz_grid_type), intent(in) :: Hgrid ! horizontal grid constants

 integer :: unit, ierr, io
!-----------------------------------------------------------------------
! read namelist
   if (file_exist('input.nml')) then
       unit = open_namelist_file ( )
       ierr=1; do while (ierr /= 0)
          read (unit, nml=bgrid_sponge_nml, iostat=io, end=5)
          ierr = check_nml_error (io, 'bgrid_sponge_nml')
       enddo
 5     call close_file (unit)
   endif
! write version and namelist to log 
   if (do_log) then
      call write_version_number (version,tagname)
      if (mpp_pe() == mpp_root_pe()) write (stdlog(), nml=bgrid_sponge_nml)
      do_log = .false.
   endif

! set values for optional arguments
   Control%coeff_vel = min(max(sponge_coeff_wind  ,0.),1.)
   Control%coeff_tmp = min(max(sponge_coeff_temp  ,0.),1.)
   Control%coeff_trs = min(max(sponge_coeff_tracer,0.),1.)
   Control%numlev    = max(num_sponge_levels,0)

!  do not allow more than one sponge layer in this version
   if (Control%numlev > 1) call error_mesg ('bgrid_sponge_mod',  &
                                            'numlev > 1 ', FATAL)

!  set up domain2d types for computing bit-reproducible zonal means

   if ( Control%coeff_tmp > small .or. Control%coeff_trs > small ) then
           call zsum_init ( Hgrid%Tmp%Domain, Control%Zdomain_tmp )
   endif
   if ( Control%coeff_vel > small ) then
           call zsum_init ( Hgrid%Vel%Domain, Control%Zdomain_vel )
   endif

   do_init=.false.

!-----------------------------------------------------------------------

 end subroutine sponge_init

!#######################################################################
! sponge/filter for temperature and tracers fields

 subroutine local_filter_mass ( Hgrid, nplev, dt, dp, t, tr, tdt, trdt )

   type (horiz_grid_type), intent(inout) :: Hgrid
   integer, intent(in)                   :: nplev
   real,    intent(in)                   :: dt
   real,    intent(in),    dimension(Hgrid%ilb:,Hgrid%jlb:,:) :: dp, t
   real,    intent(inout), dimension(Hgrid%ilb:,Hgrid%jlb:,:) :: tdt
   real,    intent(in),    dimension(Hgrid%ilb:,Hgrid%jlb:,:,:) :: tr
   real,    intent(inout), dimension(Hgrid%ilb:,Hgrid%jlb:,:,:) :: trdt

   real, dimension(Hgrid%ilb:Hgrid%iub,Hgrid%jlb:Hgrid%jub,size(t,3)) :: &
                                             tmp, akew, akns, akdp
   real, dimension(Hgrid%ilb:Hgrid%iub,Hgrid%jlb:Hgrid%jub) :: tew, tns
   real, dimension(Hgrid%jlb:Hgrid%jub) :: akew2, akns2
   integer :: i, j, k, is, ie, js, je, n

   is  = Hgrid%Tmp%is;   ie  = Hgrid%Tmp%ie
   js  = Hgrid%Tmp%js;   je  = Hgrid%Tmp%je

 ! 2D geometric constants
   do j = js-1, je
      akew2(j) = 0.0625 * (Hgrid%Tmp%area(j)+Hgrid%Tmp%area(j))
      akns2(j) = 0.0625 * (Hgrid%Tmp%area(j)+Hgrid%Tmp%area(j+1))
   enddo

 ! 3D mass weighted constants
   do k = 1, size(t,3)
   do j = js-1, je
      akew(is-1:ie,j,k) = akew2(j)
      akns(is-1:ie,j,k) = akns2(j)
      akdp(:,j,k) = Hgrid%Tmp%rarea(j)/dt
   enddo
   enddo
   do k = nplev+1, size(t,3)
      do j = js-1, je
      do i = is-1, ie
         akew(i,j,k) = akew(i,j,k) * (dp(i,j,k)+dp(i+1,j,k))
         akns(i,j,k) = akns(i,j,k) * (dp(i,j,k)+dp(i,j+1,k))
         akdp(i,j,k) = akdp(i,j,k) / (2.*dp(i,j,k))
      enddo
      enddo
   enddo


 ! temperature

   if ( Control%coeff_tmp > small ) then
      tmp = t + dt*tdt
     !---- remove zonal mean ----
      call remove_mean ( Control%Zdomain_tmp, tmp(is:ie,js:je,:), tmp(is:ie,js:je,:) )
      call update_halo ( Hgrid, TEMP, tmp )
      do k = 1, size(t,3)
         do j = js-1, je
         do i = is-1, ie
            tew(i,j) = akew(i,j,k) * (tmp(i+1,j,k)-tmp(i,j,k))
            tns(i,j) = akns(i,j,k) * (tmp(i,j+1,k)-tmp(i,j,k))
         enddo
         enddo
         do j = js, je
         do i = is, ie
            tdt(i,j,k) = tdt(i,j,k) + &
                  Control%coeff_tmp*(tew(i,j)-tew(i-1,j)+tns(i,j)-tns(i,j-1))*akdp(i,j,k)
         enddo
         enddo
      enddo
   endif

 ! tracers

   if ( Control%coeff_trs > small ) then
      do n = 1, size(tr,4)
         tmp = tr(:,:,:,n) + dt*trdt(:,:,:,n)
        !---- remove zonal mean ----
         call remove_mean ( Control%Zdomain_tmp, tmp(is:ie,js:je,:), tmp(is:ie,js:je,:) )
         call update_halo ( Hgrid, TEMP, tmp )
         do k = 1, size(tr,3)
            do j = js-1, je
            do i = is-1, ie
               tew(i,j) = akew(i,j,k) * (tmp(i+1,j,k)-tmp(i,j,k))
               tns(i,j) = akns(i,j,k) * (tmp(i,j+1,k)-tmp(i,j,k))
            enddo
            enddo
            do j = js, je
            do i = is, ie
               trdt(i,j,k,n) = trdt(i,j,k,n) +  &
                    Control%coeff_trs*(tew(i,j)-tew(i-1,j)+tns(i,j)-tns(i,j-1))*akdp(i,j,k)
            enddo
            enddo
         enddo
      enddo
   endif

 end subroutine local_filter_mass

!#######################################################################
! sponge/filter for momentum components

 subroutine local_filter_vel ( Hgrid, nplev, dt, dp, u, v, udt, vdt )

   type (horiz_grid_type), intent(inout) :: Hgrid
   integer, intent(in)                   :: nplev
   real,    intent(in)                   :: dt
   real,    intent(in),    dimension(Hgrid%ilb:,Hgrid%jlb:,:) :: dp, u, v
   real,    intent(inout), dimension(Hgrid%ilb:,Hgrid%jlb:,:) :: udt, vdt

   real, dimension(Hgrid%ilb:Hgrid%iub,Hgrid%jlb:Hgrid%jub,size(u,3)) :: &
                                                akew, akns, akdp, uu, vv
   real, dimension(Hgrid%ilb:Hgrid%iub,Hgrid%jlb:Hgrid%jub) ::  uew, vew, uns, vns
   real, dimension(Hgrid%jlb:Hgrid%jub) ::  akew2, akns2
   integer :: i, j, k, is, ie, js, je

   is  = Hgrid%Tmp%is;   ie  = Hgrid%Tmp%ie
   js  = Hgrid%Vel%js;   je  = Hgrid%Vel%je

 ! 2D geometric constants
   do j = js, je+1
      akew2(j) = 0.0625 * Control%coeff_vel * (Hgrid%Vel%area(j)+Hgrid%Vel%area(j))
      akns2(j) = 0.0625 * Control%coeff_vel * (Hgrid%Vel%area(j-1)+Hgrid%Vel%area(j))
   enddo

 ! 3D mass weighted constants
   do k = 1, size(u,3)
   do j = js, je+1
      akew(is:ie+1,j,k) = akew2(j)
      akns(is:ie+1,j,k) = akns2(j)
      akdp(:,j,k) = Hgrid%Vel%rarea(j)/dt
   enddo
   enddo
   do k = nplev+1, size(u,3)
      do j = js, je+1
      do i = is, ie+1
         akew(i,j,k) = akew(i,j,k) * (dp(i,j,k)+dp(i-1,j,k))
         akns(i,j,k) = akns(i,j,k) * (dp(i,j,k)+dp(i,j-1,k))
         akdp(i,j,k) = akdp(i,j,k) / (2.*dp(i,j,k))
      enddo
      enddo
   enddo

   uu = u + dt*udt
   vv = v + dt*vdt
  !---- remove zonal mean from u comp ----
   call remove_mean ( Control%Zdomain_vel, uu(is:ie,js:je,:), uu(is:ie,js:je,:) )
   call update_halo ( Hgrid, UWND, uu )
   call update_halo ( Hgrid, VWND, vv )

   do k = 1, size(u,3)
      do j = js, je+1
      do i = is, ie+1
         uew(i,j) = akew(i,j,k) * (uu(i,j,k)-uu(i-1,j,k))
         vew(i,j) = akew(i,j,k) * (vv(i,j,k)-vv(i-1,j,k))
         uns(i,j) = akns(i,j,k) * (uu(i,j,k)-uu(i,j-1,k))
         vns(i,j) = akns(i,j,k) * (vv(i,j,k)-vv(i,j-1,k))
      enddo
      enddo
     !---- remove meridional gradients adjacent to poles ----
      call vel_flux_boundary (Hgrid, uns)
      call vel_flux_boundary (Hgrid, vns)

      do j = js, je
      do i = is, ie
         udt(i,j,k) = udt(i,j,k) + (uew(i+1,j)-uew(i,j)+uns(i,j+1)-uns(i,j))*akdp(i,j,k)
         vdt(i,j,k) = vdt(i,j,k) + (vew(i+1,j)-vew(i,j)+vns(i,j+1)-vns(i,j))*akdp(i,j,k)
      enddo
      enddo
   enddo

 end subroutine local_filter_vel

!#######################################################################
! initializes domain2d type for summation in zonal direction

 subroutine zsum_init ( Domain, Zonal )
 type(domain2d),  intent(in)   :: Domain
 type(zsum_type), intent(out)  :: Zonal
 integer :: layout(2), xhalosize, i
 integer, allocatable :: xextent(:), yextent(:)
 type(domain1D) :: Domx, Domy

! create new domain2d type with large global halo along x-axis 
  call mpp_get_layout ( Domain, layout )
  allocate ( xextent(layout(1)), yextent(layout(2)) )
  call mpp_get_domain_components ( Domain, Domx, Domy )
  call mpp_get_compute_domains   ( Domx, size=xextent )
  call mpp_get_compute_domains   ( Domy, size=yextent )
! make halo global for minimum x-extent
  xhalosize = (sum(xextent)-minval(xextent)+1)/2

  call mpp_get_global_domain  ( Domain, Zonal%isg, Zonal%ieg, Zonal%jsg, Zonal%jeg )
  call mpp_define_domains ( (/Zonal%isg,Zonal%ieg,Zonal%jsg,Zonal%jeg/), layout, Zonal%Domain, &
                xflags=CYCLIC_GLOBAL_DOMAIN, xhalo=xhalosize, yhalo=0, &
                xextent=xextent, yextent=yextent )

! new compute and data domain 
  call mpp_get_compute_domain ( Zonal%Domain, Zonal%is , Zonal%ie , &
                                              Zonal%js , Zonal%je   )
  call mpp_get_data_domain    ( Zonal%Domain, Zonal%isd, Zonal%ied, &
                                              Zonal%jsd, Zonal%jed  )
  Zonal%nlon = Zonal%ieg-Zonal%isg+1

 ! precompute order for summation
 ! always do in same order on all PEs
   allocate(Zonal%order(Zonal%isg:Zonal%ieg))
   do i = Zonal%isg, Zonal%ieg
      Zonal%order(i) = i
      if (Zonal%order(i) < Zonal%isd) Zonal%order(i) = Zonal%order(i)+Zonal%nlon
      if (Zonal%order(i) > Zonal%ied) Zonal%order(i) = Zonal%order(i)-Zonal%nlon
   enddo

  deallocate (xextent)

 end subroutine zsum_init

!#######################################################################

 subroutine remove_mean ( Zonal, array, zarray )
 type(zsum_type), intent(in)   :: Zonal
 real,            intent(in)  ::   array(Zonal%is:,Zonal%js:,:) ! compute domain only
 real,            intent(out) ::  zarray(Zonal%is:,Zonal%js:,:) ! compute domain only
 real, dimension(Zonal%isd:Zonal%ied,Zonal%jsd:Zonal%jed,size(array,3)) :: zdat
 real    :: avg
 integer :: i, j, k

 ! store input data into local array
   do k = 1, size(array,3)
   do j = Zonal%js, Zonal%je
   do i = Zonal%is, Zonal%ie
      zdat(i,j,k) = array(i,j,k)
   enddo
   enddo
   enddo
 ! update large zonal halos
   call mpp_update_domains ( zdat, Zonal%Domain, flags=WUPDATE+EUPDATE )
 ! compute deviations from zonal mean
   do k = 1, size(array,3)
   do j = Zonal%js, Zonal%je
   ! ordered summation
   avg = 0.
   do i = Zonal%isg, Zonal%ieg
      avg = avg + zdat(Zonal%order(i),j,k)
   enddo
      zarray(:,j,k) = array(:,j,k) - avg/real(Zonal%nlon)
   enddo
   enddo
   
 end subroutine remove_mean

!#######################################################################

end module bgrid_sponge_mod

