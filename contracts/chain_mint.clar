;; Define NFT for physical assets
(define-non-fungible-token physical-asset uint)

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-asset-exists (err u101))
(define-constant err-invalid-asset (err u102))
(define-constant err-unauthorized (err u103))

;; Data vars
(define-data-var next-asset-id uint u1)
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

;; Create new asset class - admin only
(define-public (create-asset-class (name (string-ascii 64)) (symbol (string-ascii 10)))
  (if (is-eq tx-sender contract-owner)
    (let ((class-id (var-get next-asset-id)))
      (map-set asset-classes
        { class-id: class-id }
        { name: name,
          symbol: symbol })
      (var-set next-asset-id (+ class-id u1))
      (ok class-id))
    err-owner-only))

;; Mint new asset token
(define-public (mint-asset 
  (recipient principal)
  (name (string-ascii 256))
  (metadata (optional (string-utf8 1024)))
  (class-id uint))
  (let ((asset-id (var-get next-asset-id)))
    (if (map-get? asset-classes { class-id: class-id })
      (begin
        (try! (nft-mint? physical-asset asset-id recipient))
        (map-set asset-details
          { asset-id: asset-id }
          { owner: recipient,
            class-id: class-id,
            name: name,
            metadata: metadata,
            verified: false })
        (var-set next-asset-id (+ asset-id u1))
        (ok asset-id))
      err-invalid-asset)))

;; Transfer asset ownership
(define-public (transfer-asset 
  (asset-id uint)
  (sender principal)
  (recipient principal))
  (let ((asset (map-get? asset-details { asset-id: asset-id })))
    (if (and
      (is-some asset)
      (is-eq (get owner (unwrap-panic asset)) sender))
      (begin
        (try! (nft-transfer? physical-asset asset-id sender recipient))
        (map-set asset-details
          { asset-id: asset-id }
          (merge (unwrap-panic asset)
            { owner: recipient }))
        (ok true))
      err-unauthorized)))

;; Verify asset - admin only
(define-public (verify-asset (asset-id uint))
  (if (is-eq tx-sender contract-owner)
    (let ((asset (map-get? asset-details { asset-id: asset-id })))
      (if (is-some asset)
        (begin
          (map-set asset-details
            { asset-id: asset-id }
            (merge (unwrap-panic asset)
              { verified: true }))
          (ok true))
        err-invalid-asset))
    err-owner-only))

;; Read only functions
(define-read-only (get-asset-details (asset-id uint))
  (ok (map-get? asset-details { asset-id: asset-id })))

(define-read-only (get-asset-class (class-id uint))
  (ok (map-get? asset-classes { class-id: class-id })))
