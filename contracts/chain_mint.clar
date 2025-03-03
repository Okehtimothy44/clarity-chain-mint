;; Define NFT for physical assets
(define-non-fungible-token physical-asset uint)

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-asset-exists (err u101))
(define-constant err-invalid-asset (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-string (err u104))

;; String length constants
(define-constant max-name-length u64)
(define-constant max-symbol-length u10)
(define-constant max-asset-name-length u256)

;; Data vars
(define-data-var next-asset-id uint u1)

;; Maps
(define-map asset-classes 
  { class-id: uint }
  { name: (string-ascii 64),
    symbol: (string-ascii 10) })

(define-map asset-details
  { asset-id: uint }
  { owner: principal,
    class-id: uint,
    name: (string-ascii 256),
    metadata: (optional (string-utf8 1024)),
    verified: bool })

;; Helper functions
(define-private (is-valid-string (str (string-ascii 256)))
  (not (is-eq str "")))

(define-private (emit-asset-transfer (asset-id uint) (from principal) (to principal))
  (print { type: "asset-transfer", asset-id: asset-id, from: from, to: to }))

;; Create new asset class - admin only
(define-public (create-asset-class (name (string-ascii 64)) (symbol (string-ascii 10)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (is-valid-string name) (is-valid-string symbol)) err-invalid-string)
    (let ((class-id (var-get next-asset-id)))
      (map-set asset-classes
        { class-id: class-id }
        { name: name,
          symbol: symbol })
      (var-set next-asset-id (+ class-id u1))
      (print { type: "asset-class-created", class-id: class-id })
      (ok class-id))))

;; Mint new asset token
(define-public (mint-asset 
  (recipient principal)
  (name (string-ascii 256))
  (metadata (optional (string-utf8 1024)))
  (class-id uint))
  (begin
    (asserts! (is-valid-string name) err-invalid-string)
    (let ((asset-id (var-get next-asset-id)))
      (asserts! (map-get? asset-classes { class-id: class-id }) err-invalid-asset)
      (try! (nft-mint? physical-asset asset-id recipient))
      (map-set asset-details
        { asset-id: asset-id }
        { owner: recipient,
          class-id: class-id,
          name: name,
          metadata: metadata,
          verified: false })
      (var-set next-asset-id (+ asset-id u1))
      (print { type: "asset-minted", asset-id: asset-id })
      (ok asset-id))))

;; Transfer asset ownership
(define-public (transfer-asset 
  (asset-id uint)
  (sender principal)
  (recipient principal))
  (begin
    (asserts! (not (is-eq recipient sender)) err-unauthorized)
    (let ((asset (map-get? asset-details { asset-id: asset-id })))
      (asserts! (and
        (is-some asset)
        (is-eq (get owner (unwrap-panic asset)) sender)) err-unauthorized)
      (try! (nft-transfer? physical-asset asset-id sender recipient))
      (map-set asset-details
        { asset-id: asset-id }
        (merge (unwrap-panic asset)
          { owner: recipient }))
      (emit-asset-transfer asset-id sender recipient)
      (ok true))))

;; Get assets owned by address
(define-read-only (get-owner-assets (owner principal))
  (ok (filter asset-details
    (lambda (entry)
      (is-eq (get owner entry) owner)))))

;; Existing functions remain unchanged...
