;*=====================================================================*/
;*    serrano/prgm/misc/cdisc/tex.sch                                  */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun Dec 28 22:55:27 1997                          */
;*    Last change :  Mon Dec 29 08:24:36 1997 (serrano)                */
;*    -------------------------------------------------------------    */
;*    The macro to write easy code                                     */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    tex-environment ...                                              */
;*---------------------------------------------------------------------*/
(define-macro (tex-environment name options . exp)
   `(begin
       (print "\\begin{" ,name "}" ,options)
       ,@exp
       (print "\\end{" ,name "}")))

;*---------------------------------------------------------------------*/
;*    tex-rput ...                                                     */
;*---------------------------------------------------------------------*/
(define-macro (tex-rput options x y . exp)
   `(begin
       (print "\\rput" ,options "(" ,x "," ,y "){%")
       ,@exp
       (print "}")))

;*---------------------------------------------------------------------*/
;*    tex-pspicture ...                                                */
;*---------------------------------------------------------------------*/
(define-macro (tex-pspicture min-x min-y max-x max-y . exp)
   `(begin
       (print "\\begin{pspicture}(" ,min-x "," ,min-y ")(" ,max-x "," ,max-y ")")
       ,@exp
       (print "\\end{pspicture}")))

