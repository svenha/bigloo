;*=====================================================================*/
;*    serrano/prgm/project/bigloo/bigloo/tools/cfg.scm                 */
;*    -------------------------------------------------------------    */
;*    Author      :  Marc Feeley                                       */
;*    Creation    :  Mon Jul 17 08:14:47 2017                          */
;*    Last change :  Fri Oct 28 15:15:43 2022 (serrano)                */
;*    Copyright   :  2017-22 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    CFG (BB) dump for the dot program.                               */
;*    -------------------------------------------------------------    */
;*    The input file is generated by Bigloo with:                      */
;*                                                                     */
;*      bigloo file.scm -saw -fsaw-regalloc -fsaw-bbv -gself           */
;*                                                                     */
;*    The input basic-blocks dump is as follows:                       */
;*                                                                     */
;*    ;; -*- mode: bee -*-                                             */
;*    ;; *** sum:                                                      */
;*    ;; (!v)                                                          */
;*    (block 25                                                        */
;*     :preds ()                                                       */
;*     :succs (26)                                                     */
;*     [($g1130 <- (mov ($long->bint (loadi 0)))) (ctx ... ctx)]       */
;*     [(!s <- (mov ($long->bint (loadi 0)))) (ctx ... ctx)]           */
;*                                                                     */
;*    (block 26                                                        */
;*     ;; ictx=(#("$g1130" "bint") #("!s" "bint"))                     */
;*     :preds (25)                                                     */
;*     :succs (27 186)                                                 */
;*     [(ifeq ($vector? !v) 186) (ctx ... ctx)]                        */
;*                                                                     */
;*    ...                                                              */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module cfg-dump
   (main main))

;*---------------------------------------------------------------------*/
;*    bb ...                                                           */
;*---------------------------------------------------------------------*/
(define-struct bb lbl-num preds succs instrs parent merge collapsed cost color)

;*---------------------------------------------------------------------*/
;*    list->bb ...                                                     */
;*---------------------------------------------------------------------*/
(define (list->bb l)
   (match-case l
      ((blockS ?num :parent ?parent :merge ?merge :collapsed ?collapsed :cost ?cost :preds ?preds :succs ?succs . ?ins)
       (bb num preds succs ins parent merge collapsed cost (get-color parent)))
      (((or block blockS blockV SawDone) ?num :parent ?parent :merge ?merge :collapsed ?collapsed :preds ?preds :succs ?succs . ?ins)
       (bb num preds succs ins parent merge collapsed 0 (get-color parent)))
      (((or block blockS blockV SawDone) ?num :parent ?parent :preds ?preds :succs ?succs . ?ins)
       (bb num preds succs ins parent #f #f 0 (get-color parent)))
      (((or block blockS blockV SawDone) ?num :merge ?merge :preds ?preds :succs ?succs . ?ins)
       (bb num preds succs ins #f merge #f 0 (get-color 0)))
      (((or block blockS blockV SawDone) ?num :preds ?preds :succs ?succs . ?ins)
       (bb num preds succs ins #f #f #f 0 (get-color 0)))
      (else
       (error "list->bb" "bad block syntax" l))))

;*---------------------------------------------------------------------*/
;*    *colors* ...                                                     */
;*---------------------------------------------------------------------*/
(define *colors* '((0 . "#999999")))

;*---------------------------------------------------------------------*/
;*    get-color ...                                                    */
;*---------------------------------------------------------------------*/
(define (get-color num)
   (let ((col (assq num *colors*)))
      (if (pair? col)
	  (cdr col)
	  (let ((new (gennewcolor)))
	     (set! *colors* (cons (cons num new) *colors*))
	     new))))

;*---------------------------------------------------------------------*/
;*    gennewcolor ...                                                  */
;*---------------------------------------------------------------------*/
(define (gennewcolor)
   (let ((r (+fx 100 (random 155)))
	 (g (+fx 100 (random 155)))
	 (b (+fx 100 (random 155))))
      (format "#~02x~02x~02x" r g b)))

;*---------------------------------------------------------------------*/
;*    main ...                                                         */
;*---------------------------------------------------------------------*/
(define (dump-cfg name bbs)
   
   ;; For generating visual representation of control flow graph with "dot".
   
   (define nodes '())
   
   (define edges '())
   
   (define (add-node! node)
      (set! nodes (append node nodes)))
   
   (define (add-edge! from to dotted color)
      (set! edges (append (gen-edge from to dotted color) edges)))
   
   (define (gen-digraph name)
      `("digraph \"" ,name "\" {\n"
	  "  graph [splines = true overlap = false rankdir = \"TD\"];\n"
	  ,@nodes
	  ,@edges
	  "}\n"))
   
   (define (gen-node id label)
      `("  " ,id " [fontname = \"Courier New\" shape = \"none\" label = "
	  ,@label
	  " ];\n"))

   (define (gen-edge from to dotted? color)
      `(,from " -> " ,to
	  ,(cond
	      ((and dotted? color) (format " [style = dashed; color = ~a];\n" color))
	      (dotted? " [style = dotted];\n")
	      (color (format " [color = ~a];\n" color))
	      (else ";\n"))))
   
   (define (gen-table id content #!key (bgcolor "gray85") (color "black") (cellspacing 0))
      `("<table border=\"0\" cellborder=\"0\" cellspacing=\""
	  ,cellspacing
	  "\" cellpadding=\"0\""
	  ,@(if bgcolor `(" bgcolor=\"" ,bgcolor "\"") '())
	  ,@(if color `(" color=\"" ,color "\"") '())
	  ,@(if id `(" port=\"" ,id "\"") '())
	  ">"
	  ,@content
	  "</table>"))
   
   (define (gen-row content)
      `("<tr>" ,@content "</tr>"))
   
   (define (gen-col id content::pair #!key color)
      `("<td align=\"left\""
	  ,@(if id `(" port=\"" ,id "\"") '())
	  ,@(if color `(" color=\"" ,color "\"") '())
	  ">"
	  ,@content
	  "</td>"))
   
   (define (gen-head content::pair-nil)
      `("<td align=\"center\">" ,@content "</td>"))
   
   (define (gen-html-label content)
      `("<" ,@content ">"))

   (define (normalize-mov obj)
      (match-case obj
	 ((mov ?exp) exp)
	 ((?fun ?exp) `(,fun ,(normalize-mov exp)))
	 ((?- . ?-) (map normalize-mov obj))
	 (else obj)))
   
   (define (escape obj)
      (cond
	 ((string? obj)
	  (apply string-append
	     (map (lambda (c)
		     (cond ((char=? c #\<) "&lt;")
			   ((char=? c #\>) "&gt;")
			   ((char=? c #\&) "&amp;")
			   (else (string c))))
		(string->list obj))))
	 ((symbol? obj)
	  (escape (symbol->string obj)))
	 ((pair? obj)
	  (let ((nobj (normalize-mov obj)))
	     (if (pair? nobj)
		 (format "(~( ))" (map escape nobj))
		 (escape nobj))))
	 ((string? obj)
	  obj)
	 (else
	  (format "~s" obj))))

   (define (jump? x)
      (and (pair? x) (memq (car x) '(ifne ifeq go))))

   (define (go? x)
      (and (pair? x) (pair? (car x)) (eq? (caar x) 'go)))

   (define (add-bb! bb)
      
      (define id (bb-lbl-num bb))
      (define port-count (-fx (length (bb-succs bb)) 1))
      (define rev-rows '())
      
      (define (add-row row)
	 (set! rev-rows (cons row rev-rows)))

      (define (add-ref! from side to dotted? color)
	 (if from
	     (add-edge! (format "~a:~a ~a" id from side) to dotted? color)
	     (add-edge! (format "~a ~a" id side) to dotted? color)))
      
      (define (getport code)
	 (when (jump? code)
	    (let ((port port-count))
	       (set! port-count (-fx port-count 1))
	       port)))

      (define (decorate-ctx-entry entry)
	 (match-case entry
	    (#(?reg ?type _ ())
	     (format "~a:~a" (escape reg) type))
	    (#(?reg ?type ?val ())
	     (format "~a:~a/~a" (escape reg) type val))
	    (#(?reg ?type ?val ?aliases)
	     (format "~a:~a[~( )]" (escape reg) type (map escape aliases)))
	    (#(?reg ?type ?val ?aliases)
	     (format "~a:~a/~a[~( )]" (escape reg) type val (map escape aliases)))
	    (else
	     "")))
      
      (define (decorate-ctx::pair-nil ins)
	 (if (pair? (cadr ins))
	     (let ((ctx (cadr ins)))
		(gen-row
		   (gen-col #f
		      (gen-table #f
			 (gen-row
			    (gen-col #f
			       (list (format "<font color=\"blue\"><i>;; ~( )</i></font>"
					(map decorate-ctx-entry ctx)))))
			 :color "blue"
			 :cellspacing 2))))
	     '()))

      (define (decorate-instr::pair ins last-instr?)
	 
	 (define (target-id ref)
	    (string->number (substring ref 1 (string-length ref))))
	 
	 (let ((code (car ins))
	       (ctx (cadr ins)))
	    (gen-row
	       (gen-col #f
		  (gen-table #f
		     (gen-row
			(gen-col (getport code)
			   (list (format "~( )" (map escape code)))))
		     :cellspacing 2)))))
      
      (let* ((lbl (format "<b>#~a</b>" (bb-lbl-num bb)))
	     (title `(,(cond
			  ((bb-merge bb)
			   (format "<font color=\"green\">~a</font>"
			      lbl))
			  ((bb-collapsed bb)
			   (format "<font color=\"red\">~a!</font>"
			      lbl))
			  (else
			   lbl))
		      ,(if (bb-parent bb) (format "[~s]" (bb-parent bb)) "")))
	     (head (gen-row
		      (gen-col #f
			 (gen-table #f
			    (gen-row (gen-head title))
			    :bgcolor (bb-color bb)))))
	     (instrs (bb-instrs bb)))
	 (let loop ((instrs instrs)
		    (succs (reverse (bb-succs bb)))
		    (port (-fx (length (bb-succs bb)) 1)))
	    (when (pair? instrs)
	       (let ((ins (car instrs)))
		  (cond
		     ((not (pair? ins))
		      (loop (cdr instrs) succs port))
		     ((eq? (caar ins) 'go)
		      (add-ref! port ":sw" (car succs) #f "blue")
		      (loop (cdr instrs) (cdr succs) (-fx port 1)))
		     ((eq? (caar ins) 'ifne)
		      (add-ref! port ":e" (car succs) #f "green")
		      (loop (cdr instrs) (cdr succs) (-fx port 1)))
		     ((eq? (caar ins) 'ifeq)
		      (add-ref! port ":e" (car succs) #t "black")
		      (loop (cdr instrs) (cdr succs) (-fx port 1)))
		     (else
		      (loop (cdr instrs) succs port))))))
	 (when (and (pair? (bb-succs bb))
		    (or (null? instrs) (not (go? (car (last-pair instrs))))))
	    (add-ref! #f ":s" (car (bb-succs bb)) #f "red"))
	 (add-node!
	    (gen-node id
	       (gen-html-label
		  (gen-table #f
		     (cons head
			(let loop ((lst instrs))
			   (if (pair? lst)
			       (let ((rest (cdr lst)))
				  (append
				     (decorate-ctx (car lst))
				     (decorate-instr (car lst) (null? rest))
				     (loop rest)))
			       '())))))))))
   
   (for-each add-bb! (map list->bb (reverse bbs)))
   (for-each display (gen-digraph name)))

;*---------------------------------------------------------------------*/
;*    main ...                                                         */
;*---------------------------------------------------------------------*/
(define (main args)
   (if (pair? (cdr args))
       (dump-cfg (cadr args)
	  (call-with-input-file (cadr args) port->sexp-list))
       (dump-cfg "stdin"
	  (port->sexp-list (current-input-port)))))
