;; ProbMeTTa extended tests — PeTTa-compatible version
;; Covers: overlapping derivations, chains, annotated disj + negation,
;;         deterministic facts in rule bodies, multiple AD groups,
;;         evidence conditioning with AD, probabilistic graph reachability.

!(import! &self lib/lib_he)
!(import! &self lib/lib_zar)
!(import! &self /home/zar/claude/ProbMeTTa/lib_bdd)
!(import! &self /home/zar/claude/ProbMeTTa/lib_prob)

;; Test A: Overlapping rules (shared derivation paths)
;; P(d) = 1 - (1-0.3*0.5)*(1-0.4) = 0.49
!(:: 0.3 a)
!(:: 0.5 b)
!(:: 0.4 c)
!(prob-rule (, a b) d)
!(prob-rule (, c) d)
!(test-prob (?prob d) 0.49)
!(clear-prob!)

;; Test B: Chain of length 3
;; P(z) = 0.5 * 0.8 * 0.6 = 0.24
!(:: 0.5 x)
!(::=> 0.8 y (, x))
!(::=> 0.6 z (, y))
!(test-prob (?prob z) 0.24)
!(clear-prob!)

;; Test C: Annotated disj with body + negation query
;; P(h1) = 0.9*0.6 = 0.54, P(not h1) = 0.46
!(:: 0.9 trigger)
!(::=> 0.6 h1 (, trigger))
!(::=> 0.4 h2 (, trigger (naf h1)))
!(prob-rule (, (naf h1)) not-h1)
!(test-prob (?prob h1) 0.54)
!(test-prob (?prob not-h1) 0.46)
!(clear-prob!)

;; Test D: Deterministic facts in rule bodies
;; P(close alice bob) = 0.8
!(fact (parent alice bob))
!(fact (parent bob charlie))
!(:: 0.8 (likes $x $y))
!(prob-rule (, (parent $x $y) (likes $x $y)) (close $x $y))
!(test-prob (?prob (close alice bob)) 0.8)
!(clear-prob!)

;; Test E: Multiple independent AD groups
;; P(red-big) = 0.6 * 0.7 = 0.42
!(:: ((0.6 (color red)) (0.4 (color blue))))
!(:: ((0.7 (size big)) (0.3 (size small))))
!(prob-rule (, (color red) (size big)) red-big)
!(test-prob (?prob red-big) 0.42)
!(clear-prob!)

;; Test F: Evidence conditioning with AD
;; P(red | not blue) = 0.6/(0.6+0.3) = 0.66667
!(:: ((0.6 (color red)) (0.3 (color green)) (0.1 (color blue))))
!(prob-rule (, (naf (color blue))) not-blue)
!(test-prob (?prob-given (color red) (not-blue)) 0.66667)
!(clear-prob!)

;; Test G: Probabilistic graph reachability
;; path(X,Y) :- edge(X,Y).
;; path(X,Y) :- edge(X,Z), Z \= Y, path(Z,Y).
!(:: 0.6 (edge 1 2))
!(:: 0.1 (edge 1 3))
!(:: 0.4 (edge 2 5))
!(:: 0.3 (edge 2 6))
!(:: 0.3 (edge 3 4))
!(:: 0.8 (edge 4 5))
!(:: 0.2 (edge 5 6))
!(prob-rule (, (edge $x $y)) (path $x $y))
!(prob-rule (, (edge $x $z) (neq $y $z) (path $z $y)) (path $x $y))
;; ProbLog expected: path(1,5) = 0.25824, path(1,6) = 0.21673
!(test-prob (?prob (path 1 5)) 0.25824)
!(test-prob (?prob (path 1 6)) 0.21673)
!(clear-prob!)
