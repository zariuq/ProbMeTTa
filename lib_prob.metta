;; When used via git-import (upstream), uncomment:
; !(import! &self (library lib_import))
; !(git-import! "https://github.com/Habush/ProbMeTTa.git")
; !(import! &self (library lib_bdd))
;; When used locally, import lib_bdd before importing this file.

; ; Space for probabilistic facts
; !(bind! &prob-facts (new-space))
; ;; Templates: just probability + pattern
; !(bind! &prob-templates (new-space))

;; Get-or-create a BDD variable for a ground instance
(= (prob-id $atom)
    (if (is-ground $atom)
        (case (once (match &prob-facts (prob-fact $id $_ $atom) $id))
            ((Empty
                (let* (($prob (once (match &prob-templates (prob-template $p $atom) $p)))
                       ($id (new-id)))
                    (progn
                        (add-atom &prob-facts (prob-fact $id $prob $atom))
                        $id)))
             ($id $id)))
        (error! (NonGroundProbabilisticClause: $atom))))

;; "Use" a probabilistic fact in a proof
(= (prob-assume $atom $trace)
    (let $id (prob-id $atom)
        (apply-bdd bdd-and (bdd-var-node $id)  $trace)))


;; Normalize a conjunction body into a plain goal list.
;;   (, g1 g2 ... gn) -> (g1 g2 ... gn)
;;   g                -> (g)
(= (body-goals $body)
    (if (== $body ())
        ()
        (if (is-expr $body)
            (if (== (car-atom $body) ,)
                (cdr-atom $body)
                (cons $body ()))
            (cons $body ()))))

;; Preferred deterministic-rule entrypoint for PeTTa.
(= (prob-rule $body $head)
    (let $goals (body-goals $body)
        (add-atom &self (rule $head $goals))))

;; Backward-compatible alias. This helps only when the runtime evaluates =>.
(= (=> $body $head)
    (prob-rule $body $head))

;; Execute a probabilistic goal
(= (prob-goal $goal $trace)
    (let $body (match &self (rule $goal $b) $b)
        (case $body
            (((pf $atom) (prob-assume $atom $trace))
             ($goals (exec-conj $goals $trace))))))

;; Support structurally asserted bare rules: (=> BODY HEAD) with no leading !
(= (prob-goal $goal $trace)
    (let $body (match &self (=> $body $goal) $body)
        (exec-conj (body-goals $body) $trace)))

;; Negation as a failure Negation of a goal
;; 1. Take a goal
;; 2. Find all its proofs
;; 3. Take a disjunction of the proofs
;; 4. Negate the result
(= (prob-not $goal $bdd-in)
    (let* (($proofs (collapse (prob-goal $goal bdd-1)))
           ($disj (bdd-disjunction $proofs))
           ($neg (bdd-not $disj)))
        (apply-bdd bdd-and $neg $bdd-in)))

(= (prob-goal (naf $goal) $trace)
    (prob-not $goal $trace))

; Inequality constraint in rules
(= (prob-goal (neq $a $b) $trace)
    (if (== $a $b) (empty) $trace))

;; Execute a conjunction of goals, threading the trace
(= (exec-conj $goals $trace)
    (if (== $goals ())
        $trace
        (let* (($g (car-atom $goals))
               ($rest (cdr-atom $goals)))
            (if (== $rest ())
                (prob-goal $g $trace)
                (let $t1 (prob-goal $g $trace)
                    (exec-conj $rest $t1))))))
;; Build the WMC environment from all registered probabilistic facts
(= (prob-wmc-env)
    (collapse (match &prob-facts (prob-fact $id $prob $_) ($id $prob))))

(= (build-ad-helper ($prob $head) $gid $idx $cm $neg-prefix $body)
    (let* (($cond-prob (/ $prob (- 1 $cm)))
               ($aux (aux $gid $idx $head))
               ($rule-body (append (cons $aux $neg-prefix) $body))
               ($new-neg (cons (naf $aux) $neg-prefix))
               ($new-cm (+ $cm $prob))
               ($new-idx (+ $idx 1)))
            (progn 
                (add-atom &prob-templates (prob-template $cond-prob $aux))
                (add-atom &self (rule $aux (pf $aux)))
                (add-atom &self (rule $head $rule-body))
                ($new-idx $new-cm $new-neg))))

