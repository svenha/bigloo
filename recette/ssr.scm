;*=====================================================================*/
;*    serrano/prgm/project/bigloo/bigloo/recette/ssr.scm               */
;*    -------------------------------------------------------------    */
;*    Author      :  Olivier Melancon                                  */
;*    Creation    :  Sun Jun 28 16:04:55 1998                          */
;*    Last change :  Thu Jun 27 07:24:14 2024 (serrano)                */
;*    -------------------------------------------------------------    */
;*    ssr graphs                                                       */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module ssr
   (import  (main "main.scm"))
   (include "test.sch")
   (export  (test-ssr)))

;*---------------------------------------------------------------------*/
;*    compatibility kit                                                */
;*---------------------------------------------------------------------*/
(define-macro (make-table)
   '(create-hashtable :eqtest eq?))
(define-macro (table-set! set key . val)
   (if (pair? val)
       `(hashtable-put! ,set ,key ,(car val))
       `(hashtable-remove! ,set ,key)))
(define-macro (table-ref set key . def)
   (let ((k (gensym 'k)))
      `(let ((,k ,key))
	  (or (hashtable-get ,set ,k)
	      ,(if (pair? def)
		   (car def)
		   `(error "table-ref" "key unbound" ,k))))))
(define-macro (table-length set)
   `(hashtable-size ,set))
(define-macro (table-for-each proc set)
   `(hashtable-for-each ,set ,proc))
(define-macro (table->list set)
   `(hashtable-map ,set cons))
(define-macro (table-search proc set)
   (let ((k (gensym 'k))
	 (v (gensym 'v))
	 (r (gensym 'r))
	 (t (gensym 't)))
   `(bind-exit (,r)
       (hashtable-for-each ,set
	  (lambda (,k ,v)
	     (let ((,t (,proc ,k ,v)))
		(when ,t (,r ,t)))))
       #f)))
(define-macro (list->table lst)
   (let ((t (gensym 'table)))
      `(let ((,t (make-table)))
	  (for-each (lambda (pair)
		       (table-set! ,t (car pair) (cdr pair)))
	     ,lst)
	  ,t)))

(define-macro (list-sort fn lst)
   `(sort ,fn ,lst))

(define-macro (random-integer sz)
   `(random ,sz))
(define-macro (random-real)
   `(randomfl))

(define-macro (make-parameter init)
   `(lambda () ,init))
(define-macro (parameterize bindings body)
   (let ((temps (map (lambda (b) (gensym)) bindings)))
      `(let ,(map (lambda (t b) `(,t ,(car b))) temps bindings)
	  (unwind-protect
	     (begin
		,@(map (lambda (t b) `(set! ,(car b) (lambda () ,(cadr b)))) temps bindings)
		,body)
	     (begin
		,@(map (lambda (t b) `(set! ,(car b) ,t))))))))

(define infinity +inf.0)

(define (make-queue) (cons '() '()))
(define (queue-empty? queue) (null? (car queue)))
(define (queue-get! queue)
  (let ((x (caar queue)))
    (set-car! queue (cdar queue))
    (if (queue-empty? queue) (set-cdr! queue '()))
    x))
(define (queue-put! queue x)
  (let ((entry (cons x '())))
    (if (queue-empty? queue)
      (set-car! queue entry)
      (set-cdr! (cdr queue) entry))
    (set-cdr! queue entry)
    x))
(define (queue-peek queue) (if (queue-empty? queue) #f (caar queue)))

(define (get-rank graph x)
  (table-ref (graph-ranks graph) x infinity))

(define (graph-ranks graph) (vector-ref graph 1))

;*---------------------------------------------------------------------*/
;*    test-ssr ...                                                     */
;*---------------------------------------------------------------------*/
(define (test-ssr)
   
  (test-module "ssr" "ssr.scm")
  
  (define (make-test-graph #!key source)
    (list->table (list (cons source '()) (cons 'source source))))
  (define (test-graph-edges-for-each f graph)
    (table-for-each
      (lambda (from tos)
        (if (not (eq? from 'source)) 
            (for-each (lambda (to) (f from to)) tos))) graph))
  (define (test-graph-add! graph from to)
    (table-set! graph from (cons to (table-ref graph from '()))))
  (define (test-graph-remove! graph from to)
    (table-set! graph from (filter (lambda (x) (not (= x to))) (table-ref graph from '()))))
  (define (test-graph-redirect! graph node other)
    (define incoming '())
    (test-graph-edges-for-each
      (lambda (from to) (if (eq? to node) (set! incoming (cons from incoming))))
      graph)
    (set! incoming (filter (lambda (f) (not (= f node))) incoming)) ;; remove self redirect
    (for-each
      (lambda (friendly) (test-graph-remove! graph friendly node))
      incoming)
    (for-each
      (lambda (friendly) (test-graph-add! graph friendly other))
      incoming))
  (define (test-graph-rank graph target)
    (let ((queue (make-queue))
          (visited '())
          (source (table-ref graph 'source)))
      (queue-put! queue (cons 0 source))
      (set! visited (cons source visited))
      (let loop ()
        (if (queue-empty? queue)
          infinity
          (let* ((rank-node (queue-get! queue))
                 (rank (car rank-node))
                 (node (cdr rank-node))
                 (children (table-ref graph node '())))
            (if (= node target)
                rank
                (begin
                  (for-each
                    (lambda (child)
                      (when (not (memq child visited))
                        (queue-put! queue (cons (+ rank 1) child))
                        (set! visited (cons child visited))))
                    children)
                  (loop))))))))

  (define param-make      (make-parameter #f))
  (define param-add!      (make-parameter #f))
  (define param-delete!   (make-parameter #f))
  (define param-redirect! (make-parameter #f))
  (define param-rank      (make-parameter #f))

  (define (get-expected-result test . args)
    (parameterize ((param-make make-test-graph)
                   (param-add! test-graph-add!)
                   (param-delete! test-graph-remove!)
                   (param-redirect! test-graph-redirect!)
                   (param-rank test-graph-rank))
      (apply test args)))

  (define (run test . args)
    (parameterize ((param-make ssr-make-graph)
                   (param-add! ssr-add-edge!)
                   (param-delete! ssr-remove-edge!)
                   (param-redirect! ssr-redirect!)
                   (param-rank get-rank))
      (apply test args)))

  (define (run-one-fuzzy-test graph-size)
     (define delete-density 0.1)
     (define redirect-density 0.05)
     
     (define (instruction proc repr)
	(cons proc repr))
     (define (instruction-exec instr graph) ((car instr) graph))
     (define (instruction-repr instr) (cdr instr))
     
     (define (make-random-instruction)
	(let ((edge (list (random-integer graph-size) (random-integer graph-size)))
	      (r (random-real)))
	   (cond
	      ((< r redirect-density)
	       (instruction
		  (lambda (graph) (apply (param-redirect!) graph edge))
		  (cons 'redirect! edge)))
	      ((< r (+ redirect-density delete-density))
	       (instruction
		  (lambda (graph) (apply (param-delete!) graph edge))
		  (cons 'delete! edge)))
	      (else
	       (instruction
		  (lambda (graph) (apply (param-add!) graph edge))
		  (cons 'add! edge))))))
     
     (define (make-random-instructions n)
	(if (= n 0)
	    '()
	    (cons (make-random-instruction) (make-random-instructions (- n 1)))))
     
     (define (interpret-instructions instructions)
	(define graph ((param-make) :source 0))
	(for-each
	   (lambda (instr) (instruction-exec instr graph))
	   instructions)
	(map (lambda (node) ((param-rank) graph node)) (iota graph-size)))
     
     (define (find-minimal-example init-instructions)
	(let loop ((instructions init-instructions)
		   (minimal init-instructions))
	   (if (null? instructions)
	       (if (equal? minimal init-instructions)
		   (begin
		      (for-each pp (map instruction-repr minimal)))
		   (find-minimal-example minimal))
	       (let ((without (filter (lambda (i) (not (eq? i (car instructions)))) minimal)))
		  (if (equal?
			 (run interpret-instructions without)
			 (get-expected-result interpret-instructions without))
		      (loop (cdr instructions) minimal)
		      (loop (cdr instructions) without))))))
     
     (let* ((nb-instructions (* graph-size (+ 1 (random-integer graph-size))))
	    (instructions (make-random-instructions nb-instructions))
	    (expected-result (get-expected-result interpret-instructions instructions))
	    (result (run interpret-instructions instructions)))
	(equal? expected-result result)))

  (define (fuzzy-test size repetitions)
    (let loop ((i 0))
      (if (< i repetitions)
        (if (run-one-fuzzy-test size) (loop (+ i 1)))
        #t)))

  (define (test1)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 1 2)
    ((param-add!) graph 2 3)
    ((param-add!) graph 3 4)
    ((param-add!) graph 2 4)
    ((param-add!) graph 0 1)
    (map (lambda (n) ((param-rank) graph n)) (iota 5)))

  (define (test2)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 1 2)
    ((param-add!) graph 2 3)
    ((param-add!) graph 3 4)
    ((param-add!) graph 4 0)
    ((param-add!) graph 0 1)
    (map (lambda (n) ((param-rank) graph n)) (iota 5)))

  (define (test3)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 3 3)
    ((param-add!) graph 2 3)
    ((param-add!) graph 1 2)
    ((param-add!) graph 0 1)
    ((param-delete!) graph 0 1)
    (map (lambda (n) ((param-rank) graph n)) (iota 4)))

  (define (test4)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-add!) graph 2 1)
    ((param-delete!) graph 0 1)
    (map (lambda (n) ((param-rank) graph n)) (iota 6)))

  (define (test5)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-add!) graph 1 3)
    ((param-add!) graph 2 4)
    ((param-add!) graph 3 5)
    ((param-add!) graph 5 4)
    ((param-add!) graph 6 4)
    ((param-delete!) graph 2 4)
    (map (lambda (n) ((param-rank) graph n)) (iota 7)))

  (define (test6)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-add!) graph 1 3)
    ((param-add!) graph 2 4)
    ((param-add!) graph 3 5)
    ((param-add!) graph 4 6)
    ((param-add!) graph 5 4)
    ((param-add!) graph 6 7)
    ((param-delete!) graph 2 4)
    (map (lambda (n) ((param-rank) graph n)) (iota 8)))

  (define (test7)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-add!) graph 2 3)
    ((param-add!) graph 2 3)
    ((param-delete!) graph 2 3)
    (map (lambda (n) ((param-rank) graph n)) (iota 4)))

  (define (test8)
    (define graph ((param-make) :source -1))
    ((param-add!) graph -1 0)
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-add!) graph 1 2)
    ((param-delete!) graph 1 2)
    (map (lambda (n) ((param-rank) graph n)) (iota 4 -1)))

  (define (test9)
    (define result1 #f)
    (define result2 #f)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 0 6)
    ((param-add!) graph 1 2)
    ((param-add!) graph 1 3)
    ((param-add!) graph 2 4)
    ((param-add!) graph 3 4)
    ((param-add!) graph 4 5)
    ((param-add!) graph 6 2)
    ((param-add!) graph 6 7)
    ((param-add!) graph 7 3)
    ((param-delete!) graph 0 1)
    (set! result1 (map (lambda (n) ((param-rank) graph n)) (iota 8)))
    ((param-add!) graph 0 1)
    (set! result2 (map (lambda (n) ((param-rank) graph n)) (iota 8)))
    (list result1 result2))

  (define (test10)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 0 2)
    ((param-add!) graph 0 3)
    ((param-add!) graph 0 4)
    ((param-add!) graph 1 5)
    ((param-add!) graph 2 5)
    ((param-add!) graph 3 5)
    ((param-add!) graph 4 5)
    ((param-add!) graph 5 6)
    ((param-add!) graph 6 7)
    ((param-add!) graph 7 8)
    ((param-redirect!) graph 5 8)
    (map (lambda (n) ((param-rank) graph n)) (iota 9)))

  (define (test11)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 0 2)
    ((param-add!) graph 0 3)
    ((param-add!) graph 0 4)
    ((param-add!) graph 1 5)
    ((param-add!) graph 2 5)
    ((param-add!) graph 3 5)
    ((param-add!) graph 4 5)
    ((param-add!) graph 5 6)
    ((param-add!) graph 6 7)
    ((param-add!) graph 7 8)
    ((param-add!) graph 5 5)
    ((param-redirect!) graph 5 8)
    (map (lambda (n) ((param-rank) graph n)) (iota 9)))

  (define (test12)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 0 2)
    ((param-add!) graph 0 3)
    ((param-add!) graph 0 4)
    ((param-add!) graph 1 5)
    ((param-add!) graph 2 5)
    ((param-add!) graph 3 5)
    ((param-add!) graph 4 5)
    ((param-add!) graph 5 6)
    ((param-add!) graph 6 7)
    ((param-add!) graph 7 8)
    ((param-add!) graph 5 5)
    ((param-add!) graph 8 8)
    ((param-add!) graph 8 5)
    ((param-redirect!) graph 5 8)
    (map (lambda (n) ((param-rank) graph n)) (iota 9)))

  (define (test13)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 0 2)
    ((param-add!) graph 0 3)
    ((param-add!) graph 0 4)
    ((param-add!) graph 1 5)
    ((param-add!) graph 2 5)
    ((param-add!) graph 3 5)
    ((param-add!) graph 4 5)
    ((param-redirect!) graph 5 6)
    (map (lambda (n) ((param-rank) graph n)) (iota 7)))

  (define (test14)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 0 2)
    ((param-add!) graph 0 3)
    ((param-add!) graph 0 4)
    ((param-add!) graph 1 5)
    ((param-add!) graph 2 5)
    ((param-add!) graph 3 5)
    ((param-add!) graph 4 5)
    ((param-redirect!) graph 5 0)
    (map (lambda (n) ((param-rank) graph n)) (iota 6)))

  (define (test15)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-redirect!) graph 2 0)
    ((param-redirect!) graph 0 3)
    (map (lambda (n) ((param-rank) graph n)) (iota 4)))

  (define (test16)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-add!) graph 1 2)
    ((param-redirect!) graph 2 2)
    (map (lambda (n) ((param-rank) graph n)) (iota 3)))

  (define (test17)
    (define graph ((param-make) :source 0))
    ((param-add!) graph 0 1)
    ((param-redirect!) graph 1 2)
    ((param-add!) graph 0 3)
    ((param-redirect!) graph 3 2)
    ((param-delete!) graph 0 2)
    (map (lambda (n) ((param-rank) graph n)) (iota 4)))

  (define (run-all . tests)
    (for-each
      (lambda (test-data)
        (let* ((name (car test-data))
               (tst (cadr test-data))
               (expected (get-expected-result tst))
	       (result (run tst)))
	   (test name result expected)))
      tests))

  ;;(pp '(fuzzy-test 40 500)) (fuzzy-test 40 500)
  (let ()
    (define-macro (list-test name) `(list ',name ,name))
    (test "fuzzy-test" (fuzzy-test 40 500) #t)
    (run-all
      (list-test test1)
      (list-test test2)
      (list-test test3)
      (list-test test4)
      (list-test test5)
      (list-test test6)
      (list-test test7)
      (list-test test8)
      (list-test test9)
      (list-test test10)
      (list-test test11)
      (list-test test12)
      (list-test test13)
      (list-test test14)
      (list-test test15)
      (list-test test16)
      (list-test test17))))
