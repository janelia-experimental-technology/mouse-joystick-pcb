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
;; Current override: KiCad 10.0.6 while the corresponding Guix update is waiting
;; to land upstream. Drop these overrides back to plain upstream aliases once the
;; pinned Guix channel in .guix/channels.scm carries 10.0.6 or newer.

(define (resolve-package-module name)
  (catch #t
    (lambda () (resolve-interface name))
    (lambda _ #f)))

(define %upstream-kicad-packages
  (let ((electronics (resolve-package-module '(gnu packages electronics))))
    (if (and electronics (module-variable electronics 'kicad))
        electronics
        (resolve-interface '(gnu packages engineering)))))

(define %kicad-version "10.0.6")

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
         "0x9376x4nigqnx4d82qixz41p779svjdsgkxv6l0kmn3snvwbcgk"))
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
         "0y82qkks3l003d7fka3aicmrx8qa7ch819y8kgghpxc5nqzw8nz8"))
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
         "0ynmi6qg5cac37vn0q986vh2a560ab8vb24yg7bfbkyj8b5xk353"))
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
         "11hhdk8g7hsm50817x7204lzm1qpjpfjr82gyrnhdshnnzd0hbf7"))
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
         "1mkcf6yn64pqjk51srnv5cidcji0hrx8nfh0q5zyc4ca7p7984li"))
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
