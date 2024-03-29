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

module bgrid_integrals_mod

!-----------------------------------------------------------------------
!
!   computes diagnostic integrals for the bgrid dynamical core
!
!-----------------------------------------------------------------------

use bgrid_change_grid_mod, only: change_grid, TEMP_GRID, WIND_GRID
use       bgrid_horiz_mod, only: horiz_grid_type
use        bgrid_vert_mod, only:  vert_grid_type, compute_pres_depth
use       bgrid_masks_mod, only:  grid_mask_type
use    bgrid_prog_var_mod, only:   prog_var_type
use      time_manager_mod, only:  time_type, get_time, set_time,  &
                                  operator(+),  operator(-),      &
                                  operator(==), operator(>=),     &
                                  operator(/=), operator(/),      &
                                  operator(*)

use         fms_mod, only: file_exist, open_namelist_file,        &
                           check_nml_error, write_version_number, &
                           stdout, error_mesg, FATAL, NOTE
use   constants_mod, only: CP_AIR

use         mpp_mod, only: mpp_pe, mpp_root_pe, mpp_max, mpp_min, &
                           mpp_sum, stdlog
use      mpp_io_mod, only: mpp_open, mpp_close, MPP_ASCII,  &
                           MPP_OVERWR, MPP_SEQUENTIAL, MPP_SINGLE
use mpp_domains_mod, only: mpp_global_sum, BITWISE_EXACT_SUM

use  field_manager_mod, only: MODEL_ATMOS
use tracer_manager_mod, only: get_tracer_names, get_number_tracers, &
                              get_tracer_index

implicit none
private

!-----------------------------------------------------------------------
!------ interfaces ------

public :: bgrid_integrals, bgrid_integrals_init, bgrid_integrals_end

!-----------------------------------------------------------------------
!--------------------- namelist ----------------------------------------

   integer, parameter :: MXCH = 64 ! maximum length of file names

! file_name  = optional file name for output (max length of 64 chars);
!              if no name is specified (the default) then
!              standard output will be used
!                 [character, default: filename  = ' ']

   character(len=MXCH) :: file_name = ' '

! time_units = specifies the time units used for time,
!              the following values are valid strings
!                 time_units = 'seconds'
!                            = 'minutes'
!                            = 'hours'   (default)
!                            = 'days'

   character(len=8) :: time_units = 'hours'

! output_interval = time interval in units of "time_units" for
!                   global b-grid integral diagnostics;
!                   * if an interval of zero is specified then no
!                     diagnostics will be generated
!                       [real, default: output_interval = 0.0]

   real :: output_interval = 0.0

! chksum_file_name = Optional file name for global integral output in
!                    hexadecimal format.  If this file name is set, then
!                    both the hexadecimal output and standard integral
!                    output will be computed using bit-reproducible summations.

   character(len=MXCH) :: chksum_file_name = ' '

! tracer_file_name = Optional file name for global integrals of all tracers.
!                    Up to 99 tracer integrals can be output in this file.

   character(len=MXCH) :: tracer_file_name = ' '

! trsout = Tracer names to be output in the standard integral file.
!          Only up to 4 names can be specified. For more tracer integrals
!          use the "tracer_file_name" option above.
!          A default has been set for the standard atmospheric model runs.

   integer, parameter :: MXTRS = 4
   character(len=MXCH) :: trsout(MXTRS) = &
                           (/'sphum  ','liq_wat','ice_wat','cld_amt'/)


   namelist /bgrid_integrals_nml/ output_interval, time_units,  &
                                  file_name, chksum_file_name,  &
                                  trsout, tracer_file_name

!-----------------------------------------------------------------------
! private interface

interface global_integral
  module procedure global_integral_2d, global_integral_3d
end interface

!-----------------------------------------------------------------------

   type (time_type) :: Next_diag_time, Output_diag_interval,  &
                       Base_time, Zero_time

   integer :: diag_unit   = 0
   integer :: chksum_unit = 0
   integer :: tracer_unit = 0
   logical :: alarm_set  = .false.
   logical :: do_init    = .true.
   logical :: do_header  = .true.
   logical :: do_chksum  = .false.
   logical :: do_decomp_check = .true.

   character(len=128) :: version = '$Id: bgrid_integrals.f90,v 10.0 2003/10/27 23:31:04 arl Exp $'
   character(len=128) :: tag = '$Name:  $'

   character(len=256) :: frmat   ! format used for standard intergals

