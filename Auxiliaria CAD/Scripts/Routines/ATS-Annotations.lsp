;| Cria uma cota rotacionada
   @returns nil
   |;
(DEFUN C:CT ()
  (SETQ *iterationsCount* 1)
  (ATS:WriteLog "CT" nil)
  (COMMAND-S "_.DIMLINEAR")
)

;| Cria uma cota contínua
   @returns nil
   |;
(DEFUN C:CTC ()
  (SETQ *iterationsCount* 1)
  (ATS:WriteLog "CTC" nil)
  (COMMAND-S "_.DIMCONTINUE")
)

;| Cria uma cota alinhada
   @returns nil
   |;
(DEFUN C:CTA ()
  (SETQ *iterationsCount* 1)
  (ATS:WriteLog "CTA" nil)
  (COMMAND-S "_.DIMALIGNED")
)

;| Limpa as cotas de um bloco
   @returns [nil] - Limpa as hachuras do bloco
   |;
(DEFUN C:LCT (/ *error* commandName selection deleteDimension count)
  (SETQ commandName "LCT")
  (COND
    ((NOT (SETQ selection (SSGET (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco foi selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences 12)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      ;; Exclui cotas dentro dos blocos de arquitetura
      (SETQ deleteDimension (LAMBDA (dimension / backgroundColor)
                          (IF (WCMATCH (VLA-GET-ObjectName dimension) "AcDbRotatedDimension,AcDbAlignedDimension,AcDb2LineAngularDimension,AcDbArcDimension,AcDbRadialDimension,AcDbDiametricDimension")
                            (VLA-DELETE dimension)
                          (SETQ *iterationsCount* (1- *iterationsCount*)))))
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (ATS:ApplyToAllNestedItems (ATS:GetEffectiveName (ATS:SaveObject (SSNAME selection count))) deleteDimension)
      )
      (COMMAND "_.REGENALL")
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Insere uma interrupção
   @returns nil
   |;
(DEFUN C:IIN (/ *error* commandName point1 point2 blockScale blockAngle)
  (SETQ commandName "IIN")
  (COND
    ((NOT (SETQ point1 (GETPOINT "\nSelecione a primeira extremidade.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
    ((NOT (SETQ point2 (GETPOINT point1 "\nSelecione a segunda extremidade.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences 15)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ *iterationsCount* 1)
      (SETQ blockScale (IF (EQ (TYPE *scaleFactor*) (READ "STR"))
                         (PROGN
                           (SETQ *scaleFactor* (GETVAR "CANNOSCALE"))
                           ; É preciso extrair o denominador, pois o bloco de interrupção não é anotativo
                           (/ *paperUnitsFactor* (ATOF (SUBSTR *scaleFactor* (+ (VL-STRING-POSITION 58 *scaleFactor*) 2))))
                         )
                         *scaleFactor*))
      (SETQ blockAngle (ANGLE point1 point2))
      (IF (>= blockAngle PI)
        (SETQ blockAngle (- blockAngle PI))
      )
      (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" *breakLineBlockList*)))
      (COMMAND-S "_.-INSERT" (ATS:GetPropertiesValues "Name" *breakLineBlockList*) "_M2P" point1 point2 blockScale (ANGTOS blockAngle 0 4))
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
