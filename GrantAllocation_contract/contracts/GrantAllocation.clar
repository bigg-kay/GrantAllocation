
;; title: GrantAllocation
;; version: 1.0.0
;; summary: A transparent research funding platform for academic project prioritization and resource distribution
;; description: This contract manages grant pools, proposal submissions, voting mechanisms, and fund allocation for academic research projects

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-voting-closed (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-invalid-status (err u106))
(define-constant err-unauthorized (err u107))

;; data vars
(define-data-var next-grant-id uint u1)
(define-data-var next-proposal-id uint u1)

;; data maps
;; Grant pool information
(define-map grants
    uint ;; grant-id
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        total-funds: uint,
        allocated-funds: uint,
        creator: principal,
        created-at: uint,
        voting-end: uint,
        status: (string-ascii 20) ;; "active", "closed", "distributed"
    }
)

;; Research proposals submitted to grants
(define-map proposals
    uint ;; proposal-id
    {
        grant-id: uint,
        title: (string-ascii 100),
        description: (string-ascii 1000),
        requested-amount: uint,
        researcher: principal,
        submitted-at: uint,
        votes: uint,
        status: (string-ascii 20) ;; "pending", "approved", "rejected", "funded"
    }
)

;; Voting records to prevent double voting
(define-map votes
    {voter: principal, proposal-id: uint}
    {voted-at: uint, weight: uint}
)

;; Grant administrators (can create grants and manage funds)
(define-map administrators
    principal
    bool
)

;; Researcher profiles and reputation
(define-map researchers
    principal
    {
        name: (string-ascii 50),
        institution: (string-ascii 100),
        reputation-score: uint,
        total-grants-received: uint,
        successful-projects: uint
    }
)

;; public functions

;; Initialize contract owner as first administrator
(define-public (initialize)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set administrators contract-owner true))
    )
)

;; Add or remove administrators
(define-public (set-administrator (admin principal) (is-admin bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set administrators admin is-admin))
    )
)

;; Create a new grant pool
(define-public (create-grant (title (string-ascii 100)) (description (string-ascii 500)) (total-funds uint) (voting-duration uint))
    (let
        (
            (grant-id (var-get next-grant-id))
            (current-block block-height)
        )
        (asserts! (default-to false (map-get? administrators tx-sender)) err-unauthorized)
        (asserts! (> total-funds u0) err-invalid-amount)
        (map-set grants grant-id
            {
                title: title,
                description: description,
                total-funds: total-funds,
                allocated-funds: u0,
                creator: tx-sender,
                created-at: current-block,
                voting-end: (+ current-block voting-duration),
                status: "active"
            }
        )
        (var-set next-grant-id (+ grant-id u1))
        (ok grant-id)
    )
)

;; Submit a research proposal
(define-public (submit-proposal (grant-id uint) (title (string-ascii 100)) (description (string-ascii 1000)) (requested-amount uint))
    (let
        (
            (proposal-id (var-get next-proposal-id))
            (grant-info (unwrap! (map-get? grants grant-id) err-not-found))
        )
        (asserts! (is-eq (get status grant-info) "active") err-invalid-status)
        (asserts! (> (get voting-end grant-info) block-height) err-voting-closed)
        (asserts! (> requested-amount u0) err-invalid-amount)
        (asserts! (<= requested-amount (- (get total-funds grant-info) (get allocated-funds grant-info))) err-insufficient-funds)

        (map-set proposals proposal-id
            {
                grant-id: grant-id,
                title: title,
                description: description,
                requested-amount: requested-amount,
                researcher: tx-sender,
                submitted-at: block-height,
                votes: u0,
                status: "pending"
            }
        )
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
            (grant-info (unwrap! (map-get? grants (get grant-id proposal)) err-not-found))
            (vote-key {voter: tx-sender, proposal-id: proposal-id})
        )
        (asserts! (is-none (map-get? votes vote-key)) err-already-voted)
        (asserts! (> (get voting-end grant-info) block-height) err-voting-closed)
        (asserts! (is-eq (get status proposal) "pending") err-invalid-status)

        (map-set votes vote-key {voted-at: block-height, weight: u1})
        (map-set proposals proposal-id
            (merge proposal {votes: (+ (get votes proposal) u1)})
        )
        (ok true)
    )
)

