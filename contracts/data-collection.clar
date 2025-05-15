;; Data Collection Contract
;; This contract tracks health metrics

(define-data-var admin principal tx-sender)

;; Define data types for health metrics
(define-constant TYPE-HEART-RATE u1)
(define-constant TYPE-BLOOD-PRESSURE u2)
(define-constant TYPE-TEMPERATURE u3)
(define-constant TYPE-BLOOD-GLUCOSE u4)
(define-constant TYPE-OXYGEN-SATURATION u5)

;; Map to store health data records
;; Key is a composite of patient principal and timestamp
(define-map health-data
  { patient: principal, timestamp: uint }
  {
    device-id: (string-utf8 50),
    data-type: uint,
    value: uint,
    unit: (string-utf8 20)
  }
)

;; Counter for total records
(define-data-var record-count uint u0)

;; Function to submit health data (devices or providers can call)
(define-public (submit-health-data (patient principal) (device-id (string-utf8 50))
                                  (data-type uint) (value uint) (unit (string-utf8 20)))
  (let ((timestamp (get-block-info? time (- block-height u1))))
    (begin
      ;; In a real implementation, we would check:
      ;; 1. If the device is registered and active
      ;; 2. If the patient has given consent
      ;; 3. If the provider is verified

      ;; For simplicity, we're just checking if the caller is the admin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))

      ;; Check if data type is valid
      (asserts! (or (is-eq data-type TYPE-HEART-RATE)
                    (is-eq data-type TYPE-BLOOD-PRESSURE)
                    (is-eq data-type TYPE-TEMPERATURE)
                    (is-eq data-type TYPE-BLOOD-GLUCOSE)
                    (is-eq data-type TYPE-OXYGEN-SATURATION))
                (err u101))

      ;; Store the data
      (match timestamp
        time-value (begin
          (map-set health-data
            { patient: patient, timestamp: time-value }
            {
              device-id: device-id,
              data-type: data-type,
              value: value,
              unit: unit
            }
          )
          (var-set record-count (+ (var-get record-count) u1))
          (ok time-value)
        )
        (err u500)
      )
    )
  )
)

;; Function to get the latest health data for a patient
(define-read-only (get-health-data (patient principal) (timestamp uint))
  (match (map-get? health-data { patient: patient, timestamp: timestamp })
    data (ok data)
    (err u404)
  )
)

;; Function to get total record count
(define-read-only (get-record-count)
  (ok (var-get record-count))
)