! output for tracers
   integer :: ntrout=-1, indout(MXTRS)

! output options
   integer, parameter :: STANDARD=11  ! new format: min temp and TE
   integer, parameter :: TRACER1 =12  ! detailed tracer 1 (for conservation checks)
   integer, parameter :: KENERGY =13  ! old format: zonal mean and eddy KE
   integer :: output_option = STANDARD

! quantities accumulated over the output period
   real :: windspeed_max
   real :: temperature_min
   integer :: num_in_avg  ! not actually used
!-----------------------------------------------------------------------

contains

!#######################################################################

 subroutine bgrid_integrals (Time, Hgrid, Vgrid, Var, Masks)

!-----------------------------------------------------------------------
!  Time  = current/diagnostics time
!  Hgrid = horizontal grid constants
!  Vgrid = vertical grid constants
!  Var   = prognostic variables
!  Masks = grid box masking constants (for eta coordinate)
!-----------------------------------------------------------------------

   type (time_type),      intent(in) :: Time
   type(horiz_grid_type), intent(in) :: Hgrid
   type (vert_grid_type), intent(in) :: Vgrid
   type  (prog_var_type), intent(in) :: Var
   type (grid_mask_type), intent(in) :: Masks

!-----------------------------------------------------------------------

   real, dimension (Hgrid%ilb:Hgrid%iub,          &
                    Hgrid%jlb:Hgrid%jub, Var%nlev) :: dpde, dpde_xy, avg
   real, dimension (Hgrid%ilb:Hgrid%iub,          &
                    Hgrid%jlb:Hgrid%jub)           :: pssl_xy, ps_xy

   real :: avgps, avgke, avgzke, avgeke, avgens, avgtemp, avgpsv, avgte
   real ::  xtime, vmax, tmin
  integer :: i, j, k, n, ntmax, nout, ind

     real, dimension(Var%ntrace) :: avgtrace
     real, dimension(MXTRS)      :: avgtrout
  character(len=21) :: fmt

!-----------------------------------------------------------------------

  if (do_init) call error_mesg ('bgrid_integrals_mod',  &
                                'must call bgrid_integrals_init', FATAL)

! no diagnostics
  if (Output_diag_interval == Zero_time) return
!-----------------------------------------------------------------------
!  the following quantities represent averages over the output period:
!          windspeed_max, temperature_min
!-----------------------------------------------------------------------
! maximum wind speed (use dpde_xy as temp storage)
! get local maximum on current PE then across PEs

  dpde_xy(:,:,:) = sqrt(Var%u(:,:,:)*Var%u(:,:,:)+  &
                        Var%v(:,:,:)*Var%v(:,:,:))

  vmax = maxval (dpde_xy(Hgrid%Vel%is:Hgrid%Vel%ie, Hgrid%Vel%js:Hgrid%Vel%je, :))
  call mpp_max (vmax)
  windspeed_max = max(windspeed_max,vmax)

! minimum temperature

  if (Masks%sigma) then
      tmin = minval (Var%t(Hgrid%Tmp%is:Hgrid%Tmp%ie, Hgrid%Tmp%js:Hgrid%Tmp%je, :))
  else
      tmin = minval (Var%t(Hgrid%Tmp%is:Hgrid%Tmp%ie, Hgrid%Tmp%js:Hgrid%Tmp%je, :), &
       mask=Masks%Tmp%mask(Hgrid%Tmp%is:Hgrid%Tmp%ie, Hgrid%Tmp%js:Hgrid%Tmp%je, :) > .1 )
  endif
  call mpp_min (tmin)
  temperature_min = min(temperature_min,tmin)

! increment counter (not actually used for computing averages)

  num_in_avg = num_in_avg + 1

!-----------------------------------------------------------------------
! check output alarm

  if ( .not. bgrid_integrals_alarm(Time) ) return

