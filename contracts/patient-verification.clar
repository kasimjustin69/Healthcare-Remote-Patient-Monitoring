;; Patient Verification Contract
;; This contract manages participant identities

(define-data-var admin principal tx-sender)

;; Map to store patient information
(define-map patients principal
  {
    id: (string-utf8 50),
    consent-given: bool,
    provider: principal,
    active: bool
  }
)

;; Function to register a new patient (only verified providers can call)
(define-public (register-patient (patient-principal principal) (patient-id (string-utf8 50)))
  (begin
    ;; Check if provider is verified (would call provider-verification contract in a real implementation)
    ;; For simplicity, we're just checking if the caller is the admin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? patients patient-principal)) (err u100))
    (ok (map-set patients patient-principal {
      id: patient-id,
      consent-given: false,
      provider: tx-sender,
      active: true
    }))
  )
)

;; Function for patient to give consent
(define-public (give-consent)
  (begin
    (match (map-get? patients tx-sender)
      patient-data (ok (map-set patients tx-sender
                        (merge patient-data { consent-given: true })))
      (err u404)
    )
  )
)

;; Function to check if a patient exists and has given consent
(define-read-only (check-patient-consent (patient-principal principal))
  (match (map-get? patients patient-principal)
    patient-data (ok (get consent-given patient-data))
    (err u404)
  )
)

;; Function to deactivate a patient
(define-public (deactivate-patient (patient-principal principal))
  (begin
    ;; Only the patient's provider or admin can deactivate
    (match (map-get? patients patient-principal)
      patient-data (begin
        (asserts! (or (is-eq tx-sender (get provider patient-data))
                      (is-eq tx-sender (var-get admin)))
                  (err u403))
        (ok (map-set patients patient-principal
              (merge patient-data { active: false })))
      )
      (err u404)
    )
  )
)
