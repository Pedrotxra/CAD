;| Atalho para 'ATTSYNC'
   @returns nil
   |;
(DEFUN C:ATTS ()
  (ATS:WriteLog "ATTS" nil)
  (COMMAND-S "_.ATTSYNC" "_SELECT" PAUSE "")
)

;| Atalho para 'BREAKATPOINT'
   @returns nil
   |;
(DEFUN C:BB ()
  (ATS:WriteLog "BB" nil)
  (COMMAND-S "_.BREAKATPOINT")
)

;| Atalho para 'BREAK'
   @returns nil
   |;
(DEFUN C:BR ()
  (ATS:WriteLog "BR" nil)
  (COMMAND-S "_.BREAK" (ATS:SelectSingleObject nil))
)

;| Atalho para 'DIST'
   @returns nil
   |;
(DEFUN C:DD ()
  (ATS:WriteLog "DD" nil)
  (COMMAND-S "_.DIST")
)

;| Atalho para 'DIST' com múltiplos pontos
   @returns nil
   |;
(DEFUN C:DDD ()
  (ATS:WriteLog "DDD" nil)
  (COMMAND-S "_.DIST" PAUSE "_MULTIPLE")
)

;| Atalho para 'COPY'
   @returns nil
   |;
(DEFUN C:CC ()
  (ATS:WriteLog "CC" nil)
  (COMMAND-S "_.COPY" (SSGET) "" "_MULTIPLE")
)

;| Atalho para 'FILLET'
   @returns nil
   |;
(DEFUN C:F ()
  (ATS:WriteLog "F" nil)
  (COMMAND-S "_.FILLET" "_MULTIPLE")
)

;| Atalho para '-INSERT' com dedução do nome do bloco
   @returns nil
   |;
(DEFUN C:II (/ blockName layer insertionScaleFactor)
  (COND
    ((NOT (SETQ blockName (GETSTRING "\nInsira o nome do bloco:\n"))) (PROMPT "\nNenhum nome foi inserido.\n"))
    ((NOT (SETQ blockName (ATS:PredictBlockName blockName))) (PROMPT "\nBloco não encontrado.\n"))
    (T
      (IF (EQ (TYPE blockName) (READ "SYM"))
        (PROGN
          (SETQ blockName (EVAL blockName))
          (SETQ layer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" blockName)))
          (ATS:SetCurrentLayer layer)
          ;; Verifica se é um bloco de anotação
          (IF (MEMBER layer (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (CAR *layersDrawOrderList*)))
            (SETQ insertionScaleFactor (ATS:GetInsertionScale))
          )
          (SETQ blockName (ATS:GetPropertiesValues "Name" blockName))
        )
      )
      (ATS:WriteLog "II" nil)
      (COMMAND "_.-INSERT" blockName)
      (IF insertionScaleFactor
        (COMMAND "_SCALE" insertionScaleFactor)
      )
    )
  )
)

;| Atalho para 'REVCLOUD'
   @returns nil
   |;
(DEFUN C:RC ()
  (ATS:WriteLog "RC" nil)
  (IF *draftLayer*
    (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *draftLayer*))
  )
  (INITCOMMANDVERSION 2)
  (COMMAND-S "_.REVCLOUD")
)

;| Atalho para 'ROTATE'
   @returns nil
   |;
(DEFUN C:RT ()
  (ATS:WriteLog "RT" nil)
  (COMMAND-S "_.ROTATE" (SSGET) "")
)

;| Atalho para 'TEXT'
   @returns nil
   |;
(DEFUN C:TX ()
  (ATS:WriteLog "TX" nil)
  (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *primaryTextsLayer*))
  (COMMAND-S "_.TEXT" "_JUSTIFY" "_MC" PAUSE (* *primaryTextsHeight* (IF (AND (EQ (GETVAR "CTAB") "Model") (EQ (TYPE *scaleFactor*) (READ "REAL"))) *scaleFactor* 1)) "0")
)

;| Atalho para 'MTEXT'
   @returns nil
   |;
(DEFUN C:MTX (/ point)
  (ATS:WriteLog "MTX" nil)
  (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *primaryTextsLayer*))
  (PROMPT "\nPressione Enter para finalizar\n")
  (COMMAND-S "_.MTEXT" (SETQ point (GETPOINT)) "_JUSTIFY" "_TC" "_HEIGHT" (* *primaryTextsHeight* (IF (AND (EQ (GETVAR "CTAB") "Model") (EQ (TYPE *scaleFactor*) (READ "REAL"))) *scaleFactor* 1)) point)
)

;| Atalho para 'MIRROR' excluindo a fonte original
   @returns nil
   |;
(DEFUN C:MII ()
  (ATS:WriteLog "MII" nil)
  (COMMAND-S "_.MIRROR" (SSGET) "" PAUSE PAUSE "_YES")
)

;| Atalho para 'ROTATE' com cópia
   @returns nil
   |;
(DEFUN C:CRT ()
  (ATS:WriteLog "CRT" nil)
  (COMMAND-S "_.ROTATE" (SSGET) "" PAUSE "_COPY")
)

;| Atalho para 'LAYCUR'
   @returns nil
   |;
(DEFUN C:LCR ()
  (ATS:WriteLog "LCR" nil)
  (COMMAND-S "_.LAYCUR")
)

;| Atalho para 'LAYMCUR'
   @returns nil
   |;
(DEFUN C:LMC ()
  (ATS:WriteLog "LMC" nil)
  (COMMAND-S "_.LAYMCUR")
)

;| Atalho para 'LAYISO'
   @returns nil
   |;
(DEFUN C:LI ()
  (ATS:WriteLog "LI" nil)
  (COMMAND-S "_.LAYISO")
)