!-----------------------------------------------------------------------
! if there is decomposition along x-axis you will not get the
! correct integrals for zonal mean and eddy kinetic energy

  if (do_decomp_check) then
    if (mpp_pe() == mpp_root_pe()) then
      if ( Hgrid%decompx .and. output_option == KENERGY ) then
           call error_mesg ('bgrid_integrals',                    &
             'checksum integrals of zonal and eddy KE will not be &
              &exact with x-axis decomposition', NOTE )
      endif
    endif
    do_decomp_check = .false.
  endif

!-----------------------------------------------------------------------
!  the following quantities represent instantaneous values at the
!  end of the output period:   global-average pressure, temperature,
!              kinetic energy, total energy, enstrophy, and tracers.
!-----------------------------------------------------------------------
! compute pressure weights on mass grid and velocity grid

  call compute_pres_depth (Vgrid, Var%pssl, dpde)
  call change_grid        (Hgrid, TEMP_GRID, WIND_GRID, dpde, dpde_xy)

! global average of surface pressure on mass and velocity grid

  avgps  = global_integral (Hgrid, 1, Var%ps,  do_exact=do_chksum)
  avgpsv = global_integral (Hgrid, 2, dpde_xy, do_exact=do_chksum)

! global average of various kinetic energy terms
! normalize with mean global mass

  if (output_option == KENERGY) then
      call kinetic_energy (Hgrid, Masks, dpde_xy, Var%u, Var%v, avgke, avgzke, avgeke )
      avgke  = avgke /avgpsv  ! total ke
      avgzke = avgzke/avgpsv  ! zonal mean ke
      avgeke = avgeke/avgpsv  ! eddy ke
  else
      call kinetic_energy (Hgrid, Masks, dpde_xy, Var%u, Var%v, avgke )
      avgke  = avgke /avgpsv  ! total ke
  endif

! global average of enstrophy on mass grid
! scale result 

  call enstrophy (Hgrid, Masks, dpde, dpde_xy, Var%u, Var%v, avgens)
  avgens = 1.e10*avgens/avgps

! global average of temperature

   avg = Var%t * dpde
   avgtemp = global_integral(Hgrid, 1, avg, Masks, do_chksum) / avgps

! total energy (cp*T+KE)

   avgte = CP_AIR * avgtemp + avgke

! global average of tracer fields

 ! compute integrals for all tracers?
   if (tracer_file_name(1:1) .ne. ' ') then
      do n = 1, Var%ntrace
         avg = Var%r(:,:,:,n) * dpde
         avgtrace(n) = global_integral(Hgrid, 1, avg, Masks, do_chksum) / avgps
      enddo
   endif
         
 ! determine indices for output tracers (first time only)
   if (ntrout < 0) then
      ntmax = min(MXTRS,Var%ntrace)
      if (output_option == TRACER1) ntmax = 1
      ntrout = 0
    ! first output namelist tracers
      do n = 1, ntmax
         ind = get_tracer_index ( MODEL_ATMOS, trim(trsout(n)) )
         if (ind <= 0) cycle
         ntrout = ntrout+1
         indout(ntrout) = ind
      enddo
    ! then add additional output tracers (if possible)
      if (ntrout < ntmax .and. ntrout < Var%ntrace) then
          do ind = 1, Var%ntrace
             ! checking current list
             do n = 1, ntrout
                if (ind == indout(n)) go to 10
             enddo
             ! adding new tracer index
             ntrout = ntrout + 1
             indout(ntrout) = ind
             if (ntrout == ntmax) exit
          10 continue
          enddo
      endif
   endif

 ! compute integrals for output tracers in B-grid integral file
   do n = 1, ntrout
      if (tracer_file_name(1:1) .ne. ' ') then
          avgtrout(n) = avgtrace(indout(n))
      else
          avg = Var%r(:,:,:,indout(n)) * dpde
          avgtrout(n) = global_integral(Hgrid, 1, avg, Masks, do_chksum) / avgps
      endif
   enddo

! tracer conservation debugging option
   nout = ntrout
   if (output_option == TRACER1 .and. nout == 1) then
      if (indout(1) > 0) then
         avgtrout(2) = minval(Var%r(:,:,:,indout(1)))
         avgtrout(3) = maxval(Var%r(:,:,:,indout(1)))
         call mpp_min (avgtrout(2))
         call mpp_max (avgtrout(3))
         nout = 3
      endif
   endif

!-----------------------------------------------------------------------
! increment diagnostics alarm

  Next_diag_time = Next_diag_time + Output_diag_interval

!-----------------------------------------------------------------------
! output on root PE only

 if ( mpp_pe() == mpp_root_pe() ) then

      xtime = get_axis_time (Time, time_units)

      if (do_header) call diag_header

      select case (output_option)
         case (STANDARD)
            write (diag_unit,trim(frmat)) xtime, avgps, avgtemp, temperature_min, &
                                          windspeed_max, avgke, avgte, avgens,    &
                                          (avgtrout(n),n=1,nout)
         case (TRACER1)
            write (diag_unit,trim(frmat)) xtime, avgps, avgtemp, temperature_min, &
                                          windspeed_max, avgke, avgte, avgens,    &
                                          (avgtrout(n),n=1,nout)
         case (KENERGY)
            write (diag_unit,trim(frmat)) xtime, avgps, avgtemp, windspeed_max, &
                                          avgke, avgzke, avgeke, avgens,        &
                                          (avgtrout(n),n=1,nout)
      end select

      if (do_chksum) then
          write (chksum_unit,8200) xtime, avgps, avgtemp, windspeed_max, avgens, &
                                   avgke, (avgtrout(n),n=1,min(nout,1))
 8200     format (1x,f10.2,2x,6z18)
      endif


!---- output additional tracers ----

     if (tracer_file_name(1:1) .ne. ' ') then
!        ---- open file, write header ----
         if (tracer_unit == 0) then
             call  mpp_open (tracer_unit, trim(tracer_file_name), &
                             form=MPP_ASCII, action=MPP_OVERWR,   &
                             access=MPP_SEQUENTIAL, threading=MPP_SINGLE, &
                             nohdrs=.true.)
             write (tracer_unit,8300)
         endif
         ! output up to 99 tracers
         write (fmt,8310) min(Var%ntrace,99)
         write (tracer_unit,fmt) xtime, (avgtrace(n),n=1,min(Var%ntrace,99))
     endif

 8300 format ('#',6x,'n', 8x, 'tracers --->')
 8310 format ('(1x,f10.2,2x,',i2.2,'e13.6)')

 endif

! reset 
  windspeed_max   = 0.
  temperature_min = 500.
  num_in_avg      = 0
!-----------------------------------------------------------------------

 end subroutine bgrid_integrals

!#######################################################################

 subroutine bgrid_integrals_init (Time_init, Time)

!----------------------------------------------------
!  Time_init = base time for experiment
!                the base time will be subtracted from all
!                specified times before that time is output/written.
!  Time      = current time
!----------------------------------------------------

    type (time_type), intent(in) :: Time_init, Time
      
    integer :: unit, io, ierr, seconds, nc
    type (time_type) :: Time_dif, Last_diag

!-----------------------------------------------------------------------
!       ----- read namelist -----
!      ----- write namelist (to standard output) -----

      if ( file_exist('input.nml')) then
         unit = open_namelist_file ( )
         ierr=1; do while (ierr /= 0)
            read  (unit, nml=bgrid_integrals_nml, iostat=io, end=10)
            ierr = check_nml_error (io, 'bgrid_integrals_nml')
         enddo
  10     call mpp_close (unit)
      endif

      call write_version_number (version,tag)
      if (mpp_pe() == mpp_root_pe()) write (stdlog(), nml=bgrid_integrals_nml)
      do_init = .false. 

!----- initialize alarm if not already done -----

      Zero_time = set_time (0,0)
      Base_time = Time_init

    ! set output interval
      if ( output_interval > 0.0 ) then
         Output_diag_interval = set_axis_time (output_interval, time_units)
      else
       ! no diagnostics
         Output_diag_interval = Zero_time
      endif
      if ( Output_diag_interval == Zero_time ) return

    ! current diag time (base time subtracted off)
      Time_dif  = Time - Base_time
    ! last time of diagnostics
      Last_diag = (Time_dif/Output_diag_interval)*Output_diag_interval
      if ( Last_diag == Time_dif ) then
            Next_diag_time = Last_diag ! repeat diag at start of run
      else
            Next_diag_time = Last_diag + Output_diag_interval
      endif
      
!--- initialize diagnostics output unit/file ? ----

      if ( file_name(1:1) /= ' ' ) then
          call  mpp_open (diag_unit, trim(file_name), form=MPP_ASCII, &
                          action=MPP_OVERWR, access=MPP_SEQUENTIAL,   &
                          threading=MPP_SINGLE, nohdrs=.true.)
      else
          diag_unit = stdout()
      endif

      if ( chksum_file_name(1:1) /= ' ' ) then
          call  mpp_open (chksum_unit, trim(chksum_file_name),  &
                          form=MPP_ASCII, action=MPP_OVERWR,    &
                          access=MPP_SEQUENTIAL, threading=MPP_SINGLE, &
                          nohdrs=.true.)
        do_chksum = .true.
      endif


! reset quantities accumulated over the output period
! NOTE: will need a restart file if the end of the output period
!       does not coincide with the end of the model run.

  windspeed_max   = 0.
  temperature_min = 500.
  num_in_avg      = 0

!-----------------------------------------------------------------------

 end subroutine bgrid_integrals_init

!#######################################################################

 subroutine bgrid_integrals_end

! close all open units
  if (  diag_unit > 0 .and. diag_unit /= stdout()) &
                       call mpp_close (diag_unit)
  if (chksum_unit > 0) call mpp_close (chksum_unit)
  if (tracer_unit > 0) call mpp_close (tracer_unit)

! need to write a restart file if the end of the output period
! does not coincide with the end of the model run

  if (num_in_avg > 0 .and. mpp_pe() == mpp_root_pe()) then
   ! print a note for now
     call error_mesg ('bgrid_integrals_mod',  &
          'end of the output period did not coincide &
           &with the end of the model run', NOTE)
  endif

 end subroutine bgrid_integrals_end

!#######################################################################

 function bgrid_integrals_alarm (Time) result (answer)

    type (time_type), intent(in) :: Time
    logical                      :: answer

!-----------------------------------------------------------------------
!----- check the diagnostics alarm -----

      answer = .false.

!----- sound the diagnostics alarm -----

      if (Time - Base_time >= Next_diag_time) answer = .true.

 end function bgrid_integrals_alarm

!#######################################################################

 subroutine diag_header

 character(len=24) :: lab_time, lab_ps, lab_tavg, lab_tmin, lab_vmax, &
                      lab_ke, lab_zke, lab_eke, lab_te, lab_ens,      &
                      lab_trs, lab_tr1
 character(len=24) :: fmt_time, fmt_ps, fmt_tavg, fmt_tmin, fmt_vmax, &
                      fmt_ke, fmt_zke, fmt_eke, fmt_te, fmt_ens,      &
                      fmt_trs, fmt_tr1
 character(len=256) :: title
 character(len=64)  :: lab_tr, trname
 integer :: n


 lab_time = '''#'',5x,''n'',3x,' ; fmt_time = 'f10.2'
 lab_ps   = '5x,''ps'',4x,'      ; fmt_ps   = ',1x,f10.3'
 lab_tavg = '3x,''tavg'',1x,'    ; fmt_tavg = ',1x,f7.3'
 lab_tmin = '3x,''tmin'',1x,'    ; fmt_tmin = ',1x,f7.3'
 lab_vmax = '3x,''vmax'',2x,'    ; fmt_vmax = ',1x,f8.4'
 lab_ke   = '4x,''ke'',2x,'      ; fmt_ke   = ',1x,f7.2'
 lab_zke  = '4x,''zke'',1x,'     ; fmt_zke  = ',1x,f7.2'
 lab_eke  = '4x,''eke'',1x,'     ; fmt_eke  = ',1x,f7.2'
 lab_te   = '5x,''te'',4x,'      ; fmt_te   = ',1x,f10.3'
 lab_ens  = '6x,''ens'',5x,'     ; fmt_ens  = ',1x,e13.6'
 lab_trs  = '3x'                 ; fmt_trs  = ',2x,4e13.6'
!lab_trs  = '7x,''trs --->'''    ; fmt_trs  = ',2x,4e13.6'
 lab_tr1  = '7x,''tr1 --->'''    ; fmt_tr1  = ',1x,3e22.14'

 select case (output_option)

   case (STANDARD)
     title = '('//trim(lab_time)//trim(lab_ps)//trim(lab_tavg) &
                //trim(lab_tmin)//trim(lab_vmax)//trim(lab_ke) &
                //trim(lab_te)//trim(lab_ens)//trim(lab_trs)
     frmat = '('//trim(fmt_time)//trim(fmt_ps)//trim(fmt_tavg) &
                //trim(fmt_tmin)//trim(fmt_vmax)//trim(fmt_ke) &
                //trim(fmt_te)//trim(fmt_ens)//trim(fmt_trs)//')'
 
   case (KENERGY)
     title = '('//trim(lab_time)//trim(lab_ps)//trim(lab_tavg) &
                //trim(lab_vmax)//trim(lab_ke)//trim(lab_zke)  &
                //trim(lab_eke)//trim(lab_ens)//trim(lab_trs)
     frmat = '('//trim(fmt_time)//trim(fmt_ps)//trim(fmt_tavg) &
                //trim(fmt_vmax)//trim(fmt_ke)//trim(fmt_zke)  &
                //trim(fmt_eke)//trim(fmt_ens)//trim(fmt_trs)//')'
 
   case (TRACER1)
     title = '('//trim(lab_time)//trim(lab_ps)//trim(lab_tavg) &
                //trim(lab_tmin)//trim(lab_vmax)//trim(lab_ke) &
                //trim(lab_te)//trim(lab_ens)//trim(lab_trs)
     frmat = '('//trim(fmt_time)//trim(fmt_ps)//trim(fmt_tavg) &
                //trim(fmt_tmin)//trim(fmt_vmax)//trim(fmt_ke) &
                //trim(fmt_te)//trim(fmt_ens)//trim(fmt_tr1)//')'

 end select

   ! labels for tracers
     do n = 1, ntrout
        call get_tracer_names (MODEL_ATMOS,indout(n),trname)
        lab_tr = '4x,'//trim(trname)//''
        write (lab_tr,10) trim(trname)
     10 format (',2x,''',a9,''',2x')
        title = trim(title)//trim(lab_tr)
     enddo
     if (output_option == TRACER1) title = trim(title)//',''(avg,min,max)'''
     title = trim(title)//')'
    !if (mpp_pe() == mpp_root_pe()) print *, 'title=',trim(title)


   ! write the header/labels
     write (diag_unit,trim(title))


   ! for the exact integral file
     if (do_chksum) then
         write (chksum_unit,8002)
     endif
8002 format ('#',6x,'n', 14x, 'ps',  15x,  'temp', 13x, 'max vel', &
                         12x, 'ens', 16x, 'ke', 13x, 'tracer 1')

 do_header = .false.


 end subroutine diag_header

!#######################################################################

 subroutine kinetic_energy (Hgrid, Masks, dpde, u, v,   &
                            gke, gmke, geke )

 type(horiz_grid_type), intent(in)                     :: Hgrid
 type (grid_mask_type), intent(in)                     :: Masks
 real, intent(in) , dimension(Hgrid%ilb:,Hgrid%jlb:,:) :: dpde, u, v
 real, intent(out)                                     :: gke
 real, intent(out), optional                           :: gmke, geke
!-----------------------------------------------------------------------

   real, dimension (Hgrid%ilb:Hgrid%iub, Hgrid%jlb:Hgrid%jub,  &
                    size(u,3)) :: ke, mke, eke
   real, dimension (Hgrid%ilb:Hgrid%iub) :: ustar, vstar
   real    :: usum, vsum, wsum, uavg, vavg
   integer :: i, j, k, is, ie

!-----------------------------------------------------------------------
!---- zero out quantities ----

      mke = 0.;  eke = 0.

!---- total kinetic energy (2x) ----

      ke(:,:,:) = dpde(:,:,:)*(u(:,:,:)**2+v(:,:,:)**2)
      gke = global_integral (Hgrid, 2,  ke, Masks, do_chksum) * 0.50

!---- compute mean zonal and eddy kinetic energy -----

      if (.not.present(gmke) .and. .not.present(geke)) return

      is=Hgrid%Vel%is
      ie=Hgrid%Vel%ie

      do k = 1, size(u,3)
      do j = Hgrid%Vel%js, Hgrid%Vel%je

         wsum = sum(Masks%Vel%mask(is:ie,j,k))

         if (wsum > 0.50) then
          ! zonal mean
            usum = sum(Masks%Vel%mask(is:ie,j,k)*u(is:ie,j,k))
            vsum = sum(Masks%Vel%mask(is:ie,j,k)*v(is:ie,j,k))
            uavg = usum/wsum
            vavg = vsum/wsum

          ! zonal eddy components
            ustar(:) = u(:,j,k)-uavg
            vstar(:) = v(:,j,k)-vavg

          ! zonal mean ke (2x)
            mke(:,j,k) = dpde(:,j,k)*(uavg**2+vavg**2)
          ! eddy ke (2x)
            eke(:,j,k) = dpde(:,j,k)*(ustar(:)**2+vstar(:)**2)
         else
            mke(:,j,k) = 0.0
            eke(:,j,k) = 0.0
         endif

      enddo
      enddo

    ! 3-dim global integrals
      if (present(gmke)) &
          gmke = global_integral (Hgrid, 2, mke, Masks, do_chksum) * 0.50
      if (present(geke)) &
          geke = global_integral (Hgrid, 2, eke, Masks, do_chksum) * 0.50

!-----------------------------------------------------------------------

 end subroutine kinetic_energy

!#######################################################################

 subroutine enstrophy (Hgrid, Masks, dpde, dpde_xy, u, v, avgens)

!-----------------------------------------------------------------------
   type(horiz_grid_type), intent(in)       :: Hgrid
   type (grid_mask_type), intent(in)       :: Masks
      real, intent(in), dimension(Hgrid%ilb:,Hgrid%jlb:,:) :: dpde,  &
                                                          dpde_xy, u, v
      real, intent(out) :: avgens
!-----------------------------------------------------------------------

   real, dimension (lbound(u,1):ubound(u,1),  &
                    lbound(u,2):ubound(u,2), size(u,3)) :: ens

   real, dimension (lbound(u,1):ubound(u,1),                &
                    lbound(u,2):ubound(u,2)) :: vdy,  udx,  &
                                                avdy, audx, vort
   real, dimension (lbound(u,2):ubound(u,2)) :: fens

   integer :: i, j, k, is, ie, js, je
   real    :: dysq

!-----------------------------------------------------------------------

      is = Hgrid%Tmp%is;  ie = Hgrid%Tmp%ie
      js = Hgrid%Tmp%js;  je = Hgrid%Tmp%je

!-----------------------------------------------------------------------

      ens = 0.0;  vort = 0.0
      fens = 0.25*Hgrid%Tmp%rarea*Hgrid%Tmp%rarea

      do k = 1, size(u,3)

         do j = js-1, je
            vdy(:,j) = v(:,j,k)*dpde_xy(:,j,k)*Hgrid%Vel%dy
            udx(:,j) = u(:,j,k)*dpde_xy(:,j,k)*Hgrid%Vel%dx(j)
         enddo

         do j = js,   je
         do i = is-1, ie
            avdy(i,j) = vdy(i,j-1)+vdy(i,j)
         enddo
         enddo
         do j = js-1, je
         do i = is,   ie
            audx(i,j) = udx(i-1,j)+udx(i,j)
         enddo
         enddo

!        ------ vorticity * dpde_xy * area ------
         do j = js, je
         do i = is, ie
            vort(i,j)=((avdy(i,j)-avdy(i-1,j))-(audx(i,j)-audx(i,j-1)))
         enddo
         enddo

!        ------ enstrophy ------
         do j = js, je
            ens(:,j,k) = vort(:,j)*vort(:,j)*fens(j)/dpde(:,j,k)
         enddo

      enddo

!-----------------------------------------------------------------------

      avgens = global_integral (Hgrid, 1, ens, Masks, do_chksum)

!-----------------------------------------------------------------------

 end subroutine enstrophy

!#######################################################################
!#######################################################################

function get_axis_time (Time, units) result (atime)

   type(time_type),  intent(in) :: Time
   character(len=*), intent(in) :: units
   real                         :: atime
   integer                      :: sec, day

!---- returns real time in the time axis units ----
!---- convert time type to appropriate real units ----

      call get_time (Time-Base_time, sec, day)

      if (units(1:3) == 'sec') then
         atime = float(sec) + 86400.*float(day)
      else if (units(1:3) == 'min') then
         atime = float(sec)/60. + 1440.*float(day)
      else if (units(1:3) == 'hou') then
         atime = float(sec)/3600. + 24.*float(day)
      else if (units(1:3) == 'day') then
         atime = float(sec)/86400. + float(day)
      endif

end function get_axis_time

!#######################################################################

function set_axis_time (atime, units) result (Time)

   real,             intent(in) :: atime
   character(len=*), intent(in) :: units
   type(time_type)  :: Time
   integer          :: sec, day = 0

!---- returns time type given real time in axis units ----
!---- convert real time units to time type ----

      if (units(1:3) == 'sec') then
         sec = int(atime + 0.5)
      else if (units(1:3) == 'min') then
         sec = int(atime*60. + 0.5)
      else if (units(1:3) == 'hou') then
         sec = int(atime*3600. + 0.5)
      else if (units(1:3) == 'day') then
         sec = int(atime*86400. + 0.5)
      endif

!     --- do not add in base time ---

      Time = set_time (sec, day)

end function set_axis_time

!#######################################################################
!####### global averaging routines for the bgrid model #################
!#######################################################################

function global_integral_2d (Hgrid, grid, data, do_exact)  &
                     result (avg)

   type(horiz_grid_type), intent(in) :: Hgrid
integer, intent(in)  :: grid
   real, intent(in)  :: data(Hgrid%ilb:,Hgrid%jlb:)
logical, intent(in), optional :: do_exact
   real :: avg

   real, dimension(Hgrid%ilb:Hgrid%iub,Hgrid%jlb:Hgrid%jub) :: aa
   real :: asum, wsum
integer :: i, j, isd, ied, vsd, ved
logical :: bitwise_exact

!-----------------------------------------------------------------------

   bitwise_exact = .false.
   if (present(do_exact)) bitwise_exact = do_exact

!  average on mass grid
   select case (grid)
      case(1)
        do j = Hgrid%Tmp%jsd, Hgrid%Tmp%jed
        do i = Hgrid%Tmp%isd, Hgrid%Tmp%ied
           aa(i,j)= data(i,j) * Hgrid%Tmp%area(j)
        enddo
        enddo
        if ( bitwise_exact ) then
            asum = mpp_global_sum ( Hgrid%Tmp%Domain, aa, flags=BITWISE_EXACT_SUM )
        else
            asum = mpp_global_sum ( Hgrid%Tmp%Domain, aa )
        endif
            wsum = Hgrid%Tmp%areasum

!  average on velocity grid
      case(2:3)
      ! must pass data domain to mpp_global_sum
        isd = Hgrid%Vel%isd;  ied = Hgrid%Vel%ied
        vsd = Hgrid%Vel%jsd;  ved = Hgrid%Vel%jed
        do j = vsd, ved
        do i = isd, ied
           aa(i,j)= data(i,j) * Hgrid%Vel%area(j)
        enddo
        enddo
        if ( bitwise_exact ) then
            asum = mpp_global_sum ( Hgrid%Vel%Domain, aa(isd:ied,vsd:ved), &
                                    flags=BITWISE_EXACT_SUM )
        else
            asum = mpp_global_sum ( Hgrid%Vel%Domain, aa(isd:ied,vsd:ved) )
        endif
            wsum = Hgrid%Vel%areasum

   end select

   if (wsum <= 0.0) call error_mesg ('global_integral_2d in bgrid_integrals_mod', &
                                     'wsum=0', FATAL)

   avg = asum/wsum

end function global_integral_2d

!#######################################################################

function global_integral_3d (Hgrid, grid, data, Masks, do_exact)  &
                     result (avg)

type(horiz_grid_type), intent(in) :: Hgrid
integer,               intent(in) :: grid
real,                  intent(in) :: data(Hgrid%ilb:,Hgrid%jlb:,:) 
type (grid_mask_type), intent(in), optional :: Masks
logical,               intent(in), optional :: do_exact
real :: avg
real, dimension(size(data,1),size(data,2)) :: aa

!-----------------------------------------------------------------------

 if (present(Masks)) then
   select case (grid)
      case(1)
         aa = sum( data*Masks%Tmp%mask, dim=3 )
      case(2:3)
         aa = sum( data*Masks%Vel%mask, dim=3 )
   end select
 else
         aa = sum( data, dim=3 )
 endif

   avg = global_integral_2d (Hgrid, grid, aa, do_exact)

!-----------------------------------------------------------------------

end function global_integral_3d

!#######################################################################
!#######################################################################

end module bgrid_integrals_mod

