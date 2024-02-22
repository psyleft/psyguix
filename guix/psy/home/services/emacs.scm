(define-module (psy home services emacs)
  #:export (
    home-emacs-configuration
    home-emacs-service-type
))

(use-modules
 (guix gexp)
 (guix packages)
 (guix records)

 (gnu packages emacs)

 (gnu services)
 (gnu services configuration)
 (gnu services shepherd)

 (gnu home services)
 (gnu home services shepherd)
)

(define-configuration/no-serialization home-emacs-configuration
  (package
   (package emacs)
   "Package to use for emacs"))

(define home-emacs-package (compose list home-emacs-configuration-package))

(define (home-emacs-shepherd-service cfg)
  (match-record cfg <home-emacs-configuration>
    (package)
    (list (shepherd-service
           (documentation "Runs the emacs daemon")
           (provision '(emacsd))
           (start
            #~(make-forkexec-constructor
               (list #$(file-append package "/bin/emacs")
                     "--fg-daemon"
                     (string-append "--chdir=" (getenv "HOME")))))
           (stop #~(make-kill-destructor))))))

(define home-emacs-service-type
  (service-type
   (name 'home-emacs)
   (extensions
    (list (service-extension home-shepherd-service-type
                             home-emacs-shepherd-service)
          (service-extension home-profile-service-type
                             home-emacs-package)))
   (description "Provides emacs and the emacs daemon")))
