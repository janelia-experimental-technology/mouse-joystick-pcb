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
;; directory with -L), and drop the overrides back to plain aliases once the
;; pinned Guix channel in .guix/channels.scm carries the release.
;;
;; Current override: KiCad 10.0.7 (released 2026-10-08). The Guix update
;; ("gnu: kicad: Update to 10.0.7", submitted upstream 2026-10-08) is waiting to
;; land, and the channel pin in .guix/channels.scm (dd8c1c5) carries 10.0.6.
;; The hashes are the ones from that submission; the kicad-templates tree is
;; identical at the 10.0.6 and 10.0.7 tags, so its hash did not change.
;;
;; Each override inherits the pinned package and replaces only `version` and
;; `source`. The new source keeps the pinned origin's patches
;; (kicad-disable-updates.patch on kicad), so the overlay build differs from the
;; channel's package only by the release. Such a build has no substitutes and
;; compiles KiCad from source, so start it overnight or let the weekly warm job
;; realize the kicad-local tier. Reset the aliases once the pin carries 10.0.7
;; or newer (the alias form is in this file's git history; docs/guix-packaging.md
;; in kicad-libs has the hash recipe).

(define (resolve-package-module name)
  (catch #t
    (lambda () (resolve-interface name))
    (lambda _ #f)))

(define %upstream-kicad-packages
  (let ((electronics (resolve-package-module '(gnu packages electronics))))
    (if (and electronics (module-variable electronics 'kicad))
        electronics
        (resolve-interface '(gnu packages engineering)))))

(define (upstream name)
  (module-ref %upstream-kicad-packages name))

(define %kicad-version "10.0.7")

(define (release-package name url hash)
  "The pinned package NAME at the %kicad-version tag of URL; HASH is the nar
hash (nix-base32) of a plain checkout of that tag. Everything but version and
source, the pinned origin's patches included, comes from the channel's
definition."
  (let ((base (upstream name)))
    (package
      (inherit base)
      (version %kicad-version)
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url url)
               (commit %kicad-version)))
         (sha256 (base32 hash))
         (patches (origin-patches (package-source base)))
         (file-name (git-file-name (package-name base) %kicad-version)))))))

(define-public kicad
  (release-package 'kicad
                   "https://gitlab.com/kicad/code/kicad.git"
                   "0wzv12hrk08rak65kl1la5yj80x1qspssc2a032cc8w1j1cfs0pv"))

(define-public kicad-doc
  (release-package 'kicad-doc
                   "https://gitlab.com/kicad/services/kicad-doc.git"
                   "09v81dk847azpnb39fmm8s11m66hdlnsxzrx5br6bidrgl78dgmi"))

(define-public kicad-symbols
  (release-package 'kicad-symbols
                   "https://gitlab.com/kicad/libraries/kicad-symbols.git"
                   "056m402jkzz3pl5h2k48ywcqcrivvnhwrpc1rrxblcsmk1psfsxb"))

(define-public kicad-footprints
  (release-package 'kicad-footprints
                   "https://gitlab.com/kicad/libraries/kicad-footprints.git"
                   "06qc8nkgfd5301bzqqiqwg44g6pgjn0i9gp8j4585ay1vfd19ab4"))

(define-public kicad-packages3d
  (release-package 'kicad-packages3d
                   "https://gitlab.com/kicad/libraries/kicad-packages3D.git"
                   "1q9jdrqcbxypy5zw50ganhkri71pq796ghxx3b10pin0300d1lwl"))

(define-public kicad-templates
  (release-package 'kicad-templates
                   "https://gitlab.com/kicad/libraries/kicad-templates.git"
                   "0zs29zn8qjgxv0w1vyr8yxmj02m8752zagn4vcraqgik46dwg2id"))
