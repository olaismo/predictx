(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-MARKET-CLOSED (err u101))
(define-constant ERR-MARKET-OPEN (err u102))
(define-constant ERR-MARKET-NOT-FOUND (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-NOT-RESOLVED (err u105))
(define-constant ERR-ALREADY-CLAIMED (err u106))
(define-constant ERR-INVALID-VOTE (err u107))
(define-constant ERR-NOT-ORACLE (err u108))
(define-constant ERR-DISPUTE-ALREADY (err u109))
(define-constant ERR-INVALID-RESOLUTION (err u110))
(define-constant ERR-NOT-FOUND (err u111))
(define-constant ERR-NO-DISPUTE (err u112))

(define-data-var next-market-id uint u1)
(define-data-var dao-admin principal tx-sender)

;; Enum for result: none = u0, yes = u1, no = u2
(define-map markets
  { id: uint }
  {
    creator: principal,
    question: (string-ascii 100),
    deadline: uint,
    oracle: principal,
    resolved: bool,
    result: uint,
    total-yes: uint,
    total-no: uint,
    disputed: bool
  }
)

;; Who voted what and how much
(define-map votes
  { market-id: uint, voter: principal }
  {
    choice: uint, ;; u1 = yes, u2 = no
    amount: uint,
    claimed: bool
  }
)

;; ========== MARKET CREATION ==========

(define-public (create-market (question (string-ascii 100)) (deadline uint) (oracle principal))
  (let ((id (var-get next-market-id)))
    (begin
      (asserts! (> deadline burn-block-height) ERR-MARKET-CLOSED)
      (map-set markets { id: id }
        { creator: tx-sender,
          question: question,
          deadline: deadline,
          oracle: oracle,
          resolved: false,
          result: u0,
          total-yes: u0,
          total-no: u0,
          disputed: false })
      (var-set next-market-id (+ id u1))
      (ok id)
    )
  )
)

;; ========== VOTING ==========

(define-public (vote-market (market-id uint) (choice uint))
  (let ((market (map-get? markets { id: market-id })))
    (match market
      market-data
        (begin
          (asserts! (or (is-eq choice u1) (is-eq choice u2)) ERR-INVALID-VOTE)
          (asserts! (< burn-block-height (get deadline market-data)) ERR-MARKET-CLOSED)
          (asserts! (is-none (map-get? votes { market-id: market-id, voter: tx-sender })) ERR-ALREADY-VOTED)

          ;; Record the vote (amount must be passed as an argument)
          ;; TODO: Add amount as a parameter to this function and use it here
          (err u998) ;; Not implemented: pass amount as argument
        )
      ERR-MARKET-NOT-FOUND
    )
  )
)

;; ========== CLOSE MARKET & ORACLE RESOLUTION ==========

(define-public (resolve-market (market-id uint) (result uint))
  (let ((market (map-get? markets { id: market-id })))
    (match market
      market-data
        (begin
          (asserts! (>= burn-block-height (get deadline market-data)) ERR-MARKET-OPEN)
          (asserts! (is-eq tx-sender (get oracle market-data)) ERR-NOT-ORACLE)
          (asserts! (not (get resolved market-data)) ERR-INVALID-RESOLUTION)
          (asserts! (or (is-eq result u1) (is-eq result u2)) ERR-INVALID-VOTE)

          ;; Set result
            (map-set markets { id: market-id }
              (merge market-data { resolved: true, result: result }))
          (ok true)
        )
      ERR-MARKET-NOT-FOUND
    )
  )
)

;; ========== CLAIM REWARDS ==========

(define-public (claim-reward (market-id uint))
  (let ((market (map-get? markets { id: market-id }))
        (user-vote (map-get? votes { market-id: market-id, voter: tx-sender })))
    (match market
      market-data
        (begin
          (asserts! (get resolved market-data) ERR-NOT-RESOLVED)
          (match user-vote
            vote-data
              (begin
                (asserts! (not (get claimed vote-data)) ERR-ALREADY-CLAIMED)
                (let ((win-side (get result market-data))
                     (user-side (get choice vote-data))
                     (user-amt (get amount vote-data))
                     (total-yes (get total-yes market-data))
                     (total-no (get total-no market-data)))
                  (if (is-eq user-side win-side)
                    (let ((losing-pool (if (is-eq win-side u1) total-no total-yes))
                         (winning-pool (if (is-eq win-side u1) total-yes total-no))
                         (reward (+ user-amt (/ (* user-amt losing-pool) winning-pool))))
                      (begin
                        (map-set votes { market-id: market-id, voter: tx-sender }
                          (merge vote-data { claimed: true }))
                        ;; Payout (TODO: replace with stx-transfer?)
                        (ok reward)
                      )
                    )
                    (err u999) ;; lost, no reward
                  )
                )
              )
            ERR-NOT-FOUND
          )
        )
      ERR-MARKET-NOT-FOUND
    )
  )
)

;; ========== DISPUTES ==========

(define-public (flag-dispute (market-id uint))
  (let ((market (map-get? markets { id: market-id })))
    (match market
      market-data
        (begin
          (asserts! (get resolved market-data) ERR-NOT-RESOLVED)
          (asserts! (not (get disputed market-data)) ERR-DISPUTE-ALREADY)
          ;; Anyone can flag dispute
            (map-set markets { id: market-id }
              (merge market-data { disputed: true }))
          (ok true)
        )
      ERR-MARKET-NOT-FOUND
    )
  )
)

(define-public (dao-resolve-market (market-id uint) (new-result uint))
  (let ((market (map-get? markets { id: market-id })))
    (match market
      market-data
        (begin
          (asserts! (is-eq tx-sender (var-get dao-admin)) ERR-NOT-ORACLE)
          (asserts! (get disputed market-data) ERR-NO-DISPUTE)
          (asserts! (or (is-eq new-result u1) (is-eq new-result u2)) ERR-INVALID-RESOLUTION)
            (map-set markets { id: market-id }
              (merge market-data { result: new-result }))
          (ok true)
        )
      ERR-MARKET-NOT-FOUND
    )
  )
)

;; ========== READ-ONLY FUNCTIONS ==========

(define-read-only (get-market (market-id uint))
  (map-get? markets { id: market-id })
)

(define-read-only (get-user-vote (market-id uint) (user principal))
  (map-get? votes { market-id: market-id, voter: user })
)

(define-read-only (get-next-id)
  (var-get next-market-id)
)
