(define-module (orb-weaver kicad-local)
  #:use-module (guix git-download)
  #:use-module (guix packages))

;; Opt-in local KiCad overlay.
;;
;; The default manifests use the KiCad packages selected by .guix/channels.scm.
;; This module lives outside the channel package module path so package-name
;; lookup for the default manifests stays on Guix proper. Add temporary KiCad
;; package overrides here only when the Guix channel is waiting for an update.
;;
;; Current override: KiCad 10.0.5 while the corresponding Guix update is waiting
;; to land upstream. Drop these overrides back to plain upstream aliases once the
;; pinned Guix channel in .guix/channels.scm carries 10.0.5 or newer.

(define (resolve-package-module name)
  (catch #t
    (lambda () (resolve-interface name))
    (lambda _ #f)))

(define %upstream-kicad-packages
  (let ((electronics (resolve-package-module '(gnu packages electronics))))
    (if (and electronics (module-variable electronics 'kicad))
        electronics
        (resolve-interface '(gnu packages engineering)))))

(define %kicad-version "10.0.5")

(define-public kicad
  (package
    (inherit (module-ref %upstream-kicad-packages 'kicad))
    (version %kicad-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/kicad/code/kicad.git")
             (commit %kicad-version)))
       (sha256
        (base32
         "11ssgv2ycc4ad7wz7ijdd3x4fmdnwmxjjyjx1rrvrrlsz2k4nddg"))
       (file-name (git-file-name "kicad" %kicad-version))))))

(define-public kicad-doc
  (package
    (inherit (module-ref %upstream-kicad-packages 'kicad-doc))
    (version %kicad-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/kicad/services/kicad-doc.git")
             (commit %kicad-version)))
       (sha256
        (base32
         "1fi2zvpz0qzjjmv6407qw5bwhc4950nlqkk68a7mpjhgzx0gjbn8"))
       (file-name (git-file-name "kicad-doc" %kicad-version))))))

(define-public kicad-symbols
  (package
    (inherit (module-ref %upstream-kicad-packages 'kicad-symbols))
    (version %kicad-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/kicad/libraries/kicad-symbols.git")
             (commit %kicad-version)))
       (sha256
        (base32
         "12w7qbqm9wk6b7d8ljdd46afskkqc2aanh8fyf36frwqy1mjfx87"))
       (file-name (git-file-name "kicad-symbols" %kicad-version))))))

(define-public kicad-footprints
  (package
    (inherit (module-ref %upstream-kicad-packages 'kicad-footprints))
    (version %kicad-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/kicad/libraries/kicad-footprints.git")
             (commit %kicad-version)))
       (sha256
        (base32
         "0jr9q1yrlxbb796wrsrnlplb2a05k3z0g1m1dn3c87cf9ffmlaz0"))
       (file-name (git-file-name "kicad-footprints" %kicad-version))))))

(define-public kicad-packages3d
  (package
    (inherit (module-ref %upstream-kicad-packages 'kicad-packages3d))
    (version %kicad-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/kicad/libraries/kicad-packages3D.git")
             (commit %kicad-version)))
       (sha256
        (base32
         "1gqqi91g1yynfgmxl5l34g1rg3gjksl54xd1zsgp4kvyi5w50b3r"))
       (file-name (git-file-name "kicad-packages3d" %kicad-version))))))

(define-public kicad-templates
  (package
    (inherit (module-ref %upstream-kicad-packages 'kicad-templates))
    (version %kicad-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/kicad/libraries/kicad-templates.git")
             (commit %kicad-version)))
       (sha256
        (base32
         "0zs29zn8qjgxv0w1vyr8yxmj02m8752zagn4vcraqgik46dwg2id"))
       (file-name (git-file-name "kicad-templates" %kicad-version))))))
