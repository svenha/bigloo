(module saw_jvm_funcall
   (import type_type ast_var ast_node ast_env
	   type_env
	   tools_shape
	   object_class
	   object_slots
	   backend_backend
	   backend_bvm
	   backend_jvm_class
	   backend_lib
	   backend_cplib
	   saw_defs
	   saw_procedures
	   saw_jvm_out)
   (export (module-funcall/apply me::jvm)
	   (module-light-funcall me::jvm)
	   (wide-class indexed::global index::int) ))
   

(define (key-opt? v)
   (let ( (v (global-entry v)) )
      (let ( (val  (global-value v)) )
	 (when (sfun? val)
	    (let ( (clo (sfun-the-closure-global val)) )
	       (let ( (o (global-optional? clo)) (k (global-key? clo)) )
		      (or o k) ))))))
;;
;; Create the specifics methods for all light funcalls
;;
(define (module-light-funcall me)
   (with-access::jvm me (light-funcalls)
      (for-each (lambda (ins)
		   (with-access::rtl_lightfuncall ins (name funs rettype)
			 (funcall-light me name funs rettype) ))
		light-funcalls )))

(define (funcall-light me name funs rettype)
   (define (compile-bad-type me::jvm type)
      (cond
	 ((local? type)
	  (compile-type me (local-type type)) )
	 ((type? type)
	  (compile-type me type) )
	 (else (error 'compile-bad-type "unknown type" type)) ))
   (define (load t v)
      (code! me
	     `(,(case t
		   ((boolean byte char short int) 'iload)
		   ((long) 'lload)
		   ((float) 'fload)
		   ((double) 'dload)
		   (else 'aload) )
	       ,v )))
   (define (index v) (indexed-index (var-variable v)))
   (define (tas g)
      (map (lambda (a) (compile-bad-type me a))
	   (sfun-args (global-value g)) ))
   (let* ( (f (car funs))
	   (g (var-variable f))
	   (tr (compile-type me rettype));;((global-type g)))
	   (tal (tas g))
	   (p (map (lambda (t) (gensym)) tal))
	   )
      (declare-method me name 'me '(private static) tr (symbol->string name) tal)
      (open-lib-method me name)
      (declare-locals me p '())
      (for-each (lambda (t v) (load t v)) tal p)
      (code! me `(aload ,(car p)))
      (code! me '(getfield procindex))
      (funcall-light-switch me funs tr (car p))
      (close-method me) ))

(define (funcall-light-switch me funs tr this)
   (define (ret t)
      (code! me 
	     (case t
		((void) '(return))
		((boolean byte char short int) '(ireturn))
		((long) '(lreturn))
		((float) '(freturn))
		((double) '(dreturn))
		(else '(areturn)) )))
   (define (indexes l)
      (map (lambda (v) (indexed-index (var-variable v))) funs) )
   (define (L n) (string->symbol (string-append "L" (integer->string n))))
   (define (get-labs i l)
      (cond
	 ((null? l) '())
	 ((=fx i (car l))
	  (cons (L i) (get-labs (+fx i 1) (cdr l))) )
	 (else (cons 'err (get-labs (+fx i 1) l))) ))
   (let* ( (i* (indexes funs))
	   (labs (get-labs 0 (sort i* <)))
		 )
      ;; CARE check if we can start higher than 0
      (code! me `(tableswitch err 0 ,@labs))
      (label me 'err)
      (push-string me "funcall light")
      (push-string me "internal error")
      (code! me `(aload ,this))
      (code! me '(invokestatic fail))
      (code! me '(athrow))
      (for-each (lambda (f)
		   (let ( (g (var-variable f)) )
		      (label me (L (indexed-index g)))
		      (call-global me (global-entry g))
		      (ret tr) ))
		funs )))

;;
;; Overload funcall<i> and apply methods
;;
(define (module-funcall/apply me)
   (let ( (p (reverse! (get-procedures (jvm-functions me)))) )
      ;; CARE sort p in order to optimize switches
      (let ( (n '0) )
	 (for-each (lambda (var)
		      (widen!::indexed var (index n))
		      (widen!::indexed (global-entry var) (index n))
		      (set! n (+fx n 1)) )
		   p ))
      (if (not (null? p))
	  (begin (funcalli me 0 p)
		 (funcalli me 1 p)
		 (funcalli me 2 p)
		 (funcalli me 3 p)
		 (funcalli me 4 p)
		 (compile-apply me p) ))))

(define (exchange l i j)
   (let ( (li (list-tail l i)) (lj (list-tail l j)) )
      (let ( (o (car li)) )
	 (set-car! li (car lj))
	 (set-car! lj o) )))

(define (is-light-procedure?.old me::jvm g)
   ;; CARE manu, sure there is a better version of this predicate
   (define (compile-bad-type me::jvm type)
      (cond
	 ((local? type)
	  (compile-type me (local-type type)) )
	 ((type? type)
	  (compile-type me type) )
	 (else (error 'compile-bad-type "unknown type" type)) ))
   (define (tas g)
      (let ( (v (global-value g)) )
	 (if (sfun? v)
	     (begin
		(tprint "G=" (shape g) " class=" (sfun-strength v))
		(map (lambda (a) (compile-bad-type me a))
		   (cdr (sfun-args v)) ) )
	     '() )))
   (let* ( (tr (compile-type me (global-type g)))
	   (tal (tas g)) )
      (not (and (eq? tr 'obj) (every? (lambda (t) (eq? t 'obj)) tal))) ))

(define (is-light-procedure? me::jvm g)
   (let ( (v (global-value g)) )
      (when (sfun? v)
	 (eq? (sfun-strength v) 'light) )))

;;
;; The "funcall"s method
;;
(define (funcalli me i procs)
   (define (needed? p)
      (and (not (is-light-procedure? me (global-entry p)))
	   (let ( (arity (global-arity p)) )
	      (if arity
		  (or (and (>=fx arity 0)
			   (if (key-opt? p)
			       (<= arity i)
			       (=fx arity i) ))
		      (and (<fx arity 0) (>= arity (- -1 i))) )
		  (<= i 1) ))))
   (define (name n) (if (=fx n 0) '() (cons (gensym) (name (-fx n 1)))))
   (let ( (need (map needed? procs)) )
      (if (not (every not need))
	  (let* ( (fname (string-append "funcall" (integer->string i)))
		  (p (cons 'this (name i))) )
	     (open-lib-method me (string->symbol fname))
	     (declare-locals me p '())
	     (for-each (lambda (v) (code! me `(aload ,v))) p)
	     (code! me '(aload this))
	     (code! me '(getfield procindex))
	     (compile-funi me i need procs fname)
	     (close-method me) ))))

(define (compile-funi me i need procs fname)
   (define (L n) (string->symbol (string-append "L" (integer->string n))))
   (define (get-labs i ns ps)
      (if (null? ns)
	  '()
	  (cons (if (car ns) (L i) 'err)
		(get-labs (+fx i 1) (cdr ns) (cdr ps)) )))
   (let ( (labs (get-labs 0 need procs)) )
      (code! me `(tableswitch err 0 ,@labs))
      (label me 'err)
      (code! me `(invokespecial ,(string->symbol (string-append "p" fname))))
      (code! me '(areturn))
      (for-each (lambda (n? lab p) (if n? (compile-for-funcalli me i lab p)))
		need
		labs
		procs )))


(define (compile-for-funcalli me i lab p)
   (let ( (arity (global-arity p)) )
      (define (make-vect i)
	 (string->symbol (string-append "make_vector" (integer->string i))) )
      (define (make_cons n)
	 (if (= n 0)
	     (call-global me (global-entry p))
	     (begin (code! me '(invokestatic cons))
		    (make_cons (-fx n 1)) )))
      (label me lab)
      (cond
	 ((eq? arity #f)
	  (if (=fx i 0)
	      (begin (code! me '(pop))
		     (code! me `(getstatic ,(declare-global me p))) )
	      (code! me `(putstatic ,(declare-global me p))) ))
	 ((>=fx arity 0)
 	  (if (key-opt? p)
	      (let ( (v (global-entry p)) )
		 (code! me `(invokestatic ,(make-vect i)))
		 (call-global me v) )
	      (call-global me (global-entry p)) ))
	 (else
	  (code! me '(getstatic *nil*))
	  (make_cons (+ i 1 arity)) ))
      (code! me '(areturn)) ))

;;
;; The apply method
;;
(define (compile-apply me procs)
   (define (xx_global-arity p)
      (and (not (is-light-procedure? me p))
	      (not (is-light-procedure? me (global-entry p)))
	   (global-arity p)) )
   (let ( (need (map xx_global-arity procs)) )
      (unless (every not need)
	 (open-lib-method me 'apply)
	 (declare-locals me '(this l) '())
	 (code! me '(aload this))
	 (code! me '(aload this))
	 (code! me '(getfield procindex))
	 (compile-dispatch me need procs)
	 (close-method me) )))

(define (compile-dispatch me need procs)
   (define (L n) (string->symbol (string-append "L" (integer->string n))))
   (define (get-labs i ns ps)
      (if (null? ns)
	  '()
	  (cons (if (car ns) (L i) 'err)
		(get-labs (+fx i 1) (cdr ns) (cdr ps)) )))
   (let ( (labs (get-labs 0 need procs)) )
      (code! me `(tableswitch err 0 ,@labs))
      (label me 'err)
      (code! me '(aload l))
      (code! me '(invokespecial papply))
      (code! me '(areturn))
      (for-each (lambda (n? lab p) (if n? (compile-for-apply me lab p)))
		need
		labs
		procs )))

(define (compile-for-apply me lab p)
   (define (push-cars me n fixedarity?)
      (cond
	 ((=fx n 0)
	  (if (not fixedarity?)
	      (code! me '(aload l)) ))
	 ((=fx n 1)
	  (code! me '(aload l))
	  (code! me '(checkcast pair))
	  (code! me '(getfield car))
	  (unless fixedarity?
	     (code! me '(aload l))
	     (code! me '(checkcast pair))
	     (code! me '(getfield cdr)) ))
	 (else
	  (code! me '(aload l))
	  (code! me '(checkcast pair))
	  (code! me '(dup))
	  (code! me '(getfield cdr))
	  (code! me '(astore l))
	  (code! me '(getfield car))
	  (push-cars me (- n 1) fixedarity?) )))
   (let ( (arity (global-arity p)) )
      (label me lab)
      (if (>= arity 0)
	  (if (key-opt? p)
	      (begin (code! me '(aload l))
		     (code! me '(invokestatic list_to_vector)) )
	      (push-cars me arity #t) )
	  (push-cars me (- -1 arity) #f) )
      (call-global me (global-entry p))
      (code! me '(areturn)) ))
