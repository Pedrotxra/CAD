;| Salva as variáveis do preset atual
   @global
   @param variablesList [lst] - Lista de variáveis, separadas por tipos. Ex: (("UnitsFactor" *unitsFactor*) ("Layers" (LayerName1 LayerName2 ...)) ("Hatches" (HatchProperties1 HatchProperties2 ...)) ("Blocks" (BlockProperties1 BlockProperties2 ...)))
   @returns [lst] - Lista de variáveis e seus valores
   |;
(DEFUN ATS:SavePresetVariables (variablesList)
  (IF (NOT variablesList)
    (SETQ variablesList (LIST
                          (LIST "ScaleFactor" (QUOTE *scaleFactor*)) ; necessário para converter hachuras
                          (LIST "UnitsFactor" (QUOTE *unitsFactor*)) ; necessário para converter hachuras
                          (LIST "Layers" (APPEND (CAR *layersDrawOrderList*) (CADR *layersDrawOrderList*)))
                          (LIST "Hatches" (MAPCAR (FUNCTION CDR) *hatchesList*))
                          (LIST "Blocks" (MAPCAR (FUNCTION CDR) *shortenedBlocksNames*))))
  )
  ;; Transforma cada sublista em uma lista de variáveis e seus valores
  (MAPCAR
    (FUNCTION
      (LAMBDA (variablesList)
        (LIST (CAR variablesList) (IF (LISTP (SETQ variablesList (CADR variablesList))) (MAPCAR (FUNCTION (LAMBDA (variable) (CONS variable (EVAL variable)))) variablesList) (CONS variablesList (EVAL variablesList))))
      )
    )
    variablesList
  )
)

;| Ajusta o desenho para o preset atual
   @global
   @param presetVariables [lst] - Lista de variáveis de layers, hachuras e blocos e seus valores
   @returns [any] - Valor da última variável iterada
   |;
