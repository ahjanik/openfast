   SUBROUTINE GenerateDynamicElement(uuN0,uuN,vvN,Stif0,Mass0,gravity,&
                                    &elem_total,node_elem,dof_node,ngp,RHS,MassM)
   !----------------------------------------------------------------------------------------
   ! This subroutine computes Global mass matrix and force vector for the beam.
   !----------------------------------------------------------------------------------------
   REAL(ReKi),INTENT(IN):: uuN0(:,:) ! Initial position vector
   REAL(ReKi),INTENT(IN):: uuN(:) ! Displacement of Mass 1: m
   REAL(ReKi),INTENT(IN):: vvN(:) ! Velocity of Mass 1: m/s
   REAL(ReKi),INTENT(IN):: Stif0(:,:,:) ! Element stiffness matrix
   REAL(ReKi),INTENT(IN):: Mass0(:,:,:) ! Element stiffness matrix
   REAL(ReKi),INTENT(IN):: gravity(:) ! Velocity of Mass 1: m/s
   INTEGER(IntKi),INTENT(IN):: elem_total ! Total number of elements
   INTEGER(IntKi),INTENT(IN):: node_elem ! Node per element
   INTEGER(IntKi),INTENT(IN):: dof_node ! Degrees of freedom per node
   INTEGER(IntKi),INTENT(IN):: ngp ! Number of Gauss points
   REAL(ReKi),INTENT(OUT):: MassM(:,:) ! Mass matrix 
   REAL(ReKi),INTENT(OUT):: RHS(:) ! Right hand side of the equation Ax=B  

   REAL(ReKi),ALLOCATABLE:: Nuu0(:) ! Nodal initial position for each element
   REAL(ReKi),ALLOCATABLE:: Nuuu(:) ! Nodal displacement of Mass 1 for each element
   REAL(ReKi),ALLOCATABLE:: Nrr0(:) ! Nodal rotation parameters for initial position 
   REAL(ReKi),ALLOCATABLE:: Nrrr(:) ! Nodal rotation parameters for displacement of Mass 1
   REAL(ReKi),ALLOCATABLE:: Nvvv(:) ! Nodal velocity of Mass 1: m/s for each element
   REAL(ReKi),ALLOCATABLE:: EStif0_GL(:,:,:) ! Nodal material properties for each element
   REAL(ReKi),ALLOCATABLE:: EMass0_GL(:,:,:) ! Nodal material properties for each element
   REAL(ReKi),ALLOCATABLE:: elf(:) ! Total element force (Fc, Fd, Fb)
   REAL(ReKi),ALLOCATABLE:: elm(:,:) ! Element mass matrix

   INTEGER(IntKi):: dof_elem ! Degree of freedom per node
   INTEGER(IntKi):: rot_elem ! Rotational degrees of freedom
   INTEGER(IntKi):: nelem ! number of elements
   INTEGER(IntKi):: j ! Index counter
   INTEGER(IntKi):: temp_id ! Index counter
   INTEGER(IntKi):: allo_stat ! Allows for an error code return

   dof_elem = dof_node * node_elem
   rot_elem = (dof_node/2) * node_elem

   ALLOCATE(Nuu0(dof_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   Nuu0 = 0.0D0

   ALLOCATE(Nuuu(dof_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   Nuuu = 0.0D0

   ALLOCATE(Nrr0(rot_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   Nrr0 = 0.0D0

   ALLOCATE(Nrrr(rot_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   Nrrr = 0.0D0

   ALLOCATE(Nvvv(dof_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   Nvvv = 0.0D0

   ALLOCATE(EStif0_GL(dof_node,dof_node,node_elem-1),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   EStif0_GL = 0.0D0

   ALLOCATE(EMass0_GL(dof_node,dof_node,node_elem-1),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   EMass0_GL = 0.0D0

   ALLOCATE(elf(dof_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   elf = 0.0D0

   ALLOCATE(elm(dof_elem,dof_elem),STAT = allo_stat)
   IF(allo_stat/=0) GOTO 9999
   elm = 0.0D0

   DO nelem=1,elem_total
!       CALL ElemNodalDispGL(uuN0,node_elem,dof_node,nelem,Nuu0)
       Nuu0(:) = uuN0(:,nelem)
       CALL ElemNodalDispGL(uuN,node_elem,dof_node,nelem,Nuuu)
       temp_id = (nelem-1)*ngp
       DO j=1,ngp
           EStif0_GL(1:6,1:6,j) = Stif0(1:6,1:6,temp_id+j)
           EMass0_GL(1:6,1:6,j) = Mass0(1:6,1:6,temp_id+j)
       ENDDO
!       CALL ElemNodalStifGL(Stif0,node_elem,dof_node,nelem,NStif0) 
!       CALL ElemNodalMassGL(m00,mEta0,rho0,node_elem,dof_node,nelem,Nm00,NmEta0,Nrho0)
       
       CALL NodalRelRotGL(Nuu0,node_elem,dof_node,Nrr0)
       CALL NodalRelRotGL(Nuuu,node_elem,dof_node,Nrrr)

       CALL ElemNodalDispGL(vvN,node_elem,dof_node,nelem,Nvvv)

!       WRITE(*,*) 'EStif0_GL1'
!       WRITE(*,*) EStif0_GL(:,:,1)
       CALL ElementMatrix(Nuu0,Nuuu,Nrr0,Nrrr,Nvvv,EStif0_GL,EMass0_GL,gravity,&
                         &ngp,node_elem,dof_node,elf,elm)

       CALL AssembleStiffKGL(nelem,node_elem,dof_elem,dof_node,elm,MassM)
       CALL AssembleRHSGL(nelem,dof_elem,node_elem,dof_node,elf,RHS)

   ENDDO

   DEALLOCATE(Nuu0)
   DEALLOCATE(Nuuu)
   DEALLOCATE(Nrr0)
   DEALLOCATE(Nrrr)
   DEALLOCATE(Nvvv)
   DEALLOCATE(EStif0_GL)
   DEALLOCATE(EMass0_GL)
   DEALLOCATE(elf)
   DEALLOCATE(elm)

   9999 IF(allo_stat/=0) THEN
            IF(ALLOCATED(Nuu0)) DEALLOCATE(Nuu0)
            IF(ALLOCATED(Nuuu)) DEALLOCATE(Nuuu)
            IF(ALLOCATED(Nrr0)) DEALLOCATE(Nrr0)
            IF(ALLOCATED(Nrrr)) DEALLOCATE(Nrrr)
            IF(ALLOCATED(Nvvv)) DEALLOCATE(Nvvv)
            IF(ALLOCATED(EStif0_GL)) DEALLOCATE(EStif0_GL)
            IF(ALLOCATED(EMass0_GL)) DEALLOCATE(EMass0_GL)
            IF(ALLOCATED(elf)) DEALLOCATE(elf)
            IF(ALLOCATED(elm)) DEALLOCATE(elm)
        ENDIF


   END SUBROUTINE GenerateDynamicElement
