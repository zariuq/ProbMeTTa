!(import! &self (library lib_prob))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 1: Basic alarm   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; 0.1::burglary. 0.2::earthquake. 0.7::hears_alarm(X).
;; alarm :- burglary.  alarm :- earthquake.
;; calls(X) :- alarm, hears_alarm(X).
;; query(calls(mary)).  => 0.196

!(:: 0.1 (burglary))
!(:: 0.2 (earthquake))
!(:: 0.7 (hears_alarm $x))
!(=> (, (burglary)) (alarm))
!(=> (, (earthquake)) (alarm))
!(=> (, (alarm) (hears_alarm mary)) (calls mary))
!(test (?prob (calls mary)) 0.196)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 2: Alarm + negation  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; calls(X) :- alarm, hears_alarm(X), \+ earthquake.
;; Only the burglary path survives.
;; P = 0.1 * 0.7 * (1-0.2) = 0.056

!(:: 0.1 (burglary))
!(:: 0.2 (earthquake))
!(:: 0.7 (hears_alarm $x))
!(=> (, (burglary)) (alarm))
!(=> (, (earthquake)) (alarm))
!(=> (, (alarm) (hears_alarm mary) (naf (earthquake))) (calls mary))
!(test-prob (?prob (calls mary)) 0.056)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 3: Fever chain  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; 0.3::smoking. 0.2::asbestos. 0.4::cold.
;; 0.8::fever_if_flu. 0.9::fever_if_pneumonia.
;; lung_disease :- smoking.  lung_disease :- asbestos.
;; pneumonia :- lung_disease, cold.
;; flu :- cold.
;; fever :- flu, fever_if_flu.
;; fever :- pneumonia, fever_if_pneumonia.
;; query(fever).  => 0.35168

!(:: 0.3 (smoking))
!(:: 0.2 (asbestos))
!(:: 0.4 (cold))
!(:: 0.8 (fever_if_flu))
!(:: 0.9 (fever_if_pneumonia))
!(=> (, (smoking)) (lung_disease))
!(=> (, (asbestos)) (lung_disease))
!(=> (, (cold)) (flu))
!(=> (, (lung_disease) (cold)) (pneumonia))
!(=> (, (flu) (fever_if_flu)) (fever))
!(=> (, (pneumonia) (fever_if_pneumonia)) (fever))
!(test-prob (?prob (fever)) 0.35168)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 4: Simple negation  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0.3::a.
;; b :- \+ a.
;; query(b).  => 1 - 0.3 = 0.7

!(:: 0.3 (a))
!(=> (, (naf (a))) (b))
!(test-prob (?prob (b)) 0.7)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 5: Double negation  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0.3::a.
;; b :- \+ \+ a.
;; query(b).  => 0.3  (double negation = original)

!(:: 0.3 (a))
!(=> (, (naf (naf (a)))) (b))
!(test-prob (?prob (b)) 0.3)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 6: Independent facts   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0.5::a. 0.5::b.
;; c :- a, b.
;; query(c).  => 0.25

!(:: 0.5 (a))
!(:: 0.5 (b))
!(=> (, (a) (b)) (c))
!(test-prob (?prob (c)) 0.25)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 7: Single prob fact  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0.4::rain.
;; query(rain).  => 0.4

!(:: 0.4 (rain))
!(test-prob (?prob (rain)) 0.4)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 8: Negation in conjunction ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0.3::a. 0.6::b.
;; c :- a, \+ b.
;; query(c).  => 0.3 * (1-0.6) = 0.12

!(:: 0.3 (a))
!(:: 0.6 (b))
!(=> (, (a) (naf (b))) (c))
!(test-prob (?prob (c)) 0.12)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 9: Conditioning            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; P(burglary | alarm)
;; = P(burglary ∧ alarm) / P(alarm)
;; = P(burglary) / P(burglary ∨ earthquake)
;; = 0.1 / (0.1 + 0.2 - 0.02)
;; = 0.1 / 0.28
;; ≈ 0.357142857

!(:: 0.1 (burglary))
!(:: 0.2 (earthquake))
!(=> (, (burglary)) (alarm))
!(=> (, (earthquake)) (alarm))
!(test-prob (?prob-given (burglary) ((alarm))) 0.357142857)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 10: Trivial conditioning   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; P(alarm | earthquake) = 1.0
;; earthquake → alarm, so alarm is certain given earthquake

; !(:: 0.1 (burglary))
; !(:: 0.2 (earthquake))
; !(=> (, (burglary)) (alarm))
; !(=> (, (earthquake)) (alarm))
; !(test-prob (?prob-given (alarm) ((earthquake))) 1.0)

!(:: 0.1 (burglary))
!(:: 0.2 (earthquake))
!(=> (, (burglary)) (alarm))
!(=> (, (earthquake)) (alarm))
!(test-prob (?prob-given (alarm) ((earthquake))) 1.0)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 11: Simple annotated disj  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; 0.6::color(red) ; 0.3::color(green) ; 0.1::color(blue).
;; query(color(red)).   => 0.6
;; query(color(green)). => 0.3
;; query(color(blue)).  => 0.1

!(:: ((0.6 (color red)) (0.3 (color green)) (0.1 (color blue))))
!(test-prob (?prob (color red)) 0.6)
!(test-prob (?prob (color green)) 0.3)
!(test-prob (?prob (color blue)) 0.1)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 12: Annotated disj + body  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; 0.7::burglary. 0.2::earthquake.
;; 0.9::alarm ; 0.1::no_alarm :- burglary, earthquake.
;; query(alarm).  => 0.7 * 0.2 * 0.9 = 0.126

!(:: 0.7 burglary)
!(:: 0.2 earthquake)
!(::=> ((0.9 alarm)) (, burglary earthquake))
!(test-prob (?prob alarm) 0.126)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 13: Implicit null           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; 0.3::a ; 0.2::b.
;; (implicit null has prob 0.5)
;; query(a). => 0.3
;; query(b). => 0.2

!(:: ((0.3 (a)) (0.2 (b))))
!(test-prob (?prob (a)) 0.3)
!(test-prob (?prob (b)) 0.2)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 14: Prob rule (::=>)        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; 0.7::burglary.
;; 0.9::alarm :- burglary.
;; query(alarm). => 0.7 * 0.9 = 0.63

!(:: 0.7 (burglary))
!(::=> 0.9 (alarm) (, (burglary)))
!(test-prob (?prob (alarm)) 0.63)

!(clear-prob!)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test 15: Deterministic fact      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProbLog:
;; person(mary).
;; 0.7::burglary. 0.8::calls(X) :- burglary, person(X).
;; query(calls(mary)). => 0.7 * 0.8 = 0.56

!(fact (person mary))
!(:: 0.7 (burglary))
!(::=> 0.8 (calls $x) (, (burglary) (person $x)))
!(test-prob (?prob (calls mary)) 0.56)