  V  J   k820309              19.1        ؘ�^                                                                                                          
       /scratch/myoder96/dycore/src/atmos_spectral/model/water_borrowing.f90 WATER_BORROWING_MOD              WATER_BORROWING                      @                              
       MPP_PE MPP_ROOT_PE WRITE_VERSION_NUMBER ERROR_MESG FATAL                      @                              
       GET_GRID_DOMAIN                �  @                              '�             *      #X    #Y    #LIST    #PE    #POS    #FOLD    #GRIDTYPE    #OVERLAP    #RECV_E    #RECV_SE "   #RECV_S #   #RECV_SW $   #RECV_W %   #RECV_NW &   #RECV_N '   #RECV_NE (   #SEND_E )   #SEND_SE *   #SEND_S +   #SEND_SW ,   #SEND_W -   #SEND_NW .   #SEND_N /   #SEND_NE 0   #REMOTE_DOMAINS_INITIALIZED 1   #RECV_E_OFF 2   #RECV_SE_OFF 3   #RECV_S_OFF 4   #RECV_SW_OFF 5   #RECV_W_OFF 6   #RECV_NW_OFF 7   #RECV_N_OFF 8   #RECV_NE_OFF 9   #SEND_E_OFF :   #SEND_SE_OFF ;   #SEND_S_OFF <   #SEND_SW_OFF =   #SEND_W_OFF >   #SEND_NW_OFF ?   #SEND_N_OFF @   #SEND_NE_OFF A   #REMOTE_OFF_DOMAINS_INITIALIZED B                � D                                  �                      #DOMAIN1D                   �  @                              '�                    #COMPUTE    #DATA    #GLOBAL    #CYCLIC    #LIST    #PE    #POS                 � D                                                        #DOMAIN_AXIS_SPEC                   �  @                              '                    #BEGIN    #END 	   #SIZE 
   #MAX_SIZE    #IS_GLOBAL                 � D                                                             � D                             	                               � D                             
                               � D                                                            � D                                                            � D                                                       #DOMAIN_AXIS_SPEC                 � D                                         (              #DOMAIN_AXIS_SPEC                 � D                                  <                       �D                                         @       �            #DOMAIN1D              &                                                                   �              y#DOMAIN1D                                                                � D                                  �                          � D                                  �                          � D                                  �       �              #DOMAIN1D              �D                                                �           #DOMAIN2D              &                                                                   �              y#DOMAIN2D                                                                � D                                  h                         � D                                  l                         � D                                  p                         � D                                  t                         � D                                  x                         � D                                         |      	       #RECTANGLE                  @  @                              '                    #IS    #IE    #JS    #JE    #OVERLAP     #FOLDED !                �                                                               �                                                              �                                                              �                                                              �                                                               �                               !                               � D                             "            �      
       #RECTANGLE                 � D                             #            �             #RECTANGLE                 � D                             $            �             #RECTANGLE                 � D                             %            �             #RECTANGLE                 � D                             &            �             #RECTANGLE                 � D                             '                         #RECTANGLE                 � D                             (            $             #RECTANGLE                 � D                             )            <             #RECTANGLE                 � D                             *            T             #RECTANGLE                 � D                             +            l             #RECTANGLE                 � D                             ,            �             #RECTANGLE                 � D                             -            �             #RECTANGLE                 � D                             .            �             #RECTANGLE                 � D                             /            �             #RECTANGLE                 � D                             0            �             #RECTANGLE                 � D                             1     �                         � D                             2                          #RECTANGLE                 � D                             3                         #RECTANGLE                 � D                             4            0             #RECTANGLE                 � D                             5            H             #RECTANGLE                 � D                             6            `             #RECTANGLE                 � D                             7            x             #RECTANGLE                 � D                             8            �              #RECTANGLE                 � D                             9            �      !       #RECTANGLE                 � D                             :            �      "       #RECTANGLE                 � D                             ;            �      #       #RECTANGLE                 � D                             <            �      $       #RECTANGLE                 � D                             =                  %       #RECTANGLE                 � D                             >                   &       #RECTANGLE                 � D                             ?            8      '       #RECTANGLE                 � D                             @            P      (       #RECTANGLE                 � D                             A            h      )       #RECTANGLE                 � D                             B     �      *      #         @                                   C                    #DT_QG D   #QG E   #CURRENT F   #P_HALF G   #DELTA_T H             
