;; FundForge Smart Contract

;; Define campaign state values
(define-constant STATE-LIVE u1)
(define-constant STATE-SUCCESSFUL u2)
(define-constant STATE-CANCELED u3)
(define-constant STATE-TIMEOUT u4)

;; Additional error constant for timeframe validation
(define-constant ERR_INVALID_TIMEFRAME (err u111))

(define-map campaigns 
    uint 
    {
        owner: principal, 
        target: uint, 
        amount-collected: uint, 
        checkpoints: uint, 
        checkpoints-achieved: uint,
        state: uint,
        canceled: bool,
        end-block: uint
    })

(define-map backers 
    {
        campaign-id: uint, 
        supporter: principal
    } 
    uint)

(define-data-var campaign-counter uint u0)

;; Error constants
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u100))
(define-constant ERR_CAMPAIGN_FUNDED (err u101))
(define-constant ERR_CAMPAIGN_FAILED (err u102))
(define-constant ERR_NOT_AUTHORIZED (err u103))
(define-constant ERR_CHECKPOINTS_NOT_MET (err u104))
(define-constant ERR_INVALID_TARGET (err u105))
(define-constant ERR_INVALID_CHECKPOINTS (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))
(define-constant ERR_INVALID_CAMPAIGN_ID (err u108))
(define-constant ERR_INVALID_STATE (err u109))
(define-constant ERR_CAMPAIGN_EXPIRED (err u110))

;; Helper functions for validation
(define-private (is-valid-target (target uint))
    (> target u0))

(define-private (is-valid-checkpoints (checkpoints uint))
    (and (> checkpoints u0) (<= checkpoints u10)))

(define-private (is-valid-timeframe (timeframe uint))
    (and 
        (> timeframe u0)
        (<= timeframe u52560) ;; Max 1 year in blocks (assuming 10-minute blocks)
    ))

(define-private (is-valid-campaign-id (campaign-id uint))
    (< campaign-id (var-get campaign-counter)))

(define-private (is-live (campaign uint))
    (let ((campaign-data (unwrap! (map-get? campaigns campaign) false)))
        (is-eq (get state campaign-data) STATE-LIVE)))

(define-private (is-expired (campaign uint))
    (let ((campaign-data (unwrap! (map-get? campaigns campaign) false)))
        (and (is-eq (get state campaign-data) STATE-LIVE)
             (>= stacks-block-height (get end-block campaign-data)))))

(define-public (launch-campaign (target uint) (checkpoints uint) (timeframe uint))
    (begin
        (asserts! (is-valid-target target) ERR_INVALID_TARGET)
        (asserts! (is-valid-checkpoints checkpoints) ERR_INVALID_CHECKPOINTS)
        (asserts! (is-valid-timeframe timeframe) ERR_INVALID_TIMEFRAME)
        (let ((id (var-get campaign-counter)))
            (map-set campaigns id {
                owner: tx-sender, 
                target: target, 
                amount-collected: u0, 
                checkpoints: checkpoints, 
                checkpoints-achieved: u0,
                state: STATE-LIVE,
                canceled: false,
                end-block: (+ stacks-block-height timeframe)
            })
            (var-set campaign-counter (+ id u1))
            (ok id)
        )
    )
)

(define-public (back-campaign (campaign-id uint) (amount uint))
    (begin
        (asserts! (is-valid-campaign-id campaign-id) ERR_INVALID_CAMPAIGN_ID)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (is-live campaign-id) ERR_INVALID_STATE)
        (asserts! (not (is-expired campaign-id)) ERR_CAMPAIGN_EXPIRED)
        (let ((campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND)))
            (let ((amount-collected (get amount-collected campaign)))
                (if (< amount-collected (get target campaign))
                    (let ((new-amount (+ amount-collected amount)))
                        (begin
                            (try! (stx-transfer? amount tx-sender (get owner campaign)))
                            (map-set campaigns campaign-id (merge campaign {amount-collected: new-amount}))
                            (map-set backers {campaign-id: campaign-id, supporter: tx-sender} amount)
                            (ok true)
                        ))
                    (ok false)
                )
            )
        )
    )
)

(define-public (achieve-checkpoint (campaign-id uint))
    (begin
        (asserts! (is-valid-campaign-id campaign-id) ERR_INVALID_CAMPAIGN_ID)
        (asserts! (is-live campaign-id) ERR_INVALID_STATE)
        (asserts! (not (is-expired campaign-id)) ERR_CAMPAIGN_EXPIRED)
        (let ((campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND)))
            (asserts! (is-eq tx-sender (get owner campaign)) ERR_NOT_AUTHORIZED)
            (let ((checkpoints-achieved (get checkpoints-achieved campaign))
                  (checkpoints (get checkpoints campaign)))
                (if (< checkpoints-achieved checkpoints)
                    (let ((new-checkpoints-achieved (+ checkpoints-achieved u1)))
                        (map-set campaigns campaign-id 
                            (merge campaign {
                                checkpoints-achieved: new-checkpoints-achieved,
                                state: (if (is-eq new-checkpoints-achieved checkpoints) 
                                            STATE-SUCCESSFUL 
                                            STATE-LIVE)
                            }))
                        (ok true))
                    ERR_CHECKPOINTS_NOT_MET
                )
            )
        )
    )
)

(define-public (claim-funds (campaign-id uint))
    (begin
        (asserts! (is-valid-campaign-id campaign-id) ERR_INVALID_CAMPAIGN_ID)
        (asserts! (not (is-expired campaign-id)) ERR_CAMPAIGN_EXPIRED)
        (let ((campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND)))
            (asserts! (is-eq tx-sender (get owner campaign)) ERR_NOT_AUTHORIZED)
            (asserts! (is-eq (get state campaign) STATE-SUCCESSFUL) ERR_CHECKPOINTS_NOT_MET)
            (let ((checkpoints-achieved (get checkpoints-achieved campaign))
                  (target (get target campaign))
                  (amount-collected (get amount-collected campaign)))
                (if (>= amount-collected target)
                    (begin
                        (try! (stx-transfer? 
                            (* (/ checkpoints-achieved (get checkpoints campaign)) amount-collected) 
                            (get owner campaign) 
                            tx-sender))
                        (ok true))
                    (ok false)
                )
            )
        )
    )
)

(define-private (handle-withdrawal (campaign-id uint))
    (let ((campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND)))
        (if (or (< (get checkpoints-achieved campaign) (get checkpoints campaign))
                (is-expired campaign-id))
            (let ((backing (unwrap! (map-get? backers {campaign-id: campaign-id, supporter: tx-sender}) ERR_CAMPAIGN_FAILED)))
                (begin
                    (try! (stx-transfer? backing (get owner campaign) tx-sender))
                    (map-set campaigns campaign-id 
                        (merge campaign {
                            state: STATE-CANCELED,
                            canceled: true
                        }))
                    (ok true))
            )
            (ok false)
        )
    )
)

(define-public (withdraw-backing (campaign-id uint))
    (begin
        (asserts! (is-valid-campaign-id campaign-id) ERR_INVALID_CAMPAIGN_ID)
        (let ((campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND)))
            (if (is-eq (get state campaign) STATE-LIVE)
                (handle-withdrawal campaign-id)
                ERR_INVALID_STATE
            )
        )
    )
)