;; ==========================================================
;; Class accessors
;; Bigloo (4.2c)
;; Inria -- Sophia Antipolis     Fri Nov 6 10:55:25 CET 2015 
;; (bigloo.new -classgen SawMill/expr.scm)
;; ==========================================================

;; The directives
(directives

;; ireg
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-ireg::ireg type1196::type var1197::obj onexpr?1198::obj name1199::obj key1200::obj hardware1201::obj index1202::obj status1203::obj)
    (inline ireg?::bool ::obj)
    (ireg-nil::ireg)
    (inline ireg-status::obj ::ireg)
    (inline ireg-status-set! ::ireg ::obj)
    (inline ireg-index::obj ::ireg)
    (inline ireg-index-set! ::ireg ::obj)
    (inline ireg-hardware::obj ::ireg)
    (inline ireg-key::obj ::ireg)
    (inline ireg-name::obj ::ireg)
    (inline ireg-onexpr?::obj ::ireg)
    (inline ireg-onexpr?-set! ::ireg ::obj)
    (inline ireg-var::obj ::ireg)
    (inline ireg-var-set! ::ireg ::obj)
    (inline ireg-type::type ::ireg)
    (inline ireg-type-set! ::ireg ::type))))

;; preg
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-preg::preg type1187::type var1188::obj onexpr?1189::obj name1190::obj key1191::obj hardware1192::obj index1193::obj status1194::obj)
    (inline preg?::bool ::obj)
    (preg-nil::preg)
    (inline preg-status::obj ::preg)
    (inline preg-status-set! ::preg ::obj)
    (inline preg-index::obj ::preg)
    (inline preg-index-set! ::preg ::obj)
    (inline preg-hardware::obj ::preg)
    (inline preg-key::obj ::preg)
    (inline preg-name::obj ::preg)
    (inline preg-onexpr?::obj ::preg)
    (inline preg-onexpr?-set! ::preg ::obj)
    (inline preg-var::obj ::preg)
    (inline preg-var-set! ::preg ::obj)
    (inline preg-type::type ::preg)
    (inline preg-type-set! ::preg ::type))))

;; inlined
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-inlined::inlined loc1181::obj %spill1182::pair-nil dest1183::obj fun1184::rtl_fun args1185::pair-nil)
    (inline inlined?::bool ::obj)
    (inlined-nil::inlined)
    (inline inlined-args::pair-nil ::inlined)
    (inline inlined-args-set! ::inlined ::pair-nil)
    (inline inlined-fun::rtl_fun ::inlined)
    (inline inlined-fun-set! ::inlined ::rtl_fun)
    (inline inlined-dest::obj ::inlined)
    (inline inlined-dest-set! ::inlined ::obj)
    (inline inlined-%spill::pair-nil ::inlined)
    (inline inlined-%spill-set! ::inlined ::pair-nil)
    (inline inlined-loc::obj ::inlined)
    (inline inlined-loc-set! ::inlined ::obj)))))

