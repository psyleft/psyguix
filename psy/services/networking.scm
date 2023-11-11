(define-module (psy services networking)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix packages)
  
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages networking)
  
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services configuration)
  #:use-module (gnu services dbus)
  #:use-module (gnu services shepherd)

  #:export (iwd-service-type
            iwd-configuration))

;; Mostly taken from https://git.sr.ht/~krevedkokun/dotfiles/
;; In channel/system/services/networking.scm
(define raw-configuration-string? string?)

(define-configuration/no-serialization iwd-configuration
  (package
   (package iwd)
   "Package to use for iwd")
  (extra-content
   (raw-configuration-string "")
   "Raw configuration for /etc/iwd/main.conf"))

(define (iwd-shepherd-service cfg)
  (match-record cfg <iwd-configuration>
   (package)
   (let ((environment
          #~(list (string-append
                   "PATH=" #$(file-append openresolv "/sbin")
                   ":" #$(file-append coreutils "/bin")))))
     (list (shepherd-service
            (documentation "Runs iwd")
            (provision '(iwd))
            (requirement '(user-processes dbus-system loopback))
            (start #~(make-forkexec-constructor
                      (list #$(file-append package "/libexec/iwd"))
                      #:log-file "/var/log/iwd.log"
                      #:environment-variables #$environment))
            (stop #~(make-kill-destructor)))))))

(define (iwd-etc-service cfg)
  (match-record cfg <iwd-configuration>
   (extra-content)
   `(("iwd/main.conf"
      ,(plain-file "main.conf" extra-content)))))

(define iwd-service-type
  (service-type
   (name 'iwd)
   (extensions
    (list (service-extension shepherd-root-service-type
                             iwd-shepherd-service)
          (service-extension dbus-root-service-type
                             (compose list iwd-configuration-package))
          (service-extension etc-service-type
                             iwd-etc-service)
          (service-extension profile-service-type
                             (compose list iwd-configuration-package))))
   (default-value (iwd-configuration))
   (description "Provides iwd for use with other networking tools")))
