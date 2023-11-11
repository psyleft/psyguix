(define-module (psy services thunderbolt)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix packages)

  #:use-module (gnu packages)
  #:use-module (gnu packages linux)

  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu services dbus)

  #:export (bolt-service-type
            bolt-configuration))

(define-configuration/no-serialization bolt-configuration
  (package
    (package bolt)
    "Package to use for bolt"))

(define bolt-service-type
  (service-type
   (name 'bolt)
   (extensions
    (list (service-extension dbus-root-service-type
                             (compose list bolt-configuration-package))
          (service-extension profile-service-type
                             (compose list bolt-configuration-package))))
   (default-value (bolt-configuration))
   (description "Provides the bolt thunderbolt management tool")))
