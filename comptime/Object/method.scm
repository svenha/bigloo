;*=====================================================================*/
;*    serrano/prgm/project/bigloo/comptime/Object/method.scm           */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Wed May  1 13:58:40 1996                          */
;*    Last change :  Thu Apr  7 20:50:48 2011 (serrano)                */
;*    Copyright   :  1996-2011 Manuel Serrano, see LICENSE file        */
;*    -------------------------------------------------------------    */
;*    The method management                                            */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module object_method
   (import tools_args
	   tools_error
	   tools_misc
	   type_type
	   ast_var
	   ast_ident
	   ast_env
	   object_class
	   (find-location tools_location)
	   engine_param
	   backend_backend)
   (export (make-method-body ::symbol ::obj ::obj ::obj ::obj)))

;*---------------------------------------------------------------------*/
;*    make-method-body ...                                             */
;*---------------------------------------------------------------------*/
(define (make-method-body ident args locals body src)
   (let* ((id (id-of-id ident (find-location src)))
	  (met (gensym 'next-method))
	  (arity (global-arity args))
	  (args-id (map local-id locals))
	  (type (local-type (car locals)))
	  (m-id (gensym (symbol-append id '- (type-id type)))))
      (if (not (tclass? type))
	  (method-error id "method has a non-class dispatching type arg" src)
	  (let* ((holder (tclass-holder type))
		 (module (global-module holder))
		 (generic (find-global id)))
	     (cond
		((not (global? generic))
		 (method-error id "Can't find generic for method" src))
		(else
		 (let* ((body `(labels ((call-next-method ()
				  (let ((,met (find-super-class-method
						 ,(car args-id)
						 ,id
						 (@ ,(global-id holder)
						    ,module))))
				     ,(if (>=fx arity 0)
					  `(,met ,@args-id)
					  `(apply ,met (cons* ,@args-id))))))
				  ,body))
			(ebody (if (epair? src)
				   (econs (car body) (cdr body) (cer src))
				   body))
			(bdg   `(,m-id ,args ,ebody))
			(ebdg  (if (epair? src)
				   (econs (car bdg) (cdr bdg) (cer src))
				   bdg)))
		    (list `(labels (,ebdg)
			      ,(when (and (>=fx *debug-module* 1)
					  (memq 'module
						(backend-debug-support
						 (the-backend))))
				  `(pragma::void
				   ,(string-append "bgl_init_module_debug_string( \"generic-add-method: " (symbol->string ident) " ::" (symbol->string (global-id holder)) "\"); ")))
			      (generic-add-method!
			       ,id
			       (@ ,(global-id holder) ,module)
			       ,m-id
			       ,(symbol->string ident)))))))))))

;*---------------------------------------------------------------------*/
;*    method-error ...                                                 */
;*---------------------------------------------------------------------*/
(define (method-error id msg src)
   (user-error id msg src (list ''method-definition-error)))
