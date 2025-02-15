(namespace "free")
(define-keyset "free.km-test" (read-keyset "km-test"))
(module ktest001 GOVERNANCE
  ;-----------------------------------------------------------------------------
  ; Imports
  ;-----------------------------------------------------------------------------
  (use n_5caec7ffe20c6e09fd632fb1ee04468848966332.ng-poly-fungible-v1 
    [ account-details 
      sender-balance-change 
      receiver-balance-change
    ])
  (use free.util-strings [to-string starts-with])
  (use free.util-time [time-between now from-now])
  (use kip.token-manifest)
  (use free.util-fungible 
    [ enforce-precision 
      enforce-reserved 
      enforce-valid-account 
      enforce-valid-transfer 
      enforce-valid-amount
    ])
  (use free.guards)
  (use n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger)
  (use n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.policy-collection)
  (use free.kmpasstest003 [get-priority-users burn get-pass-balance])

  ;-----------------------------------------------------------------------------
  ; Blessed Hashes
  ;-----------------------------------------------------------------------------
  (bless "X9E1JykXF0hkh81MUxo1KWxrBIW0uyD5j01GAPScQw4")
  (bless "ZRBWB_S-f3L0kf4Lop2ZqZa2cxBD27EDe6f3nfpraMA")

  ;-----------------------------------------------------------------------------
  ; Constants
  ;-----------------------------------------------------------------------------
  (defconst name:string "n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db")
  (defconst PRIORITY-CONST:string "PRIORITY")
  (defconst KRYPTOMERCH_BANK "Kryptomerch-Bank")
  (defconst LAUNCHPAD_ACC:string "k:56609bf9d1983f0c13aaf3bd3537fe00db65eb15160463bb641530143d4e9bcf")
  (defconst LAUNCH:string "launch")
  (defconst PRIME:string "Prime")
  (defconst DISCOUNT:string "Discount")
  (defconst FEE:string "fee")
  (defconst MAX_MINT_PER_TX:integer 10)
  (defconst MIN_PRICE:decimal 0.000001)
  (defconst MAX_ROYALTY_PERCENTAGE:decimal 1.0)
  (defconst MAX_SUPPLY_LIMIT:integer 10000)

  ;-----------------------------------------------------------------------------
  ; Schema Definitions
  ;-----------------------------------------------------------------------------
  (defschema collection-details
    @doc "Comprehensive collection information and configuration"
    collection-name:string  ; Primary identifier
    symbol:string          ; Collection symbol
    collection-id:string   ; Unique chain identifier
    launched:bool         ; Launch status
    creator:string        ; Creator account
    creator-guard:guard   ; Creator's guard
    description:string    ; Collection description
    category:string       ; Collection category
    total-supply:integer  ; Maximum supply
    urisIPFS:string      ; IPFS URI base
    mint-price:decimal    ; Public mint price
    wl-price:decimal     ; Whitelist price
    royalty-percentage:decimal  ; Creator royalties (0.0-1.0)
    royalty-address:string      ; Royalty recipient
    cover-image-url:string     ; Cover image
    banner-image-url:string    ; Banner image

    ; Timing controls
    mint-start-date:string
    mint-start-time:time
    mint-end-date:string
    mint-end-time:time

    ; Feature flags
    allow-free-mints:bool
    enable-whitelist:bool
    enable-presale:bool
    enable-airdrop:bool

    ; Whitelist configuration
    whitelist-addresses:[string]
    whitelist-start-time:time

    ; Presale configuration
    presale-addresses:[string]
    presale-start-date:string
    presale-start-time:time
    presale-end-date:string
    presale-end-time:time
    presale-mint-price:decimal

    ; Airdrop configuration
    airdrop-supply:integer
    airdrop-addresses:[string]

    ; State tracking
    current-index:integer
    policy:string
    created-time:time
    last-updated:time
    total-minted:integer
    total-sales:decimal)

  (defschema token-record-schema
    @doc "Token URI tracking and management"
    uri-list:[string]     ; List of token URIs
    current-length:integer ; Current count
    max-length:integer    ; Maximum allowed
    last-updated:time     ; Last modification time
    created-by:string     ; Creator account
    is-frozen:bool)       ; Freeze status
    
    (defschema mint-count-schema
    account:string
    count:integer
    )

  (defschema token-ledger-schema
    @doc "Token supply management"
    current-length:integer   ; Current supply
    max-supply:integer      ; Maximum supply
    last-mint-time:time     ; Last mint timestamp
    total-minted:integer    ; Total minted count
   )
   
   (defschema collection-status
       @doc "Status tracking for collection state"
       request-exists:bool
       collection-exists:bool
       status:string
   )


  (defschema nft-info
    @doc "NFT ownership and metadata"
    owner:string           ; Current owner
    token-id:string        ; Unique token ID
    collection-name:string ; Parent collection
    collection-id:string   ; Collection identifier
    minted-time:time      ; Mint timestamp
    mint-price:decimal    ; Original mint price
    transaction-hash:string ; Minting transaction
    metadata:object        ; Token metadata
    transfer-count:integer ; Number of transfers
    last-transfer-time:time) ; Last transfer time

  (defschema account-schema
    @doc "Account minting and activity tracking"
    account:string         ; Account identifier
    guard:guard           ; Account guard
    minted:integer        ; Total mints
    last-mint-time:time   ; Last mint time
    total-spent:decimal   ; Total spent on mints
    collections:[string]  ; Participated collections
    roles:[string]       ; Account roles
    created-time:time    ; Account creation time
    last-active:time)    ; Last activity time

  (defschema reservation
    @doc "Presale reservation details"
    account:string        ; Reserved for
    guard:guard          ; Account guard
    amount-nft:integer   ; Reserved amount
    price:decimal        ; Reserved price
    reservation-time:time ; Reservation time
    expiry-time:time     ; Reservation expiry
    status:string        ; Reservation status
    collection-name:string) ; Target collection

  (defschema minted-token
    @doc "Minted token tracking"
    collection-name:string ; Parent collection
    account:string       ; Minting account
    guard:guard         ; Account guard
    accountId:integer   ; Account identifier
    marmToken:string    ; Token identifier
    revealed:bool       ; Reveal status
    mint-time:time      ; Mint timestamp
    mint-price:decimal  ; Mint price
    mint-type:string)   ; Mint type (public/wl/presale)

  (defschema whitelist-schema
    @doc "Whitelist participation tracking"
    account:string      ; Whitelisted account
    guard:guard        ; Account guard
    claimed:integer    ; Claimed amount
    max-allowed:integer ; Maximum allowed
    expiry:time        ; Whitelist expiry
    mint-price:decimal ; Special price
    added-by:string    ; Admin who added
    added-time:time)   ; Time added

  (defschema priority-schema
    @doc "Priority access management"
    account:string     ; Priority account
    guard:guard       ; Account guard
    priority-level:integer ; Access level
    expiry:time       ; Priority expiry
    granted-by:string ; Admin who granted
    granted-time:time ; Time granted
    claimed:bool      ; Whether priority has been claimed
  )

  (defschema account-token-info
    @doc "Account token holdings"
    account:string     ; Owner account
    collection-name:string ; Collection name
    tokens:[string]    ; Owned tokens
    last-updated:time  ; Last update time
    total-value:decimal) ; Total value held

  (defschema free-mint-schema
    @doc "Free mint configuration"
    total-supply:integer ; Total free supply
    current-index:integer ; Current index
    start-time:time     ; Start time
    end-time:time       ; End time
    is-active:bool      ; Active status
    max-per-account:integer ; Per-account limit
    accounts-claimed:[string]) ; Claimed accounts

  (defschema free-mint-account-schema
    @doc "Free mint account tracking"
    account:string     ; Claiming account
    collection-name:string ; Collection name
    claimed:bool       ; Claim status
    claim-time:time    ; Claim timestamp
    claim-index:integer) ; Claim position

  (defschema counts-schema
    @doc "General counter tracking"
    count:integer      ; Current count
    last-updated:time  ; Last update
    description:string) ; Counter purpose

  (defschema airdrop-history-schema
    @doc "Airdrop tracking and history"
    collection-name:string ; Collection name
    account:string       ; Recipient
    token-id:string     ; Airdropped token
    airdrop-time:time   ; Time of airdrop
    sender:string       ; Airdrop sender
    transaction-hash:string) ; Transaction hash

  (defschema fee-schema
    @doc "Fee configuration management"
    fee:decimal        ; Base fee
    discount:decimal   ; Discount rate
    minimum-fee:decimal ; Minimum fee
    last-updated:time  ; Last update time
    updated-by:string) ; Admin who updated

  (defschema prime-schema
    @doc "Prime member management"
    accounts:string    ; Prime accounts
    benefits:[string]  ; Prime benefits
    updated-at:time    ; Last update
    updated-by:string) ; Admin who updated

  (defschema discount-schema
    @doc "Discount member management"
    accounts:string    ; Discount accounts
    discount-rate:decimal ; Discount rate
    updated-at:time    ; Last update
    updated-by:string) ; Admin who updated

  (defschema rate-limit-schema
      @doc "Rate limiting configuration"
      state:string           ; active/paused
      last-call:time         ; Last operation time
      call-count:integer     ; Operations in window
      max-calls:integer      ; Maximum calls allowed
      window-seconds:integer ; Time window in seconds
  )

  (defschema operation-log-schema
      @doc "Audit trail for critical operations"
      operation:string    ; Operation type
      account:string      ; Executing account
      timestamp:time      ; Operation time
      details:object      ; Operation details
      status:string      ; Success/failure
      tx-hash:string     ; Transaction hash
  )

  (defschema presale-schema
      collection-name:string
      account:string
      claimed:bool
      claim-time:time
  )

  (defschema pri-col
      collection-name:string
      claimed:bool
  )

  ;-----------------------------------------------------------------------------
  ; Tables
  ;-----------------------------------------------------------------------------
  
  ;; Collection Management Tables
  (deftable collections:{collection-details}
      @doc "Main collection storage with active collections")

  (deftable request-collection-ledger:{collection-details}
      @doc "Pending collection requests awaiting approval")

  ;; Token Management Tables
  (deftable token-record:{token-record-schema}
      @doc "Token URI tracking and metadata storage")

  (deftable token-ledger:{token-ledger-schema}
      @doc "Token supply and minting records")

  ;; NFT Ownership Tables
  (deftable nfts-info-by-id:{nft-info}
      @doc "NFT lookup by token ID with ownership history")

  (deftable nfts-info-by-owner:{nft-info}
      @doc "NFT lookup by owner account")

  ;; Account Management Tables
  (deftable account-details:{account-schema}
      @doc "User account details and activity tracking")

  (deftable accountsInfo:{account-token-info}
      @doc "Account token holdings and activity")

  (deftable minted-tokens:{minted-token}
      @doc "Record of all minted tokens with details")

  (deftable reservations:{reservation}
      @doc "Presale reservation tracking")

  (deftable presale-ledger:{presale-schema}
      @doc "Presale participation records")

  ;; Access Control Tables
  (deftable whitelists:{whitelist-schema}
      @doc "Whitelist participation tracking")

  (deftable priority:{priority-schema}
      @doc "Priority access management")

  (deftable priority-collection:{pri-col}
      @doc "Priority collection access tracking")

  ;; Free Mint Management
  (deftable free-mint-ledger:{free-mint-schema}
      @doc "Free mint allocation tracking")

  (deftable free-mint-account-ledger:{free-mint-account-schema}
      @doc "Per-account free mint claims")

  ;; System Tables
  (deftable counts-table:{counts-schema}
      @doc "System counter tracking")

  (deftable airdrop-history-table:{airdrop-history-schema}
      @doc "Airdrop distribution records")

  ;; Fee and Role Management
  (deftable fee-ledger:{fee-schema}
      @doc "Fee configuration management")

  (deftable prime_role:{prime-schema}
      @doc "Prime member management")

  (deftable discount_role:{discount-schema}
      @doc "Discount member management")

  ;; Security and Monitoring Tables
  (deftable rate-limits:{rate-limit-schema}
      @doc "Operation rate limiting for security")

  (deftable operation-logs:{operation-log-schema}
      @doc "Audit trail for critical operations")




  ;; Table Creation Commands - Run these only once during initial deployment
  ; (create-table collections)
  ; (create-table request-collection-ledger)
  ; (create-table token-record)
  ; (create-table token-ledger)
  ; (create-table nfts-info-by-id)
  ; (create-table nfts-info-by-owner)
  ; (create-table account-details)
  ; (create-table accountsInfo)
  ; (create-table sale-status)
  ; (create-table minted-tokens)
  ; (create-table reservations)
  ; (create-table presale-ledger)
  ; (create-table whitelists)
  ; (create-table priority)
  ; (create-table priority-collection)
  ; (create-table free-mint-ledger)
  ; (create-table free-mint-account-ledger)
  ; (create-table counts-table)
  ; (create-table airdrop-history-table)
  ; (create-table fee-ledger)
  ; (create-table prime_role)
  ; (create-table discount_role)
  ; (create-table rate-limits)
  ; (create-table operation-logs)


;-----------------------------------------------------------------------------
  ; Capabilities
  ;-----------------------------------------------------------------------------

  (defcap GOVERNANCE ()
    @doc "Admin governance capability, highest level access"
    (enforce-guard (keyset-ref-guard "free.km-test"))
    (compose-capability (PRIVATE))
  )

  (defcap PRIVATE ()
    @doc "Private internal capability"
    true
  )

  (defcap IS_ADMIN ()
    @doc "Admin-only operations capability"
    (compose-capability (GOVERNANCE))
  )

  (defcap OWNER (account:string)
    @doc "Verifies account ownership and format"
    (enforce (!= account "") "Account cannot be empty")
    (enforce-valid-account account)
    (enforce-guard (at "guard" (coin.details account)))
  )

  (defcap CREDIT-NFT (receiver:string)
    @doc "Capability for crediting NFTs to receiver"
    (enforce (!= receiver "") "Receiver cannot be empty")
    (enforce-valid-account receiver)
    true
  )

  (defcap MINT-NFT (account:string)
    @doc "Controls NFT minting process"
    @managed
    (enforce (!= account "") "Account cannot be empty")
    (enforce-valid-account account)
    (compose-capability (PRIVATE))
    (compose-capability (CREDIT-NFT account))
    (compose-capability (UPDATE_SUPPLY))
  )

  (defcap CREATE-COLLECTION (collection-name:string creator:string)
    @doc "Collection creation event capability"
    @event
    (enforce (!= collection-name "") "Collection name cannot be empty")
    (enforce (!= creator "") "Creator cannot be empty")
    (enforce-valid-account creator)
    true
  )

  (defcap UPDATE_SUPPLY ()
    @doc "Private capability for supply management"
    true
  )

  (defcap RESERVE (collection-name:string)
    @doc "Controls NFT presale reservations"
    @event
    (enforce (!= collection-name "") "Collection name cannot be empty")
    
    ;; Directly enforce time constraints without guards
    (let ((current-time (at 'block-time (chain-data)))
          (presale-end (get-presale-end-time collection-name))
          (presale-start (get-presale-start-time collection-name)))
        (enforce (>= presale-end current-time) "Presale has ended")
        (enforce (<= presale-start current-time) "Presale has not started")
    )
)

  (defcap CLAIM-RESERVED (account:string collection-name:string guard:guard)
    @doc "Controls reserved NFT claims"
    (enforce (!= account "") "Account cannot be empty")
    (enforce (!= collection-name "") "Collection name cannot be empty")
    (let ((accounts:[string] (get-presale-accounts collection-name)))
      (enforce (contains account accounts) "Account not in presale list")
      (let ((reserved-guard:guard (at 'guard (read-reservation account collection-name))))
        (enforce (= guard reserved-guard) "Invalid guard for reservation")
      )
    )
  )

  (defcap WHITELIST (collection-name:string creatorguard:guard)
    @doc "Whitelist management capability"
    (compose-capability (PRIVATE))
    (enforce-owner collection-name creatorguard)
  )

  (defcap PRIORITY ()
    @doc "Priority access management"
    (compose-capability (PRIVATE))
    (compose-capability (IS_ADMIN))
  )

  (defcap MINT_EVENT (collection-name:string account:string amount:integer)
    @doc "Mint event tracking"
    @event
    (enforce (> amount 0) "Amount must be positive")
    true
  )

  (defcap MINTPROCESS:bool (collection-name:string)
    @doc "Controls NFT minting process after payment"
    (compose-capability (PRIVATE))
    (enforce-guard (at 'creator-guard (read collections collection-name ['creator-guard])))
    "Must be the collection creator guard"
  )

  (defcap AIRDROP:bool (collection-name:string)
    @doc "Controls airdrop process"
    (compose-capability (PRIVATE))
  )

  ;-----------------------------------------------------------------------------
  ; Capability Enforcement Functions
  ;-----------------------------------------------------------------------------

  (defun read-reservation:object{reservation} (account:string collection-name:string)
    @doc "Read reservation details for account"
    (enforce (!= account "") "Account cannot be empty")  
    (enforce (!= collection-name "") "Collection name cannot be empty")
    (read reservations (get-reservation-id account collection-name))
)

(defun get-reservation-id:string (account:string collection-name:string)
    @doc "Generates unique reservation ID"
    (concat [collection-name "|" account])
)

  (defun enforce-owner:bool (collection-name:string creatorguard:guard)
    @doc "Enforces collection ownership"
    (with-read collections collection-name
      { "creator-guard" := guard }
      (enforce (= creatorguard guard) "Not the collection owner")
      true
    )
  )

  (defun enforce-mint-auth (account:string collection-name:string)
    @doc "Enforces minting authorization"
    (enforce-guard (at "guard" (coin.details account)))
    (enforce-valid-account account)
    (with-read collections collection-name
      { "launched" := launched }
      (enforce launched "Collection not launched")
    )
  )

  (defun enforce-transfer-auth:bool (token-id:string sender:string)
    @doc "Enforces transfer authorization"
    (enforce (!= sender "") "Invalid sender")
    (enforce-guard (at "guard" (coin.details sender)))
    (with-read nfts-info-by-id token-id
      { "owner" := owner }
      (enforce (= owner sender) "Not token owner")
    )
  )

  (defcap RATE_LIMIT ()
      @doc "Rate limiting capability"
      (compose-capability (PRIVATE))
  )



  ;-----------------------------------------------------------------------------
  ; Read/Get Functions - Core Data Access
  ;-----------------------------------------------------------------------------

  (defun get-launched-collection ()
      @doc "Returns list of all launched collections"
      (with-capability (RATE_LIMIT)
          (keys collections))
  )

  (defun get-collection-creator-of-request (collection-name:string)
      @doc "Get creator of a requested collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read request-collection-ledger collection-name
          {"creator" := creator}
          creator)
  )

  (defun get-collection-id (collection-name:string)
      @doc "Get unique identifier of a collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name
          {"collection-id" := id}
          id)
  )

  (defun get-collection-symbol (collection-name:string)
      @doc "Get symbol of a collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name
          {"symbol" := symbol}
          symbol)
  )

  (defun get-collection-details (collection-name:string)
      @doc "Get comprehensive collection details"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (read collections collection-name)
  )

  (defun get-collection-creator (collection-name:string)
      @doc "Get creator address of a collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name
          {"creator" := creator}
          creator)
  )

  (defun get-collection-creator-guard (collection-name:string)
      @doc "Get creator guard of a collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name
          {"creator-guard" := guard}
          guard)
  )

  ;-----------------------------------------------------------------------------
  ; Time and Price Functions
  ;-----------------------------------------------------------------------------

  (defun get-mint-start-time:time (collection-name:string)
      @doc "Get mint start time for collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'mint-start-time (read collections collection-name))
  )

  (defun get-mint-end-time:time (collection-name:string)
      @doc "Get mint end time for collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'mint-end-time (read collections collection-name))
  )

  (defun get-wl-start-time:time (collection-name:string)
      @doc "Get whitelist start time with validation"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let ((wl-enabled:bool (get-wl-enabled collection-name)))
          (if (= wl-enabled true)
              (at 'whitelist-start-time (read collections collection-name))
              (time "9999-12-31T23:59:59Z")
          ))
  )

  (defun get-collection-launch-fee:decimal ()
      @doc "Get current launch fee"
      (with-read fee-ledger LAUNCH
          {"fee" := fee}
          fee)
  )

  (defun get-collection-discount-fee:decimal ()
      @doc "Get current discount fee"
      (with-read fee-ledger LAUNCH
          {"discount" := discount}
          discount)
  )

  ;-----------------------------------------------------------------------------
  ; Status Check Functions
  ;-----------------------------------------------------------------------------

  (defun get-presale-start-time:time (collection-name:string)
      @doc "Get presale start time"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'presale-start-time (read collections collection-name))
  )

