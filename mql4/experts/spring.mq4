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
       !" "/ 
       1 .   A>25B=8:  >B:@K205B  >@45@0  B>;L:>  2  >4=><  =0?@02;5=88,   ;81>  l o n g   ;81>  s h o r t .  
       2 .   A>25B=8:  @01>B05B  B>;L:>  ?>  C:070==K<  2>  2E>4=KE  ?0@0<5B@0E  8=AB@C<5=B0<  ( U _ T i k e r s ) .  
       3 .   A>25B=8:  @01>B05B  ?>  ?@8=F8?C  A5B:8.  
       4 .   A=0G0;0  A>25B=8:  2KAB02;O5B  >B;>65==K9  >@45@  ?>  F5=5  >B;8G0NI59AO  >B  B5:CI59  =0  U _ P r i c e S t a r t D e v i a t i o n   ( % ) ,   ?@8G5<  A  7040==K<  2@5<5=5<  687=8  U _ P e n d i n g E x p i r a t i o n  
       5 .   ?>A;5  B>3>  :0:  >@45@  A@01>B0;  8  ?5@5H5;  2  >B:@KBCN  ?>7C,   2KAB02;O5B  >G5@54=>9  >B;>65==K9  >@45@  ?>  F5=5 
                     >B;8G0NI59AO  >B  F5=K  >B:@KB8O  ?@54K4CI53>  >@45@0  =0  U _ P r i c e S t a r t D e v i a t i o n   C<=>65==K9  =0  U _ N e x t D e v i a t i o n F a c t o r   s t e p - 1   @07.   ( 2@5<O  687=8  =5  C:07K20BL) .  
                   A  ;>B><  @02=K<    ?@54K4CI89  l o t _ s i z e * U _ L o t F a c t o r .              
                   5A;8  ?@54K4CI89  H03  4>AB83  I _ D i s t ,   B>  =8G53>  =5  >B:@K205<  1>;LH5.  
       6 .   5A;8  B5:CI89  AC<0@=K9  ?@>D8B  ?>  2A5<  >B:@KBK<  ?>70<  ?@52KA8;    U _ T r a l i n g S t o p P r o f i t   ( 2  20;NB5  AG5B0)    
                   0:B828@C5<  t r a l i g   s t o p   0  2KAB02;5==K9  >@45@  C40;O5< 
       7 .   40;55  645<  ?>:0  2A5  >B:@KBK5  ?>7K  =5  70:@>NBAO  ?>  AB>?0<,   ?>A;5  G53>  ?>4AG8BK205<  ( >1=>2;O5<)   @57C;LB0BK/ A>AB>O=85                                                     
       8 .   2K?>;=8BL  ?. 4  
                      
              
 * /  
  
  
 # i n c l u d e   < m y l i b / e x b a s e / e x t r a d e a b s t r a c t . m q h >  
 / / # i n c l u d e   < m y l i b / c o m m o n / l i n p u t d i a l o g e n u m . m q h >  
  
  
 i n p u t   i n t   I _ D i s t   =   6 ;   / / G a m e   d i s t  
 i n p u t   d o u b l e   U _ S t a r t L o t   =   0 . 1 ;   / / S t a r t   l o t  
 i n p u t   d o u b l e   U _ L o t F a c t o r   =   1 . 8 ;   / / N e x t   l o t   f a c t o r  
 i n p u t   d o u b l e   U _ P r i c e S t a r t D e v i a t i o n   =   3 . 2 ;   / / S t a r t   p r i c e   d e v i a t i o n ,   %  
 i n p u t   i n t   U _ P e n d i n g E x p i r a t i o n   =   1 2 ;   / / O r d e r   e x p i r a t i o n ,   h o u r s  
 i n p u t   d o u b l e   U _ N e x t D e v i a t i o n F a c t o r   =   1 . 5 ;   / / S t e p   d e v i a t i o n   f a c t o r  
 i n p u t   d o u b l e   U _ T r a l i n g S t o p P r o f i t   =   3 0 ;   / /   A c t i v a t e   t r a l i g   s t o p   p r o f i t  
  
 / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /  
  
        
 / / =01>@  ?0@0<5B@>2  A>AB>O=8O   
 / /   1 .   B8:5B  >B;>65==>3>  >@45@0 
 / /   2 .   =01>@  B5:CI8E  >B:@KBKE  ?>7  ( B8:5B>2)   -   L I n t L i s t  
 / /   3 .   <0:A8<0;L=K9  H03  >B:@KB>9  ?>7K  70  2A5  2@5<O  @01>BK  A>25B=8:0 
 / /   4 .   AC<0@=K9  ;>B  2A5E  >B:@KBKE  ?>7    70  2A5  2@5<O  @01>BK  A>25B=8:0 
 / /   5 .   8B>3>2K9  p n l       70  2A5  2@5<O  @01>BK  A>25B=8:0 
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
        
       i n l i n e   i n t   c u r S t e p ( )   c o n s t   { r e t u r n   o p e n e d _ t i c k e t s . c o u n t ( ) ; }  
       i n l i n e   b o o l   n e e d P e n d i n g ( )   c o n s t   { r e t u r n   ( m _ v a l u e s . v a l u e ( e x s p P e n d i n g O r d e r )   < =   0 ) ; }  
       i n l i n e   b o o l   d i s t O v e r ( )   c o n s t   { r e t u r n   ( c u r S t e p ( )   > =   I _ D i s t ) ; }  
  
 p r o t e c t e d :  
       L I n t L i s t   o p e n e d _ t i c k e t s ;  
  
 } ;  
 v o i d   E x C o u p l e S t a t e S p r i n g : : i n i t V a l u e s ( )  
 {  
       o p e n e d _ t i c k e t s . c l e a r ( ) ;  
       m _ v a l u e s . i n s e r t ( e x s p P e n d i n g O r d e r ,   - 1 ) ;  
       m _ v a l u e s . i n s e r t ( e x s p M a x S t e p ,   0 ) ;  
       m _ v a l u e s . i n s e r t ( e x s p L o t s S i z e ,   0 ) ;  
       m _ v a l u e s . i n s e r t ( e x s p R e s u l t S u m ,   0 ) ;                    
 } ;  
 v o i d   E x C o u p l e S t a t e S p r i n g : : l o a d ( c o n s t   L S t r i n g L i s t   & s t a t e _ d a t a ,   s t r i n g   & e r r )  
 {  
       i f   ( s t a t e _ d a t a . c o u n t ( )   ! =   5 )    
       {  
             e r r   =   S t r i n g C o n c a t e n a t e ( " i n v a l i d   s t a t e _ d a t a   s i z e ( " ,   s t a t e _ d a t a . c o u n t ( ) ,   " )   ! =   5 ,     i n s t r u m e n t :   " ,   m _ c o u p l e ) ;  
             r e t u r n ;  
       }  
        
       i n t   i   =   0 ;  
       s t r i n g   f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p P e n d i n g O r d e r ,   S t r T o I n t e g e r ( f l i n e ) ) ;  
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       l o a d T i c k e t s F r o m S t a t e L i n e ( f l i n e ,   o p e n e d _ t i c k e t s ) ;        
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p M a x S t e p ,   S t r T o I n t e g e r ( f l i n e ) ) ;                    
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p L o t s S i z e ,   S t r T o D o u b l e ( f l i n e ) ) ;        
       f l i n e   =   s t a t e _ d a t a . a t ( i ) ;   i + + ;  
       m _ v a l u e s . i n s e r t ( e x s p R e s u l t S u m ,   S t r T o D o u b l e ( f l i n e ) ) ;  
 } ;  
 v o i d   E x C o u p l e S t a t e S p r i n g : : s a v e ( L S t r i n g L i s t   & s t a t e _ d a t a )  
 {  
       s t a t e _ d a t a . c l e a r ( ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p P e n d i n g O r d e r ) ,   0 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( t i c k e t s T o S t a t e L i n e ( o p e n e d _ t i c k e t s ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p M a x S t e p ) ,   0 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p L o t s S i z e ) ,   2 ) ) ;  
       s t a t e _ d a t a . a p p e n d ( D o u b l e T o S t r ( m _ v a l u e s . v a l u e ( e x s p R e s u l t S u m ) ,   3 ) ) ;  
 } ;  
  
  
        
 / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /  
 c l a s s   E x S p r i n g   :   p u b l i c   L E x T r a d e A b s t r a c t  
 {  
 p u b l i c :  
       E x S p r i n g ( )   : L E x T r a d e A b s t r a c t ( )   { }  
        
 p r o t e c t e d :        
       / / p a r e n t   f u n c s  
       v i r t u a l   s t r i n g   n a m e ( )   c o n s t   { r e t u r n   " s p r i n g " ; }   / / 8<O  A>25B=8:0       
       v i r t u a l   v o i d   w o r k ( ) ;   / / 2K?>;=8BL  AF5=0@89  0;3>@8B<0  :>=:@5B=>9  AB@0B5388  ( >A=>2=0O  DC=:F8O)  
       v i r t u a l   v o i d   l o a d I n p u t P a r a m s ( ) ;   / / 703@C78BL  2E>4=K5  ?0@0<5B@K  A>25B=8:0       
       v i r t u a l   v o i d   i n i t S t a t e C o n t a i n e r ( ) ;   / / 8=8F80;878@>20BL  >1J5:B  m _ s t a t e C o n t a i n e r ,   f r o m   p a r e n t  
        
       / / t r a d e   f u n c s  
       v o i d   t r y P e n d i n g ( c o n s t   E x C o u p l e S t a t e S p r i n g * ) ;   / / 2KAB028BL  >B;>65==K9  >@45@  4;O  B5:CI53>  8=AB@C<5=B0         
        
 p r i v a t e :  
       i n t   p e n T r a d e T y p e ( )   c o n s t ;            
              
 } ;  
 i n t   E x S p r i n g : : p e n T r a d e T y p e ( )   c o n s t  
 {  
       i f   ( i n t ( m _ i n p u t P a r a m s . v a l u e ( e x i p T r a d e T y p e ) )   = =   i p M T I _ O n l y S e l l )   r e t u r n   O P _ S E L L L I M I T ;  
       r e t u r n   O P _ B U Y L I M I T ;  
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
 v o i d   E x S p r i n g : : w o r k ( )  
 {  
       i f   ( m _ t i c k e r s . i s E m p t y ( ) )   r e t u r n ;  
        
       L E x T r a d e A b s t r a c t : : w o r k ( ) ;  
       P r i n t ( " E x S p r i n g : : w o r k ( )   c u r _ t i c k e r :   " ,   m _ t i c k e r s . a t ( t i c k e r _ i n d e x ) ) ;  
        
        
       c o n s t   E x C o u p l e S t a t e S p r i n g   * c s   =   m _ s t a t e C o n t a i n e r . c o u p l e S t a t e A t ( t i c k e r _ i n d e x ) ;  
       i f   ( ! c s )   r e t u r n ;  
              
       i f   ( c s . d i s t O v e r ( ) )   r e t u r n ;  
        
       i f   ( c s . n e e d P e n d i n g ( ) )  
       {  
             t r y P e n d i n g ( c s ) ;  
       }  
       e l s e  
       {  
              
       }        
 }  
 v o i d   E x S p r i n g : : t r y P e n d i n g ( c o n s t   E x C o u p l e S t a t e S p r i n g   * c s )  
 {  
       i n t   s t e p   =   c s . c u r S t e p ( ) ;  
       s t r i n g   v   =   c s . i n s t r u m e n t N a m e ( ) ;  
       i f   ( s t e p   = =   0 )  
       {  
             L O p e n P e n d i n g O r d e r   d a t a ;  
             d a t a . c o u p l e   =   v ;  
             d a t a . d e v _ p r i c e   =   m _ i n p u t P a r a m s . v a l u e ( e x i p D e v i a t i o n ) ;  
             d a t a . t y p e   =   p e n T r a d e T y p e ( ) ;  
             d a t a . l o t s   =   m _ i n p u t P a r a m s . v a l u e ( e x i p S t a r t L o t ) ;  
             d a t a . c o m m e n t   =   S t r i n g C o n c a t e n a t e ( " s t e p _ " ,   s t e p + 1 ) ;  
             d a t a . d _ e x p i r a t i o n   =   i n t ( m _ i n p u t P a r a m s . v a l u e ( e x i p E x p i r a t i o n ) ) * 3 6 0 0 ;  
             P r i n t ( " t r y   p e n d i n g   o r d e r :   " ,   d a t a . o u t ( ) ) ;  
              
             i n t   t i c k e t   =   0 ;  
             L S t a t i c T r a d e : : s e t P e n d i n g O r d e r ( t i c k e t ,   d a t a ) ;  
             i f   ( t i c k e t   >   0 )    
             {  
                   P r i n t ( " O K !   t i k e t = " ,   t i c k e t ) ;  
                   m _ s t a t e C o n t a i n e r . u p d a t e V a l u e ( v ,   e x s p P e n d i n g O r d e r ,   t i c k e t ) ;  
             }  
       }        
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
       m _ i n p u t P a r a m s . i n s e r t ( e x i p E x p i r a t i o n ,   U _ P e n d i n g E x p i r a t i o n ) ;  
        
        
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
       d e s t r o y O b j ( ) ;  
       e x _ o b j   =   n e w   E x S p r i n g ( ) ;  
       e x _ o b j . e x I n i t ( ) ;  
       i f   ( e x _ o b j . i n v a l i d ( ) )  
       {  
             P r i n t ( " W A R N I N G   -   E x p e r t   i n v a l i d   s t a t e " ) ;        
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
  
  
 v o i d   d e s t r o y O b j ( )  
 {  
       i f   ( e x _ o b j )   { d e l e t e   e x _ o b j ;   e x _ o b j   =   N U L L ; }        
 }  
  
  
  
 