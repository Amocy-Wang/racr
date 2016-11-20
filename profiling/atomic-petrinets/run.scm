; This program and the accompanying materials are made available under the
; terms of the MIT license (X11 license) which accompanies this distribution.

; Author: C. Bürger

#!r6rs

(import (rnrs) (atomic-petrinets profiling))

(define arguments     (command-line))
(define $caching      (list-ref arguments 1))
(define $transitions  (string->number (list-ref arguments 2)))
(define $influenced   (string->number (list-ref arguments 3)))
(define $local-places (string->number (list-ref arguments 4)))
(define $local-tokens (string->number (list-ref arguments 5)))
(define $executions   (string->number (list-ref arguments 6)))

(assert (find (lambda (s) (string=? $caching s)) (list "on" "off")))

(initialise-petrinet-language (string=? $caching "on"))
(profile-net
 (make-profiling-net $transitions $influenced $local-places $local-tokens)
 $executions)