(DEFUN ATS:ApplyPresetVariablesChanges (presetVariables / oldScaleFactor oldUnitsFactor newValue selection count oldName newName)
  (SETQ oldScaleFactor (CADR (ASSOC "ScaleFactor" presetVariables)))
  (SETQ oldUnitsFactor (CADR (ASSOC "UnitsFactor" presetVariables)))
  (SETQ currentScaleFactor *scaleFactor*)
  ;; Aplica a alteração nos layers
  (FOREACH layer (CADR (ASSOC "Layers" presetVariables))
    (SETQ newValue (EVAL (CAR layer)))
    (SETQ layer (CDR layer))
    (IF (NOT (EQ layer newValue))
      (IF (AND layer (NOT (WCMATCH layer "0,Defpoints")) (TBLOBJNAME "LAYER" layer) newValue (ATS:InsertLayer newValue))
        (PROGN
          (IF (EQ (GETVAR "CLAYER") layer)
            (SETVAR "CLAYER" "0")
          )
          (ATS:LayerMerge layer newValue)
        )
      )
    )
  )
  ;; Aplica a alteração nas hachuras
  (FOREACH hatch (CADR (ASSOC "Hatches" presetVariables))
    (SETQ newValue (EVAL (CAR hatch)))
    (SETQ hatch (CDR hatch))
    ;; Verifica se as propriedades da hachura são diferentes do valor atual
    (IF (NOT (EQUAL hatch newValue *minimalFuzz*))
      (PROGN
        ;; Adiciona transparência ao filtro de seleção
        (SETQ count (ATS:GetPropertiesValues "Transparency" hatch))
        (IF (EQ (TYPE count) (READ "REAL"))
          (SETQ selection (LIST (CONS 440 (FIX (+ (* (- 100.0 count) 2.55) 33554432)))))
        )
        ;; Adiciona layer ao filtro de seleção
        (SETQ count (ATS:GetPropertiesValues "Layer" hatch))
        (IF (ATS:InsertLayer count)
          (SETQ selection (CONS (CONS 8 count) selection))
        )
        ;; Adiciona cor ao filtro de seleção
        (SETQ count (ATS:GetPropertiesValues "Color" hatch))
        ;; Verifica se a cor armazenada é 'TrueColor' ou índice
        (COND
          ((LISTP count)
            (SETQ count (ATS:StringToList "," (CADR count)))
            (SETQ selection (APPEND (LIST (CONS 62 9) (CONS 420 (CADR (+ (LSH (CAR count) 16) (LSH (CADR count) 8) (CADDR count))))) selection))
          )
          ((EQ (TYPE count) (READ "INT"))
            (SETQ selection (CONS (CONS 62 count) selection))
          )
        )
        ;; Adiciona rotação ao filtro de seleção
        (IF (ATS:GetPropertiesValues "PresetRotation" hatch)
          (SETQ selection (CONS (CONS 52 (* (/ (ATS:GetPropertiesValues "Rotation" hatch) 180.0) PI)) selection))
        )
        ;; Adiciona o nome do padrão ao filtro de seleção
        (SETQ selection (CONS (CONS 2 (ATS:GetPropertiesValues "Pattern" hatch)) selection))
        ;; Seleciona as hachuras e altera
        (SETQ selection (SSGET "_A" selection))
        (IF selection
          (PROGN
            ;; Caso a rotação não seja fixa, mantém a atual da hachura
            (SETQ oldName (ATS:GetPropertiesValues "Rotation" newValue))
            (IF (OR (NOT oldName) (AND oldName (NOT (ATS:GetPropertiesValues "PresetRotation" newValue))))
              (SETQ newValue (VL-REMOVE (CONS "Rotation" oldName) newValue))
            )
            ;; Caso a escala não seja fixa, mantém a atual da hachura
            (SETQ newScale (ATS:GetPropertiesValues "Scale" newValue))
            (IF newScale
              (PROGN
                (SETQ oldScale (ATS:GetPropertiesValues "Scale" hatch))
                (IF (EQ newScale oldScale)
                  (PROGN
                    (SETQ newValue (VL-REMOVE (ASSOC "Scale" newValue) newValue))
                    (SETQ newScale nil)
                    (SETQ *scaleFactor* currentScaleFactor)
                  )
                  (PROGN
                    (SETQ newPresetScale (ATS:GetPropertiesValues "PresetScale" newValue))
                    (SETQ newValue (SUBST (CONS "PresetScale" T) (ASSOC "PresetScale" newValue) newValue))
                    (SETQ oldPresetScale (ATS:GetPropertiesValues "PresetScale" hatch))
                    (IF (EQ (TYPE newPresetScale) (READ "REAL"))
                      (IF (NOT (EQ (TYPE oldPresetScale) (READ "REAL")))
                        (SETQ *scaleFactor* (/ newPresetScale (EXPT newScale 2)))
                      )
                    )
                  )
                )
              )
            )
            (SETQ oldName (ATS:GetPropertiesValues "BackgroundColor" hatch))
            (IF (EQ oldName ".")
              (SETQ oldName 257)
            )
            (SETQ count (SSLENGTH selection))
            (SETQ *iterationsCount* count)
            (REPEAT count
              (SETQ count (1- count))
              (SETQ selectionHatch (SSNAME selection count))
              ;; Verifica a correspondência de cor de fundo entre padrão antigo e novo
              (SETQ newName (VLAX-GET (ATS:SaveObject selectionHatch) "BackgroundColor"))
              (IF (OR (NOT oldName)
                      (AND (LISTP oldName) (EQ (CAR oldName) "_TRUECOLOR") (EQ (CADR oldName) (ATS:ListToString "," (MAPCAR (FUNCTION (LAMBDA (color) (ITOA (VLAX-GET newName color)))) (LIST "Red" "Green" "Blue")))))
                      (AND (EQ (TYPE oldName) (READ "INT")) (EQ (VLAX-GET newName "ColorIndex") oldName)))
                (PROGN
                  ;; Ajusta o fator de escala
                  (IF newScale
                    (PROGN
                      (SETQ newName (ATS:GetPropertiesValues 41 selectionHatch))
                      (IF (EQ (TYPE newPresetScale) (READ "REAL"))
                        (IF (EQ (TYPE oldPresetScale) (READ "REAL"))
                          (SETQ *scaleFactor* (/ (* newName oldScale) (EXPT newScale 2)))
                        )
                        (IF (AND oldScale
                                 (EQ (TYPE currentScaleFactor) (READ "REAL"))
                                 (EQ (TYPE oldScaleFactor) (READ "REAL"))
                                 (NOT (EQ (* (SETQ *scaleFactor* (/ newName oldScale oldUnitsFactor)) *paperUnitsFactor*) (FIX (* *scaleFactor* *paperUnitsFactor*)))))
                          (SETQ *scaleFactor* currentScaleFactor)
                        )
                      )
                    )
                  )
                  (AT:EditHatch selectionHatch newValue)
                )
              )
            )
          )
        )
      )
    )
  )
  (SETQ *scaleFactor* currentScaleFactor)
  ;; Aplica a alteração nos blocos
  (FOREACH block (CADR (ASSOC "Blocks" presetVariables))
    (SETQ newValue (EVAL (CAR block)))
    (SETQ block (CDR block))
    (IF (NOT (EQUAL block newValue))
      (PROGN
        (SETQ oldName (ATS:GetPropertiesValues "Name" block))
        (SETQ newName (ATS:GetPropertiesValues "Name" newValue))
        (IF (AND oldName (TBLOBJNAME "BLOCK" oldName) newName (ATS:InsertBlockFromSupportPaths newName))
          (PROGN
            (ATS:ReplaceAllBlocksInstances newValue block)
            (COMMAND-S "_.-PURGE" "_BLOCK" oldName "_NO")
          )
        )
      )
    )
  )
)
