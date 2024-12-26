;; Define token
(define-fungible-token wellfit-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-activity (err u101))
(define-constant err-invalid-verifier (err u102))
(define-constant err-invalid-points (err u106))
(define-constant err-invalid-period (err u107))
(define-constant max-activity-points u1000)
(define-constant max-lock-period u52560) ;; approximately 1 year in blocks

;; Data Variables
(define-map user-achievements
    principal
    {
        total-tokens: uint,
        activity-streak: uint,
        last-activity: uint,
        tier-level: uint
    })

(define-map activity-verifiers
    principal
    bool)

;; Authorization check
(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner))

;; Validate verifier address
(define-private (is-valid-verifier (verifier principal))
    (and 
        (not (is-eq verifier contract-owner))
        (not (is-eq verifier (as-contract tx-sender)))))

;; Add authorized verifier
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (asserts! (is-valid-verifier verifier) err-invalid-verifier)
        (ok (map-set activity-verifiers verifier true))))

;; Record verified activity and mint tokens
(define-public (record-activity (user principal) (activity-type uint) (activity-points uint))
    (begin
        ;; Check activity points are within bounds
        (asserts! (<= activity-points max-activity-points) err-invalid-points)
        (let ((current-time block-height))
            (asserts! (is-some (map-get? activity-verifiers tx-sender)) err-invalid-verifier)
            (let ((user-stats (default-to
                {
                    total-tokens: u0,
                    activity-streak: u0,
                    last-activity: u0,
                    tier-level: u1
                }
                (map-get? user-achievements user))))
                
                ;; Calculate rewards with streak bonus
                (let ((streak-bonus (if (is-eq (+ (get last-activity user-stats) u1) current-time)
                                    (+ u1 (get activity-streak user-stats))
                                    u1)))
                    
                    ;; Calculate safe token amount using if instead of min
                    (let ((safe-token-amount 
                            (if (> (* activity-points streak-bonus) max-activity-points)
                                max-activity-points
                                (* activity-points streak-bonus))))
                        
                        ;; Update user achievements
                        (map-set user-achievements
                            user
                            {
                                total-tokens: (+ (get total-tokens user-stats) safe-token-amount),
                                activity-streak: streak-bonus,
                                last-activity: current-time,
                                tier-level: (calculate-tier (get total-tokens user-stats))
                            })
                        
                        ;; Mint tokens with streak bonus
                        (ok (try! (ft-mint? wellfit-token safe-token-amount user)))))))))

;; Calculate user tier based on total tokens
(define-private (calculate-tier (total-tokens uint))
    (if (>= total-tokens u10000)
        u4  ;; Diamond tier
        (if (>= total-tokens u5000)
            u3  ;; Gold tier
            (if (>= total-tokens u1000)
                u2  ;; Silver tier
                u1)))) ;; Bronze tier

;; Get user stats
(define-read-only (get-user-stats (user principal))
    (map-get? user-achievements user))

;; Time-locked rewards vault
(define-map locked-rewards
    principal
    {
        amount: uint,
        unlock-height: uint
    })

;; Lock tokens for time-based challenge
(define-public (lock-tokens-challenge (amount uint) (lock-period uint))
    (begin
        ;; Check lock period is within bounds
        (asserts! (<= lock-period max-lock-period) err-invalid-period)
        (let ((unlock-height (+ block-height lock-period)))
            (begin
                (asserts! (>= (ft-get-balance wellfit-token tx-sender) amount)
                         (err u103))
                (try! (ft-transfer? wellfit-token amount tx-sender (as-contract tx-sender)))
                (ok (map-set locked-rewards
                    tx-sender
                    {
                        amount: amount,
                        unlock-height: unlock-height
                    }))))))

;; Claim time-locked rewards with bonus
(define-public (claim-locked-rewards)
    (let ((locked-data (unwrap! (map-get? locked-rewards tx-sender)
                               (err u104))))
        (begin
            (asserts! (>= block-height (get unlock-height locked-data))
                     (err u105))
            (let ((bonus-amount (/ (* (get amount locked-data) u10) u100)))
                (begin
                    (try! (as-contract
                        (ft-transfer? wellfit-token
                                    (+ (get amount locked-data) bonus-amount)
                                    (as-contract tx-sender)
                                    tx-sender)))
                    (map-delete locked-rewards tx-sender)
                    (ok true))))))