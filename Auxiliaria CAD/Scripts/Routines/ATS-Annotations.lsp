;| Cria uma cota rotacionada
   @returns nil
   |;
(DEFUN C:CT ()
  (ATS:WriteLog "CT" nil)
  (COMMAND-S "_.DIMLINEAR")
)

;| Cria uma cota contínua
   @returns nil
   |;
(DEFUN C:CTC ()
  (ATS:WriteLog "CTC" nil)
  (COMMAND-S "_.DIMCONTINUE")
)

;| Cria uma cota alinhada
   @returns nil
   |;
(DEFUN C:CTA ()
  (ATS:WriteLog "CTA" nil)
  (COMMAND-S "_.DIMALIGNED")
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