(defun get-presale-mint-price:decimal (collection-name:string)
    @doc "Get presale mint price for collection"
    (enforce (!= collection-name "") "Collection name cannot be empty")
    (with-read collections collection-name
        {"presale-mint-price" := price}
        (enforce (>= price MIN_PRICE) "Invalid presale mint price")
        price
    )
)

  (defun get-presale-end-time:time (collection-name:string)
      @doc "Get presale end time"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'presale-end-time (read collections collection-name))
  )

  (defun get-mint-price:decimal (collection-name:string)
      @doc "Get public mint price"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name
          {"mint-price" := price}
          (enforce (>= price MIN_PRICE) "Invalid mint price")
          price)
  )

  (defun get-wl-price:decimal (collection-name:string)
      @doc "Get whitelist mint price"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name
          {"wl-price" := price}
          (enforce (>= price MIN_PRICE) "Invalid whitelist price")
          price)
  )

  ;-----------------------------------------------------------------------------
  ; Account List Functions
  ;-----------------------------------------------------------------------------

  (defun get-whitelist-accounts:list (collection-name:string)
      @doc "Get all whitelisted accounts"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'whitelist-addresses (read collections collection-name))
  )

  (defun get-presale-accounts:list (collection-name:string)
      @doc "Get all presale accounts"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'presale-addresses (read collections collection-name))
  )

  (defun get-airdrop-accounts:list (collection-name:string)
      @doc "Get all airdrop accounts"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'airdrop-addresses (read collections collection-name))
  )

  ;-----------------------------------------------------------------------------
  ; Collection Metadata Functions
  ;-----------------------------------------------------------------------------

  (defun get-category:string (collection-name:string)
      @doc "Get collection category"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'category (read collections collection-name))
  )

  (defun get-description:string (collection-name:string)
      @doc "Get collection description"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'description (read collections collection-name))
  )

  (defun get-cover-url:string (collection-name:string)
      @doc "Get collection cover image URL"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'cover-image-url (read collections collection-name))
  )

  (defun get-banner-url:string (collection-name:string)
      @doc "Get collection banner image URL"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'banner-image-url (read collections collection-name))
  )

  (defun get-collection-request ()
      @doc "Get all pending collection requests"
      (with-capability (RATE_LIMIT)
          (keys request-collection-ledger))
  )

  ;-----------------------------------------------------------------------------
  ; Feature Status Functions
  ;-----------------------------------------------------------------------------

  (defun get-presale-enabled:bool (collection-name:string)
      @doc "Check if presale is enabled"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'enable-presale (read collections collection-name))
  )

  (defun get-wl-enabled:bool (collection-name:string)
      @doc "Check if whitelist is enabled"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'enable-whitelist (read collections collection-name))
  )

  (defun get-airdrop-enabled:bool (collection-name:string)
      @doc "Check if airdrop is enabled"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'enable-airdrop (read collections collection-name))
  )

  (defun get-free-mint-enabled:bool (collection-name:string)
      @doc "Check if free mint is enabled"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'allow-free-mints (read collections collection-name))
  )

  ;-----------------------------------------------------------------------------
  ; Supply and Count Functions
  ;-----------------------------------------------------------------------------

  (defun get-total-supply:integer (collection-name:string)
      @doc "Get total supply of collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'total-supply (get-collection-details collection-name))
  )

  (defun get-current-index:integer (collection-name:string)
      @doc "Get current minting index"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'current-index (read collections collection-name))
  )

  (defun get-total-nft-reserved:decimal (collection-name:string)
      @doc "Get total NFTs reserved in presale"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let ((presale-accounts:[string] (get-presale-accounts collection-name)))
          (fold (+) 0.0 (map (get-nft-reserved collection-name) presale-accounts))
      )
  )

  ;-----------------------------------------------------------------------------
  ; Account Info Functions
  ;-----------------------------------------------------------------------------

  (defun get-all-tokens-by-account (account:string)
      @doc "Get all tokens owned by an account"
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)
      (select accountsInfo (where 'account (= account)))
  )

  (defun get-nft-reserved:integer (collection-name:string account:string)
      @doc "Get number of NFTs reserved by account"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= account "") "Account cannot be empty")
      (with-default-read reservations (concat [collection-name "|" account])
          {"amount-nft": 0}
          {"amount-nft" := amount}
          amount)
  )

  (defun get-user-roles:[string] (account:string)
      @doc "Get all roles assigned to an account"
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)
      (with-default-read account-details account
          {"roles": []}
          {"roles" := roles}
          roles)
  )


  (defun get-free-mint-claim:bool (collection-name:string account:string)
      @doc "Check if account has claimed free mint"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= account "") "Account cannot be empty")
      (with-default-read free-mint-account-ledger (concat [collection-name "|" account])
          {'claimed: false}
          {'claimed := claimed}
          claimed
      )
  )

  (defun get-policy-of-collection (collection-name:string)
      @doc "Get collection policy configuration"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'policy (read collections collection-name))
  )

  (defun get-whitelist-info:object{whitelist-schema} (account:string collection-name:string)
      @doc "Get whitelist details for account"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= account "") "Account cannot be empty")
      (read whitelists (concat [collection-name "|" account]))
  )

  (defun get-minted:integer (collection-name:string)
      @doc "Get total minted count"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read token-ledger collection-name
          {'current-length := current-length}
          (- (at 'total-supply (get-collection-details collection-name)) current-length)
      )
  )

  (defun get-current-length:integer (collectionName:string)
      @doc "Get current token record length"
      (enforce (!= collectionName "") "Collection name cannot be empty")
      (with-read token-record collectionName
          {'current-length := current-length}
          current-length
      )
  )

  (defun get-length:integer (collectionName:string)
      @doc "Get token ledger length"
      (enforce (!= collectionName "") "Collection name cannot be empty")
      (with-read token-ledger collectionName
          {'current-length := current-length}
          current-length
      )
  )

  (defun get-account-minted:integer (account:string)
      @doc "Get total NFTs minted by account"
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)
      (with-default-read account-details account
          {"minted": 0}
          {"minted" := minted}
          minted
      )
  )

  (defun get-royalty-info (collection-name:string type:string)
      @doc "Get royalty information based on type (rate/account/both)"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= type "") "Type cannot be empty")
      (with-read collections collection-name
          { "royalty-percentage" := rate,
            "royalty-address" := address }
          (cond
              ((= type "rate") rate)
              ((= type "account") address)
              ((= type "both")
                  (format "Royalty Rate {} and Royalty Account {}"
                      [rate, address]))
              ["Invalid Type"]
          )
      )
  )

  (defun get-prime-role ()
      @doc "Get all prime role accounts"
      (at 'accounts (read prime_role PRIME))
  )

  (defun get-discount-role ()
      @doc "Get all discount role accounts"
      (at 'accounts (read discount_role DISCOUNT))
  )

  (defun get-presale-claim:bool (collection-name:string account:string)
      @doc "Check if account has claimed presale"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= account "") "Account cannot be empty")
      (with-read presale-ledger (concat [collection-name "|" account])
          {'claimed := claimed}
          claimed
      )
  )

  (defun get-pass-claim:bool (collection-name:string account:string)
      @doc "Check if priority pass claimed for collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= account "") "Account cannot be empty")
      (with-default-read priority-collection (concat [collection-name "|" account])
          {'claimed: false}
          {'claimed := claimed}
          claimed
      )
  )

  (defun get-token-details (account:string)
      @doc "Get detailed token info for account"
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)
      (let* ((balances (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger.list-balances account))
             (token-ids (map (lambda (balance) (at 'id balance)) balances)))
          (map (lambda (token-id)
              { "token-id": token-id,
                "uri": (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger.get-uri token-id),
                "collection": (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.policy-collection.get-token-collection token-id)
              }) token-ids)
      )
  )

  ;; Free Mint Status Functions
  (defun get-free-mint-status:object{free-mint-schema} (collection-name:string)
      @doc "Get comprehensive free mint status"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-default-read free-mint-ledger collection-name
          { 'total-supply: 0,
            'current-index: 0,
            'start-time: (time "1970-01-01T00:00:00Z"),
            'end-time: (time "1970-01-01T00:00:00Z"),
            'is-active: false }
          { 'total-supply := total-supply,
            'current-index := current-index,
            'start-time := start-time,
            'end-time := end-time,
            'is-active := is-active }
          { 'total-supply: total-supply,
            'current-index: current-index,
            'start-time: start-time,
            'end-time: end-time,
            'is-active: is-active }
      )
  )

  (defun get-mint-availability:object (collection-name:string)
      @doc "Get mint availability statistics"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let* ((total-supply:integer (get-total-supply collection-name))
             (free-mints-used:integer (- (get-current-index-free-mint collection-name) 1))
             (normal-mints:integer (get-current-index collection-name))
             (total-mints:integer (+ normal-mints (if (> free-mints-used 0) free-mints-used 0)))
             (remaining:integer (- total-supply total-mints)))
          { "total-supply": total-supply,
            "free-mints-used": (if (> free-mints-used 0) free-mints-used 0),
            "normal-mints": normal-mints,
            "total-mints": total-mints,
            "remaining-supply": remaining }
      )
  )

  (defun get-current-index-free-mint:integer (collection-name:string)
      @doc "Get current free mint index"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (at 'current-index (read free-mint-ledger collection-name))
  )

  (defun get-total-supply-free-mint:integer (collection-name:string)
      @doc "Get total free mint supply"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-default-read free-mint-ledger collection-name
          {'total-supply: 0}
          {'total-supply := total-supply}
          total-supply
      )
  )

  (defun get-airdrop-history ()
      @doc "Get complete airdrop history"
      (select airdrop-history-table (where "account" (!= "")))
  )

  (defun get-urisIPFS:integer (collection-name:string)
    @doc "Get urisIPFS data for collection"
    (enforce (!= collection-name "") "Collection name cannot be empty")
    (at 'urisIPFS (read collections collection-name)))





  ;-----------------------------------------------------------------------------
  ; Admin Functions - Collection and System Management
  ;-----------------------------------------------------------------------------

  
  (defun verify-collection-status:object{collection-status} (collection-name:string)
      @doc "Get comprehensive status of collection"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      
      (let* (
          (request-exists:bool 
              (with-default-read request-collection-ledger collection-name
                  {"creator": ""}
                  {"creator" := creator}
                  (!= creator "")))
          
          (collection-exists:bool 
              (with-default-read collections collection-name
                  {"launched": false}
                  {"launched" := launched}
                  launched))
      )
          { "request-exists": request-exists,
            "collection-exists": collection-exists,
            "status": (cond
                ((and (not request-exists) (not collection-exists)) "NOT_FOUND")
                ((and request-exists (not collection-exists)) "PENDING")
                ((and (not request-exists) collection-exists) "LAUNCHED")
                "INVALID_STATE")
          }
      )
  )
  
  (defun nft-collection-request (
      collection-name:string
      symbol:string
      creator:string
      creator-guard:guard
      description:string
      category:string
      total-supply:integer
      urisIPFS:string
      mint-price:decimal
      royalty-percentage:decimal
      royalty-address:string
      cover-image-url:string
      banner-image-url:string
      mint-start-date:string
      mint-start-time:time
      mint-end-date:string
      mint-end-time:time
      allow-free-mints:bool
      enable-whitelist:bool
      enable-presale:bool
      enable-airdrop:bool
      policies:string)
  
      @doc "Creator function to request a new collection"
  
      ;; Input validations
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= symbol "") "Symbol cannot be empty")
      (enforce (!= creator "") "Creator cannot be empty")
      (enforce (>= total-supply 0) "Invalid supply")
      (enforce (<= total-supply MAX_SUPPLY_LIMIT) "Supply exceeds limit")
      (enforce (>= mint-price MIN_PRICE) "Price below minimum")
      (enforce (and (>= royalty-percentage 0.0) (<= royalty-percentage MAX_ROYALTY_PERCENTAGE))
          "Invalid royalty percentage")
      (enforce (!= royalty-address "") "Invalid royalty address")
  
      ;; Time validations
      (let ((curr-time:time (at "block-time" (chain-data))))
          (enforce (>= mint-end-time mint-start-time) "Invalid time range")
          (enforce (>= mint-start-time curr-time) "Start time must be future")
      )
  
      ;; Check collection status
      (let ((status (verify-collection-status collection-name)))
          (enforce (= (at "status" status) "NOT_FOUND") 
              "Collection already exists or pending"))
  
      ;; Calculate fees
      (let* ((g:guard (at 'guard (coin.details creator)))
             (fee:decimal (get-collection-launch-fee))
             (discount:decimal (get-collection-discount-fee))
             (prime_accounts:string (get-prime-role))
             (discount_accounts:string (get-discount-role))
             (discounted-fee (* fee (- 1 discount)))
             (log-key:string (format "{}-{}" [collection-name (hash (at "block-time" (chain-data)))])))
  
          ;; Validate creator account
          (enforce-reserved creator g)
  
          ;; Handle fee payment based on role
          (cond
              ((contains creator prime_accounts)
                  ["Prime member - no fee"])
              ((contains creator discount_accounts)
                  [(coin.transfer creator LAUNCHPAD_ACC discounted-fee)])
              [(coin.transfer creator LAUNCHPAD_ACC fee)]
          )
  
          ;; Create collection request
          (insert request-collection-ledger collection-name {
              'collection-name: collection-name,
              'symbol: symbol,
              'collection-id: "",
              'launched: false,
              'creator: creator,
              'creator-guard: creator-guard,
              'description: description,
              'category: category,
              'total-supply: total-supply,
              'urisIPFS: urisIPFS,
              'mint-price: mint-price,
              'wl-price: 0.0,
              'royalty-percentage: royalty-percentage,
              'royalty-address: royalty-address,
              'cover-image-url: cover-image-url,
              'banner-image-url: banner-image-url,
              'mint-start-date: mint-start-date,
              'mint-start-time: mint-start-time,
              'mint-end-date: mint-end-date,
              'mint-end-time: mint-end-time,
              'allow-free-mints: allow-free-mints,
              'enable-whitelist: enable-whitelist,
              'whitelist-addresses: [],
              'whitelist-start-time: (time "9999-12-31T23:59:59Z"),
              'enable-presale: enable-presale,
              'presale-addresses: [],
              'presale-start-date: "",
              'presale-start-time: (time "9999-12-31T23:59:59Z"),
              'presale-end-date: "",
              'presale-end-time: (time "9999-12-31T23:59:59Z"),
              'presale-mint-price: 0.0,
              'enable-airdrop: enable-airdrop,
              'airdrop-supply: 0,
              'airdrop-addresses: [],
              'current-index: 0,
              'policy: policies,
              'created-time: (at "block-time" (chain-data)),
              'last-updated: (at "block-time" (chain-data)),
              'total-minted: 0,
              'total-sales: 0.0
          })
  
          ;; Initialize required tables
          (write token-ledger collection-name {
              'current-length: 0,
              'max-supply: total-supply,
              'last-mint-time: (at "block-time" (chain-data)),
              'total-minted: 0
          })
  
          (write token-record collection-name {
              'uri-list: [],
              'current-length: 0,
              'max-length: total-supply,
              'last-updated: (at "block-time" (chain-data)),
              'created-by: creator,
              'is-frozen: false
          })
  
          ;; Log with unique key based on collection name and timestamp hash
          (write operation-logs log-key {
              "operation": "request-collection",
              "account": creator,
              "timestamp": (at "block-time" (chain-data)),
              "details": {
                  "collection": collection-name,
                  "status": "pending"
              },
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
  
          ;; Initialize counts table for the collection
          (write counts-table collection-name {
              "count": 0,
              "last-updated": (at "block-time" (chain-data)),
              "description": "Collection mint counter"
          })
  
          ;; Initialize free mint ledger
          (write free-mint-ledger collection-name {
              'total-supply: 0,
              'current-index: 1,
              'start-time: (time "1970-01-01T00:00:00Z"),
              'end-time: (time "1970-01-01T00:00:00Z"),
              'is-active: false,
              'max-per-account: 1,
              'accounts-claimed: []
          })
  
          (emit-event (CREATE-COLLECTION collection-name creator))
          
          ;; Return success message with collection name
          (format "Collection {} requested successfully" [collection-name])
      )
  )

  ; (defun create-ng-collection:string
  ;     (collection-name:string
  ;      creator:string
  ;      creator-guard:guard)

  ;     @doc "Creator function to initialize collection after approval"

  ;     ;; Verify ownership and status
  ;     (enforce-owner collection-name creator-guard)
  ;     (with-read collections collection-name
  ;         {"launched" := launched,
  ;          "creator-guard" := guard}

  ;         (enforce (= launched true) "Wait for admin approval")

  ;         (let* ((collection-id:string
  ;                     (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.policy-collection.create-collection-id
  ;                         collection-name
  ;                         guard))
  ;                (collectionSize:integer
  ;                     (get-total-supply collection-name)))

  ;             ;; Create collection with policy
  ;             (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.policy-collection.create-collection
  ;                 collection-id
  ;                 collection-name
  ;                 collectionSize
  ;                 creator
  ;                 guard)

  ;             ;; Update collection with ID
  ;             (update collections collection-name {
  ;                 "collection-id": collection-id,
  ;                 "last-updated": (at "block-time" (chain-data))
  ;             })

  ;             ;; Initialize counter
  ;             (insert counts-table collection-name {
  ;                 "count": 0,
  ;                 "last-updated": (at "block-time" (chain-data)),
  ;                 "description": "Collection mint counter"
  ;             })

  ;             collection-id
  ;         )
  ;     )
  ; )
  
  (defun create-ng-collection:string 
      (collection-name:string 
       creator:string 
       creator-guard:guard)
      @doc "Creator function to initialize collection after approval"
      
      ;; Verify ownership and status
      (enforce-owner collection-name creator-guard)
      (with-read collections collection-name
          {"launched" := launched,
           "creator-guard" := guard}
          
          (enforce (= launched true) "Wait for admin approval")
          
          (let* ((collection-id:string 
                      (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.policy-collection.create-collection-id
                          collection-name
                          guard))
                 (collectionSize:integer 
                      (get-total-supply collection-name)))
              
              ;; Create collection with policy
              (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.policy-collection.create-collection
                  collection-id
                  collection-name
                  collectionSize
                  creator
                  guard)
              
              ;; Update existing collection record instead of insert
              (update collections collection-name {
                  "collection-id": collection-id,
                  "last-updated": (at "block-time" (chain-data))
              })
              
              ;; Update token ledger if exists, otherwise write
              (with-default-read token-ledger collection-name
                  {"current-length": 0}
                  {"current-length" := curr-length}
                  (write token-ledger collection-name {
                      'current-length: curr-length,
                      'max-supply: collectionSize,
                      'last-mint-time: (at "block-time" (chain-data)),
                      'total-minted: 0
                  }))
              
              ;; Update counts table if exists, otherwise skip
              (with-default-read counts-table collection-name
                  {"count": 0}
                  {"count" := current-count}
                  (if (> current-count 0)
                      "Counts table exists"
                      (write counts-table collection-name {
                          "count": 0,
                          "last-updated": (at "block-time" (chain-data)),
                          "description": "Collection mint counter"
                      })))
              
              ;; Log the operation
              (write operation-logs 
                  (format "{}-{}" [collection-name (at "block-time" (chain-data))]) 
                  {
                      "operation": "create-ng-collection",
                      "account": creator,
                      "timestamp": (at "block-time" (chain-data)),
                      "details": {
                          "collection": collection-name,
                          "collection-id": collection-id
                      },
                      "status": "completed",
                      "tx-hash": (hash (at "block-time" (chain-data)))
                  })
              
              collection-id))
  )
  
  (defun check-ng-collection-state:object 
      (collection-name:string)
      @doc "Check if collection is ready for NG initialization"
      
      (with-read collections collection-name
          {"launched" := launched,
           "collection-id" := collection-id,
           "creator" := creator}
          
          {"collection-name": collection-name,
           "launched": launched,
           "initialized": (!= collection-id ""),
           "creator": creator,
           "ready-for-ng": (and launched (= collection-id ""))
          }
      )
  )

  (defun updateCollectionDetails
      (creator:string
       creator-guard:guard
       collection-name:string
       description:string
       category:string
       cover-image-url:string
       banner-image-url:string)

      @doc "Creator function to update collection metadata"

      ;; Validate inputs
      (enforce (!= description "") "Description cannot be empty")
      (enforce (!= category "") "Category cannot be empty")

      ;; Verify ownership
      (with-read collections collection-name {
          "creator-guard" := guard
      }
          (enforce (= creator-guard guard) "Not collection owner")

          ;; Update collection
          (update collections collection-name {
              "description": description,
              "category": category,
              "cover-image-url": cover-image-url,
              "banner-image-url": banner-image-url,
              "last-updated": (at "block-time" (chain-data))
          })

          ;; Log update
          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "update-collection",
              "account": creator,
              "timestamp": (at "block-time" (chain-data)),
              "details": {
                  "collection": collection-name,
                  "type": "metadata-update"
              },
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun update-royalty-info
      (collection-name:string
       creator-guard:guard
       royalty-address:string
       royalty-percentage:decimal)

      @doc "Creator function to update royalty configuration"

      ;; Validate inputs
      (enforce (!= royalty-address "") "Invalid royalty address")
      (enforce (and (>= royalty-percentage 0.0)
                   (<= royalty-percentage MAX_ROYALTY_PERCENTAGE))
          "Invalid royalty percentage")

      ;; Verify ownership
      (enforce-owner collection-name creator-guard)

      ;; Update royalties
      (update collections collection-name {
          'royalty-percentage: royalty-percentage,
          'royalty-address: royalty-address,
          'last-updated: (at "block-time" (chain-data))
      })

      ;; Log update
      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "update-royalties",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": {
              "collection": collection-name,
              "new-percentage": royalty-percentage,
              "new-address": royalty-address
          },
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )

  (defun update-mint-time
      (collection-name:string
       creator-guard:guard
       mint-start-time:time
       mint-end-time:time
       wl-start-time:time)

      @doc "Creator function to update minting schedule"

      ;; Verify ownership
      (enforce-owner collection-name creator-guard)

      ;; Validate times
      (let ((curr-time:time (at "block-time" (chain-data))))
          (enforce (>= mint-end-time mint-start-time) "Invalid mint time range")
          (enforce (>= mint-start-time curr-time) "Start time must be future")
          (enforce (>= mint-start-time wl-start-time) "Invalid whitelist time")
      )

      ;; Update times
      (update collections collection-name {
          "mint-start-time": mint-start-time,
          "mint-end-time": mint-end-time,
          "whitelist-start-time": wl-start-time,
          "last-updated": (at "block-time" (chain-data))
      })

      ;; Log update
      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "update-times",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": {
              "collection": collection-name,
              "new-start": mint-start-time,
              "new-end": mint-end-time
          },
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )


  ;-----------------------------------------------------------------------------
  ; Sale Management Functions
  ;-----------------------------------------------------------------------------

  (defun check-whitelist:bool (collection-name:string)
      @doc "Check if whitelist sale is active"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let* (
          (mint-start-time:time (get-mint-start-time collection-name))
          (whitelist-mint-time:time (get-wl-start-time collection-name))
          (chain-time (at 'block-time (chain-data)))
      )
          (and (<= whitelist-mint-time chain-time) (<= chain-time mint-start-time))
      )
  )

  (defun check-public:bool (collection-name:string)
      @doc "Check if public sale is active"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let* (
          (mint-start-time:time (get-mint-start-time collection-name))
          (mint-end-time:time (get-mint-end-time collection-name))
          (chain-time (at 'block-time (chain-data)))
      )
          (and (<= chain-time mint-end-time) (>= chain-time mint-start-time))
      )
  )

  (defun check-presale:bool (collection-name:string)
      @doc "Check if presale is active"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let* (
          (presale-start-time:time (get-presale-start-time collection-name))
          (presale-end-time:time (get-presale-end-time collection-name))
          (chain-time (at 'block-time (chain-data)))
      )
          (and (<= chain-time presale-end-time) (>= chain-time presale-start-time))
      )
  )

  (defun update-public-price (collection-name:string creator-guard:guard price:decimal)
      @doc "Update public sale price"
      (enforce-owner collection-name creator-guard)
      (enforce (>= price MIN_PRICE) "Price below minimum")

      (update collections collection-name {
          "mint-price": price,
          "last-updated": (at 'block-time (chain-data))
      })

      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "update-public-price",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": {
              "collection": collection-name,
              "new-price": price
          },
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )

  (defun update-presale-mint-price:decimal (creator-guard:guard collection-name:string price:decimal)
      @doc "Update presale price"
      (enforce-owner collection-name creator-guard)
      (enforce (>= price MIN_PRICE) "Price below minimum")

      (update collections collection-name {
          "presale-mint-price": price,
          "last-updated": (at 'block-time (chain-data))
      })

      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "update-presale-price",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": {
              "collection": collection-name,
              "new-price": price
          },
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )

  (defun update-presale-mint-time (
      creator-guard:guard
      collection-name:string
      presale-start-time:time
      presale-end-time:time)

      @doc "Update presale timing"
      (enforce-owner collection-name creator-guard)

      (let ((curr-time (at 'block-time (chain-data))))
          (enforce (>= presale-end-time presale-start-time) "Invalid time range")
          (enforce (>= presale-start-time curr-time) "Start time must be future")
      )

      (update collections collection-name {
          "presale-start-time": presale-start-time,
          "presale-end-time": presale-end-time,
          "last-updated": (at 'block-time (chain-data))
      })

      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "update-presale-time",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": {
              "collection": collection-name,
              "new-start": presale-start-time,
              "new-end": presale-end-time
          },
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )

  (defun enable-presale:string
      (creator:string
       creator-guard:guard
       collection-name:string)

      @doc "Enable presale for collection"

      (enforce-owner collection-name creator-guard)
      (let (
          (enabled:bool (get-presale-enabled collection-name))
          (launched:bool (is_col_launched collection-name))
          (wl-enabled:bool (check-whitelist collection-name))
          (public-enabled:bool (check-public collection-name))
      )
          (enforce (= launched true) "Collection not launched")
          (enforce (!= wl-enabled true) "Whitelist sale is live")
          (enforce (!= public-enabled true) "Public sale is live")
          (enforce (= enabled false) "Presale already enabled")

          (update collections collection-name {
              'enable-presale: true,
              'last-updated: (at 'block-time (chain-data))
          })

          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "enable-presale",
              "account": creator,
              "timestamp": (at "block-time" (chain-data)),
              "details": {"collection": collection-name},
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun enable-whitelist:string
      (creator:string
       creator-guard:guard
       collection-name:string)

      @doc "Enable whitelist for collection"

      (enforce-owner collection-name creator-guard)
      (let (
          (enabled:bool (get-wl-enabled collection-name))
          (launched:bool (is_col_launched collection-name))
          (public-enabled:bool (check-public collection-name))
      )
          (enforce (= launched true) "Collection not launched")
          (enforce (!= public-enabled true) "Public sale is live")
          (enforce (= enabled false) "Whitelist already enabled")

          (update collections collection-name {
              'enable-whitelist: true,
              'last-updated: (at 'block-time (chain-data))
          })

          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "enable-whitelist",
              "account": creator,
              "timestamp": (at "block-time" (chain-data)),
              "details": {"collection": collection-name},
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun enforce-sale-state (collection-name:string)
      @doc "Validate current sale state"
      (let (
          (public-active:bool (check-public collection-name))
          (wl-active:bool (check-whitelist collection-name))
          (presale-active:bool (check-presale collection-name))
      )
          (enforce (or public-active wl-active presale-active)
              "No active sale phase")
      )
  )

  (defun enforce-mint-limit (account:string collection-name:string amount:integer)
      @doc "Enforce minting limits"
      (let (
          (current-minted:integer (get-account-minted account))
          (max-mint:integer MAX_MINT_PER_TX)
      )
          (enforce (<= amount max-mint) "Exceeds max mint per tx")
          (enforce (<= (+ current-minted amount) (get-total-supply collection-name))
              "Exceeds collection supply")
      )
  )


  ;-----------------------------------------------------------------------------
  ; Minting Functions
  ;-----------------------------------------------------------------------------

  (defun get-available-normal-supply:integer (collection-name:string)
      @doc "Calculate available supply for normal minting"
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (let* (
          (total-supply (get-total-supply collection-name))
          (free-mints-used (- (get-current-index-free-mint collection-name) 1))
          (normal-mints (get-current-index collection-name))
          (total-minted (+ normal-mints (if (> free-mints-used 0) free-mints-used 0)))
      )
      (- total-supply total-minted))
  )


  (defun reserve-token:bool
      (collection-name:string
       account:string
       amount:integer)
      @doc "Main minting function handling all minting scenarios"
  
      ;; Validate basic parameters
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (!= account "") "Account cannot be empty")
      (enforce (> amount 0) "Amount must be positive")
      (enforce (<= amount MAX_MINT_PER_TX) "Exceeds max mint per transaction")
  
      ;; Check available supply
      (let (
          (available-supply:integer (get-available-normal-supply collection-name))
          (current-indx:integer (get-current-index collection-name))
      )
          (enforce (<= amount available-supply) "Insufficient supply")
  
          ;; Process mint with MINT-NFT capability
          (with-capability (MINT-NFT account)
              (let* (
                  (priority-sale-users:[string] (get-priority-users))
                  (presale-users:[string] (get-presale-accounts collection-name))
                  (acc-guard:guard (at "guard" (coin.details account)))
                  (passBalance:integer (get-pass-balance account))
                  (creator:string (get-collection-creator collection-name))
                  (account-info-key:string (concat [collection-name "|" account]))
              )
                  ;; Handle different minting scenarios with price/payment check
                  (let ((mint-result
                      (cond
                          ;; Creator free mint
                          ((= account creator)
                              [true])
                          ;; Presale mint
                          ((and (check-presale collection-name)
                                (contains account presale-users))
                              (let ((claimPresale:bool (get-presale-claim collection-name account)))
                                  (if (= claimPresale false)
                                      (mint-presale-nft account collection-name amount)
                                      (if (and (> passBalance 0)
                                             (contains account priority-sale-users))
                                          (let ((claimPass:bool (get-pass-claim collection-name account)))
                                              (if (= claimPass false)
                                                  (mint-for-free account collection-name amount)
                                                  (mint-for-price account collection-name amount)))
                                          [false]))))
                          ;; Priority pass mint
                          ((and (> passBalance 0)
                                (contains account priority-sale-users))
                              (let ((claim:bool (get-pass-claim collection-name account)))
                                  (if (= claim false)
                                      (mint-for-free account collection-name amount)
                                      (mint-for-price account collection-name amount))))
                          ;; Regular mint
                          [(mint-for-price account collection-name amount)])))
  
                      ;; Update or create account info using with-default-read
                      (with-default-read accountsInfo account-info-key
                          { "account": account,
                            "collection-name": collection-name,
                            "tokens": [],
                            "last-updated": (at "block-time" (chain-data)),
                            "total-value": 0.0 }
                          { "tokens" := existing-tokens }
                          (write accountsInfo account-info-key
                              { "account": account,
                                "collection-name": collection-name,
                                "tokens": existing-tokens,
                                "last-updated": (at "block-time" (chain-data)),
                                "total-value": 0.0 }))
  
                      ;; Execute mint
                      (mint-internal
                          collection-name
                          account
                          acc-guard
                          amount
                          current-indx)
  
                      ;; Log operation
                      (write operation-logs 
                          (format "{}-{}" [collection-name (hash (at "block-time" (chain-data)))])
                          { "operation": "reserve-token",
                            "account": account,
                            "timestamp": (at "block-time" (chain-data)),
                            "details": {
                                "collection": collection-name,
                                "amount": amount,
                                "type": "regular"
                            },
                            "status": "completed",
                            "tx-hash": (hash (at "block-time" (chain-data)))
                          })
                      
                      true))
          )
      )
  )

  (defun mint-internal:bool
      (collection-name:string
       account:string
       guard:guard
       amount:integer
       current-indx:integer)

      @doc "Internal function to process mint"

      (require-capability (MINT-NFT account))

      ;; Update collection index
      (update collections collection-name
          { "current-index": (+ current-indx amount),
            "total-minted": (+ (get-total-supply collection-name) amount),
            "last-updated": (at "block-time" (chain-data))
          }
      )

      ;; Process individual token mints
      (map
          (mint-token collection-name account guard)
          (map (+ current-indx) (enumerate 0 (- amount 1)))
      )

      ;; Emit mint event
      (emit-event (MINT_EVENT collection-name account amount))
  )

  (defun mint-token:string
      (collection-name:string
       account:string
       guard:guard
       accountId:integer)

      @doc "Mint single token"

      (require-capability (MINT-NFT account))

      ;; Insert minted token record
      (insert minted-tokens (get-mint-token-id collection-name accountId)
          { "collection-name": collection-name,
            "account": account,
            "guard": guard,
            "accountId": accountId,
            "marmToken": "",
            "revealed": false,
            "mint-time": (at "block-time" (chain-data)),
            "mint-price": (get-mint-price collection-name),
            "mint-type": "standard"
          }
      )
  )

  (defun mint-for-free:bool
      (account:string
       collection-name:string
       amount:integer)

      @doc "Process free mint"

      (require-capability (MINT-NFT account))

      (let* (
          (acc-guard:guard (at "guard" (coin.details account)))
          (col-acc:[string] (keys priority-collection))
          (isAvailable:bool (contains (concat [collection-name "|" account]) col-acc))
      )
          (enforce (= amount 1) "Free mint limited to 1 per collection")

          ;; Update priority collection status
          (if (= isAvailable true)
              (update priority-collection
                  (concat [collection-name "|" account]) {
                  "collection-name": collection-name,
                  "claimed": true
              })
              (insert priority-collection
                  (concat [collection-name "|" account]) {
                  "collection-name": collection-name,
                  "claimed": true
              })
          )

          ;; Burn priority pass
          (free.kmpasstest003.burn account acc-guard)
          true
      )
  )

  (defun mint-for-price
      (account:string
       collection-name:string
       amount:integer)

      @doc "Process paid mint"

      (require-capability (MINT-NFT account))

      (let* (
          (whitelist-enabled:bool (check-whitelist collection-name))
          (creator:string (get-collection-creator collection-name))
          (wl-accounts:[string] (get-whitelist-accounts collection-name))
          (contain:bool (contains account wl-accounts))
      )
          (cond
              ;; Whitelist mint
              (whitelist-enabled
                  [
                      (enforce (= contain true) "Not whitelisted")
                      (enforce-whitelist account
                          (at 'guard (coin.details account))
                          collection-name)
                      (let ((claimed:integer
                              (at 'claimed (get-whitelist-info account collection-name)))
                            (price:decimal (get-wl-price collection-name)))
                          (coin.transfer account creator (* amount price))
                          (update whitelists
                              (concat [collection-name "|" account]) {
                              "claimed": (+ claimed 1)
                          })
                      )
                  ]
              )
              ;; Public mint
              [(check-public collection-name)
               (coin.transfer account creator
                  (* amount (get-mint-price collection-name)))]
          )
      )
  )

  (defun get-mint-token-id:string
      (collection:string
       accountId:integer)

      @doc "Generate unique token ID"
      (concat [collection "|" (int-to-str 10 accountId)])
  )

  ;-----------------------------------------------------------------------------
  ; Whitelist Functions
  ;-----------------------------------------------------------------------------

  (defun create-whitelist:[string]
      (collection-name:string
       creator:string
       creator-guard:guard
       wl-addresses:[string]
       wl-price:decimal
       wl-time:time)

      @doc "Create whitelist for collection"

      ;; Basic validation
      (enforce (!= collection-name "") "Collection name cannot be empty")
      (enforce (> (length wl-addresses) 0) "Whitelist cannot be empty")
      (enforce (>= wl-price MIN_PRICE) "Price below minimum")

      (with-capability (PRIVATE)
          ;; Verify creator and collection status
          (enforce-owner collection-name creator-guard)
          (let (
              (enabled:bool (get-wl-enabled collection-name))
              (launched:bool (is_col_launched collection-name))
          )
              (enforce (= launched true) "Collection not launched")
              (enforce (= enabled true) "Whitelist is disabled")

              ;; Update collection with whitelist info
              (update collections collection-name {
                  "whitelist-addresses": (+ (get-whitelist-accounts collection-name) wl-addresses),
                  "whitelist-start-time": wl-time,
                  "wl-price": wl-price,
                  "last-updated": (at "block-time" (chain-data))
              })

              ;; Add whitelist entries
              (add-whitelists collection-name wl-addresses creator-guard)

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "create-whitelist",
                  "account": creator,
                  "timestamp": (at "block-time" (chain-data)),
                  "details": {
                      "collection": collection-name,
                      "addresses": wl-addresses,
                      "price": wl-price
                  },
                  "status": "completed",
                  "tx-hash": (hash (at "block-time" (chain-data)))
              })
          )
      )
  )

  (defun add-wl-accounts
      (collection-name:string
       wl-addresses:[string]
       creator-guard:guard)

      @doc "Add additional addresses to whitelist"

      (enforce-owner collection-name creator-guard)
      (enforce (> (length wl-addresses) 0) "Address list empty")

      (with-capability (PRIVATE)
          ;; Update collection whitelist
          (update collections collection-name {
              "whitelist-addresses": (+ (get-whitelist-accounts collection-name) wl-addresses),
              "last-updated": (at "block-time" (chain-data))
          })

          ;; Process new whitelist entries
          (add-whitelists collection-name wl-addresses creator-guard)

          ;; Log operation
          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "add-whitelist-accounts",
              "account": (at "sender" (chain-data)),
              "timestamp": (at "block-time" (chain-data)),
              "details": {
                  "collection": collection-name,
                  "new-addresses": wl-addresses
              },
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun add-whitelists
      (collection-name:string
       accounts:[string]
       creator-guard:guard)

      @doc "Internal function to process whitelist additions"

      (require-capability (PRIVATE))
      (map (add-whitelist collection-name) accounts)
  )

  (defun add-whitelist
      (collection-name:string
       account:string)

      @doc "Add single account to whitelist"

      (require-capability (PRIVATE))
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)

      ;; Create whitelist entry
      (insert whitelists (concat [collection-name "|" account]) {
          "account": account,
          "guard": (at 'guard (coin.details account)),
          "claimed": 0,
          "max-allowed": MAX_MINT_PER_TX,
          "expiry": (get-mint-start-time collection-name),
          "mint-price": (get-wl-price collection-name),
          "added-by": (at "sender" (chain-data)),
          "added-time": (at "block-time" (chain-data))
      })
  )

  (defun remove-whitelist-addresses
      (collection-name:string
       creator-guard:guard
       addresses:[string])

      @doc "Remove addresses from whitelist"

      (with-capability (PRIVATE)
          (enforce-owner collection-name creator-guard)
          (enforce (> (length addresses) 0) "Address list empty")

          (map (remove-whitelist-address collection-name) addresses)

          ;; Log operation
          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "remove-whitelist-addresses",
              "account": (at "sender" (chain-data)),
              "timestamp": (at "block-time" (chain-data)),
              "details": {
                  "collection": collection-name,
                  "removed-addresses": addresses
              },
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun remove-whitelist-address
    (collection-name:string
     address:string)
    @doc "Remove single address from whitelist"
    (require-capability (PRIVATE))
    (let* (
        (wl-addresses:[string] (get-whitelist-accounts collection-name))
        (contain:bool (contains address wl-addresses))
    )
        (if (= contain true)
            [(update collections collection-name {
                "whitelist-addresses": (filter (!= address) wl-addresses),
                "last-updated": (at "block-time" (chain-data))
            })
            ;; Instead of delete, write with default values
            (write whitelists (concat [collection-name "|" address]) {
                "account": address,
                "guard": (at 'guard (coin.details address)),
                "claimed": 0,
                "max-allowed": 0,
                "expiry": (at "block-time" (chain-data)),
                "mint-price": 0.0,
                "added-by": "",
                "added-time": (at "block-time" (chain-data))
            })]
            "Account not in whitelist"
        )
    )
)

  (defun update-wl-price
      (collection-name:string
       creator-guard:guard
       price:decimal)

      @doc "Update whitelist price"

      (enforce-owner collection-name creator-guard)
      (enforce (>= price MIN_PRICE) "Price below minimum")

      (update collections collection-name {
          "wl-price": price,
          "last-updated": (at "block-time" (chain-data))
      })

      ;; Log operation
      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "update-whitelist-price",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": {
              "collection": collection-name,
              "new-price": price
          },
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )

  (defun enforce-whitelist:bool
      (account:string
       guard:guard
       collection-name:string)

      @doc "Validate whitelist status for account"

      (with-read whitelists (concat [collection-name "|" account]) {
          'guard := g,
          'claimed := claimed,
          'max-allowed := max-allowed
      }
          (enforce (= g guard) "Invalid guard")
          (enforce (< claimed max-allowed) "Exceeded whitelist allocation")
          true
      )
  )


  ;-----------------------------------------------------------------------------
  ; Presale Functions
  ;-----------------------------------------------------------------------------

;    (defun enforce-presale
;        (account:string
;         collection-name:string)

;        @doc "Enforce presale constraints"

;        (enforce (!= account "") "Account cannot be empty")
;        (enforce (!= collection-name "") "Collection name cannot be empty")

;        (let ((accounts:[string] (get-presale-accounts collection-name)))
;            ;; Validate presale eligibility
;            (enforce (contains account accounts) "Not in presale list")

;            ;; Validate presale timing
;            (enforce-guard (at-after-date (get-presale-start-time collection-name)))
;            (enforce-guard (before-date (get-presale-end-time collection-name)))

;            ;; Log validation
;            (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
;                "operation": "presale-validation",
;                "account": account,
;                "timestamp": (at "block-time" (chain-data)),
;                "details": {
;                    "collection": collection-name,
;                    "type": "presale-check"
;                },
;                "status": "completed",
;                "tx-hash": (hash (at "block-time" (chain-data)))
;            })
;        )
;    )

(defun enforce-presale
    (account:string
     collection-name:string)

    @doc "Enforce presale constraints"
    (enforce (!= account "") "Account cannot be empty")
    (enforce (!= collection-name "") "Collection name cannot be empty")

    (let ((accounts:[string] (get-presale-accounts collection-name))
          (current-time (at 'block-time (chain-data)))
          (presale-start (get-presale-start-time collection-name))
          (presale-end (get-presale-end-time collection-name)))
        (enforce (contains account accounts) "Not in presale list")
        (enforce (>= current-time presale-start) "Presale has not started")
        (enforce (<= current-time presale-end) "Presale has ended")
    )
)

  (defun create-presale
      (creator:string
       creator-guard:guard
       collection-name:string
       presale-mint-price:decimal
       presale-start-date:string
       presale-start-time:time
       presale-end-date:string
       presale-end-time:time
       addresses:[string])

      @doc "Create presale for collection"

      (with-capability (PRIVATE)
          ;; Validate creator and inputs
          (enforce-owner collection-name creator-guard)
          (enforce (>= presale-mint-price MIN_PRICE) "Price below minimum")
          (enforce (> (length addresses) 0) "Address list empty")

          (let (
              (enabled:bool (get-presale-enabled collection-name))
              (launched:bool (is_col_launched collection-name))
              (wl-enabled:bool (check-whitelist collection-name))
              (public-enabled:bool (check-public collection-name))
              (mint-end-time:time (get-mint-end-time collection-name))
              (chain-time:time (at 'block-time (chain-data)))
          )
              ;; Validate collection state
              (enforce (<= chain-time mint-end-time) "Mint not live")
              (enforce (= launched true) "Collection not launched")
              (enforce (!= wl-enabled true) "Whitelist sale is live")
              (enforce (!= public-enabled true) "Public sale is live")
              (enforce (= enabled true) "Presale is disabled")

              ;; Update collection with presale info
              (update collections collection-name {
                  'presale-start-date: presale-start-date,
                  'presale-start-time: presale-start-time,
                  'presale-end-date: presale-end-date,
                  'presale-end-time: presale-end-time,
                  'presale-mint-price: presale-mint-price,
                  'presale-addresses: (+ (get-presale-accounts collection-name) addresses),
                  'last-updated: chain-time
              })

              ;; Add presale addresses
              (add-presale-addresses collection-name addresses)

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "create-presale",
                  "account": creator,
                  "timestamp": chain-time,
                  "details": {
                      "collection": collection-name,
                      "addresses": addresses,
                      "price": presale-mint-price
                  },
                  "status": "completed",
                  "tx-hash": (hash chain-time)
              })
          )
      )
  )

  (defun mint-presale-nft
      (account:string
       collection-name:string
       amount:integer)

      @doc "Process presale mint"

      (with-capability (RESERVE collection-name)
          ;; Validate presale timing
          (if (< (diff-time (at 'block-time (chain-data))
                           (get-presale-start-time collection-name)) 0.0)
              (enforce-presale account collection-name)
              "Presale ended"
          )

          ;; Process payment
          (let (
              (creator:string (get-collection-creator collection-name))
              (g:guard (at 'guard (coin.details account)))
              (nft-amount:integer (+ amount (get-nft-reserved collection-name account)))
              (price:decimal (* (get-presale-mint-price collection-name) amount))
          )
              ;; Transfer payment
              (coin.transfer account creator price)

              ;; Record reservation
              (write reservations (concat [collection-name "|" account]) {
                  "account": account,
                  "amount-nft": nft-amount,
                  "guard": g,
                  "price": price,
                  "reservation-time": (at "block-time" (chain-data)),
                  "expiry-time": (get-presale-end-time collection-name),
                  "status": "active",
                  "collection-name": collection-name
              })

              ;; Update presale status
              (update presale-ledger (concat [collection-name "|" account]) {
                  "claimed": true
              })

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "presale-mint",
                  "account": account,
                  "timestamp": (at "block-time" (chain-data)),
                  "details": {
                      "collection": collection-name,
                      "amount": amount,
                      "price": price
                  },
                  "status": "completed",
                  "tx-hash": (hash (at "block-time" (chain-data)))
              })

              (format "{} reserved NFT with {} KDA" [account, price])
          )
      )
  )

  (defun add-presale-accounts
      (collection-name:string
       presale-addresses:[string]
       creator-guard:guard)

      @doc "Add addresses to presale list"

      (enforce-owner collection-name creator-guard)
      (let (
          (enabled:bool (get-presale-enabled collection-name))
          (launched:bool (is_col_launched collection-name))
          (presaleLive:bool (check-presale collection-name))
      )
          (with-capability (PRIVATE)
              ;; Validate collection state
              (enforce (= launched true) "Collection not launched")
              (enforce (= enabled true) "Presale is disabled")
              (enforce (= presaleLive false) "Presale is live")

              ;; Update collection
              (update collections collection-name {
                  "presale-addresses": (+ (get-presale-accounts collection-name)
                                        presale-addresses),
                  "last-updated": (at "block-time" (chain-data))
              })

              ;; Add addresses
              (add-presale-addresses collection-name presale-addresses)

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "add-presale-accounts",
                  "account": (at "sender" (chain-data)),
                  "timestamp": (at "block-time" (chain-data)),
                  "details": {
                      "collection": collection-name,
                      "new-addresses": presale-addresses
                  },
                  "status": "completed",
                  "tx-hash": (hash (at "block-time" (chain-data)))
              })
          )
      )
  )

  (defun add-presale-addresses
      (collection-name:string
       accounts:[string])

      @doc "Internal function to add presale addresses"

      (require-capability (PRIVATE))
      (map (add-presale-address collection-name) accounts)
  )

  (defun add-presale-address
      (collection-name:string
       account:string)

      @doc "Add single presale address"

      (require-capability (PRIVATE))
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)

      (insert presale-ledger (concat [collection-name "|" account]) {
          "collection-name": collection-name,
          "account": account,
          "claimed": false
      })
  )

  ;-----------------------------------------------------------------------------
  ; Free Mint Functions
  ;-----------------------------------------------------------------------------

  (defun create-free-mint:string
      (collection-name:string
       creator:string
       free-mint-supply:integer
       start-time:time
       end-time:time
       creator-guard:guard)

      @doc "Create free mint allocation for collection"

      (with-capability (PRIVATE)
          (enforce-owner collection-name creator-guard)

          (let* (
              (enabled:bool (get-free-mint-enabled collection-name))
              (launched:bool (is_col_launched collection-name))
              (total-collection-supply:integer (get-total-supply collection-name))
              (current-time:time (at "block-time" (chain-data)))
              (normal-mints-used:integer (get-current-index collection-name))
              (existing-free-mints:integer
                  (with-default-read free-mint-ledger collection-name
                      {'total-supply: 0}
                      {'total-supply := ts}
                      ts))
              (total-minted-or-allocated:integer
                  (+ normal-mints-used existing-free-mints))
              (available-supply:integer
                  (- total-collection-supply total-minted-or-allocated))
          )
              ;; Basic validation
              (enforce (= launched true) "Collection not launched")
              (enforce (= enabled true) "Free mint disabled")
              (enforce (< start-time end-time) "Invalid time range")
              (enforce (>= end-time current-time) "End time must be future")

              ;; Supply validation
              (enforce (<= free-mint-supply available-supply)
                  (format "Requested supply {} exceeds available {}"
                      [free-mint-supply, available-supply]))
              (enforce (> free-mint-supply 0) "Supply must be positive")

              ;; Create free mint record
              (write free-mint-ledger collection-name {
                  'total-supply: free-mint-supply,
                  'current-index: 1,
                  'start-time: start-time,
                  'end-time: end-time,
                  'is-active: true
              })

              ;; Update ledgers
              (write token-ledger collection-name {
                  'current-length: free-mint-supply
              })

              (update collections collection-name {
                  'total-supply: (- total-collection-supply free-mint-supply),
                  'last-updated: current-time
              })

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "create-free-mint",
                  "account": creator,
                  "timestamp": current-time,
                  "details": {
                      "collection": collection-name,
                      "supply": free-mint-supply,
                      "start": start-time,
                      "end": end-time
                  },
                  "status": "completed",
                  "tx-hash": (hash current-time)
              })

              "Free mint created successfully"
          )
      )
  )

  (defun cancel-free-mint:string
      (collection-name:string
       creator-guard:guard)

      @doc "Cancel active free mint and restore supply"

      (with-capability (PRIVATE)
          (enforce-owner collection-name creator-guard)

          (with-read free-mint-ledger collection-name
              {'total-supply := total-fm-supply,
               'current-index := current-idx,
               'is-active := is-active}

              (if (= is-active true)
                  (let* (
                      (used-supply:integer
                          (if (> current-idx 1) (- current-idx 1) 0))
                      (original-collection-supply:integer
                          (at 'total-supply (read collections collection-name)))
                      (unused-fm-supply:integer
                          (- total-fm-supply used-supply))
                      (restored-supply:integer
                          (+ original-collection-supply unused-fm-supply))
                  )
                      ;; Update free mint status
                      (write free-mint-ledger collection-name {
                          'total-supply: used-supply,
                          'current-index: current-idx,
                          'start-time: (time "1970-01-01T00:00:00Z"),
                          'end-time: (time "1970-01-01T00:00:00Z"),
                          'is-active: false
                      })

                      ;; Restore unused supply
                      (update collections collection-name {
                          'total-supply: restored-supply,
                          'last-updated: (at "block-time" (chain-data))
                      })

                      ;; Log operation
                      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                          "operation": "cancel-free-mint",
                          "account": (at "sender" (chain-data)),
                          "timestamp": (at "block-time" (chain-data)),
                          "details": {
                              "collection": collection-name,
                              "restored-supply": unused-fm-supply
                          },
                          "status": "completed",
                          "tx-hash": (hash (at "block-time" (chain-data)))
                      })

                      "Free mint cancelled, remaining supply returned"
                  )
                  "Free mint was already cancelled"
              )
          )
      )
  )

  (defun mint-internal-free-mint:bool
      (collection-name:string
       account:string
       guard:guard
       amount:integer
       normal-index:integer
       free-mint-index:integer)

      @doc "Internal function to process free mint"

      (require-capability (MINT-NFT account))

      ;; Process individual token mints
      (map
          (mint-token collection-name account guard)
          (map (+ free-mint-index) (enumerate 0 (- amount 1)))
      )

      (emit-event (MINT_EVENT collection-name account amount))
      true
  )

  (defun reserve-token-free-mint:bool
      (collection-name:string
       account:string
       amount:integer)

      @doc "Process free mint reservation"

      (enforce (= amount 1) "Can only mint 1 token at a time")

      (with-default-read collections collection-name
          {"allow-free-mints": false}
          {"allow-free-mints" := free-mints-enabled}
          (enforce free-mints-enabled "Free mints not enabled")

          (with-read free-mint-ledger collection-name
              {'total-supply := total-supply,
               'current-index := current-index,
               'start-time := start-time,
               'end-time := end-time,
               'is-active := is-active}

              ;; Validate free mint state
              (enforce (> total-supply 0) "Free mint not initialized")
              (enforce is-active "Free mint not active")

              (let ((current-time:time (at "block-time" (chain-data))))
                  (enforce (>= current-time start-time) "Not started")
                  (enforce (<= current-time end-time) "Ended")

                  ;; Check claim status
                  (let ((claimed (has-claimed collection-name account)))
                      (enforce (not claimed) "Already claimed")

                      (let ((used-mints (- current-index 1)))
                          (enforce (<= (+ used-mints amount) total-supply)
                              "No more free mints available")

                          (with-capability (MINT-NFT account)
                              ;; Initialize account info
                              (write accountsInfo
                                  (concat [collection-name "|" account])
                                  {
                                      "account": account,
                                      "collection-name": collection-name,
                                      "tokens": [],
                                      "last-updated": (at "block-time" (chain-data)),
                                      "total-value": 0.0
                                  })

                              ;; Mark as claimed
                              (write free-mint-account-ledger
                                  (concat [collection-name "|" account])
                                  {
                                      'account: account,
                                      'collection-name: collection-name,
                                      'claimed: true,
                                      'claim-time: current-time,
                                      'claim-index: current-index
                                  })

                              ;; Update index
                              (update free-mint-ledger collection-name
                                  {'current-index: (+ current-index amount)})

                              ;; Mint token
                              (mint-internal-free-mint
                                  collection-name
                                  account
                                  (at "guard" (coin.details account))
                                  amount
                                  0
                                  current-index)

                              ;; Log operation
                              (insert operation-logs
                                  (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                                  "operation": "free-mint",
                                  "account": account,
                                  "timestamp": current-time,
                                  "details": {
                                      "collection": collection-name,
                                      "amount": amount
                                  },
                                  "status": "completed",
                                  "tx-hash": (hash current-time)
                              })

                              true
                          )
                      )
                  )
              )
          )
      )
  )

  ;-----------------------------------------------------------------------------
  ; Airdrop Functions
  ;-----------------------------------------------------------------------------

  (defun create-airdrop
      (collection-name:string
       creator-guard:guard
       airdrop-addresses:[string])

      @doc "Create airdrop for collection"

      (with-capability (PRIVATE)
          (enforce-owner collection-name creator-guard)
          (enforce (> (length airdrop-addresses) 0) "Empty address list")

          (let (
              (enabled:bool (get-airdrop-enabled collection-name))
              (launched:bool (is_col_launched collection-name))
          )
              ;; Validate collection state
              (enforce (= launched true) "Collection not launched")
              (enforce (= enabled true) "Airdrop is disabled")

              ;; Add addresses and initialize token tracking
              (add-to-airdrop collection-name airdrop-addresses)
              (map (add-tokens-for-airdrop collection-name) airdrop-addresses)

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "create-airdrop",
                  "account": (at "sender" (chain-data)),
                  "timestamp": (at "block-time" (chain-data)),
                  "details": {
                      "collection": collection-name,
                      "addresses": airdrop-addresses
                  },
                  "status": "completed",
                  "tx-hash": (hash (at "block-time" (chain-data)))
              })
          )
      )
  )

  (defun add-tokens-for-airdrop
      (collection-name:string
       account:string)

      @doc "Initialize token tracking for airdrop recipient"

      (require-capability (PRIVATE))
      (enforce-valid-account account)

      (write accountsInfo (concat [collection-name "|" account]) {
          "account": account,
          "collection-name": collection-name,
          "tokens": [],
          "last-updated": (at "block-time" (chain-data)),
          "total-value": 0.0
      })
  )

  (defun add-to-airdrop
      (collection-name:string
       addresses:[string])

      @doc "Add addresses to airdrop list"

      (require-capability (PRIVATE))
      (update collections collection-name {
          "airdrop-addresses": (+ (get-airdrop-accounts collection-name) addresses),
          "last-updated": (at "block-time" (chain-data))
      })
  )

  (defun bulk-airdrop
      (collection-name:string
       data:list
       creator:string
       creator-guard:guard)

      @doc "Process bulk airdrop operation"

      (enforce-owner collection-name creator-guard)
      (enforce (> (length data) 0) "Empty airdrop data")

      (with-capability (PRIVATE)
          ;; Process airdrops
          (map (airdrop-nft) data)

          ;; Log operation
          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "bulk-airdrop",
              "account": creator,
              "timestamp": (at "block-time" (chain-data)),
              "details": {
                  "collection": collection-name,
                  "count": (length data)
              },
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun airdrop-nft:string
      (data:object)

      @doc "Process single token airdrop"

      (enforce (!= (at 'account data) "") "Account cannot be empty")
      (require-capability (PRIVATE))

      (let* (
          (collection-name:string (at 'collection-name data))
          (airdrop-addresses:[string] (get-airdrop-accounts collection-name))
          (token_id:string (at 'token-id data))
          (creator:string (get-collection-creator collection-name))
          (account:string (at 'account data))
      )
          ;; Transfer token
          (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger.transfer-create
              token_id
              creator
              account
              (at 'guard (coin.details account))
              1.0)

          ;; Update counts
          (increase-count collection-name)

          ;; Record airdrop
          (insert airdrop-history-table
              (int-to-str 10 (+ 1 (get-count collection-name))) {
              'collection-name: collection-name,
              'account: account,
              'token-id: token_id,
              'airdrop-time: (at "block-time" (chain-data)),
              'sender: creator,
              'transaction-hash: (hash (at "block-time" (chain-data)))
          })

          ;; Update account tokens
          (with-read accountsInfo
              (concat [collection-name "|" account])
              {"tokens" := tokens}

              (let ((col-token:string (concat [collection-name "|" token_id])))
                  (update accountsInfo
                      (concat [collection-name "|" account]) {
                      "tokens": (+ tokens [col-token]),
                      "last-updated": (at "block-time" (chain-data))
                  })
              )
          )

          token_id
      )
  )

  (defun remove-airdrop-addresses
      (collection-name:string
       creator-guard:guard
       addresses:[string])

      @doc "Remove addresses from airdrop list"

      (with-capability (PRIVATE)
          (enforce-owner collection-name creator-guard)
          (enforce (> (length addresses) 0) "Empty address list")

          (map (remove-airdrop-address collection-name) addresses)

          ;; Log operation
          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "remove-airdrop-addresses",
              "account": (at "sender" (chain-data)),
              "timestamp": (at "block-time" (chain-data)),
              "details": {
                  "collection": collection-name,
                  "removed": addresses
              },
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun remove-airdrop-address
      (collection-name:string
       address:string)

      @doc "Remove single address from airdrop list"

      (require-capability (PRIVATE))
      (let* (
          (airdrop-addresses:[string] (get-airdrop-accounts collection-name))
          (contain:bool (contains address airdrop-addresses))
      )
          (if (= contain true)
              [(update collections collection-name {
                  "airdrop-addresses": (filter (!= address) airdrop-addresses),
                  "last-updated": (at "block-time" (chain-data))
              })]
              "Account not in airdrop list"
          )
      )
  )


  ;-----------------------------------------------------------------------------
  ; Priority User Functions
  ;-----------------------------------------------------------------------------

  (defun add-priority-user
      (account:string)

      @doc "Add single account to priority users"

      (with-capability (PRIVATE)
          (enforce (!= account "") "Account cannot be empty")
          (enforce-valid-account account)

          ;; Insert priority record
          (insert priority account {
              "account": account,
              "guard": (at 'guard (coin.details account)),
              "priority-level": 1,
              "expiry": (add-time (at "block-time" (chain-data))
                                 (* 24.0 3600.0 30.0)), ; 30 days
              "granted-by": (at "sender" (chain-data)),
              "granted-time": (at "block-time" (chain-data))
          })

          ;; Log operation
          (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
              "operation": "add-priority-user",
              "account": (at "sender" (chain-data)),
              "timestamp": (at "block-time" (chain-data)),
              "details": {"account": account},
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
      )
  )

  (defun add-priority-users
      (accounts:[string])

      @doc "Add multiple priority users"

      (enforce (> (length accounts) 0) "Empty account list")
      (map (add-priority-user) accounts)
  )

  (defun claim-pass-nft
      (collection-name:string
       account:string
       creator-guard:guard)

      @doc "Initialize priority pass claim for collection"

      (enforce-owner collection-name creator-guard)
      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)

      ;; Insert priority collection record
      (insert priority-collection
          (concat [collection-name "|" account])
          {
              "collection-name": collection-name,
              "claimed": false
          }
      )

      ;; Log operation
      (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "claim-pass-init",
          "account": account,
          "timestamp": (at "block-time" (chain-data)),
          "details": {"collection": collection-name},
          "status": "completed",
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
  )

  (defun enforce-priority
      (account:string
       guard:guard)

      @doc "Validate priority status"

      (with-read priority account {
          'guard := g,
          'expiry := expiry
      }
          (enforce (= g guard) "Invalid guard")
          (enforce (< (at "block-time" (chain-data)) expiry)
              "Priority status expired")
      )
  )

  (defun upgrade-priority-level
      (account:string
       new-level:integer)

      @doc "Upgrade account priority level"

      (with-capability (IS_ADMIN)
          (enforce (!= account "") "Account cannot be empty")
          (enforce (> new-level 0) "Invalid priority level")

          (with-read priority account {
              'guard := guard,
              'expiry := expiry
          }
              (update priority account {
                  "priority-level": new-level,
                  "last-updated": (at "block-time" (chain-data))
              })

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "upgrade-priority",
                  "account": (at "sender" (chain-data)),
                  "timestamp": (at "block-time" (chain-data)),
                  "details": {
                      "account": account,
                      "new-level": new-level
                  },
                  "status": "completed",
                  "tx-hash": (hash (at "block-time" (chain-data)))
              })
          )
      )
  )

  (defun extend-priority-expiry
      (account:string
       days:decimal)

      @doc "Extend priority status duration"

      (with-capability (IS_ADMIN)
          (enforce (!= account "") "Account cannot be empty")
          (enforce (> days 0.0) "Invalid duration")

          (with-read priority account {
              'expiry := current-expiry
          }
              (update priority account {
                  "expiry": (add-time current-expiry (* days 24.0 3600.0)),
                  "last-updated": (at "block-time" (chain-data))
              })

              ;; Log operation
              (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                  "operation": "extend-priority",
                  "account": (at "sender" (chain-data)),
                  "timestamp": (at "block-time" (chain-data)),
                  "details": {
                      "account": account,
                      "days-added": days
                  },
                  "status": "completed",
                  "tx-hash": (hash (at "block-time" (chain-data)))
              })
          )
      )
  )

  (defun revoke-priority
    (account:string)
    @doc "Revoke priority status"

    (with-capability (IS_ADMIN)
        (enforce (!= account "") "Account cannot be empty")

        ;; Instead of delete, use write with empty/null values or default values
        (write priority account {
            "account": account,
            "guard": (at 'guard (coin.details account)),
            "priority-level": 0,  
            "expiry": (at "block-time" (chain-data)),  
            "granted-by": "",
            "granted-time": (at "block-time" (chain-data))
        })

        ;; Log operation
        (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
            "operation": "revoke-priority",
            "account": (at "sender" (chain-data)),
            "timestamp": (at "block-time" (chain-data)),
            "details": {"account": account},
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })
    )
)

  (defun get-priority-details
      (account:string)

      @doc "Get priority status details"

      (enforce (!= account "") "Account cannot be empty")
      (enforce-valid-account account)

      (with-read priority account {
          "priority-level" := level,
          "expiry" := expiry,
          "granted-time" := granted
      }
          {
              "account": account,
              "level": level,
              "expiry": expiry,
              "granted": granted,
              "days-remaining": (/ (diff-time expiry (at "block-time" (chain-data)))
                                 (* 24.0 3600.0))
          }
      )
  )


  ;-----------------------------------------------------------------------------
  ; Utility and Helper Functions
  ;-----------------------------------------------------------------------------

  (defun increase-count
      (collection-name:string)

      @doc "Increment counter for collection"

      (require-capability (PRIVATE))
      (enforce (!= collection-name "") "Collection name cannot be empty")

      (update counts-table collection-name {
          "count": (+ 1 (get-count collection-name)),
          "last-updated": (at "block-time" (chain-data))
      })
  )


  (defun is_col_launched:bool (collection-name:string)
      @doc "Check if collection is launched"
      (with-read collections collection-name
          { "launched" := launched }
          (enforce launched "Collection not launched")
          launched
      )
  )

  (defun has-claimed:bool (collection-name:string account:string)
      @doc "Check if account has claimed free mint"
      (with-default-read free-mint-account-ledger (concat [collection-name "|" account])
          { "claimed": false }
          { "claimed" := claimed }
          claimed
      )
  )

 

;    (defun get-count:integer
;        (collection-name:string)

;        @doc "Get current count for collection"

;        (enforce (!= collection-name "") "Collection name cannot be empty")
;        (at "count" (read counts-table collection-name ['count]))
;    )

(defun get-count:integer
    (collection-name:string)
    @doc "Get current count for collection. Returns 0 if collection not found."
    (enforce (!= collection-name "") "Collection name cannot be empty")
    (with-default-read counts-table collection-name
        { "count": 0 }  ; Default value if entry doesn't exist
        { "count" := count }  ; Destructure the count value
        count  ; Return the count value
    )
)



  (defun get-random:integer
      (account:string)

      @doc "Generate deterministic random number for account"

      (require-capability (PRIVATE))
      (enforce (!= account "") "Account cannot be empty")

      (let* (
          (prev-block-hash (at "prev-block-hash" (chain-data)))
          (random (str-to-int 64 (hash (+ prev-block-hash (take 20 account)))))
      )
          random
      )
  )

  (defun custom-time-format:string
    (format:string
     time:time)
    @doc "Format time according to specified format"
    (enforce (!= format "") "Format cannot be empty")
    (at "formatted" {
        "formatted": (format "{format}" [time])
    })
)

  (defun validate-account:bool
    (account:string)
    @doc "Validate account format and existence"
    (enforce (!= account "") "Account cannot be empty")
    (enforce-valid-account account)
    true
)

  (defun validate-collection:bool
      (collection-name:string)

      @doc "Validate collection exists and is launched"

      (enforce (!= collection-name "") "Collection name cannot be empty")
      (with-read collections collection-name {
          "launched" := launched
      }
          (enforce launched "Collection not launched")
          true
      )
  )

  (defun check-rate-limit:bool
      (operation:string
       account:string)

      @doc "Enforce rate limiting for operations"

      (let* (
          (current-time:time (at "block-time" (chain-data)))
          (rate-key:string (concat [operation "|" account]))
      )
          (with-default-read rate-limits rate-key
              { "last-call": (time "1970-01-01T00:00:00Z"),
                "call-count": 0 }
              { "last-call" := last-call,
                "call-count" := count }

              (let* (
                  (time-diff:decimal (diff-time current-time last-call))
                  (window:decimal 3600.0) ; 1 hour window
              )
                  (if (> time-diff window)
                      ;; Reset counter for new window
                      (write rate-limits rate-key {
                          "last-call": current-time,
                          "call-count": 1
                      })
                      ;; Increment within window
                      (do
                          (enforce (<= count 10) "Rate limit exceeded")
                          (write rate-limits rate-key {
                              "last-call": current-time,
                              "call-count": (+ count 1)
                          })
                      )
                  )
                  true
              )
          )
      )
  )

  (defun log-operation:string
      (operation:string
       account:string
       details:object)

      @doc "Log operation with details"

      (require-capability (PRIVATE))
      (let (
          (log-id:string (int-to-str 10 (+ 1 (get-count "operation-logs"))))
      )
          (insert operation-logs log-id {
              "operation": operation,
              "account": account,
              "timestamp": (at "block-time" (chain-data)),
              "details": details,
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
          log-id
      )
  )

  (defun concat-all:[string]
      (elements:[string])

      @doc "Concatenate list of strings"

      (enforce (> (length elements) 0) "Empty list")
      (fold (+) "" elements)
  )

  (defun get-time-diff:decimal
      (time1:time
       time2:time)

      @doc "Get time difference in seconds"

      (diff-time time1 time2)
  )

  (defun is-expired:bool
      (expiry:time)

      @doc "Check if time is expired"

      (> (at "block-time" (chain-data)) expiry)
  )

  (defun get-current-time:time ()
      @doc "Get current blockchain time"

      (at "block-time" (chain-data))
  )

  (defun clean-string:string
      (input:string)

      @doc "Clean and validate string input"

      (enforce (!= input "") "Empty string")
      (let ((cleaned (take 1000 input))) ; Limit string length
          (enforce (= (length cleaned) (length input))
              "String too long")
          cleaned
      )
  )

  (defun validate-price:decimal
      (price:decimal)

      @doc "Validate price value"

      (enforce (>= price 0.0) "Negative price")
      (enforce (>= price MIN_PRICE) "Price below minimum")
      price
  )

  (defun handle-error:string
      (error:string
       details:object)

      @doc "Standard error handling"

      (insert operation-logs
          (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
          "operation": "error",
          "account": (at "sender" (chain-data)),
          "timestamp": (at "block-time" (chain-data)),
          "details": details,
          "status": "error",
          "error": error,
          "tx-hash": (hash (at "block-time" (chain-data)))
      })
      error
  )

  (defun init-state:string ()
      @doc "Initialize contract state"

      (with-capability (IS_ADMIN)
          (insert operation-logs "0" {
              "operation": "init",
              "account": (at "sender" (chain-data)),
              "timestamp": (at "block-time" (chain-data)),
              "details": {},
              "status": "completed",
              "tx-hash": (hash (at "block-time" (chain-data)))
          })
          "State initialized"
      )
  )


;-----------------------------------------------------------------------------
; Initialization Functions
;-----------------------------------------------------------------------------

(defun init (fee:decimal discount:decimal)
    @doc "Initialize contract with fee and role settings"
    (with-capability (IS_ADMIN)
        ; Initialize fee ledger
        (write fee-ledger LAUNCH {
            "fee": fee,
            "discount": discount,
            "minimum-fee": 0.000001,
            "last-updated": (at "block-time" (chain-data)),
            "updated-by": (at "sender" (chain-data))
        })

        ; Initialize prime role
        (write prime_role PRIME {
            "accounts": "",
            "benefits": [],
            "updated-at": (at "block-time" (chain-data)),
            "updated-by": (at "sender" (chain-data))
        })

        ; Initialize discount role 
        (write discount_role DISCOUNT {
            "accounts": "",
            "discount-rate": discount,
            "updated-at": (at "block-time" (chain-data)),
            "updated-by": (at "sender" (chain-data))
        })

        ; Log initialization
        (write operation-logs "init" {
            "operation": "init",
            "account": (at "sender" (chain-data)),
            "timestamp": (at "block-time" (chain-data)),
            "details": {
                "fee": fee,
                "discount": discount
            },
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })
    )
)

;-----------------------------------------------------------------------------
; Collection Launch Functions
;-----------------------------------------------------------------------------

(defun launch-collection:string (collection-name:string)
    @doc "Enhanced launch function with better validation and cleanup"
    
    (with-capability (IS_ADMIN)
        ;; Verify collection status
        (let ((status (verify-collection-status collection-name)))
            (enforce (= (at "status" status) "PENDING") 
                "Collection must be in PENDING state to launch"))

        ;; Read collection details from request ledger
        (with-read request-collection-ledger collection-name {
            "collection-name" := collection-name,
            "symbol" := symbol,
            "creator" := creator,
            "creator-guard" := guard,
            "description" := description,
            "category" := category,
            "total-supply" := total-supply,
            "urisIPFS" := urisIPFS,
            "mint-price" := mint-price,
            "wl-price" := wl-price,
            "royalty-percentage" := royalty-percentage,
            "royalty-address" := royalty-address,
            "cover-image-url" := cover-image-url,
            "banner-image-url" := banner-image-url,
            "mint-start-date" := mint-start-date,
            "mint-start-time" := mint-start-time,
            "mint-end-date" := mint-end-date,
            "mint-end-time" := mint-end-time,
            "allow-free-mints" := allow-free-mints,
            "enable-whitelist" := enable-whitelist,
            "whitelist-addresses" := wl-addresses,
            "whitelist-start-time" := wl-time,
            "enable-presale" := enable-presale,
            "presale-addresses" := presale-addresses,
            "presale-start-date" := presaleStartDate,
            "presale-start-time" := presaleStartTime,
            "presale-end-date" := presaleEndDate,
            "presale-end-time" := presaleEndTime,
            "presale-mint-price" := preSaleMintPrice,
            "enable-airdrop" := enable-airdrop,
            "airdrop-supply" := airdropSupply,
            "airdrop-addresses" := airdrop-addresses,
            "current-index" := current-index,
            "policy" := policy
        }
            ;; Additional validations before launch
            (enforce (>= total-supply 0) "Invalid supply")
            (enforce (<= total-supply MAX_SUPPLY_LIMIT) "Supply exceeds limit")
            (enforce (>= mint-price MIN_PRICE) "Price below minimum")
            (enforce (and (>= royalty-percentage 0.0) 
                        (<= royalty-percentage MAX_ROYALTY_PERCENTAGE))
                "Invalid royalty percentage")
            (enforce (!= royalty-address "") "Invalid royalty address")

            ;; Insert into collections table
            (insert collections collection-name {
                "collection-name": collection-name,
                "symbol": symbol,
                "launched": true,
                "collection-id": "",
                'creator: creator,
                'creator-guard: guard,
                'description: description,
                'category: category,
                'total-supply: total-supply,
                'urisIPFS: urisIPFS,
                'mint-price: mint-price,
                'wl-price: wl-price,
                'royalty-percentage: royalty-percentage,
                'royalty-address: royalty-address,
                'cover-image-url: cover-image-url,
                'banner-image-url: banner-image-url,
                'mint-start-date: mint-start-date,
                'mint-start-time: mint-start-time,
                'mint-end-date: mint-end-date,
                'mint-end-time: mint-end-time,
                'allow-free-mints: allow-free-mints,
                'enable-whitelist: enable-whitelist,
                'whitelist-addresses: wl-addresses,
                'whitelist-start-time: wl-time,
                'enable-presale: enable-presale,
                'presale-addresses: presale-addresses,
                'presale-start-date: presaleStartDate,
                'presale-start-time: presaleStartTime,
                'presale-end-date: presaleEndDate,
                'presale-end-time: presaleEndTime,
                'presale-mint-price: preSaleMintPrice,
                'enable-airdrop: enable-airdrop,
                'airdrop-supply: airdropSupply,
                'airdrop-addresses: airdrop-addresses,
                'current-index: 0,
                'policy: policy,
                'created-time: (at "block-time" (chain-data)),
                'last-updated: (at "block-time" (chain-data)),
                'total-minted: 0,
                'total-sales: 0.0
            })

            ;; Initialize supply tracking
            (write token-ledger collection-name {
                'current-length: 0,
                'max-supply: total-supply,
                'last-mint-time: (at "block-time" (chain-data)),
                'total-minted: 0
            })

            ;; Initialize free mint ledger
            (write free-mint-ledger collection-name {
                'total-supply: 0,
                'current-index: 1,
                'start-time: (time "1970-01-01T00:00:00Z"),
                'end-time: (time "1970-01-01T00:00:00Z"),
                'is-active: false,
                'max-per-account: 1,
                'accounts-claimed: []
            })

            ;; Initialize token record
            (write token-record collection-name {
                'uri-list: [],
                'current-length: 0,
                'max-length: total-supply,
                'last-updated: (at "block-time" (chain-data)),
                'created-by: creator,
                'is-frozen: false
            })

            ;; Initialize counter
            (write counts-table collection-name {
                "count": 0,
                "last-updated": (at "block-time" (chain-data)),
                "description": "Collection mint counter"
            })

            ;; Log launch operation
            (let ((log-key (format "{}-{}" [collection-name (at "block-time" (chain-data))])))
                (write operation-logs log-key {
                    "operation": "launch-collection",
                    "account": (at "sender" (chain-data)),
                    "timestamp": (at "block-time" (chain-data)),
                    "details": {
                        "collection": collection-name,
                        "creator": creator,
                        "total-supply": total-supply,
                        "status": "launched"
                    },
                    "status": "completed",
                    "tx-hash": (hash (at "block-time" (chain-data)))
                }))

            ;; Return success message
            "Collection launched successfully"
        )
    )
)



;-----------------------------------------------------------------------------
; Role Management Functions
;-----------------------------------------------------------------------------

(defun add-roles (role:string accounts:[string])
    @doc "Add multiple accounts to a role"
    (with-capability (PRIVATE)
        (map (add-role role) accounts)

        ; Log role addition
        (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
            "operation": "add-roles",
            "account": (at "sender" (chain-data)),
            "timestamp": (at "block-time" (chain-data)),
            "details": {
                "role": role,
                "accounts": accounts
            },
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })
    )
)

(defun add-role (role:string account:string)
    @doc "Add single account to a role"
    (require-capability (PRIVATE))
    (let* (
        (prime_accounts:string (get-prime-role))
        (discount_accounts:string (get-discount-role))
        (in_prime:bool (contains account prime_accounts))
        (in_discount:bool (contains account discount_accounts))
    )
        (cond
            ((= role "prime")
                [
                    (enforce (!= in_discount true) "Remove from Discount Ledger")
                    (update prime_role PRIME {
                        "accounts": (+ (+ prime_accounts " ") account)
                    })
                ]
            )
            ((= role "discount")
                [
                    (enforce (!= in_prime true) "Remove from Prime Ledger")
                    (update discount_role DISCOUNT {
                        "accounts": (+ (+ discount_accounts " ") account)
                    })
                ]
            )
            ["Invalid Role"]
        )

        ; Log role assignment
        (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
            "operation": "add-role",
            "account": account,
            "timestamp": (at "block-time" (chain-data)),
            "details": {
                "role": role,
                "status": "assigned"
            },
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })
    )
)

;-----------------------------------------------------------------------------
; Collection Management Functions
;-----------------------------------------------------------------------------

(defun deny-collection (collection-name:string)
    @doc "Deny a collection request and refund fee"
    (with-capability (IS_ADMIN)
        (let (
            (fee:decimal (get-collection-launch-fee))
            (creator:string (get-collection-creator-of-request collection-name))
        )
            ; Process refund
            (coin.transfer LAUNCHPAD_ACC creator fee)

            ; Log denial
            (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
                "operation": "deny-collection",
                "account": (at "sender" (chain-data)),
                "timestamp": (at "block-time" (chain-data)),
                "details": {
                    "collection": collection-name,
                    "creator": creator,
                    "fee-refunded": fee
                },
                "status": "completed",
                "tx-hash": (hash (at "block-time" (chain-data)))
            })
        )
    )
)

;-----------------------------------------------------------------------------
; Fee Management Functions
;-----------------------------------------------------------------------------

(defun update-launch-fee (fee:decimal type:string)
    @doc "Update launch or discount fee"
    (with-capability (IS_ADMIN)
        (enforce (< 0.0 fee) "Fee must be positive")
        (let ((update-result
            (cond
                ((= type "launch")
                    (update fee-ledger LAUNCH {
                        'fee: fee
                    })
                )
                ((= type "discount")
                    (update fee-ledger LAUNCH {
                        'discount: fee
                    })
                )
                ["Invalid Type"]
            )))

        ; Log fee update
        (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
            "operation": "update-fee",
            "account": (at "sender" (chain-data)),
            "timestamp": (at "block-time" (chain-data)),
            "details": {
                "type": type,
                "new-fee": fee
            },
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })
    ))
)

;-----------------------------------------------------------------------------
; Bulk Update Functions
;-----------------------------------------------------------------------------

(defun bulk-sync-with-ng
    (collection-name:string
     accountIds:[integer]
     uris:[string])
    @doc "Bulk sync token URIs with accountIds"
    
    (enforce (= (length accountIds) (length uris))
        "Account IDs and URIs length mismatch")
    (enforce (> (length accountIds) 0) 
        "Account IDs cannot be empty")
    (enforce (> (length uris) 0) 
        "URIs cannot be empty")

    (with-capability (MINTPROCESS collection-name)
        (process-sync collection-name accountIds uris)

        ; Log bulk sync operation
        (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
            "operation": "bulk-sync",
            "account": (at "sender" (chain-data)),
            "timestamp": (at "block-time" (chain-data)),
            "details": {
                "collection": collection-name,
                "count": (length accountIds)
            },
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })
    )
)

(defun process-sync
    (collection-name:string
     accountIds:[integer]
     uris:[string])
    @doc "Process bulk sync of tokens"
    (require-capability (MINTPROCESS collection-name))
    (map
        (lambda (idx)
            (let ((accountId (at idx accountIds))
                  (uri (at idx uris)))
                (sync-with-ng collection-name accountId uri))
        )
        (enumerate 0 (- (length accountIds) 1))
    )
)

(defun sync-with-ng
    (collection-name:string
     accountId:integer
     uri:string)
    @doc "Sync a single token with NG"

    (require-capability (MINTPROCESS collection-name))
    
    (with-read minted-tokens (get-mint-token-id collection-name accountId)
        { "account" := account
        , "revealed" := revealed }
        
        (enforce (= revealed false) "Token already revealed")

        (let* ((collection-info:object{collection-details} (get-collection-details collection-name))
               (creator:string (at 'creator collection-info))
               (collection-id:string (at 'collection-id collection-info))
               (guard:guard (at 'creator-guard collection-info))
               (mintto:guard (at "guard" (coin.details account)))
               (random:integer (get-random account))
               (account-minted:integer (get-account-minted account))
               (token-id:string (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger.create-token-id guard uri))
               (token-precision 0)
               (policy_stack:string (get-policy-of-collection collection-name))
               (policy:[module{n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.token-policy-ng-v1}] (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.std-policies.to-policies policy_stack)))

            ; Create and mint token
            (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger.create-token token-id token-precision uri policy guard)
            (n_442d3e11cfe0d39859878e5b1520cd8b8c36e5db.ledger.mint token-id account mintto 1.0)

            ; Update token status
            (update minted-tokens (get-mint-token-id collection-name accountId) 
                {"revealed": true, "marmToken": token-id})

            ; Record NFT info
            (mint-nft-info collection-name account token-id)
            (update-minted account account-minted)

            ; Update account info
            (with-read accountsInfo (concat [collection-name "|" account])
                { "tokens" := tokens }
                (let ((colToken:string (concat [collection-name "|" token-id])))
                    (update accountsInfo (concat [collection-name "|" account])
                        { "tokens": (+ tokens [colToken]) })))

            ; Log sync operation
            (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) 
                { "operation": "sync-token"
                , "account": account
                , "timestamp": (at "block-time" (chain-data))
                , "details": 
                    { "collection": collection-name
                    , "token-id": token-id
                    , "account-id": accountId }
                , "status": "completed"
                , "tx-hash": (hash (at "block-time" (chain-data)))
                })

            token-id)))


(defun mint-nft-info:string 
    (collection-name:string 
     account:string 
     token-id:string)
    @doc "Record NFT ownership and metadata information"
    
    (require-capability (PRIVATE))
    
    ; Insert NFT info by token ID
    (insert nfts-info-by-id token-id {
        "owner": account,
        "token-id": token-id,
        "collection-name": collection-name,
        "collection-id": (get-collection-id collection-name),
        "minted-time": (at "block-time" (chain-data)),
        "mint-price": (get-mint-price collection-name),
        "transaction-hash": (hash (at "block-time" (chain-data))),  ; Fixed closing parenthesis
        "metadata": {},
        "transfer-count": 0,
        "last-transfer-time": (at "block-time" (chain-data))
    })

    ; Write NFT info by owner
    (write nfts-info-by-owner account {
        "owner": account,
        "token-id": token-id,
        "collection-name": collection-name,
        "collection-id": (get-collection-id collection-name),
        "minted-time": (at "block-time" (chain-data)),
        "mint-price": (get-mint-price collection-name),
        "transaction-hash": (hash (at "block-time" (chain-data))),  ; Fixed closing parenthesis
        "metadata": {},
        "transfer-count": 0,
        "last-transfer-time": (at "block-time" (chain-data))
    })

    ; Log the minting
    (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
        "operation": "mint-nft-info",
        "account": account,
        "timestamp": (at "block-time" (chain-data)),
        "details": {
            "collection": collection-name,
            "token-id": token-id
        },
        "status": "completed",
        "tx-hash": (hash (at "block-time" (chain-data)))
    })

    ; Return token ID
    token-id)


(defun update-minted:string 
    (account:string 
     minted:integer)
    @doc "Update minting count for account"
    
    (require-capability (PRIVATE))
    
    (write account-details account {
        "account": account,
        "guard": (at 'guard (coin.details account)),
        "minted": (+ minted 1),
        "last-mint-time": (at "block-time" (chain-data)),
        "total-spent": 0.0,
        "collections": [],
        "roles": [],
        "created-time": (at "block-time" (chain-data)),
        "last-active": (at "block-time" (chain-data))
    })

    ; Log the update
    (insert operation-logs (int-to-str 10 (+ 1 (get-count "operation-logs"))) {
        "operation": "update-minted",
        "account": account,
        "timestamp": (at "block-time" (chain-data)),
        "details": {
            "previous-count": minted,
            "new-count": (+ minted 1)
        },
        "status": "completed",
        "tx-hash": (hash (at "block-time" (chain-data)))
    }))


(defcap CAN_DELETE ()
  (enforce-guard (keyset-ref-guard "free.km-test")))

(defun delete-table-entry (table-name:string key:string)
  @doc "Delete entry from specified table"
  (with-capability (CAN_DELETE)
    (cond
      ((= table-name "fee") 
       [(enforce (= key LAUNCH) "Invalid key")
        (write fee-ledger LAUNCH {
          "fee": 0.0,
          "discount": 0.0,
          "minimum-fee": 0.0,
          "last-updated": (at "block-time" (chain-data)),
          "updated-by": (at "sender" (chain-data))
        })])
      ["Invalid table name"]))
)


(defun initialize-contract ()
    @doc "Initialize all required contract state"
    (with-capability (IS_ADMIN)
        ; Initialize fee ledger
        (write fee-ledger LAUNCH {
            "fee": 1.0,
            "discount": 0.5,
            "minimum-fee": 0.000001,
            "last-updated": (at "block-time" (chain-data)),
            "updated-by": (at "sender" (chain-data))
        })

        ; Initialize prime role
        (write prime_role PRIME {
            "accounts": "",
            "benefits": [],
            "updated-at": (at "block-time" (chain-data)),
            "updated-by": (at "sender" (chain-data))
        })

        ; Initialize discount role 
        (write discount_role DISCOUNT {
            "accounts": "",
            "discount-rate": 0.5,
            "updated-at": (at "block-time" (chain-data)),
            "updated-by": (at "sender" (chain-data))
        })

        ; Initialize operation logs counter
        (write counts-table "operation-logs" {
            "count": 0,
            "last-updated": (at "block-time" (chain-data)),
            "description": "Operation logs counter"
        })

        ; Initialize operation logs with first entry
        (write operation-logs "0" {
            "operation": "init",
            "account": (at "sender" (chain-data)),
            "timestamp": (at "block-time" (chain-data)),
            "details": {},
            "status": "completed",
            "tx-hash": (hash (at "block-time" (chain-data)))
        })

        "Contract initialized successfully"
    )
)


(defun initialize-supply-ledgers (collection-name:string)
    @doc "Initialize token ledger and free mint ledger for a collection"
    (with-capability (PRIVATE)
        ; Initialize token ledger
        (write token-ledger collection-name {
            'current-length: 0,
            'max-supply: (get-total-supply collection-name),
            'last-mint-time: (at "block-time" (chain-data)),
            'total-minted: 0
        })

        ; Initialize free mint ledger
        (write free-mint-ledger collection-name {
            'total-supply: 0,
            'current-index: 1,
            'start-time: (time "1970-01-01T00:00:00Z"),
            'end-time: (time "1970-01-01T00:00:00Z"),
            'is-active: false
        })
        "Supply ledgers initialized"
    )
)
)

