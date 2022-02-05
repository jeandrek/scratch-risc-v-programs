(define number? integer?)

(define (> x y) (< y x))
(define (<= x y) (not (< y x)))
(define (>= x y) (not (< x y)))

(define (abs x) (if (< x 0) (- 0 x) x))

(define (not obj) (if obj #f #t))
(define (boolean? obj) (if obj (eq? obj #t) #t))

(define (null? obj) (eq? obj '()))

(define (length lst)
  (define (loop lst n)
    (if (null? lst) n (loop (cdr lst) (+ n 1))))
  (loop lst 0))

(define (reverse lst)
  (define (loop lst acc)
    (if (null? lst)
        acc
        (loop (cdr lst) (cons (car lst) acc))))
  (loop lst '()))

(define (memq obj lst)
  (cond ((null? lst) #f)
        ((eq? (car lst) obj) lst)
        (else (memq obj (cdr lst)))))

(define (assq obj lst)
  (cond ((null? lst) #f)
        ((eq? (car (car lst)) obj) lst)
        (else (assq obj (cdr lst)))))

(define (map proc lst)
  (define (loop lst acc)
    (if (null? lst)
        (reverse acc)
        (loop (cdr lst) (cons (proc (car lst)) acc))))
  (loop lst '()))

(define (for-each proc lst)
  (cond ((not (null? lst))
         (proc (car lst))
         (for-each proc (cdr lst)))))