(= (build-ad-rules $alts $gid $idx $cm $neg-prefix $body)
    (let* (($alt (car-atom $alts))
           ($prob (first-from-pair $alt))
           ($head (second-from-pair $alt))
           ($rest (cdr-atom $alts)))
        (if (== $rest ())
            ;; Last element
            (if (< (+ $cm $prob) 1) ;add implicit null
                (let $_ (build-ad-helper ($prob $head) $gid $idx $cm $neg-prefix $body) (empty))
                (let $body-final (append $neg-prefix $body)
                    (add-atom &self (rule $head $body-final))))
            ;; Not last — process and recurse
            (let $next-state (build-ad-helper ($prob $head) $gid $idx $cm $neg-prefix $body)
                (let* (($new-idx (car-atom $next-state))
                       ($state-rest (cdr-atom $next-state))
                       ($new-cm (car-atom $state-rest))
                       ($new-neg (car-atom (cdr-atom $state-rest))))
                    (build-ad-rules $rest $gid $new-idx $new-cm $new-neg $body))))))

(= (:: $alts)
    (let $gid (new-id)
        (build-ad-rules $alts $gid 1 0 () ())))

;; :: stores template + rule. No BDD variable yet.
(= (:: $prob $goal)
    (progn
        (add-atom &prob-templates (prob-template $prob $goal))
        (add-atom &self (rule $goal (pf $goal)))))

(= (::adr $alts $body)
    (let $gid (new-id)
        (build-ad-rules $alts $gid 1 0 () $body)))

(= (::=> $prob $head $body)
    (::adr (($prob $head)) (body-goals $body)))

(= (::=> $heads $body)
    (::adr $heads (body-goals $body)))

(= (fact $f) (add-atom &self (rule $f ())))

;; Helper function
(= (remove-all $space)
    (collapse (match $space $x (remove-atom $space $x))))

(= (round-to $x $digits)
    (let $f (pow-math 10 $digits)
        (/ (round-math (* $x $f)) $f)))

;; Clear all probabilistic program state
(= (clear-prob!)
    (progn
        (collapse (match &self (rule $h $b) (remove-atom &self (rule $h $b))))
        (collapse (match &self (=> $body $head) (remove-atom &self (=> $body $head))))
        (remove-all &prob-facts)
        (remove-all &prob-templates)
        (remove-all &apply-cache)))

(= (?prob-bdd $goal)
    (let $proofs (collapse (prob-goal $goal bdd-1))
        (bdd-disjunction $proofs)))
(= (?prob-bdd-ev $evidence)
        (let $ev-bdds (collapse (?prob-bdd (superpose $evidence)))
            (bdd-conjunction $ev-bdds)))

;; Top-level: query the probability of a goal
(= (?prob $goal)
    (if (is-ground $goal)
        (let* (($final-bdd (?prob-bdd $goal))
           ($env (prob-wmc-env)))
            (round-to (bdd-wmc $final-bdd $env) 5))
        (let $g (match &self (rule $goal $_) $goal)
            (?prob $g))))

;; Top-level: probability of P(Query | Evidence)
(= (?prob-given $query $evidence)
    (if (is-ground $query)
        (let* (($query-bdd (?prob-bdd $query))
               ($evid-bdd (?prob-bdd-ev $evidence))
               ($conj-bdd (apply-bdd bdd-and $query-bdd $evid-bdd))
               ($env (prob-wmc-env))
               ($conj-prob (bdd-wmc $conj-bdd $env))
               ($evid-prob (bdd-wmc $evid-bdd $env)))
            (round-to (/ $conj-prob $evid-prob) 5))
        (let $q (match &self (rule $query $_) $query)
            (?prob-given $q $evidence))))

;; Helper Test function that takes into account decimal points
(= (test-prob $actual $expected)
    (if (< (abs-math (- $actual $expected)) 1e-4)
        (println! ("is " $actual ", should "  $expected ". ✅"))
        (println! ("is " $actual ", should "  $expected ". ❌"))))