;; Approve proposal for funding (admin only)
(define-public (approve-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
            (grant-info (unwrap! (map-get? grants (get grant-id proposal)) err-not-found))
        )
        (asserts! (default-to false (map-get? administrators tx-sender)) err-unauthorized)
        (asserts! (is-eq (get status proposal) "pending") err-invalid-status)
        (asserts! (<= (+ (get allocated-funds grant-info) (get requested-amount proposal)) (get total-funds grant-info)) err-insufficient-funds)

        (map-set proposals proposal-id
            (merge proposal {status: "approved"})
        )
        (map-set grants (get grant-id proposal)
            (merge grant-info {allocated-funds: (+ (get allocated-funds grant-info) (get requested-amount proposal))})
        )
        (ok true)
    )
)

;; Distribute funds to approved proposal
(define-public (distribute-funds (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
        )
        (asserts! (default-to false (map-get? administrators tx-sender)) err-unauthorized)
        (asserts! (is-eq (get status proposal) "approved") err-invalid-status)

        ;; In a real implementation, this would transfer STX tokens
        ;; For now, we just update the status
        (map-set proposals proposal-id
            (merge proposal {status: "funded"})
        )

        ;; Update researcher profile
        (update-researcher-profile (get researcher proposal) (get requested-amount proposal))
        (ok true)
    )
)

;; Register researcher profile
(define-public (register-researcher (name (string-ascii 50)) (institution (string-ascii 100)))
    (begin
        (map-set researchers tx-sender
            {
                name: name,
                institution: institution,
                reputation-score: u100,
                total-grants-received: u0,
                successful-projects: u0
            }
        )
        (ok true)
    )
)

;; Close grant voting period
(define-public (close-grant (grant-id uint))
    (let
        (
            (grant-info (unwrap! (map-get? grants grant-id) err-not-found))
        )
        (asserts! (default-to false (map-get? administrators tx-sender)) err-unauthorized)
        (asserts! (is-eq (get status grant-info) "active") err-invalid-status)

        (map-set grants grant-id
            (merge grant-info {status: "closed"})
        )
        (ok true)
    )
)

;; read only functions

;; Get grant information
(define-read-only (get-grant (grant-id uint))
    (map-get? grants grant-id)
)

;; Get proposal information
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

;; Get researcher profile
(define-read-only (get-researcher (researcher principal))
    (map-get? researchers researcher)
)

;; Check if user is administrator
(define-read-only (is-administrator (user principal))
    (default-to false (map-get? administrators user))
)

;; Check if user has voted on proposal
(define-read-only (has-voted (voter principal) (proposal-id uint))
    (is-some (map-get? votes {voter: voter, proposal-id: proposal-id}))
)

;; Get total number of grants
(define-read-only (get-total-grants)
    (- (var-get next-grant-id) u1)
)

;; Get total number of proposals
(define-read-only (get-total-proposals)
    (- (var-get next-proposal-id) u1)
)

;; Get remaining funds in grant
(define-read-only (get-remaining-funds (grant-id uint))
    (match (map-get? grants grant-id)
        grant-info (ok (- (get total-funds grant-info) (get allocated-funds grant-info)))
        err-not-found
    )
)

;; private functions

;; Update researcher profile after receiving funding
(define-private (update-researcher-profile (researcher principal) (amount uint))
    (match (map-get? researchers researcher)
        profile (map-set researchers researcher
            (merge profile
                {
                    total-grants-received: (+ (get total-grants-received profile) amount),
                    reputation-score: (+ (get reputation-score profile) u10)
                }
            )
        )
        ;; Create default profile if doesn't exist
        (map-set researchers researcher
            {
                name: "",
                institution: "",
                reputation-score: u110,
                total-grants-received: amount,
                successful-projects: u0
            }
        )
    )
)
