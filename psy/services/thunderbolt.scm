(define-module (psy services thunderbolt)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix packages)

  #:use-module (gnu packages)
  #:use-module (gnu packages linux)

  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu services dbus)
  #:use-module (gnu services shepherd)

  #:export (bolt-service-type
            bolt-configuration))

(define-configuration/no-serialization bolt-configuration
  (package
    (package bolt)
    "Package to use for bolt"))

(define (bolt-shepherd-service cfg)
  (match-record cfg <bolt-configuration>
                (package)
    (list (shepherd-service
           (documentation "Runs bolt")
           (provision '(bolt))
           (requirement '(dbus-system))
           (start #~(make-forkexec-constructor
                     (list #$(file-append package "/libexec/boltd"))
                     #:log-file "/var/log/bolt.log"))
           (stop #~(make-kill-destructor))))))

(define bolt-service-type
  (service-type
   (name 'bolt)
   (extensions
    (list (service-extension shepherd-root-service-type
                             bolt-shepherd-service)
          (service-extension dbus-root-service-type
                             (compose list bolt-configuration-package))
          (service-extension profile-service-type
                             (compose list bolt-configuration-package))))
   (default-value (bolt-configuration))
   (description "Provides bolt thunderbolt management tool")))
