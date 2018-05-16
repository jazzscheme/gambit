;;;============================================================================

;;; File: "_gsclib.scm"

;;; Copyright (c) 1994-2018 by Marc Feeley, All Rights Reserved.

(include "generic.scm")

;;;----------------------------------------------------------------------------

(set! make-global-environment ;; import runtime macros into compilation env
  (lambda ()

    (define (extract-macros cte)
      (if (##cte-top? cte)
        (env-frame #f '())
        (let ((parent-cte (##cte-parent-cte cte)))
          (if (##cte-macro? cte)
            (env-macro (extract-macros parent-cte)
                       (##cte-macro-name cte)
                       (##cte-macro-descr cte))
            (extract-macros parent-cte)))))

    (extract-macros (##cte-top-cte ##interaction-cte))))

(define (##compile-options-normalize options)
  (##map (lambda (opt)
           (if (##pair? opt)
               opt
               (##list opt)))
         options))

(define (compile-file-to-target
         filename
         #!rest other;;;;;;;;;;
         #!key
         (options (macro-absent-obj))
         (output (macro-absent-obj))
         (module-name (macro-absent-obj))
         (linker-name (macro-absent-obj)))
  (macro-force-vars (filename)
    (macro-check-string filename 1 (compile-file-to-target filename . other);;;;;;
      (let* ((opts
              (if (##eq? options (macro-absent-obj))
                  '()
                  (macro-force-vars (options)
                    options)))
             (out
              (if (##eq? output (macro-absent-obj))
                  (##path-directory
                   (##path-normalize filename))
                  (macro-force-vars (output)
                    output)))
             (mod-name
              (if (##eq? module-name (macro-absent-obj))
                  #f
                  (macro-force-vars (module-name)
                    module-name)))
             (link-name
              (if (##eq? linker-name (macro-absent-obj))
                  #f
                  (macro-force-vars (linker-name)
                    linker-name))))
        (cond ((##not (or (##null? opts)
                          (##pair? opts)))
               (error "list expected for options: parameter"));;;;;;;
              ((##not (##string? out))
               (error "string expected for output: parameter"));;;;;;;;;;
              ((##not (or (##not mod-name) (##string? mod-name)))
               (error "string or #f expected for module-name: parameter"));;;;;;;;;;
              ((##not (or (##not link-name) (##string? link-name)))
               (error "string or #f expected for linker-name: parameter"));;;;;;;;;;
              (else
               (##compile-file-to-target filename
                                         opts
                                         out
                                         mod-name
                                         link-name)))))))

(define (##compile-file-to-target filename options output mod-name link-name)
  (let* ((options
          (##compile-options-normalize options))
         (expanded-output
          (##path-normalize output))
         (output-directory?
          (##not (##equal? expanded-output
                           (##path-strip-trailing-directory-separator
                            expanded-output))))
         (output-filename-gen
          (lambda ()
            (if output-directory?
                (##string-append
                 (##path-expand
                  (##path-strip-directory
                   (##path-strip-extension filename))
                  expanded-output)
                 (##caar target.file-extensions))
                expanded-output)))
         (module-name
          (or mod-name
              (##path-strip-directory
               (##path-strip-extension
                (if output-directory?
                    filename
                    expanded-output)))))
         (linker-name
          (or link-name
              module-name)))
    (c#cf filename
          options
          output-filename-gen
          module-name
          linker-name)))

(define (compile-file
         filename
         #!rest other;;;;;;;;;;
         #!key
         (options (macro-absent-obj))
         (output (macro-absent-obj))
         (module-name (macro-absent-obj))
         (linker-name (macro-absent-obj))
         (cc-options (macro-absent-obj))
         (ld-options-prelude (macro-absent-obj))
         (ld-options (macro-absent-obj)))
  (macro-force-vars (filename)
    (macro-check-string filename 1 (compile-file filename . other);;;;;;
      (let* ((opts
              (if (##eq? options (macro-absent-obj))
                  '()
                  (macro-force-vars (options)
                    options)))
             (out
              (if (##eq? output (macro-absent-obj))
                  (##path-directory
                   (##path-normalize filename))
                  (macro-force-vars (output)
                    output)))
             (mod-name
              (if (##eq? module-name (macro-absent-obj))
                  #f
                  (macro-force-vars (module-name)
                    module-name)))
             (link-name
              (if (##eq? linker-name (macro-absent-obj))
                  #f
                  (macro-force-vars (linker-name)
                    linker-name)))
             (cc-opts
              (if (##eq? cc-options (macro-absent-obj))
                  ""
                  (macro-force-vars (cc-options)
                    cc-options)))
             (ld-opts-prelude
              (if (##eq? ld-options-prelude (macro-absent-obj))
                  ""
                  (macro-force-vars (ld-options-prelude)
                    ld-options-prelude)))
             (ld-opts
              (if (##eq? ld-options (macro-absent-obj))
                  ""
                  (macro-force-vars (ld-options)
                    ld-options))))
        (cond ((##not (or (##null? opts)
                          (##pair? opts)))
               (error "list expected for options: parameter"));;;;;;;
              ((##not (##string? out))
               (error "string expected for output: parameter"));;;;;;;;;;
              ((##not (or (##not mod-name) (##string? mod-name)))
               (error "string or #f expected for module-name: parameter"));;;;;;;;;;
              ((##not (or (##not link-name) (##string? link-name)))
               (error "string or #f expected for linker-name: parameter"));;;;;;;;;;
              ((##not (##string? cc-opts))
               (error "string expected for cc-options: parameter"));;;;;;;;;;
              ((##not (##string? ld-opts-prelude))
               (error "string expected for ld-options-prelude: parameter"));;;;;;;;;;
              ((##not (##string? ld-opts))
               (error "string expected for ld-options: parameter"));;;;;;;;;;
              (else
               (##compile-file filename
                               opts
                               out
                               mod-name
                               link-name
                               cc-opts
                               ld-opts-prelude
                               ld-opts)))))))

(define (##compile-file
         filename
         options
         output
         module-name
         linker-name
         cc-options
         ld-options-prelude
         ld-options)
  (let* ((options
          (##compile-options-normalize options))
         (target
          (##extract-target options)))

    (define type
      (cond ((##assq 'obj options)
             'obj)
            ((##assq 'exe options)
             'exe)
            (else
             'dyn)))

    (define (generate-next-version-of-object-file root)
      (let loop ((version 1))
        (let ((root-with-ext
               (##string-append root ".o" (##number->string version 10))))
          (if (##file-exists? root-with-ext)
              (loop (##fx+ version 1))
              root-with-ext))))

    (define (generate-output-filename root input-is-target-file?)
      (case type
        ((obj)
         (##string-append
          root
          ##os-obj-extension-string-saved))
        (else
         (if input-is-target-file?
             root
             (generate-next-version-of-object-file root)))))

    (let* ((input-is-target-file?
            (##assoc (##path-extension filename)
                     (c#target-file-extensions target)))
           (target-filename
            (if input-is-target-file?
                filename
                (##string-append
                 (##path-strip-extension filename)
                 (##caar (c#target-file-extensions target)))))
           (expanded-output
            (##path-normalize output))
           (output-directory?
            (##not (##equal? expanded-output
                             (##path-strip-trailing-directory-separator
                              expanded-output))))
           (output-filename
            (if output-directory?
                (generate-output-filename
                 (##path-expand
                  (##path-strip-directory
                   (##path-strip-extension filename))
                  expanded-output)
                 input-is-target-file?)
                expanded-output))
           (output-dir
            (##path-directory output-filename))
           (output-filename-no-dir
            (##path-strip-directory output-filename))
           (module-name
            (or module-name
                (##path-strip-extension output-filename-no-dir)))
           (linker-name
            (or linker-name
                (if (##eq? type 'dyn)
                    output-filename-no-dir
                    module-name))))
      (and (or input-is-target-file?
               (c#cf filename
                     options
                     (lambda () target-filename)
                     module-name
                     linker-name))
           (let ((exit-status
                  (##gambcomp
                   (c#target-name target)
                   type
                   output-dir
                   (##list target-filename)
                   output-filename-no-dir
                   (##assq 'verbose options)
                   (##assq 'hide-console options)
                   (##list (##cons "CC_OPTIONS" cc-options)
                           (##cons "LD_OPTIONS_PRELUDE" ld-options-prelude)
                           (##cons "LD_OPTIONS" ld-options)))))
             (if (and (##not (##assq 'keep-c options))
                      (##not (##string=? filename target-filename)))
                 (##delete-file target-filename))
             (if (##fx= exit-status 0)
                 output-filename
                 (##raise-error-exception
                  "target compilation or link failed while compiling"
                  (##list filename))))))))

(define (##build-executable
         obj-files
         options
         output-filename
         cc-options
         ld-options-prelude
         ld-options)
  (let* ((options
          (##compile-options-normalize options))
         (target
          (##extract-target options))
         (output-dir
          (##path-directory output-filename))
         (output-filename-no-dir
          (##path-strip-directory output-filename))
         (exit-status
          (##gambcomp
           (c#target-name target)
           'exe
           output-dir
           obj-files
           output-filename-no-dir
           (##assq 'verbose options)
           (##assq 'hide-console options)
           (##list (##cons "CC_OPTIONS" cc-options)
                   (##cons "LD_OPTIONS_PRELUDE" ld-options-prelude)
                   (##cons "LD_OPTIONS" ld-options)))))
    (if (##fx= exit-status 0)
        output-filename
        (##raise-error-exception
         "target link failed while linking"
         obj-files))))

(define (##gambcomp
         target
         op
         output-dir
         input-filenames
         output-filename
         verbose?
         hide-console?
         options)

  (define arg-prefix
    (case op
      ((obj) "BUILD_OBJ_")
      ((dyn) "BUILD_DYN_")
      ((lib) "BUILD_LIB_")
      ((exe) "BUILD_EXE_")
      (else  "BUILD_OTHER_")))

  (define (arg name-val)
    (##string-append (##car name-val) "=" (##cdr name-val)))

  (define (prefixed-arg name-val)
    (arg (##cons (##string-append arg-prefix (##car name-val))
                 (##cdr name-val))))

  (define (install-dir path)
    (parameterize
     ((##current-directory
       (##path-expand path)))
     (##current-directory)))

  (define (relative-to-output-dir filename)
    (##path-normalize (##path-expand filename) #t output-dir))

  (define (separate lst sep)
    (if (##pair? lst)
        (##cons sep (##cons (##car lst) (separate (##cdr lst) sep)))
        '()))

  (let* ((gambitdir-bin
          (install-dir "~~bin"))
         (gambitdir-include
          (install-dir "~~include"))
         (gambitdir-lib
          (install-dir "~~lib"))
         (input-filenames-relative
          (##map relative-to-output-dir input-filenames)))
    (##open-process-generic
     (macro-direction-inout)
     #t
     (lambda (port)
       (let ((status (##process-status port)))
         (##close-port port)
         status))
     open-process
     (##list path:
             (##string-append gambitdir-bin
                              "gambcomp-"
                              (##symbol->string target)
                              ##os-bat-extension-string-saved)
             arguments:
             (##list (##symbol->string op))
             directory:
             output-dir
             environment:
             (##append
              (##map arg
                     (##append
                      (if verbose?
                          (##list (##cons "GAMBCOMP_VERBOSE" "yes"))
                          '())
                      (##list
                       (##cons "GAMBITDIR_BIN"
                               (##path-strip-trailing-directory-separator
                                gambitdir-bin))
                       (##cons "GAMBITDIR_INCLUDE"
                               (##path-strip-trailing-directory-separator
                                gambitdir-include))
                       (##cons "GAMBITDIR_LIB"
                               (##path-strip-trailing-directory-separator
                                gambitdir-lib)))))
              (##append
               (##map prefixed-arg
                      (##append
                       (##list
                        (##cons "INPUT_FILENAMES"
                                (##append-strings
                                 (##cdr (separate input-filenames-relative
                                                  " "))))
                        (##cons "OUTPUT_FILENAME"
                                output-filename))
                       options))
               (let ((env (##os-environ)))
                 (if (##fixnum? env) '() env))))
             stdin-redirection: #f
             stdout-redirection: #f
             stderr-redirection: #f
             show-console: (##not hide-console?)))))

(define (##extract-target options)
  (let ((t (##assq 'target options)))
    (c#with-exception-handling
     (lambda ()
       (c#target-get
        (if (and (##pair? t)
                 (##pair? (##cdr t)))
            (##cadr t)
            (c#default-target)))))))

(define (link-incremental
         modules
         #!rest other;;;;;;;;;;
         #!key
         (output (macro-absent-obj))
         (linker-name (macro-absent-obj))
         (base (macro-absent-obj))
         (warnings? (macro-absent-obj)))
  (macro-force-vars (modules)
    (let loop ((lst modules) (rev-mods '()))
      (macro-force-vars (lst)
        (if (##pair? lst)
            (let ((m (##car lst)))
              (cond ((##string? m)
                     (loop (##cdr lst)
                           (##cons (##list m) rev-mods)))
                    ((and (##pair? m)
                          (##string? (##car m)))
                     (loop (##cdr lst)
                           (##cons m rev-mods)))
                    (else
                     (error "module list expected")))) ;;;;;;;;;;
            (let* ((out
                    (if (##eq? output (macro-absent-obj))
                        (##path-directory
                         (##path-normalize (##car (##car rev-mods))))
                        (macro-force-vars (output)
                          output)))
                   (link-name
                    (if (##eq? linker-name (macro-absent-obj))
                        #f
                        (macro-force-vars (linker-name)
                          linker-name)))
                   (baselib
                    (if (##eq? base (macro-absent-obj))
                        (let ((gambitdir-lib
                               (parameterize
                                ((##current-directory
                                  (##path-expand "~~lib")))
                                (##current-directory))))
                          (##string-append gambitdir-lib "_gambit"))
                        (macro-force-vars (base)
                          base)))
                   (warn?
                    (if (##eq? warnings? (macro-absent-obj))
                        #t
                        (macro-force-vars (warnings?)
                          warnings?))))
              (cond ((##not (##string? out))
                     (error "string expected for output: parameter")) ;;;;;;;;;;
                    ((##not (or (##not link-name) (##string? link-name)))
                     (error "string or #f expected for linker-name: parameter"));;;;;;;;;;
                    ((##not (##string? baselib))
                     (error "string expected for base: parameter")) ;;;;;;;;;;
                    (else
                     (##link-incremental rev-mods
                                         out
                                         link-name
                                         baselib
                                         warn?)))))))))

(define (##link-incremental rev-mods output linker-name base warnings?)
  (c#link-modules #t
                  (##cons (##list base) (##reverse rev-mods))
                  output
                  linker-name
                  warnings?))

(define (link-flat
         modules
         #!rest other;;;;;;;;;;
         #!key
         (output (macro-absent-obj))
         (linker-name (macro-absent-obj))
         (warnings? (macro-absent-obj)))
  (macro-force-vars (modules)
    (let loop ((lst modules) (rev-mods '()))
      (macro-force-vars (lst)
        (if (##pair? lst)
            (let ((m (##car lst)))
              (cond ((##string? m)
                     (loop (##cdr lst)
                           (##cons (##list m) rev-mods)))
                    ((and (##pair? m)
                          (##string? (##car m)))
                     (loop (##cdr lst)
                           (##cons m rev-mods)))
                    (else
                     (error "module list expected")))) ;;;;;;;;;;
            (let* ((out
                    (if (##eq? output (macro-absent-obj))
                        (##path-directory
                         (##path-normalize (##car (##car rev-mods))))
                        (macro-force-vars (output)
                          output)))
                   (link-name
                    (if (##eq? linker-name (macro-absent-obj))
                        #f
                        (macro-force-vars (linker-name)
                          linker-name)))
                   (warn?
                    (if (##eq? warnings? (macro-absent-obj))
                        #t
                        (macro-force-vars (warnings?)
                          warnings?))))
              (cond ((##not (##string? out))
                     (error "string expected for output: parameter")) ;;;;;;;;;;
                    ((##not (or (##not link-name) (##string? link-name)))
                     (error "string or #f expected for linker-name: parameter"));;;;;;;;;;
                    (else
                     (##link-flat rev-mods
                                  out
                                  link-name
                                  warn?)))))))))

(define (##link-flat rev-mods output linker-name warnings?)
  (c#link-modules #f
                  (##reverse rev-mods)
                  output
                  linker-name
                  warnings?))

(define (##c-code . args) ;; avoid errors when using -expansion
  (error "##c-code is not callable dynamically"))

;;;============================================================================
