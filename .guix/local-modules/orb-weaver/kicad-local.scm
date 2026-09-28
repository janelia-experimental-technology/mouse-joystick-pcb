(define-module (orb-weaver kicad-local)
  #:use-module (guix git-download)
  #:use-module (guix packages))

;; Opt-in local KiCad overlay.
;;
;; The default manifests use the KiCad packages selected by .guix/channels.scm.
;; This module lives outside the channel package module path so package-name
;; lookup for the default manifests stays on Guix proper. It exists for the
;; interval between a KiCad release and the matching Guix package update: put
;; temporary overrides here, use the *-local Make targets (which add this
;; directory with -L), and drop the overrides back to the plain aliases below
;; once the pinned Guix channel in .guix/channels.scm carries the release.
;;
;; Current override: none. The pinned channel carries KiCad 10.0.6 (checked
;; 2026-09-28), so every alias resolves to the upstream package and the *-local
;; targets behave exactly like the default ones.
;;
;; To override again, replace an alias with a package that inherits the
;; upstream one and sets `version` and a git-fetch `source` at the release tag
;; (the 10.0.6 override is in this file's git history; docs/guix-packaging.md
;; in kicad-libs has the hash recipe). Such a build has no substitutes and
;; compiles KiCad from source, so start it overnight or let the weekly warm job
;; realize the kicad-local tier.

(define (resolve-package-module name)
  (catch #t
    (lambda () (resolve-interface name))
    (lambda _ #f)))

(define %upstream-kicad-packages
  (let ((electronics (resolve-package-module '(gnu packages electronics))))
    (if (and electronics (module-variable electronics 'kicad))
        electronics
        (resolve-interface '(gnu packages engineering)))))

(define-public kicad
  (module-ref %upstream-kicad-packages 'kicad))

(define-public kicad-doc
  (module-ref %upstream-kicad-packages 'kicad-doc))

(define-public kicad-symbols
  (module-ref %upstream-kicad-packages 'kicad-symbols))

(define-public kicad-footprints
  (module-ref %upstream-kicad-packages 'kicad-footprints))

(define-public kicad-packages3d
  (module-ref %upstream-kicad-packages 'kicad-packages3d))

(define-public kicad-templates
  (module-ref %upstream-kicad-packages 'kicad-templates))
