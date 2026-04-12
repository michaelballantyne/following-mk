(define (r)
  (conde
   [(fresh (x)
      (== x 1)
      (r))]))

(define (r/d)
  (conde/d
   [[x]
    [(==/d x 1)]
    [(r/d)]]))

(display
 (run 1 (q)
   (follower q
             (conde/d
              [[]
               [(==/d q 1)]
               []]
              [[]
               [(==/d q 2)
                (fresh/d ()
                         (r/d)
                         (r/d))]
               []]))
   (conde
     [(== q 1)]
     [(fresh ()
        (== q 2)
        (r)
        (r))])))