;; The definitions
(cond-expand (bigloo-class-sans
;; ireg
(define-inline (make-ireg::ireg type1196::type var1197::obj onexpr?1198::obj name1199::obj key1200::obj hardware1201::obj index1202::obj status1203::obj) (instantiate::ireg (type type1196) (var var1197) (onexpr? onexpr?1198) (name name1199) (key key1200) (hardware hardware1201) (index index1202) (status status1203)))
(define-inline (ireg?::bool obj::obj) ((@ isa? __object) obj (@ ireg saw_expr)))
(define (ireg-nil::ireg) (class-nil (@ ireg saw_expr)))
(define-inline (ireg-status::obj o::ireg) (-> |#!bigloo_wallow| o status))
(define-inline (ireg-status-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o status) v))
(define-inline (ireg-index::obj o::ireg) (-> |#!bigloo_wallow| o index))
(define-inline (ireg-index-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o index) v))
(define-inline (ireg-hardware::obj o::ireg) (-> |#!bigloo_wallow| o hardware))
(define-inline (ireg-hardware-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o hardware) v))
(define-inline (ireg-key::obj o::ireg) (-> |#!bigloo_wallow| o key))
(define-inline (ireg-key-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o key) v))
(define-inline (ireg-name::obj o::ireg) (-> |#!bigloo_wallow| o name))
(define-inline (ireg-name-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o name) v))
(define-inline (ireg-onexpr?::obj o::ireg) (-> |#!bigloo_wallow| o onexpr?))
(define-inline (ireg-onexpr?-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o onexpr?) v))
(define-inline (ireg-var::obj o::ireg) (-> |#!bigloo_wallow| o var))
(define-inline (ireg-var-set! o::ireg v::obj) (set! (-> |#!bigloo_wallow| o var) v))
(define-inline (ireg-type::type o::ireg) (-> |#!bigloo_wallow| o type))
(define-inline (ireg-type-set! o::ireg v::type) (set! (-> |#!bigloo_wallow| o type) v))

;; preg
(define-inline (make-preg::preg type1187::type var1188::obj onexpr?1189::obj name1190::obj key1191::obj hardware1192::obj index1193::obj status1194::obj) (instantiate::preg (type type1187) (var var1188) (onexpr? onexpr?1189) (name name1190) (key key1191) (hardware hardware1192) (index index1193) (status status1194)))
(define-inline (preg?::bool obj::obj) ((@ isa? __object) obj (@ preg saw_expr)))
(define (preg-nil::preg) (class-nil (@ preg saw_expr)))
(define-inline (preg-status::obj o::preg) (-> |#!bigloo_wallow| o status))
(define-inline (preg-status-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o status) v))
(define-inline (preg-index::obj o::preg) (-> |#!bigloo_wallow| o index))
(define-inline (preg-index-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o index) v))
(define-inline (preg-hardware::obj o::preg) (-> |#!bigloo_wallow| o hardware))
(define-inline (preg-hardware-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o hardware) v))
(define-inline (preg-key::obj o::preg) (-> |#!bigloo_wallow| o key))
(define-inline (preg-key-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o key) v))
(define-inline (preg-name::obj o::preg) (-> |#!bigloo_wallow| o name))
(define-inline (preg-name-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o name) v))
(define-inline (preg-onexpr?::obj o::preg) (-> |#!bigloo_wallow| o onexpr?))
(define-inline (preg-onexpr?-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o onexpr?) v))
(define-inline (preg-var::obj o::preg) (-> |#!bigloo_wallow| o var))
(define-inline (preg-var-set! o::preg v::obj) (set! (-> |#!bigloo_wallow| o var) v))
(define-inline (preg-type::type o::preg) (-> |#!bigloo_wallow| o type))
(define-inline (preg-type-set! o::preg v::type) (set! (-> |#!bigloo_wallow| o type) v))

;; inlined
(define-inline (make-inlined::inlined loc1181::obj %spill1182::pair-nil dest1183::obj fun1184::rtl_fun args1185::pair-nil) (instantiate::inlined (loc loc1181) (%spill %spill1182) (dest dest1183) (fun fun1184) (args args1185)))
(define-inline (inlined?::bool obj::obj) ((@ isa? __object) obj (@ inlined saw_expr)))
(define (inlined-nil::inlined) (class-nil (@ inlined saw_expr)))
(define-inline (inlined-args::pair-nil o::inlined) (-> |#!bigloo_wallow| o args))
(define-inline (inlined-args-set! o::inlined v::pair-nil) (set! (-> |#!bigloo_wallow| o args) v))
(define-inline (inlined-fun::rtl_fun o::inlined) (-> |#!bigloo_wallow| o fun))
(define-inline (inlined-fun-set! o::inlined v::rtl_fun) (set! (-> |#!bigloo_wallow| o fun) v))
(define-inline (inlined-dest::obj o::inlined) (-> |#!bigloo_wallow| o dest))
(define-inline (inlined-dest-set! o::inlined v::obj) (set! (-> |#!bigloo_wallow| o dest) v))
(define-inline (inlined-%spill::pair-nil o::inlined) (-> |#!bigloo_wallow| o %spill))
(define-inline (inlined-%spill-set! o::inlined v::pair-nil) (set! (-> |#!bigloo_wallow| o %spill) v))
(define-inline (inlined-loc::obj o::inlined) (-> |#!bigloo_wallow| o loc))
(define-inline (inlined-loc-set! o::inlined v::obj) (set! (-> |#!bigloo_wallow| o loc) v))
))