D                                 D                   
               &                   &                   &                                                  0  
 @                               E                   
              &                   &                   &                                                     
  @                               F                     
                                  G                   
              &                   &                   &                                                     
                                  H     
         �   b      fn#fn )         b   uapp(WATER_BORROWING_MOD    "  y   J  FMS_MOD    �  P   J  TRANSFORMS_MOD )   �  �     DOMAIN2D+MPP_DOMAINS_MOD -   �  ^   %   DOMAIN2D%X+MPP_DOMAINS_MOD=X )   �  �      DOMAIN1D+MPP_DOMAINS_MOD 9   �  f   %   DOMAIN1D%COMPUTE+MPP_DOMAINS_MOD=COMPUTE 1   �  �      DOMAIN_AXIS_SPEC+MPP_DOMAINS_MOD =   �  H   %   DOMAIN_AXIS_SPEC%BEGIN+MPP_DOMAINS_MOD=BEGIN 9   �  H   %   DOMAIN_AXIS_SPEC%END+MPP_DOMAINS_MOD=END ;     H   %   DOMAIN_AXIS_SPEC%SIZE+MPP_DOMAINS_MOD=SIZE C   ^  H   %   DOMAIN_AXIS_SPEC%MAX_SIZE+MPP_DOMAINS_MOD=MAX_SIZE E   �  H   %   DOMAIN_AXIS_SPEC%IS_GLOBAL+MPP_DOMAINS_MOD=IS_GLOBAL 3   �  f   %   DOMAIN1D%DATA+MPP_DOMAINS_MOD=DATA 7   T  f   %   DOMAIN1D%GLOBAL+MPP_DOMAINS_MOD=GLOBAL 7   �  H   %   DOMAIN1D%CYCLIC+MPP_DOMAINS_MOD=CYCLIC 3   	    %   DOMAIN1D%LIST+MPP_DOMAINS_MOD=LIST /   
  H   %   DOMAIN1D%PE+MPP_DOMAINS_MOD=PE 1   Z
  H   %   DOMAIN1D%POS+MPP_DOMAINS_MOD=POS -   �
  ^   %   DOMAIN2D%Y+MPP_DOMAINS_MOD=Y 3        %   DOMAIN2D%LIST+MPP_DOMAINS_MOD=LIST /     H   %   DOMAIN2D%PE+MPP_DOMAINS_MOD=PE 1   X  H   %   DOMAIN2D%POS+MPP_DOMAINS_MOD=POS 3   �  H   %   DOMAIN2D%FOLD+MPP_DOMAINS_MOD=FOLD ;   �  H   %   DOMAIN2D%GRIDTYPE+MPP_DOMAINS_MOD=GRIDTYPE 9   0  H   %   DOMAIN2D%OVERLAP+MPP_DOMAINS_MOD=OVERLAP 7   x  _   %   DOMAIN2D%RECV_E+MPP_DOMAINS_MOD=RECV_E *   �  �      RECTANGLE+MPP_DOMAINS_MOD -   `  H   a   RECTANGLE%IS+MPP_DOMAINS_MOD -   �  H   a   RECTANGLE%IE+MPP_DOMAINS_MOD -   �  H   a   RECTANGLE%JS+MPP_DOMAINS_MOD -   8  H   a   RECTANGLE%JE+MPP_DOMAINS_MOD 2   �  H   a   RECTANGLE%OVERLAP+MPP_DOMAINS_MOD 1   �  H   a   RECTANGLE%FOLDED+MPP_DOMAINS_MOD 9     _   %   DOMAIN2D%RECV_SE+MPP_DOMAINS_MOD=RECV_SE 7   o  _   %   DOMAIN2D%RECV_S+MPP_DOMAINS_MOD=RECV_S 9   �  _   %   DOMAIN2D%RECV_SW+MPP_DOMAINS_MOD=RECV_SW 7   -  _   %   DOMAIN2D%RECV_W+MPP_DOMAINS_MOD=RECV_W 9   �  _   %   DOMAIN2D%RECV_NW+MPP_DOMAINS_MOD=RECV_NW 7   �  _   %   DOMAIN2D%RECV_N+MPP_DOMAINS_MOD=RECV_N 9   J  _   %   DOMAIN2D%RECV_NE+MPP_DOMAINS_MOD=RECV_NE 7   �  _   %   DOMAIN2D%SEND_E+MPP_DOMAINS_MOD=SEND_E 9     _   %   DOMAIN2D%SEND_SE+MPP_DOMAINS_MOD=SEND_SE 7   g  _   %   DOMAIN2D%SEND_S+MPP_DOMAINS_MOD=SEND_S 9   �  _   %   DOMAIN2D%SEND_SW+MPP_DOMAINS_MOD=SEND_SW 7   %  _   %   DOMAIN2D%SEND_W+MPP_DOMAINS_MOD=SEND_W 9   �  _   %   DOMAIN2D%SEND_NW+MPP_DOMAINS_MOD=SEND_NW 7   �  _   %   DOMAIN2D%SEND_N+MPP_DOMAINS_MOD=SEND_N 9   B  _   %   DOMAIN2D%SEND_NE+MPP_DOMAINS_MOD=SEND_NE _   �  H   %   DOMAIN2D%REMOTE_DOMAINS_INITIALIZED+MPP_DOMAINS_MOD=REMOTE_DOMAINS_INITIALIZED ?   �  _   %   DOMAIN2D%RECV_E_OFF+MPP_DOMAINS_MOD=RECV_E_OFF A   H  _   %   DOMAIN2D%RECV_SE_OFF+MPP_DOMAINS_MOD=RECV_SE_OFF ?   �  _   %   DOMAIN2D%RECV_S_OFF+MPP_DOMAINS_MOD=RECV_S_OFF A     _   %   DOMAIN2D%RECV_SW_OFF+MPP_DOMAINS_MOD=RECV_SW_OFF ?   e  _   %   DOMAIN2D%RECV_W_OFF+MPP_DOMAINS_MOD=RECV_W_OFF A   �  _   %   DOMAIN2D%RECV_NW_OFF+MPP_DOMAINS_MOD=RECV_NW_OFF ?   #  _   %   DOMAIN2D%RECV_N_OFF+MPP_DOMAINS_MOD=RECV_N_OFF A   �  _   %   DOMAIN2D%RECV_NE_OFF+MPP_DOMAINS_MOD=RECV_NE_OFF ?   �  _   %   DOMAIN2D%SEND_E_OFF+MPP_DOMAINS_MOD=SEND_E_OFF A   @  _   %   DOMAIN2D%SEND_SE_OFF+MPP_DOMAINS_MOD=SEND_SE_OFF ?   �  _   %   DOMAIN2D%SEND_S_OFF+MPP_DOMAINS_MOD=SEND_S_OFF A   �  _   %   DOMAIN2D%SEND_SW_OFF+MPP_DOMAINS_MOD=SEND_SW_OFF ?   ]  _   %   DOMAIN2D%SEND_W_OFF+MPP_DOMAINS_MOD=SEND_W_OFF A   �  _   %   DOMAIN2D%SEND_NW_OFF+MPP_DOMAINS_MOD=SEND_NW_OFF ?     _   %   DOMAIN2D%SEND_N_OFF+MPP_DOMAINS_MOD=SEND_N_OFF A   z  _   %   DOMAIN2D%SEND_NE_OFF+MPP_DOMAINS_MOD=SEND_NE_OFF g   �  H   %   DOMAIN2D%REMOTE_OFF_DOMAINS_INITIALIZED+MPP_DOMAINS_MOD=REMOTE_OFF_DOMAINS_INITIALIZED     !  �       WATER_BORROWING &   �  �   a   WATER_BORROWING%DT_QG #   ^  �   a   WATER_BORROWING%QG (     @   a   WATER_BORROWING%CURRENT '   Z  �   a   WATER_BORROWING%P_HALF (     @   a   WATER_BORROWING%DELTA_T 