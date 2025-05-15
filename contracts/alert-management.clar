;; Alert Management Contract
;; This contract handles concerning readings notification

(define-data-var admin principal tx-sender)

;; Define alert levels
(define-constant ALERT-LEVEL-LOW u1)
(define-constant ALERT-LEVEL-MEDIUM u2)
(define-constant ALERT-LEVEL-HIGH u3)

;; Map to store alert thresholds for different data types
(define-map alert-thresholds
  { data-type: uint, patient: principal }
  {
    low-threshold: uint,
    high-threshold: uint,
    provider: principal
  }
)

;; Map to store active alerts
(define-map active-alerts
  { patient: principal, timestamp: uint }
  {
    data-type: uint,
    value: uint,
    alert-level: uint,
    acknowledged: bool
  }
)

;; Counter for total alerts
(define-data-var alert-count uint u0)

;; Function to set alert thresholds (only providers can call)
(define-public (set-alert-thresholds (patient principal) (data-type uint)
                                    (low-threshold uint) (high-threshold uint))
  (begin
    ;; Check if provider is verified (would call provider-verification contract in a real implementation)
    ;; For simplicity, we're just checking if the caller is the admin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (ok (map-set alert-thresholds
      { data-type: data-type, patient: patient }
      {
        low-threshold: low-threshold,
        high-threshold: high-threshold,
        provider: tx-sender
      }
    ))
  )
)

;; Function to generate an alert (called when data is outside thresholds)
(define-public (generate-alert (patient principal) (data-type uint) (value uint))
  (let ((timestamp (get-block-info? time (- block-height u1)))
        (thresholds (map-get? alert-thresholds { data-type: data-type, patient: patient })))
    (begin
      ;; Check if thresholds exist for this patient and data type
      (asserts! (is-some thresholds) (err u404))

      (match thresholds
        threshold-data (begin
          ;; Determine alert level
          (let ((alert-level (if (< value (get low-threshold threshold-data))
                                ALERT-LEVEL-LOW
                                (if (> value (get high-threshold threshold-data))
                                    ALERT-LEVEL-HIGH
                                    ALERT-LEVEL-MEDIUM))))

            ;; Only generate alerts for low or high levels
            (asserts! (or (is-eq alert-level ALERT-LEVEL-LOW)
                          (is-eq alert-level ALERT-LEVEL-HIGH))
                      (err u102))

            ;; Store the alert
            (match timestamp
              time-value (begin
                (map-set active-alerts
                  { patient: patient, timestamp: time-value }
                  {
                    data-type: data-type,
                    value: value,
                    alert-level: alert-level,
                    acknowledged: false
                  }
                )
                (var-set alert-count (+ (var-get alert-count) u1))
                (ok time-value)
              )
              (err u500)
            )
          )
        )
        (err u404)
      )
    )
  )
)

;; Function to acknowledge an alert (only providers can call)
(define-public (acknowledge-alert (patient principal) (timestamp uint))
  (begin
    ;; In a real implementation, we would check if the caller is the patient's provider
    ;; For simplicity, we're just checking if the caller is the admin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (match (map-get? active-alerts { patient: patient, timestamp: timestamp })
      alert-data (ok (map-set active-alerts
                      { patient: patient, timestamp: timestamp }
                      (merge alert-data { acknowledged: true })))
      (err u404)
    )
  )
)

;; Function to get active unacknowledged alerts for a patient
(define-read-only (get-unacknowledged-alerts (patient principal))
  ;; In a real implementation, this would return a list of alerts
  ;; For simplicity, we're just returning the total count
  (ok (var-get alert-count))
)
