
subroutine vertvel(ia,iam,ja,ka)

#ifndef explicit_w
  
  ! === Computes the vertical velocity by integrating ===
  ! === the continuity eq. from the bottom            ===
  ! === for the nsm and nsp velocity time steps       ===
  
  USE mod_param
  USE mod_vel
  USE mod_time, only: intrpr, intrpg
  USE mod_grid
  USE mod_turb
#if defined ifs || defined larval_fish
  USE mod_grid
#endif
#ifdef sediment
  USE mod_sed
  USE mod_orbital
  USE mod_grid
#endif
#if defined larval_fish
  USE mod_fish
#endif /*fish*/
  
  IMPLICIT none
  
#if defined sediment
  REAL kin
#endif
  
  real*8                                     :: uu, um, vv, vm
  integer                                    :: ia, iam, ja, ka, k,n
  integer                                    :: n1, n2

  
  
  wflux=0.d0
  
  n1=min(nsm,nsp)
  n2=max(nsm,nsp)

#ifdef twodim
  return
  
! start 3D code
#else

  kloop: do k=1,ka
     uu = intrpg * uflux(ia ,ja  ,k,nsp) + intrpr * uflux(ia ,ja  ,k,nsm)
     um = intrpg * uflux(iam,ja  ,k,nsp) + intrpr * uflux(iam,ja  ,k,nsm)
     vv = intrpg * vflux(ia ,ja  ,k,nsp) + intrpr * vflux(ia ,ja  ,k,nsm)
     vm = intrpg * vflux(ia ,ja-1,k,nsp) + intrpr * vflux(ia ,ja-1,k,nsm)

! start ifs code
#if defined ifs || defined roms
    do n=n1,n2
     wflux(k,n) = wflux(k-1,n) - ff * &
     ( uflux(ia,ja,k,n) - uflux(iam,ja,k,n) + vflux(ia,ja,k,n) - vflux(ia,ja-1,k,n)  &
     + (dzt(ia,ja,k,nsp)-dzt(ia,ja,k,nsm))*dxdy(ia,ja)/tseas )  ! time change of the mass the in grid box
    enddo
#endif
!end ifs code

! start ocean code
#ifndef ifs
#ifdef  full_wflux
     wflux(ia,ja,k,nsm)=wflux(ia,ja,k-1,nsm) - ff * ( uu - um + vv - vm )
#else
    do n=n1,n2
     wflux(k,n) = wflux(k-1,n) - ff * &
     ( uflux(ia,ja,k,n) - uflux(iam,ja,k,n) + vflux(ia,ja,k,n) - vflux(ia,ja-1,k,n) )
    enddo
#endif
#endif
!end ocean code
  end do kloop

#ifdef ifs
wflux(0,:) = 0.d0
wflux(km,:) = 0.d0
#endif

#endif
! end 3D code

! start sediment code
#ifdef sediment  
  ! === Godtyckligt vaerde paa kinetiska energin ===
  ! === daer wsed inte laengre paaverkar, 3e6.   ===
  
  k2loop: do k=0,km
     wsedtemp=0.d0
     kin=(uflux(ia,ja,k,nsm)*uflux(ia,ja,k,nsm)+ &
          vflux(ia,ja,k,nsm)*vflux(ia,ja,k,nsm))*0.5d0
     !if (kin.le.3000000) then   !f�r RCO
     !wsedtemp=wsed*(3000000-kin)/3000000
     if (kin.le.kincrit) then   !f�r SKB
        wsedtemp=wsed*(kincrit-kin)/kincrit
     endif
#if defined full_wflux || explicit_w
     wflux(ia,ja,k,nsm)=wflux(ia,ja,k,nsm) + wsedtemp * dxdy(ia,ja)   ! *dx *dy *deg**2 
#else
    do n=n1,n2
     wflux(k,n)=wflux(k,n) +  wsedtemp * dxdy(ia,ja)
    enddo
#endif
  end do k2loop
#endif   
! end sediment code
  
#ifdef larval_fish
  ! === fisk!   ===

  k3loop: do k=0,km
#ifdef full_wflux
     wflux(ia,ja,k,nsm)=wflux(ia,ja,k,nsm) + wfish * dxdy(ia,ja)   ! *dx *dy *deg**2
!     wflux(k)=wflux(ia,ja,k,nsm) +  wfish * dxdy(ia,ja)     ! *dx *dy *deg**2
#else
    do n=n1,n2
     wflux(k,n)=wflux(k,n) +  wfish * dxdy(ia,ja)     ! *dx *dy *deg**2
    enddo
#endif
  end do k3loop
#endif
! end fish code
#endif /* !explicit_w */

  return
end subroutine vertvel
