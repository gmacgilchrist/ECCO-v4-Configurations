C $Header: /home/ubuntu/mnt/e9_copy/MITgcm/pkg/shelfice/shelfice_forcing_surf.F,v 1.3 2015/02/14 22:28:57 jmc Exp $
C $Name:  $

#include "SHELFICE_OPTIONS.h"

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP
C     !ROUTINE: SHELFICE_FORCING_SURF
C     !INTERFACE:
      SUBROUTINE SHELFICE_FORCING_SURF(
     I           bi, bj, iMin, iMax, jMin, jMax,
     I           myTime, myIter, myThid )
C     !DESCRIPTION: \bv
C     *==========================================================*
C     | S/R SHELFICE_FORCING_SURF
C     | o Contains problem specific surface forcing
C     *==========================================================*
C     \ev

C     !USES:
      IMPLICIT NONE
C     == Global data ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
c#include "DYNVARS.h"
#include "SURFACE.h"
#include "FFIELDS.h"
#include "SHELFICE.h"

C     !INPUT/OUTPUT PARAMETERS:
C     == Routine arguments ==
C     bi,bj     :: Current tile indices
C     iMin,iMax :: Working range of x-index for applying forcing.
C     jMin,jMax :: Working range of y-index for applying forcing.
C     myTime    :: Current time in simulation
C     myIter    :: Current iteration number in simulation
C     myThid    :: Thread Id number
      INTEGER bi, bj
      INTEGER iMin, iMax, jMin, jMax
      _RL myTime
      INTEGER myIter
      INTEGER myThid

#ifdef ALLOW_SHELFICE
C     !LOCAL VARIABLES:
C     == Local variables ==
C     i,j   :: Loop counters
      INTEGER i, j
CEOP

c     DO bj=myByLo(myThid),myByHi(myThid)
c      DO bi=myBxLo(myThid),myBxHi(myThid)

C--   Zero out surface forcing terms below ice-shelf
        DO j=1-OLy,sNy+OLy
         DO i=1-OLx,sNx+OLx
          IF ( kTopC(i,j,bi,bj).NE.0 ) THEN
            surfaceForcingT(i,j,bi,bj) = 0.
            surfaceForcingS(i,j,bi,bj) = 0.
            EmPmR(i,j,bi,bj) = 0.
          ENDIF
         ENDDO
        ENDDO
        DO j=1-OLy,sNy+OLy
         DO i=2-OLx,sNx+OLx
          IF ( MAX( kTopC(i-1,j,bi,bj), kTopC(i,j,bi,bj) ).NE.0 ) THEN
            surfaceForcingU(i,j,bi,bj) = 0.
          ENDIF
         ENDDO
        ENDDO
        DO j=2-OLy,sNy+OLy
         DO i=1-OLx,sNx+OLx
          IF ( MAX( kTopC(i,j-1,bi,bj), kTopC(i,j,bi,bj) ).NE.0 ) THEN
            surfaceForcingV(i,j,bi,bj) = 0.
          ENDIF
         ENDDO
        ENDDO

C--   Forcing term


#ifndef shelfice_new_thermo
      
        IF ( .NOT.SHELFICEboundaryLayer ) THEN
C-    for now, forcing using SHELFICEboundaryLayer is done separately
C     (calling SHELFICE_FORCING_T & _S from APPLY_FORCING_T & _S)

         DO j=1,sNy
          DO i=1,sNx
           IF ( kTopC(i,j,bi,bj).NE.0 ) THEN
            surfaceForcingT(i,j,bi,bj) = shelficeForcingT(i,j,bi,bj)
            surfaceForcingS(i,j,bi,bj) = shelficeForcingS(i,j,bi,bj)
           ENDIF
          ENDDO
         ENDDO

         IF ( useRealFreshWaterFlux ) THEN
#ifdef ALLOW_AUTODIFF
          STOP 'RealFreshWaterFlux disabled in SHELFICE_FORCING_SURF'
#else /* ALLOW_AUTODIFF */
          DO j=1-OLy,sNy+OLy
           DO i=1-OLx,sNx+OLx
c           IF ( kTopC(i,j,bi,bj).NE.0 ) THEN
             EmPmR(i,j,bi,bj) = EmPmR(i,j,bi,bj)
     &         + shelfIceFreshWaterFlux(i,j,bi,bj)
c           ENDIF
           ENDDO
          ENDDO
#endif /* ALLOW_AUTODIFF */
         ENDIF

C--   end if not SHELFICEboundaryLayer
        ENDIF
#endif /* shelfice_new_thermo */

#ifdef EXACT_CONSERV
        IF ( staggerTimeStep ) THEN
          DO j=1-OLy,sNy+OLy
           DO i=1-OLx,sNx+OLx
             PmEpR(i,j,bi,bj) = -EmPmR(i,j,bi,bj)
           ENDDO
          ENDDO
        ENDIF
#endif /* EXACT_CONSERV */

        IF ( usingZCoords ) THEN
          DO j = jMin, jMax
           DO i = iMin, iMax
             phi0surf(i,j,bi,bj) = phi0surf(i,j,bi,bj)
     &         + shelficeLoadAnomaly(i,j,bi,bj)*recip_rhoConst
           ENDDO
          ENDDO
        ENDIF

c      ENDDO
c     ENDDO

#endif /* ALLOW_SHELFICE */
      RETURN
      END
