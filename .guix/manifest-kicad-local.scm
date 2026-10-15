;; KiCad editing environment with the opt-in local KiCad overlay.
;;
;; Same shape as .guix/manifest-kicad.scm, except the KiCad packages come from
;; (orb-weaver kicad-local) in .guix/local-modules instead of the pinned Guix
;; channel. Use this only while that overlay carries a temporary override, and
;; run it through the -local Makefile targets so the module path is added.

((@ (guix profiles) concatenate-manifests)
 (list
  ((@ (guix profiles) packages->manifest)
   (list (@ (guix-agent-tools packages) guix-agent-tools)
         (@ (orb-weaver context packages) orb-weaver-context-kicad)
         (@ (orb-weaver packages) mcp-server-kicad)
         (@ (orb-weaver packages) orb-weaver-kicad-libs)
         (@ (orb-weaver packages) orb-weaver-kicad-tools)
         (@ (orb-weaver packages) sqliteodbc)
         (@ (orb-weaver packages) freerouting)
         (@ (orb-weaver kicad-local) kicad)
         (@ (orb-weaver kicad-local) kicad-symbols)
         (@ (orb-weaver kicad-local) kicad-footprints)
         (@ (orb-weaver kicad-local) kicad-packages3d)
         (@ (orb-weaver kicad-local) kicad-templates)))
  ((@ (gnu packages) specifications->manifest)
   '("bash"
     "make"
     "python"
     "git"
     "nss-certs"
     "openjdk@25"
     "ripgrep"
     "ghostscript"
     "poppler"
     "sqlite"
     "unixodbc"))))
