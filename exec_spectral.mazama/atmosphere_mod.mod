  87  �   k820309              19.1        ���^                                                                                                          
       /scratch/myoder96/dycore/src/atmos_spectral/driver/solo/atmosphere.f90 ATMOSPHERE_MOD              ATMOSPHERE_INIT ATMOSPHERE ATMOSPHERE_END                      @                              
       SET_DOMAIN WRITE_VERSION_NUMBER MPP_PE MPP_ROOT_PE ERROR_MESG FATAL                      @                              
       GRAV PI                      @                              
       TRANS_GRID_TO_SPHERICAL TRANS_SPHERICAL_TO_GRID GET_DEG_LAT GET_GRID_BOUNDARIES GRID_DOMAIN SPECTRAL_DOMAIN GET_GRID_DOMAIN                      @                              
      TIME_TYPE SET_TIME GET_TIME i@ i@ i@                      @                              
       COMPUTE_PRESSURES_AND_HEIGHTS                      @                              
       SPECTRAL_DYNAMICS_INIT SPECTRAL_DYNAMICS SPECTRAL_DYNAMICS_END GET_NUM_LEVELS COMPLETE_INIT_OF_TRACERS GET_AXIS_ID SPECTRAL_DIAGNOSTICS COMPLETE_ROBERT_FILTER          @       �   @                              
       TRACER_TYPE                      @                              
       HS_FORCING_INIT HS_FORCING                      @                         	     
       MODEL_ATMOS                      @                         
     
       GET_NUMBER_TRACERS               @�                                       u #TRANS_SPHERICAL_TO_GRID_3D    #TRANS_SPHERICAL_TO_GRID_2D    #         @     @                                                #SPHERICAL    #GRID           " 
     �                                                             & 5 r              & 5 r              &                                                  "     �                                               
               & 5 r              &                   &                                           #         @     @                                                #SPHERICAL    #GRID              
                                                                  &                   &                                                                                                        
               &                   &                                                         @�                                       u #TRANS_GRID_TO_SPHERICAL_3D    #TRANS_GRID_TO_SPHERICAL_2D    #         @     @                                                #GRID    #SPHERICAL    #DO_TRUNCATION           " 
     �                                               
              & 5 r              &                   &                                                  " 
    �                                                              & 5 r              & 5 r              &                                                     
                                            #         @     @                                                #GRID    #SPHERICAL    #DO_TRUNCATION              
                                                    
              &                   &                                                     
                                                                  &                   &                                                     
                                                                                                       #TIME_PLUS    &         @   @                                                      #TIME1    #TIME2    #TIME_TYPE              
                                                     #TIME_TYPE              
                                                     #TIME_TYPE                                                               #TIME_MINUS     &         @   @                                                       #TIME1 !   #TIME2 "   #TIME_TYPE              
                                  !                   #TIME_TYPE              
                                  "                   #TIME_TYPE                                                               #TIME_LT #   %         @   @                            #                           #TIME1 $   #TIME2 %             
                                  $                   #TIME_TYPE              
                                  %                   #TIME_TYPE                   �  @                                '                    #SECONDS &   #DAYS '                � D                              &                                � D                              '                                 @  @                           (     '�                    #NAME )   #NUMERICAL_REPRESENTATION *   #ADVECT_HORIZ +   #ADVECT_VERT ,   #HOLE_FILLING -   #ROBERT_COEFF .   #RESTARTED /                � $                             )                                         � $                             *                                         � $                             +             @                           � $                             ,             `                           � $                             -             �                           � $                              .     �          
                � $                              /     �                            �  @                         0     '�             *      #X 1   #Y @   #LIST A   #PE B   #POS C   #FOLD D   #GRIDTYPE E   #OVERLAP F   #RECV_E G   #RECV_SE O   #RECV_S P   #RECV_SW Q   #RECV_W R   #RECV_NW S   #RECV_N T   #RECV_NE U   #SEND_E V   #SEND_SE W   #SEND_S X   #SEND_SW Y   #SEND_W Z   #SEND_NW [   #SEND_N \   #SEND_NE ]   #REMOTE_DOMAINS_INITIALIZED ^   #RECV_E_OFF _   #RECV_SE_OFF `   #RECV_S_OFF a   #RECV_SW_OFF b   #RECV_W_OFF c   #RECV_NW_OFF d   #RECV_N_OFF e   #RECV_NE_OFF f   #SEND_E_OFF g   #SEND_SE_OFF h   #SEND_S_OFF i   #SEND_SW_OFF j   #SEND_W_OFF k   #SEND_NW_OFF l   #SEND_N_OFF m   #SEND_NE_OFF n   #REMOTE_OFF_DOMAINS_INITIALIZED o                � D                             1     �                      #DOMAIN1D 2                  �  @                         2     '�                    #COMPUTE 3   #DATA :   #GLOBAL ;   #CYCLIC <   #LIST =   #PE >   #POS ?                � D                             3                           #DOMAIN_AXIS_SPEC 4                  �  @                         4     '                    #BEGIN 5   #END 6   #SIZE 7   #MAX_SIZE 8   #IS_GLOBAL 9                � D                             5                                � D                             6                               � D                             7                               � D                             8                               � D                             9                               � D                             :                          #DOMAIN_AXIS_SPEC 4                � D                             ;            (              #DOMAIN_AXIS_SPEC 4                � D                             <     <                       �D                             =            @       �            #DOMAIN1D 2             &                                                                                 y#DOMAIN1D 2                                                               � D                             >     �                          � D                             ?     �                          � D                             @     �       �              #DOMAIN1D 2             �D                             A                   �           #DOMAIN2D 0             &                                                                                 y#DOMAIN2D 0                                                               � D                             B     h                         � D                             C     l                         � D                             D     p                         � D                             E     t                         � D                             F     x                         � D                             G            |      	       #RECTANGLE H                 @  @                         H     '                    #IS I   #IE J   #JS K   #JE L   #OVERLAP M   #FOLDED N                �                               I                                �                               J                               �                               K                               �                               L                               �                               M                               �                               N                               � D                             O            �      
       #RECTANGLE H                � D                             P            �             #RECTANGLE H                � D                             Q            �             #RECTANGLE H                � D                             R            �             #RECTANGLE H                � D                             S            �             #RECTANGLE H                � D                             T                         #RECTANGLE H                � D                             U            $             #RECTANGLE H                � D                             V            <             #RECTANGLE H                � D                             W            T             #RECTANGLE H                � D                             X            l             #RECTANGLE H                � D                             Y            �             #RECTANGLE H                � D                             Z            �             #RECTANGLE H                � D                             [            �             #RECTANGLE H                � D                             \            �             #RECTANGLE H                � D                             ]            �             #RECTANGLE H                � D                             ^     �                         � D                             _                          #RECTANGLE H                � D                             `                         #RECTANGLE H                � D                             a            0             #RECTANGLE H                � D                             b            H             #RECTANGLE H                � D                             c            `             #RECTANGLE H                � D                             d            x             #RECTANGLE H                � D                             e            �              #RECTANGLE H                � D                             f            �      !       #RECTANGLE H                � D                             g            �      "       #RECTANGLE H                � D                             h            �      #       #RECTANGLE H                � D                             i            �      $       #RECTANGLE H                � D                             j                  %       #RECTANGLE H                � D                             k                   &       #RECTANGLE H                � D                             l            8      '       #RECTANGLE H                � D                             m            P      (       #RECTANGLE H                � D                             n            h      )       #RECTANGLE H                � D                             o     �      *                    @  @                          p     '�                    #NAME q   #NUMERICAL_REPRESENTATION r   #ADVECT_HORIZ s   #ADVECT_VERT t   #HOLE_FILLING u   #ROBERT_COEFF v   #RESTARTED w                � $                             q                                         � $                             r                                         � $                             s             @                           � $                             t             `                           � $                             u             �                           � $                              v     �          
                � $                              w     �             #         @                                   x                    #TIME_INIT y   #TIME z   #TIME_STEP_IN {             
                                  y                   #TIME_TYPE              
  @                               z                   #TIME_TYPE              
                                  {                   #TIME_TYPE    #         @                                   |                    #TIME }   #TIMESPINUP ~             
  @                               }                   #TIME_TYPE              D @                               ~     
       #         @                                                                      @                                                       @                                                       @                                            �   ^      fn#fn $   �   :   b   uapp(ATMOSPHERE_MOD    8  �   J  FMS_MOD    �  H   J  CONSTANTS_MOD      �   J  TRANSFORMS_MOD !   �  k   J  TIME_MANAGER_MOD %   +  ^   J  PRESS_AND_GEOPOT_MOD &   �  �   J  SPECTRAL_DYNAMICS_MOD     h  L   J  TRACER_TYPE_MOD    �  [   J  HS_FORCING_MOD "     L   J  FIELD_MANAGER_MOD #   [  S   J  TRACER_MANAGER_MOD ;   �  �       gen@TRANS_SPHERICAL_TO_GRID+TRANSFORMS_MOD :   .  a      TRANS_SPHERICAL_TO_GRID_3D+TRANSFORMS_MOD D   �  �   a   TRANS_SPHERICAL_TO_GRID_3D%SPHERICAL+TRANSFORMS_MOD ?   S  �   a   TRANS_SPHERICAL_TO_GRID_3D%GRID+TRANSFORMS_MOD :     a      TRANS_SPHERICAL_TO_GRID_2D+TRANSFORMS_MOD D   t  �   a   TRANS_SPHERICAL_TO_GRID_2D%SPHERICAL+TRANSFORMS_MOD ?   	  �   a   TRANS_SPHERICAL_TO_GRID_2D%GRID+TRANSFORMS_MOD ;   �	  �       gen@TRANS_GRID_TO_SPHERICAL+TRANSFORMS_MOD :   <
  t      TRANS_GRID_TO_SPHERICAL_3D+TRANSFORMS_MOD ?   �
  �   a   TRANS_GRID_TO_SPHERICAL_3D%GRID+TRANSFORMS_MOD D   p  �   a   TRANS_GRID_TO_SPHERICAL_3D%SPHERICAL+TRANSFORMS_MOD H   4  @   a   TRANS_GRID_TO_SPHERICAL_3D%DO_TRUNCATION+TRANSFORMS_MOD :   t  t      TRANS_GRID_TO_SPHERICAL_2D+TRANSFORMS_MOD ?   �  �   a   TRANS_GRID_TO_SPHERICAL_2D%GRID+TRANSFORMS_MOD D   �  �   a   TRANS_GRID_TO_SPHERICAL_2D%SPHERICAL+TRANSFORMS_MOD H   0  @   a   TRANS_GRID_TO_SPHERICAL_2D%DO_TRUNCATION+TRANSFORMS_MOD &   p  O      i@+TIME_MANAGER_MOD +   �  u      TIME_PLUS+TIME_MANAGER_MOD 1   4  W   a   TIME_PLUS%TIME1+TIME_MANAGER_MOD 1   �  W   a   TIME_PLUS%TIME2+TIME_MANAGER_MOD &   �  P      i@+TIME_MANAGER_MOD ,   2  u      TIME_MINUS+TIME_MANAGER_MOD 2   �  W   a   TIME_MINUS%TIME1+TIME_MANAGER_MOD 2   �  W   a   TIME_MINUS%TIME2+TIME_MANAGER_MOD &   U  M      i@+TIME_MANAGER_MOD )   �  f      TIME_LT+TIME_MANAGER_MOD /     W   a   TIME_LT%TIME1+TIME_MANAGER_MOD /   _  W   a   TIME_LT%TIME2+TIME_MANAGER_MOD +   �  g       TIME_TYPE+TIME_MANAGER_MOD ;     H   %   TIME_TYPE%SECONDS+TIME_MANAGER_MOD=SECONDS 5   e  H   %   TIME_TYPE%DAYS+TIME_MANAGER_MOD=DAYS ,   �  �      TRACER_TYPE+TRACER_TYPE_MOD 1   {  P   a   TRACER_TYPE%NAME+TRACER_TYPE_MOD E   �  P   a   TRACER_TYPE%NUMERICAL_REPRESENTATION+TRACER_TYPE_MOD 9     P   a   TRACER_TYPE%ADVECT_HORIZ+TRACER_TYPE_MOD 8   k  P   a   TRACER_TYPE%ADVECT_VERT+TRACER_TYPE_MOD 9   �  P   a   TRACER_TYPE%HOLE_FILLING+TRACER_TYPE_MOD 9     H   a   TRACER_TYPE%ROBERT_COEFF+TRACER_TYPE_MOD 6   S  H   a   TRACER_TYPE%RESTARTED+TRACER_TYPE_MOD )   �  �     DOMAIN2D+MPP_DOMAINS_MOD -   M  ^   %   DOMAIN2D%X+MPP_DOMAINS_MOD=X )   �  �      DOMAIN1D+MPP_DOMAINS_MOD 9   E  f   %   DOMAIN1D%COMPUTE+MPP_DOMAINS_MOD=COMPUTE 1   �  �      DOMAIN_AXIS_SPEC+MPP_DOMAINS_MOD =   6  H   %   DOMAIN_AXIS_SPEC%BEGIN+MPP_DOMAINS_MOD=BEGIN 9   ~  H   %   DOMAIN_AXIS_SPEC%END+MPP_DOMAINS_MOD=END ;   �  H   %   DOMAIN_AXIS_SPEC%SIZE+MPP_DOMAINS_MOD=SIZE C     H   %   DOMAIN_AXIS_SPEC%MAX_SIZE+MPP_DOMAINS_MOD=MAX_SIZE E   V  H   %   DOMAIN_AXIS_SPEC%IS_GLOBAL+MPP_DOMAINS_MOD=IS_GLOBAL 3   �  f   %   DOMAIN1D%DATA+MPP_DOMAINS_MOD=DATA 7     f   %   DOMAIN1D%GLOBAL+MPP_DOMAINS_MOD=GLOBAL 7   j  H   %   DOMAIN1D%CYCLIC+MPP_DOMAINS_MOD=CYCLIC 3   �    %   DOMAIN1D%LIST+MPP_DOMAINS_MOD=LIST /   �  H   %   DOMAIN1D%PE+MPP_DOMAINS_MOD=PE 1   
  H   %   DOMAIN1D%POS+MPP_DOMAINS_MOD=POS -   R  ^   %   DOMAIN2D%Y+MPP_DOMAINS_MOD=Y 3   �    %   DOMAIN2D%LIST+MPP_DOMAINS_MOD=LIST /   �   H   %   DOMAIN2D%PE+MPP_DOMAINS_MOD=PE 1   !  H   %   DOMAIN2D%POS+MPP_DOMAINS_MOD=POS 3   P!  H   %   DOMAIN2D%FOLD+MPP_DOMAINS_MOD=FOLD ;   �!  H   %   DOMAIN2D%GRIDTYPE+MPP_DOMAINS_MOD=GRIDTYPE 9   �!  H   %   DOMAIN2D%OVERLAP+MPP_DOMAINS_MOD=OVERLAP 7   ("  _   %   DOMAIN2D%RECV_E+MPP_DOMAINS_MOD=RECV_E *   �"  �      RECTANGLE+MPP_DOMAINS_MOD -   #  H   a   RECTANGLE%IS+MPP_DOMAINS_MOD -   X#  H   a   RECTANGLE%IE+MPP_DOMAINS_MOD -   �#  H   a   RECTANGLE%JS+MPP_DOMAINS_MOD -   �#  H   a   RECTANGLE%JE+MPP_DOMAINS_MOD 2   0$  H   a   RECTANGLE%OVERLAP+MPP_DOMAINS_MOD 1   x$  H   a   RECTANGLE%FOLDED+MPP_DOMAINS_MOD 9   �$  _   %   DOMAIN2D%RECV_SE+MPP_DOMAINS_MOD=RECV_SE 7   %  _   %   DOMAIN2D%RECV_S+MPP_DOMAINS_MOD=RECV_S 9   ~%  _   %   DOMAIN2D%RECV_SW+MPP_DOMAINS_MOD=RECV_SW 7   �%  _   %   DOMAIN2D%RECV_W+MPP_DOMAINS_MOD=RECV_W 9   <&  _   %   DOMAIN2D%RECV_NW+MPP_DOMAINS_MOD=RECV_NW 7   �&  _   %   DOMAIN2D%RECV_N+MPP_DOMAINS_MOD=RECV_N 9   �&  _   %   DOMAIN2D%RECV_NE+MPP_DOMAINS_MOD=RECV_NE 7   Y'  _   %   DOMAIN2D%SEND_E+MPP_DOMAINS_MOD=SEND_E 9   �'  _   %   DOMAIN2D%SEND_SE+MPP_DOMAINS_MOD=SEND_SE 7   (  _   %   DOMAIN2D%SEND_S+MPP_DOMAINS_MOD=SEND_S 9   v(  _   %   DOMAIN2D%SEND_SW+MPP_DOMAINS_MOD=SEND_SW 7   �(  _   %   DOMAIN2D%SEND_W+MPP_DOMAINS_MOD=SEND_W 9   4)  _   %   DOMAIN2D%SEND_NW+MPP_DOMAINS_MOD=SEND_NW 7   �)  _   %   DOMAIN2D%SEND_N+MPP_DOMAINS_MOD=SEND_N 9   �)  _   %   DOMAIN2D%SEND_NE+MPP_DOMAINS_MOD=SEND_NE _   Q*  H   %   DOMAIN2D%REMOTE_DOMAINS_INITIALIZED+MPP_DOMAINS_MOD=REMOTE_DOMAINS_INITIALIZED ?   �*  _   %   DOMAIN2D%RECV_E_OFF+MPP_DOMAINS_MOD=RECV_E_OFF A   �*  _   %   DOMAIN2D%RECV_SE_OFF+MPP_DOMAINS_MOD=RECV_SE_OFF ?   W+  _   %   DOMAIN2D%RECV_S_OFF+MPP_DOMAINS_MOD=RECV_S_OFF A   �+  _   %   DOMAIN2D%RECV_SW_OFF+MPP_DOMAINS_MOD=RECV_SW_OFF ?   ,  _   %   DOMAIN2D%RECV_W_OFF+MPP_DOMAINS_MOD=RECV_W_OFF A   t,  _   %   DOMAIN2D%RECV_NW_OFF+MPP_DOMAINS_MOD=RECV_NW_OFF ?   �,  _   %   DOMAIN2D%RECV_N_OFF+MPP_DOMAINS_MOD=RECV_N_OFF A   2-  _   %   DOMAIN2D%RECV_NE_OFF+MPP_DOMAINS_MOD=RECV_NE_OFF ?   �-  _   %   DOMAIN2D%SEND_E_OFF+MPP_DOMAINS_MOD=SEND_E_OFF A   �-  _   %   DOMAIN2D%SEND_SE_OFF+MPP_DOMAINS_MOD=SEND_SE_OFF ?   O.  _   %   DOMAIN2D%SEND_S_OFF+MPP_DOMAINS_MOD=SEND_S_OFF A   �.  _   %   DOMAIN2D%SEND_SW_OFF+MPP_DOMAINS_MOD=SEND_SW_OFF ?   /  _   %   DOMAIN2D%SEND_W_OFF+MPP_DOMAINS_MOD=SEND_W_OFF A   l/  _   %   DOMAIN2D%SEND_NW_OFF+MPP_DOMAINS_MOD=SEND_NW_OFF ?   �/  _   %   DOMAIN2D%SEND_N_OFF+MPP_DOMAINS_MOD=SEND_N_OFF A   *0  _   %   DOMAIN2D%SEND_NE_OFF+MPP_DOMAINS_MOD=SEND_NE_OFF g   �0  H   %   DOMAIN2D%REMOTE_OFF_DOMAINS_INITIALIZED+MPP_DOMAINS_MOD=REMOTE_OFF_DOMAINS_INITIALIZED ,   �0  �      TRACER_TYPE+TRACER_TYPE_MOD 1   �1  P   a   TRACER_TYPE%NAME+TRACER_TYPE_MOD E   �1  P   a   TRACER_TYPE%NUMERICAL_REPRESENTATION+TRACER_TYPE_MOD 9   ?2  P   a   TRACER_TYPE%ADVECT_HORIZ+TRACER_TYPE_MOD 8   �2  P   a   TRACER_TYPE%ADVECT_VERT+TRACER_TYPE_MOD 9   �2  P   a   TRACER_TYPE%HOLE_FILLING+TRACER_TYPE_MOD 9   /3  H   a   TRACER_TYPE%ROBERT_COEFF+TRACER_TYPE_MOD 6   w3  H   a   TRACER_TYPE%RESTARTED+TRACER_TYPE_MOD     �3  s       ATMOSPHERE_INIT *   24  W   a   ATMOSPHERE_INIT%TIME_INIT %   �4  W   a   ATMOSPHERE_INIT%TIME -   �4  W   a   ATMOSPHERE_INIT%TIME_STEP_IN    75  b       ATMOSPHERE     �5  W   a   ATMOSPHERE%TIME &   �5  @   a   ATMOSPHERE%TIMESPINUP    06  H       ATMOSPHERE_END "   x6  @      NS+TRANSFORMS_MOD "   �6  @      MS+TRANSFORMS_MOD "   �6  @      IS+TRANSFORMS_MOD 