;| Atalho para 'LAYUNISO'
   @returns nil
   |;
(DEFUN C:LUI ()
  (ATS:WriteLog "LUI" nil)
  (COMMAND-S "_.LAYUNISO")
)

;| Atalho para 'REGENALL'
   @returns nil
   |;
(DEFUN C:RA ()
  (ATS:WriteLog "RA" nil)
  (COMMAND-S "_.REGENALL")
)

;| Atalho para 'WIPEOUT'
   @returns nil
   |;
(DEFUN C:WP ()
  (ATS:WriteLog "WP" nil)
  (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *wipeoutLayer*))
  (COMMAND-S "_.WIPEOUT")
)

;| Atalho para 'LINE'
   @returns nil
   |;
(DEFUN C:W ()
  (ATS:WriteLog "W" nil)
  (COMMAND-S "_.LINE")
)

;| Atalho para 'PLINE'
   @returns nil
   |;
(DEFUN C:WW ()
  (ATS:WriteLog "WW" nil)
  (COMMAND-S "_.PLINE")
)

;;; Atalhos para CAD em idioma fora do inglês
(COND
  ((EQ *CADLanguage* "Português - Brasil")
   (SETQ *functionCancelled* "Função cancelada")

   ;| Atalho para 'APPLOAD'
      @returns nil
      |;
   (DEFUN C:APP ()
     (ATS:WriteLog "APP" nil)
     (COMMAND-S "_.APPLOAD")
   )

   ;| Atalho para 'ARRAY'
      @returns nil
      |;
   (DEFUN C:AR ()
     (ATS:WriteLog "AR" nil)
     (COMMAND-S "_.ARRAY")
   )

   ;| Atalho para 'BEDIT'
      @returns nil
      |;
   (DEFUN C:BE ()
     (ATS:WriteLog "BE" nil)
     (COMMAND-S "_.BEDIT")
   )

   ;| Atalho para 'CIRCLE'
      @returns nil
      |;
   (DEFUN C:C ()
     (ATS:WriteLog "C" nil)
     (COMMAND-S "_.CIRCLE")
   )

   ;| Atalho para 'DRAWORDER'
      @returns nil
      |;
   (DEFUN C:DR ()
     (ATS:WriteLog "DR" nil)
     (COMMAND-S "_.DRAWORDER")
   )

   ;| Atalho para 'ERASE'
      @returns nil
      |;
   (DEFUN C:E ()
     (ATS:WriteLog "E" nil)
     (COMMAND-S "_.ERASE" (SSGET) "")
   )

   ;| Atalho para 'EXTEND'
      @returns nil
      |;
   (DEFUN C:EX ()
     (ATS:WriteLog "EX" nil)
     (COMMAND-S "_.EXTEND")
   )

   ;| Atalho para 'JOIN'
      @returns nil
      |;
   (DEFUN C:J ()
     (ATS:WriteLog "J" nil)
     (COMMAND-S "_.JOIN")
   )

   ;| Atalho para 'MATCHPROP'
      @returns nil
      |;
   (DEFUN C:MA ()
     (ATS:WriteLog "MA" nil)
     (COMMAND-S "_.MATCHPROP")
   )

   ;| Atalho para 'MIRROR'
      @returns nil
      |;
   (DEFUN C:MI () 
     (ATS:WriteLog "MI" nil)
     (COMMAND-S "_.MIRROR")
   )

   ;| Atalho para 'MLEADER'
      @returns nil
      |;
   (DEFUN C:MLD ()
     (ATS:WriteLog "MLD" nil)
     (COMMAND-S "_.MLEADER")
   )

   ;| Atalho para 'OFFSET'
      @returns nil
      |;
   (DEFUN C:O ()
     (ATS:WriteLog "O" nil)
     (COMMAND-S "_.OFFSET")
   )

   ;| Atalho para 'OVERKILL'
      @returns nil
      |;
   (DEFUN C:OV ()
     (ATS:WriteLog "OV" nil)
     (COMMAND-S "_.OVERKILL")
   )

   ;| Atalho para 'QSELECT'
      @returns nil
      |;
   (DEFUN C:QSE ()
     (ATS:WriteLog "QSE" nil)
     (COMMAND-S "_.QSELECT")
   )

   ;| Atalho para 'RECTANG'
      @returns nil
      |;
   (DEFUN C:REC ()
     (ATS:WriteLog "REC" nil)
     (COMMAND-S "_.RECTANG")
   )

   ;| Atalho para 'REFEDIT'
      @returns nil
      |;
   (DEFUN C:REFE ()
     (ATS:WriteLog "REFE" nil)
     (COMMAND-S "_.REFEDIT")
   )

   ;| Atalho para 'REFCLOSE'
      @returns nil
      |;
   (DEFUN C:REFC ()
     (ATS:WriteLog "REFC" nil)
     (COMMAND-S "_.REFCLOSE")
   )

   ;| Atalho para 'STRETCH'
      @returns nil
      |;
   (DEFUN C:S ()
     (ATS:WriteLog "S" nil)
     (COMMAND-S "_.STRETCH")
   )

   ;| Atalho para 'SCALE'
      @returns nil
      |;
   (DEFUN C:SC ()
     (ATS:WriteLog "SC" nil)
     (COMMAND-S "_.SCALE")
   )

   ;| Atalho para 'TRIM'
      @returns nil
      |;
   (DEFUN C:TR ()
     (ATS:WriteLog "TR" nil)
     (COMMAND-S "_.TRIM")
   )
  )
  (T
    (SETQ *functionCancelled* "Function cancelled")
  )
)
