/ / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                               s p r i n g . m q 4   |  
 / / |                                                                     C o p y r i g h t   2 0 2 4 ,   M e t a Q u o t e s   L t d .   |  
 / / |                                                                                           h t t p s : / / w w w . m q l 5 . c o m   |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 # p r o p e r t y   c o p y r i g h t   " C o p y r i g h t   2 0 2 4 ,   M e t a Q u o t e s   L t d . "  
 # p r o p e r t y   l i n k             " h t t p s : / / w w w . m q l 5 . c o m "  
 # p r o p e r t y   v e r s i o n       " 1 . 0 0 "  
 # p r o p e r t y   s t r i c t  
  
 / *  
       !" "/  ( >?8A0=85  B>;L:>  ?>  >4=><C  8=AB@C<5=BC)  
       1 .   A>25B=8:  >B:@K205B  >@45@0  B>;L:>  2  >4=><  =0?@02;5=88,   ;81>  l o n g   ;81>  s h o r t .  
       2 .   A>25B=8:  @01>B05B  B>;L:>  ?>  C:070==K<  2>  2E>4=KE  ?0@0<5B@0E  8=AB@C<5=B0<  ( U _ T i k e r s ) .  
       3 .   A>25B=8:  @01>B05B  ?>  ?@8=F8?C  A5B:8.  
       4 .   A=0G0;0  A>25B=8:  2KAB02;O5B  >B;>65==K9  1 - 9  >@45@  ?>  F5=5  >B;8G0NI59AO  >B  B5:CI59  =0  U _ P r i c e S t a r t D e v i a t i o n   ( % ) ,    
                   ?@8G5<  A  7040==K<  2@5<5=5<  687=8  U _ P e n d i n g E x p i r a t i o n   8  157  AB>?>2 
       5 .   ?>A;5  B>3>  :0:  >@45@  A@01>B0;  8  ?5@5H5;  2  >B:@KBCN  ?>7C,   2KAB02;O5B  >G5@54=>9  >B;>65==K9  >@45@  ?>  F5=5 
                     >B;8G0NI59AO  >B  F5=K  >B:@KB8O  ?@54K4CI53>  >@45@0  =0  U _ P r i c e S t a r t D e v i a t i o n   C<=>65==K9  =0  U _ N e x t D e v i a t i o n F a c t o r   s t e p   @07.   ( 2@5<O  687=8  =5  C:07K20BL) .  
                     5A;8  ?>  :0:8<  B>  ?@8G8=0<  F5=0  CH;0  40;5:>  8  =52>7<>6=>  2KAB028BL  >@45@  A  B0:>9  F5=>9,   B>  F5=C  A@010BK20=8O  >?@545;O5<  B0:  65  :0:  2  4 ?.  
                   A  ;>B><  @02=K<  ?@54K4CI89  H03  l o t _ s i z e * U _ L o t F a c t o r .              
                   5A;8  ?@54K4CI89  H03  4>AB83  I _ D i s t ,   B>  =8G53>  =5  >B:@K205<  1>;LH5.  
       6 .   5A;8  B5:CI89  AC<0@=K9  ?@>D8B  ?>  2A5<  >B:@KBK<  ?>70<  ?@52KA8;    U _ T r a l i n g S t o p T r i g g e r P r o f i t   ( 2  20;NB5  AG5B0) .  
                   0:B828@C5<  t r a l i g   s t o p   ( 157C1KB>:)   0  2KAB02;5==K9  B5:CI89  >@45@  C40;O5<  ( 5A;8  B0:>9  5ABL) .  
                   2KAB02;O5<  AB>?K  2A5<  >B:@KBK<  ?>70<  =0  C@>2=5  U _ T r a l i n g S t o p S i z e ( % )   >B  B5:CI59  F5=K.  
       7 .   40;55  645<  ?>:0  2A5  >B:@KBK5  ?>7K  =5  70:@>NBAO  ?>  AB>?0<,   ?>A;5  G53>  ?>4AG8BK205<  ( >1=>2;O5<)   @57C;LB0BK/ A>AB>O=85                                                     
       8 .   A1@0AK205<  ?@><56CB>G=85  ?0@0<5B@K  2  8AE>4=>5  A>AB>O=85  8  2K?>;=8BL  ?. 4  
                                  
 * /  
  
  
 # i n c l u d e   < m y l i b / e x b a s e / e x t r a d e a b s t r a c t . m q h >  
 # i n c l u d e   < m y l i b / t r a d e / l t r a i l i n g o b j . m q h >  
  
  
 i n p u t   i n t   I _ D i s t   =   6 ;   / / G a m e   d i s t  
 i n p u t   d o u b l e   U _ S t a r t L o t   =   0 . 1 ;   / / S t a r t   l o t  
 i n p u t   d o u b l e   U _ L o t F a c t o r   =   1 . 4 ;   / / N e x t   l o t   f a c t o r  
 i n p u t   d o u b l e   U _ P r i c e S t a r t D e v i a t i o n   =   2 . 5 ;   / / S t a r t   p r i c e   d e v i a t i o n ,   %  
 i n p u t   i n t   U _ P e n d i n g E x p i r a t i o n   =   4 ;   / / O r d e r   e x p i r a t i o n ,   h o u r s  
 i n p u t   d o u b l e   U _ N e x t D e v i a t i o n F a c t o r   =   2 . 2 ;   / / S t e p   d e v i a t i o n   f a c t o r  
 i n p u t   d o u b l e   U _ T r a l i n g S t o p T r i g g e r P r o f i t   =   6 0 ;   / /   A c t i v a t e   t r a i l i n g   s t o p   w h e n   p r o f i t ,   c e n t  
 i n p u t   d o u b l e   U _ T r a l i n g S t o p S i z e   =   5 . 5 ;   / /   T r a i l i n g   s t o p   d e v i a t i o n   f r o m   c u r r e n t   p r i c e ,   %  
 i n p u t   i n t   U _ T r a i l i n g N u m b e r M a x   =   3 ;   / /   M o v e   S L   c o u n t   d u r i n g   t r a i l i n g   w o r k   f o r   o n e   c y c l e  
  
 / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /  
  
        
 / / =01>@  ?0@0<5B@>2  A>AB>O=8O   
 / /   1 .   B8:5B  >B;>65==>3>  >@45@0 
 / /   2 .   =01>@  B5:CI8E  >B:@KBKE  ?>7  ( B8:5B>2)   -   L I n t L i s t  
 / /   3 .   <0:A8<0;L=K9  H03  >B:@KB>9  ?>7K  70  2A5  2@5<O  @01>BK  A>25B=8:0 
 / /   4 .   AC<0@=K9  ;>B  2A5E  >B:@KBKE  ?>7    70  2A5  2@5<O  @01>BK  A>25B=8:0 
 / /   5 .   8B>3>2K9  p n l       70  2A5  2@5<O  @01>BK  A>25B=8:0  ( 157  CG5B0  A2>?>2  8  :><8AA89)  
 / /   6 .   AC<<0@=K5  :><8AA88  8  A2>?K  70  2A5  2@5<O  @01>BK  A>25B=8:0 
 / /   7 .   AB0@B>20O  F5=0  >B:@KB8O  =0  1 - <  H035 
 / /   8 .   ?@87=0:  0:B820F88  B@0;8=30  ( t r u e / f a l s e )  
 c l a s s   E x C o u p l e S t a t e S p r i n g   :   p u b l i c   E x C o u p l e S t a t e B a s e  
 {  
 p u b l i c :  
       E x C o u p l e S t a t e S p r i n g ( s t r i n g   v )   : E x C o u p l e S t a t e B a s e ( v )   { }  
       v i r t u a l   ~ E x C o u p l e S t a t e S p r i n g ( )   { }  
      
       / /   f r o m   p a r e n t   c l a s s ,   a b s t r a c t   f u n c s  
       v o i d   i n i t V a l u e s ( ) ;    
       v o i d   l o a d ( c o n s t   L S t r i n g L i s t   & s t a t e _ d a t a ,   s t r i n g   & e r r ) ;  
       v o i d   s a v e ( L S t r i n g L i s t   & s t a t e _ d a t a ) ;    
       u i n t   s t a t e B l o c k S i z e ( )   c o n s t   { r e t u r n   8 ; }    
       s t r i n g   t o S t r ( )   c o n s t ;   / / d i a g   f u n c  
  
       / / m o n i t   f u n c s  
       d o u b l e   c u r P r o f i t ( ) ;   / / B5:CI89  AC<<0@=K9  ?@>D8B  ?>  2A5<  >B:@KBK<  ?>70<  ( <>65B  1KBL  >B@8F0B5;L=K9)  
       v o i d   p e n d i n g T o P o s ( ) ;   / / >B;>65==K9  >@45@  ?5@5H5;  2  >B:@KBCN  ?>7C 
       v o i d   r e s e t L i n e ( ) ;   / / 2K?>;=8BL  A1@>A  ;8=88,   =0?@8<5@  ?>A;5  B>3>  :0:  2A5  ?>7K  ?5@5H;8  2  8AB>@8N 
       v o i d   u p d a t e S t a t e A f t e r F i n i s h L i n e ( ) ;   / / >1=>28BL  ?0@0<5B@K  A>AB>O=8O  ?>A;5  7025@H5=8O  @01>BK  2A5E  ?>7  ;8=88 
       v o i d   u p d a t e M a x S t e p ( ) ;  
  
       i n l i n e   i n t   c u r S t e p ( )   c o n s t   { r e t u r n   o p e n e d _ t i c k e t s . c o u n t ( ) ; }  
       i n l i n e   i n t   g e t P e n O r d e r ( )   c o n s t     { r e t u r n   i n t ( m _ v a l u e s . v a l u e ( e x s p P e n d i n g O r d e r ) ) ; }  
       i n l i n e   b o o l   n e e d P e n d i n g ( )   c o n s t   { r e t u r n   ( g e t P e n O r d e r ( ) < =   0 ) ; }  
       i n l i n e   b o o l   d i s t O v e r ( )   c o n s t   { r e t u r n   ( c u r S t e p ( )   > =   I _ D i s t ) ; }  
       i n l i n e   b o o l   i s B e g i n S t a t e ( )   c o n s t   { r e t u r n   ( c u r S t e p ( )   = =   0   & &   n e e d P e n d i n g ( ) ) ; }   / / A8BC0F8O  :>340  =8G53>  =5  >B:@KB>  ( AB0@B>2>5  A>AB>O=85)  
       i n l i n e   v o i d   s e t S t a r t P r i c e ( d o u b l e   p )   { u p d a t e V a l u e ( e x i p S t a r t P r i c e ,   p ) ; }  
       i n l i n e   d o u b l e   s t a r t L i n e P r i c e ( )   c o n s t   { r e t u r n   m _ v a l u e s . v a l u e ( e x i p S t a r t P r i c e ) ; }  
       i n l i n e   v o i d   t r a i l i n g O n ( )   { t r a i l i n g _ a c t i v e   =   t r u e ; }  
       i n l i n e   b o o l   i s T r a i l i n g A c t i v a t e d ( )   c o n s t   { r e t u r n   t r a i l i n g _ a c t i v e ; }  
       i n l i n e   i n t   o p e n e d P o s A t ( i n t   i )   c o n s t   { r e t u r n   ( i < 0   | |   i > = c u r S t e p ( ) )   ?   - 1   :   o p e n e d _ t i c k e t s . a t ( i ) ; }  
  
 p r o t e c t e d :  
       L I n t L i s t   o p e n e d _ t i c k e t s ;   / / :>=B59=5@  4;O  B8:5B>2  B5:CI8E  >B:@KBKE  ?>7 
       b o o l   t r a i l i n g _ a c t i v e ;   / / ?@87=0:  B>3>  GB>  0:B828@>20=  B@0;8=3  4;O  2A5E  >B:@KBKE  ?>7,   B. 5.   ;8=8O  2>H;0  2  157C1KB>:  8  <K  645<  ?@>AB>  ?>:0  2A5  ?>7K  A@01>B0NB  ?>  AB>?0< 
  
 } ;  
 v o i d   E x C o u p l e S t a t e S p r i n g : : p e n d i n g T o P o s ( )  
 {  
       o p e n e d _ t i c k e t s . a p p e n d ( g e t P e n O r d e r ( ) ) ;  
       u p d a t e V a l u e ( e x s p P e n d i n g O r d e r ,   - 1 ) ;  
       u p d a t e M a x S t e p ( ) ;  
 }  
 s t r i n g   E x C o u p l e S t a t e S p r i n g : : t o S t r ( )   c o n s t  
 {  
       s t r i n g   s   =   E x C o u p l e S t a t e B a s e : : t o S t r ( ) ;  
       s   + =   S t r i n g C o n c a t e n a t e ( "   P E N _ T I C K E T = " ,   D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p P e n d i n g O r d e r ) ,   0 ) ) ;  
       s   + =   S t r i n g C o n c a t e n a t e ( "   O P E N E D [ " ,   o p e n e d _ t i c k e t s . t o S t r L i n e ( ) ,   " ] " ) ;  
       s   + =   S t r i n g C o n c a t e n a t e ( "   S T A R T _ P R I C E = " ,   D o u b l e T o S t r ( s t a r t L i n e P r i c e ( ) ,   4 ) ) ;  
       r e t u r n   s ;  
 }  
 v o i d   E x C o u p l e S t a t e S p r i n g : : u p d a t e M a x S t e p ( )  
 {  
       i n t   m a x   =   i n t ( m _ v a l u e s . v a l u e ( e x s p M a x S t e p ) ) ;  
       i f   ( c u r S t e p ( )   >   m a x )   u p d a t e V a l u e ( e x s p M a x S t e p ,   c u r S t e p ( ) ) ;  
 }  
 d o u b l e   E x C o u p l e S t a t e S p r i n g : : c u r P r o f i t ( )  
 {  
       m _ l a s t E r r   =   " " ;  
       d o u b l e   s   =   0 ;  
       i f   ( o p e n e d _ t i c k e t s . i s E m p t y ( ) )   r e t u r n   s ;  
        
       i n t   n   =   o p e n e d _ t i c k e t s . c o u n t ( ) ;        
       f o r   ( i n t   i = 0 ;   i < n ;   i + + )  
       {  
             i n t   t   =   o p e n e d _ t i c k e t s . a t ( i ) ;  
             L C h e c k O r d e r I n f o   i n f o ( t ) ;  
             L S t a t i c T r a d e : : c h e c k O r d e r S t a t e ( i n f o ) ;        
             i f   ( i n f o . i s E r r o r ( ) )    
             {                    
                   m _ l a s t E r r   =   S t r i n g C o n c a t e n a t e ( " E x C o u p l e S t a t e S p r i n g :   [ " ,   i n s t r u m e n t N a m e ( ) ,   " ]   o c c u r e d   e r r o r ( " ,   i n f o . e r r _ c o d e , " )   b y   c h e c k i n g   p o s ,   t i k e t = " ,   t ) ;  
                   P r i n t ( " W A R N I N G :   " ,   l a s t E r r ( ) ) ;    
                   c o n t i n u e ;  
             }  
             i f   ( ! i n f o . i s O p e n e d ( ) )    
             {  
                   s t r i n g   s _ e r r   =   S t r i n g C o n c a t e n a t e ( " E x C o u p l e S t a t e S p r i n g :   [ " ,   i n s t r u m e n t N a m e ( ) ,   " ]   c h e c k i n g   p o s ,   t i k e t = " ,   t ,   " ,   p o s   i s   n o t   o p e n e d ,   s t a t u s = " ,   i n f o . s t a t u s ) ;  
                   P r i n t ( " W A R N I N G :   " ,   s _ e r r ) ;    
                   c o n t i n u e ;  
             }  
             s   + =   O r d e r P r o f i t ( ) ;  
       }        
       r e t u r n   s ;  
 }  
 v o i d   E x C o u p l e S t a t e S p r i n g : : u p d a t e S t a t e A f t e r F i n i s h L i n e ( )  
 {  
       m _ l a s t E r r   =   " " ;  
       i n t   n   =   o p e n e d _ t i c k e t s . c o u n t ( ) ;        
       f o r   ( i n t   i = 0 ;   i < n ;   i + + )  
       {  
             i n t   t   =   o p e n e d _ t i c k e t s . a t ( i ) ;  
             L C h e c k O r d e r I n f o   i n f o ( t ) ;  
             L S t a t i c T r a d e : : c h e c k O r d e r S t a t e ( i n f o ) ;        
             i f   ( i n f o . i s E r r o r ( ) )    
             {                    
                   m _ l a s t E r r   =   S t r i n g C o n c a t e n a t e ( " E x C o u p l e S t a t e S p r i n g :   [ " ,   i n s t r u m e n t N a m e ( ) ,   " ]   o c c u r e d   e r r o r ( " ,   i n f o . e r r _ c o d e , " )   b y   c h e c k i n g   p o s ,   t i k e t = " ,   t ) ;  
                   P r i n t ( " W A R N I N G :   " ,   l a s t E r r ( ) ) ;    
                   c o n t i n u e ;  
             }  
             i f   ( ! i n f o . i s H i s t o r y ( ) )    
             {  
                   s t r i n g   s _ e r r   =   S t r i n g C o n c a t e n a t e ( " E x C o u p l e S t a t e S p r i n g :   [ " ,   i n s t r u m e n t N a m e ( ) ,   " ]   c h e c k i n g   p o s ,   t i k e t = " ,   t ,   " ,   p o s   i s   n o t   h i s t o r y ,   s t a t u s = " ,   i n f o . s t a t u s ) ;  
                   P r i n t ( " W A R N I N G :   " ,   s _ e r r ) ;    
                   c o n t i n u e ;  
             }  
              
             d o u b l e   p n l   =   m _ v a l u e s . v a l u e ( e x s p R e s u l t S u m ) ;  
             m _ v a l u e s . i n s e r t ( e x s p R e s u l t S u m ,   p n l + i n f o . r e s u l t ) ;  
             d o u b l e   c m s   =   m _ v a l u e s . v a l u e ( e x s p C o m m i s i o n S i z e ) ;  
             m _ v a l u e s . i n s e r t ( e x s p C o m m i s i o n S i z e ,   c m s + i n f o . c o m m i s i o n + i n f o . s w a p ) ;  
             d o u b l e   l o t s   =   m _ v a l u e s . v a l u e ( e x s p L o t s S i z e ) ;  
             m _ v a l u e s . i n s e r t ( e x s p L o t s S i z e ,   l o t s + i n f o . l o t s ) ;  
       }  
 }  
 v o i d   E x C o u p l e S t a t e S p r i n g : : i n i t V a l u e s ( )  
 {  
       m _ l a s t E r r   =   " " ;  
       o p e n e d _ t i c k e t s . c l e a r ( ) ;  
       m _ v a l u e s . i n s e r t ( e x s p P e n d i n g O r d e r ,   - 1 ) ;  
       m _ v a l u e s . i n s e r t ( e x i p S t a r t P r i c e ,   - 1 ) ;   / / B@835@=0O  F5=0  A  :>B>@>9  >B:@K;AO  >B;>65==K9  >@45@  =0  1 - <  H035 
       m _ v a l u e s . i n s e r t ( e x s p M a x S t e p ,   0 ) ;  
       m _ v a l u e s . i n s e r t ( e x s p L o t s S i z e ,   0 ) ;  
       m _ v a l u e s . i n s e r t ( e x s p R e s u l t S u m ,   0 ) ;  
       m _ v a l u e s . i n s e r t ( e x s p C o m m i s i o n S i z e ,   0 ) ;        
       t r a i l i n g _ a c t i v e   =   f a l s e ;  
 } ;  
 v o i d   E x C o u p l e S t a t e S p r i n g : : r e s e t L i n e ( )  
 {  
       m _ l a s t E r r   =   " " ;  
       o p e n e d _ t i c k e t s . c l e a r ( ) ;  
       m _ v a l u e s . i n s e r t ( e x s p P e n d i n g O r d e r ,   - 1 ) ;  
       t r a i l i n g _ a c t i v e   =   f a l s e ;  
       m _ v a l u e s . i n s e r t ( e x i p S t a r t P r i c e ,   - 1 ) ;  
 }  
 v o i d   E x C o u p l e S t a t e S p r i n g : : l o a d ( c o n s t   L S t r i n g L i s t   & s t a t e _ d a t a ,   s t r i n g   & e r r )  
 {  
       i f   ( s t a t e _ d a t a . c o u n t ( )   ! =   s t a t e B l o c k S i z e ( ) )    
       {  
             e r r   =   S t r i n g C o n c a t e n a t e ( " i n v a l i d   s t a t e _ d a t a   s i z e ( " ,   s t a t e _ d a t a . c o u n t ( ) ,   " )   ! =   " ,   s t a t e B l o c k S i z e ( ) ,   " ,     i n s t r u m e n t :   " ,   m _ c o u p l e ) ;  
             r e t u r n ;  
       }  
        
       b o o l   o k ;  
       i n t   i   =   0 ;  
       s t r i n g   f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p P e n d i n g O r d e r ,   L S t r i n g W o r k e r : : t o I n t ( f l i n e ,   o k ) ) ;  
       i f   ( ! o k )   P r i n t ( " E x C o u p l e S t a t e S p r i n g : : l o a d :   i n v a l i d   c o n v e r t   P e n d i n g O r d e r   t o   I N T :   f l i n e = " ,   f l i n e ) ;  
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       l o a d T i c k e t s F r o m S t a t e L i n e ( f l i n e ,   o p e n e d _ t i c k e t s ) ;              
        
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;        
       m _ v a l u e s . i n s e r t ( e x i p S t a r t P r i c e ,   L S t r i n g W o r k e r : : t o D o u b l e ( f l i n e ,   o k ) ) ;        
       i f   ( ! o k )   P r i n t ( " E x C o u p l e S t a t e S p r i n g : : l o a d :   i n v a l i d   c o n v e r t   S t a r t P r i c e   t o   D O U B L E :   f l i n e = " ,   f l i n e ) ;  
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;              
       m _ v a l u e s . i n s e r t ( e x s p M a x S t e p ,   L S t r i n g W o r k e r : : t o I n t ( f l i n e ,   o k ) ) ;                    
       i f   ( ! o k )   P r i n t ( " E x C o u p l e S t a t e S p r i n g : : l o a d :   i n v a l i d   c o n v e r t   p M a x S t e p   t o   I N T :   f l i n e = " ,   f l i n e ) ;  
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p L o t s S i z e ,   L S t r i n g W o r k e r : : t o D o u b l e ( f l i n e ,   o k ) ) ;        
       i f   ( ! o k )   P r i n t ( " E x C o u p l e S t a t e S p r i n g : : l o a d :   i n v a l i d   c o n v e r t   L o t s S i z e   t o   D O U B L E :   f l i n e = " ,   f l i n e ) ;  
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p R e s u l t S u m ,   L S t r i n g W o r k e r : : t o D o u b l e ( f l i n e ,   o k ) ) ;  
       i f   ( ! o k )   P r i n t ( " E x C o u p l e S t a t e S p r i n g : : l o a d :   i n v a l i d   c o n v e r t   R e s u l t S u m   t o   D O U B L E :   f l i n e = " ,   f l i n e ) ;  
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p C o m m i s i o n S i z e ,   L S t r i n g W o r k e r : : t o D o u b l e ( f l i n e ,   o k ) ) ;  
       i f   ( ! o k )   P r i n t ( " E x C o u p l e S t a t e S p r i n g : : l o a d :   i n v a l i d   c o n v e r t   C o m m i s i o n S i z e   t o   D O U B L E :   f l i n e = " ,   f l i n e ) ;  
        
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       t r a i l i n g _ a c t i v e   =   ( f l i n e   = =   " t r u e " ) ;  
        
 } ;  
 v o i d   E x C o u p l e S t a t e S p r i n g : : s a v e ( L S t r i n g L i s t   & s t a t e _ d a t a )  
 {  
       s t a t e _ d a t a . c l e a r ( ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p P e n d i n g O r d e r ) ,   0 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( t i c k e t s T o S t a t e L i n e ( o p e n e d _ t i c k e t s ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x i p S t a r t P r i c e ) ,   m _ d i g i s t ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p M a x S t e p ) ,   0 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p L o t s S i z e ) ,   2 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p R e s u l t S u m ) ,   3 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p C o m m i s i o n S i z e ) ,   3 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( t r a i l i n g _ a c t i v e   ?   " t r u e "   :   " f a l s e " ) ;  
 } ;  
  
  
        
 / / / / / / / / / / / E X P E R T   C O D E / / / / / / / / / / / / / / / / / / / / / / / / /  
 c l a s s   E x S p r i n g   :   p u b l i c   L E x T r a d e A b s t r a c t  
 {  
 p u b l i c :  
       E x S p r i n g ( )   : L E x T r a d e A b s t r a c t ( )   { t _ o b j   =   n e w   L T r a i l i n g O b j ( ) ; }  
       v i r t u a l   ~ E x S p r i n g ( )   { d e l e t e   t _ o b j ;   t _ o b j = N U L L ; }  
        
 p r o t e c t e d :        
       L T r a i l i n g O b j   * t _ o b j ;  
  
       / / p a r e n t   v i r t u a l   f u n c s  
       v i r t u a l   s t r i n g   n a m e ( )   c o n s t   { r e t u r n   " s p r i n g " ; }   / / 8<O  A>25B=8:0       
       v i r t u a l   v o i d   w o r k ( ) ;   / / 2K?>;=8BL  AF5=0@89  0;3>@8B<0  :>=:@5B=>9  AB@0B5388  ( >A=>2=0O  DC=:F8O)  
       v i r t u a l   v o i d   l o a d I n p u t P a r a m s ( ) ;   / / 703@C78BL  2E>4=K5  ?0@0<5B@K  A>25B=8:0       
       v i r t u a l   v o i d   i n i t S t a t e C o n t a i n e r ( ) ;   / / 8=8F80;878@>20BL  >1J5:B  m _ s t a t e C o n t a i n e r ,   f r o m   p a r e n t  
       v i r t u a l   v o i d   a c t i o n A f t e r L o a d ( ) ;   / / ?@8  =5>1E>48<>ABL  2K?>;=8BL  =5:>B>@K5  459AB28O  ?>A;5  703@C7:8  D09;0- A>AB>O=8O 
  
       / / t h i s   t r a t e g y   t r a d e   f u n c s   b y   c u r r e n t _ i n d e x   i n s t r u m e n t  
       v o i d   d o N e x t ( E x C o u p l e S t a t e S p r i n g * ) ;   / / ?@>25@8BL  8  2K?>;=8BL  A;54CNI55  459AB285  ?>  C:070==><C  8=AB@C<5=BC  A>3;0A=>  AB@0B5388 
       v o i d   t r y P e n d i n g ( E x C o u p l e S t a t e S p r i n g * ,   b o o l   w i t h _ e x p i r a t i o n ) ;   / / 2KAB028BL  >B;>65==K9  >@45@  4;O  B5:CI53>  8=AB@C<5=B0       
       v o i d   c h e c k P e n d i n g S t a t u s ( E x C o u p l e S t a t e S p r i n g * ) ;   / / ?@>25@8BL  =0  ?@54<5B  B>3>  GB>  >B;>65==K9  >@45@  ?5@5H5;  2  >B:@KBCN  ?>7C,   B>340  =5>1E>48<>  >1=>28BL  ?>;O  A>>B25BAB2CNI53>  >1J5:B0  A>AB>O=8O 
       v o i d   c h e c k C u r r e n t P r o f i t ( E x C o u p l e S t a t e S p r i n g * ) ;   / /   ?@>25@8BL  @07<5@  B5:CI53>  ?@>D8B  8  ?@8  =5>1E>48<>AB8  0:B828@>20BL  @568<  B@0;8=30  ( 157C1KB:0)  
       v o i d   a c t i v a t e T r a i l i n g ( E x C o u p l e S t a t e S p r i n g * ) ;   / / a c t i v a t e   t r a l i n g   m o d e  
       v o i d   c h e c k T r a l i n g S t a t u s ( E x C o u p l e S t a t e S p r i n g * ) ;   / / ?>7K  =0E>4OBAO  2  A>AB>O=88  157C1KB:0  8  =5>1E>48<>  ?@>AB>  ?@>25@OBL  A>AB>O=85  B@0;8=30 
       v o i d   r e m o v e P e n d i n g ( E x C o u p l e S t a t e S p r i n g * ) ;   / / C40;8BL  >B;>65==K9  >@45@  4;O  B5:CI53>  8=AB@C<5=B0       
        
 p r i v a t e :  
       i n t   p e n T r a d e T y p e ( )   c o n s t ;            
       d o u b l e   n e x t S t e p L o t ( c o n s t   E x C o u p l e S t a t e S p r i n g * )   c o n s t ;  
       d o u b l e   n e x t S t e p T r i g g e r P r i c e ( c o n s t   E x C o u p l e S t a t e S p r i n g * )   c o n s t ;              
              
 } ;  
 i n t   E x S p r i n g : : p e n T r a d e T y p e ( )   c o n s t  
 {  
       i f   ( i n t ( m _ i n p u t P a r a m s . v a l u e ( e x i p T r a d e T y p e ) )   = =   i p M T I _ O n l y S e l l )   r e t u r n   O P _ S E L L L I M I T ;  
       r e t u r n   O P _ B U Y L I M I T ;  
 }  
 d o u b l e   E x S p r i n g : : n e x t S t e p L o t ( c o n s t   E x C o u p l e S t a t e S p r i n g   * c s )   c o n s t  
 {  
       d o u b l e   l o t   =   m _ i n p u t P a r a m s . v a l u e ( e x i p S t a r t L o t ) ;  
       i f   ( ! c s . i s B e g i n S t a t e ( ) )  
       {  
             i n t   s t e p   =   c s . c u r S t e p ( ) ;  
             f o r   ( i n t   i = 0 ;   i < s t e p ;   i + + )  
                   l o t   * =   m _ i n p u t P a r a m s . v a l u e ( e x i p N e x t B e t F a c t o r ) ;        
       }        
       r e t u r n   N o r m a l i z e D o u b l e ( l o t ,   2 ) ;      
 }  
 d o u b l e   E x S p r i n g : : n e x t S t e p T r i g g e r P r i c e ( c o n s t   E x C o u p l e S t a t e S p r i n g   * c s )   c o n s t  
 {  
       i n t   s i g n   =   ( ( p e n T r a d e T y p e ( )   = =   O P _ B U Y L I M I T )   ?   1   :   - 1 ) ;  
       d o u b l e   s t a r t _ d e v   =   m _ i n p u t P a r a m s . v a l u e ( e x i p D e v i a t i o n ) ;  
       d o u b l e   c p   =   M a r k e t I n f o ( c s . i n s t r u m e n t N a m e ( ) ,   ( s i g n   >   0 )   ?   M O D E _ A S K   :   M O D E _ B I D ) ;  
        
       d o u b l e   t _ p r i c e   =   - 1 ;  
       i f   ( c s . i s B e g i n S t a t e ( ) )  
       {  
             L P r i c e P a i r   l p p ( c s . i n s t r u m e n t N a m e ( ) ,   c p ) ;  
             l p p . a d d P r i c e D e v i a t i o n ( - 1 * s i g n * s t a r t _ d e v ) ;  
             t _ p r i c e   =   l p p . p 2 ;              
       }  
       e l s e  
       {  
             t _ p r i c e   =   c s . s t a r t L i n e P r i c e ( ) ;  
             i n t   s t e p   =   c s . c u r S t e p ( ) ;  
             f o r   ( i n t   i = 0 ;   i < s t e p ;   i + + )  
             {  
                   d o u b l e   d e v   =   s t a r t _ d e v * M a t h P o w ( U _ N e x t D e v i a t i o n F a c t o r ,   i + 1 ) ;  
                   L P r i c e P a i r   l p p ( c s . i n s t r u m e n t N a m e ( ) ,   t _ p r i c e ) ;  
                   l p p . a d d P r i c e D e v i a t i o n ( - 1 * s i g n * d e v ) ;  
                   t _ p r i c e   =   l p p . p 2 ;              
             }  
              
             i f   ( ( s i g n   >   0   & &   t _ p r i c e   > =   c p )   | |   ( s i g n   <   0   & &   t _ p r i c e   < =   c p ) )        
             {  
                   L P r i c e P a i r   l p p ( c s . i n s t r u m e n t N a m e ( ) ,   c p ) ;  
                   l p p . a d d P r i c e D e v i a t i o n ( - 1 * s i g n * s t a r t _ d e v ) ;  
                   t _ p r i c e   =   l p p . p 2 ;                          
             }  
       }        
       r e t u r n   N o r m a l i z e D o u b l e ( t _ p r i c e ,   c s . d i g i s t ( ) ) ;      
 }  
 v o i d   E x S p r i n g : : i n i t S t a t e C o n t a i n e r ( )  
 {  
       i n t   n   =   m _ t i c k e r s . c o u n t ( ) ;  
       f o r   ( i n t   i = 0 ;   i < m _ t i c k e r s . c o u n t ( ) ;   i + + )  
       {  
             E x C o u p l e S t a t e S p r i n g   * c s   =   n e w   E x C o u p l e S t a t e S p r i n g ( m _ t i c k e r s . a t ( i ) ) ;  
             c s . i n i t V a l u e s ( ) ;  
             m _ s t a t e C o n t a i n e r . a d d C o u p l e S t a t e O b j ( c s ) ;  
       }  
 }  
 v o i d   E x S p r i n g : : a c t i o n A f t e r L o a d ( )  
 {  
       i n t   n   =   m _ t i c k e r s . c o u n t ( ) ;  
       f o r   ( i n t   i = 0 ;   i < m _ t i c k e r s . c o u n t ( ) ;   i + + )  
       {  
             E x C o u p l e S t a t e S p r i n g   * c s   =   n e w   E x C o u p l e S t a t e S p r i n g ( m _ t i c k e r s . a t ( i ) ) ;  
             i f   ( c s . i s T r a i l i n g A c t i v a t e d ( ) )   a c t i v a t e T r a i l i n g ( c s ) ;  
       }  
 }  
 v o i d   E x S p r i n g : : w o r k ( )  
 {  
       L E x T r a d e A b s t r a c t : : w o r k ( ) ;  
       P r i n t ( S t r i n g C o n c a t e n a t e ( L S t r i n g W o r k e r : : s y m b o l S t r i n g ( ' - ' ,   2 0 ) ,   m _ t i c k e r s . a t ( t i c k e r _ i n d e x ) ,   L S t r i n g W o r k e r : : s y m b o l S t r i n g ( ' - ' ,   2 0 ) ) ) ;  
              
       E x C o u p l e S t a t e S p r i n g   * c s   =   m _ s t a t e C o n t a i n e r . c o u p l e S t a t e A t V a r ( t i c k e r _ i n d e x ) ;  
       i f   ( ! c s )   r e t u r n ;      
    
       P r i n t ( " S T A R T _ W O R K :     c u r _ s t e p = " ,   c s . c u r S t e p ( ) ,   "     p e n _ o r d e r = " ,   c s . g e t P e n O r d e r ( ) ) ;  
                
       i f   ( c s . d i s t O v e r ( ) )   P r i n t ( "     c u r _ s t e p = " ,   c s . c u r S t e p ( ) ,   "     I S _ O V E R " ) ;   / / >B:@KB0  ?>70  =0  <0:A8<0;L=><  H035,   =8G53>  =5  45;05< 
       e l s e   d o N e x t ( c s ) ;  
 }  
 v o i d   E x S p r i n g : : d o N e x t ( E x C o u p l e S t a t e S p r i n g   * c s )  
 {        
       i f   ( c s . i s B e g i n S t a t e ( ) )   { t r y P e n d i n g ( c s ,   t r u e ) ;   r e t u r n ; }  
       i f   ( c s . i s T r a i l i n g A c t i v a t e d ( ) )   { c h e c k T r a l i n g S t a t u s ( c s ) ;   r e t u r n ; }  
              
       / / c h e c k   l i n e   s t a t e  
       c h e c k P e n d i n g S t a t u s ( c s ) ;  
       i f   ( c s . i s B e g i n S t a t e ( ) )   r e t u r n ;  
        
       c h e c k C u r r e n t P r o f i t ( c s ) ;  
       i f   ( c s . h a s E r r ( ) )   r e t u r n ;        
        
       i f   ( c s . n e e d P e n d i n g ( )   & &   ! c s . i s T r a i l i n g A c t i v a t e d ( ) )    
                 t r y P e n d i n g ( c s ,   f a l s e ) ;              
 }  
 v o i d   E x S p r i n g : : c h e c k C u r r e n t P r o f i t ( E x C o u p l e S t a t e S p r i n g   * c s )  
 {  
       i f   ( c s . i s T r a i l i n g A c t i v a t e d ( ) )   r e t u r n ;  
       i f   ( c s . c u r S t e p ( )   = =   0 )   r e t u r n ;  
        
       d o u b l e   c u r _ p   =   c s . c u r P r o f i t ( ) ;  
       i f   ( c s . h a s E r r ( ) )   { a d d E r r ( e t F i n d O r d e r ,   c s . l a s t E r r ( ) ) ;   r e t u r n ; }  
        
       P r i n t ( " c u r   p r o f i t = " ,   D o u b l e T o S t r ( c u r _ p ,   4 ) ,   " ,       s t e p = " ,   c s . c u r S t e p ( ) ,   " ,     s t a r t _ p r i c e = " ,   D o u b l e T o S t r ( c s . s t a r t L i n e P r i c e ( ) ,   4 ) ) ;  
       i f   ( c u r _ p   >   U _ T r a l i n g S t o p T r i g g e r P r o f i t )  
       {  
             P r i n t ( " c u r   p r o f i t   >   U _ T r a l i n g S t o p T r i g g e r P r o f i t ,   N E E D   A C T I V A T E   T R A L I N G _ M O D E " ) ;  
             a c t i v a t e T r a i l i n g ( c s ) ;  
       }  
       e l s e  
       {  
             P r i n t ( " c u r   p r o f i t   n o t   e n o u g h   f o r   s t a r t   t r a i l i n g   m o d e " ) ;  
       }        
 }  
 v o i d   E x S p r i n g : : a c t i v a t e T r a i l i n g ( E x C o u p l e S t a t e S p r i n g   * c s )  
 {  
       c s . t r a i l i n g O n ( ) ;  
       i n t   n   =   c s . c u r S t e p ( ) ;  
       f o r   ( i n t   i = 0 ;   i < n ;   i + + )  
             t _ o b j . a d d T r a c k P o s ( c s . o p e n e d P o s A t ( i ) ,   U _ T r a l i n g S t o p S i z e ) ;  
 }  
 v o i d   E x S p r i n g : : c h e c k T r a l i n g S t a t u s ( E x C o u p l e S t a t e S p r i n g   * c s )  
 {  
       P r i n t ( " c h e c k T r a l i n g S t a t u s   f o r   " ,   c s . i n s t r u m e n t N a m e ( ) ,   "     t r a c k i n g   p o s i t i o n s :   " ,   t _ o b j . c o u n t ( ) ) ;  
       i f   ( c s . n e e d P e n d i n g ( ) )   { r e m o v e P e n d i n g ( c s ) ;   r e t u r n ; }  
        
       i f   ( t _ o b j . i s E m p t y ( ) )   / / w i n ,   a l l   p o s   i n   g o n e   t o   h i s t o r y  
       {  
             c s . u p d a t e S t a t e A f t e r F i n i s h L i n e ( ) ;  
             i f   ( c s . h a s E r r ( ) )   a d d E r r ( e t F i n d O r d e r ,   c s . l a s t E r r ( ) ) ;  
             e l s e   c s . r e s e t L i n e ( ) ;        
       }  
       e l s e   t _ o b j . t r y T r a i l i n g ( ) ;  
 }  
 v o i d   E x S p r i n g : : c h e c k P e n d i n g S t a t u s ( E x C o u p l e S t a t e S p r i n g   * c s )  
 {  
       i f   ( c s . n e e d P e n d i n g ( ) )   r e t u r n ;  
        
       P r i n t ( " t r y   c h e c k P e n d i n g S t a t u s . . . " ) ;  
       i n t   t   =   c s . g e t P e n O r d e r ( ) ;  
       L C h e c k O r d e r I n f o   i n f o ( t ) ;  
       L S t a t i c T r a d e : : c h e c k O r d e r S t a t e ( i n f o ) ;  
       i f   ( i n f o . i s E r r o r ( ) )  
       {  
             s t r i n g   s   =   S t r i n g C o n c a t e n a t e ( " E r r o r   c h e k i n g   o r d e r :   " ,   t ,   " e r r _ c o d e = " ,   i n f o . e r r _ c o d e ) ;  
             P r i n t ( s ) ;  
             a d d E r r ( e t F i n d O r d e r ,   s ) ;  
             r e t u r n ;  
       }  
        
       i f   ( i n f o . i s O p e n e d ( ) )    
       {  
             P r i n t ( c s . i n s t r u m e n t N a m e ( ) , " :     T h e   o r d e r   " , t , "   b e c a m e   o p e n   p o s ! " ) ;  
             c s . p e n d i n g T o P o s ( ) ;  
       }  
       e l s e   i f   ( i n f o . i s P e n g i n g C a n c e l l e d ( ) )  
       {  
             P r i n t ( c s . i n s t r u m e n t N a m e ( ) , " :     T h e   o r d e r   " , t , "   w a s   c a n c e l e d ! " ) ;  
             c s . u p d a t e V a l u e ( e x s p P e n d i n g O r d e r ,   - 1 ) ;  
             i f   ( c s . c u r S t e p ( )   = =   0 )   c s . s e t S t a r t P r i c e ( - 1 ) ;  
       }  
       / / e l s e   P r i n t ( i n f o . t o S t r ( ) ) ;  
 }  
 v o i d   E x S p r i n g : : t r y P e n d i n g ( E x C o u p l e S t a t e S p r i n g   * c s ,   b o o l   w i t h _ e x p i r a t i o n )  
 {  
       L O p e n P e n d i n g O r d e r P a r a m s   p a r a m s ( c s . i n s t r u m e n t N a m e ( ) ,   p e n T r a d e T y p e ( ) ) ;  
       p a r a m s . t r i g g e r _ p r i c e   =   n e x t S t e p T r i g g e r P r i c e ( c s ) ;  
       p a r a m s . l o t s   =   n e x t S t e p L o t ( c s ) ;  
       i f   ( w i t h _ e x p i r a t i o n )    
             p a r a m s . d _ e x p i r a t i o n   =   i n t ( m _ i n p u t P a r a m s . v a l u e ( e x i p E x p i r a t i o n ) ) * 6 0 ;              
       p a r a m s . c o m m e n t = S t r i n g C o n c a t e n a t e ( f u l l N a m e ( ) , "   s t e p = " , I n t e g e r T o S t r i n g ( c s . c u r S t e p ( ) + 1 ) ) ;  
              
       P r i n t ( " t r y   s e t   p e n d i n g   o r d e r ,   I N F O   -   " ,   p a r a m s . t o S t r ( ) ) ;  
       L S t a t i c T r a d e : : s e t P e n d i n g O r d e r ( p a r a m s ) ;  
       i f   ( p a r a m s . i s E r r o r ( ) )  
       {  
             a d d E r r ( e t O p e n O r d e r ,   S t r i n g C o n c a t e n a t e ( " e r r _ c o d e = " ,   p a r a m s . e r r _ c o d e ) ) ;              
       }  
       e l s e    
       {  
             c s . u p d a t e V a l u e ( e x s p P e n d i n g O r d e r ,   p a r a m s . t i c k e t ) ;  
             i f   ( w i t h _ e x p i r a t i o n )   c s . s e t S t a r t P r i c e ( p a r a m s . t r i g g e r _ p r i c e ) ;  
             P r i n t ( " R E S U L T _ O K   -   " ,   p a r a m s . t o S t r ( ) ) ;  
       }  
 }  
 v o i d   E x S p r i n g : : r e m o v e P e n d i n g ( E x C o u p l e S t a t e S p r i n g   * c s )  
 {  
       L C l o s e O r d e r P a r a m s   p a r a m s ( c s . g e t P e n O r d e r ( ) ) ;  
       L S t a t i c T r a d e : : d e l e t e P e n d i n g O r d e r ( p a r a m s ) ;  
       i f   ( p a r a m s . i s E r r o r ( ) )  
       {        
             s t r i n g   s   =   S t r i n g C o n c a t e n a t e ( " E r r o r   d e l e t e   p e n d i n g   o r d e r :   " ,   c s . g e t P e n O r d e r ( ) ,   " e r r _ c o d e = " ,   p a r a m s . e r r _ c o d e ) ;  
             P r i n t ( s ) ;  
             a d d E r r ( e t D e l e t e N e x t O r d e r ,   s ) ;  
       }  
       e l s e   c s . u p d a t e V a l u e ( e x s p P e n d i n g O r d e r ,   - 1 ) ;        
 }  
 v o i d   E x S p r i n g : : l o a d I n p u t P a r a m s ( )  
 {  
       L E x T r a d e A b s t r a c t : : l o a d I n p u t P a r a m s ( ) ;  
       i f   ( i n v a l i d ( ) )   r e t u r n ;        
        
       m _ i n p u t P a r a m s . i n s e r t ( e x i p D i s t ,   I _ D i s t ) ;  
       m _ i n p u t P a r a m s . i n s e r t ( e x i p S t a r t L o t ,   U _ S t a r t L o t ) ;  
       m _ i n p u t P a r a m s . i n s e r t ( e x i p N e x t B e t F a c t o r ,   U _ L o t F a c t o r ) ;  
       m _ i n p u t P a r a m s . i n s e r t ( e x i p D e v i a t i o n ,   U _ P r i c e S t a r t D e v i a t i o n ) ;  
       m _ i n p u t P a r a m s . i n s e r t ( e x i p E x p i r a t i o n ,   U _ P e n d i n g E x p i r a t i o n ) ;              
        
       t _ o b j . s e t T r a i l M a x ( U _ T r a i l i n g N u m b e r M a x ) ;  
 }  
  
 / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /  
  
  
 / /   e x   v a r s  
 E x S p r i n g   * e x _ o b j   =   N U L L ;  
  
  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   E x p e r t   g l o b a l   f u n c t i o n s                                                                       |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 i n t   O n I n i t ( )  
 {        
       P r i n t ( " / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / " ) ;  
       P r i n t ( " S T A R T I N G   E X P E R T " ) ;  
  
       d e s t r o y O b j ( ) ;  
       i f   ( U _ M a i n T i m e r I n t e r v a l   <   5 )    
       {  
             P r i n t ( " E x p e r t   s t a r t e d   [ F A L E D ] :   M a i n T i m e r I n t e r v a l = " , U _ M a i n T i m e r I n t e r v a l ,   "     ( < 5 ) " ) ;        
             r e t u r n   I N I T _ F A I L E D ;  
       }  
        
       e x _ o b j   =   n e w   E x S p r i n g ( ) ;  
       e x _ o b j . e x I n i t ( ) ;  
       i f   ( e x _ o b j . i n v a l i d ( ) )  
       {  
             P r i n t ( " W A R N I N G   -   E x p e r t   i n v a l i d   o b j   s t a t e " ) ;        
             d e s t r o y O b j ( ) ;  
             r e t u r n   I N I T _ F A I L E D ;  
       }  
        
       P r i n t ( " E x p e r t   s t a r t e d   [ S U C C E S S ] " ) ;        
       E v e n t S e t T i m e r ( U _ M a i n T i m e r I n t e r v a l ) ;  
       r e t u r n ( I N I T _ S U C C E E D E D ) ;  
 }  
 v o i d   O n D e i n i t ( c o n s t   i n t   r e a s o n )  
 {  
       E v e n t K i l l T i m e r ( ) ;  
       i f   ( e x _ o b j )   e x _ o b j . e x D e i n i t ( ) ;  
       d e s t r o y O b j ( ) ;  
 }  
 v o i d   O n T i m e r ( )  
 {  
       i f   ( e x _ o b j )   e x _ o b j . m a i n E x e c ( ) ;  
 }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   d e s t r o y O b j ( )  
 {  
       i f   ( e x _ o b j )   { d e l e t e   e x _ o b j ;   e x _ o b j   =   N U L L ; }        
 }  
  
  
  
 