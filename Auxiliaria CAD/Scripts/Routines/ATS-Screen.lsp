;| Obtém as extensões da vista atual
   @global
   @returns [lst] - Lista com as coordenadas mínimas e máximas da vista
   |;
(DEFUN ATS:GetViewExtents (/ viewCenter viewHeight screenSize viewQuarter)
  (SETQ viewCenter (GETVAR "VIEWCTR"))
  (SETQ viewHeight (GETVAR "VIEWSIZE"))
  (SETQ screenSize (GETVAR "SCREENSIZE"))
  (SETQ viewQuarter (MAPCAR (FUNCTION /) (LIST (* viewHeight (/ (CAR screenSize) (CADR screenSize))) viewHeight) (LIST 2.0 2.0)))
  (LIST (MAPCAR (FUNCTION -) viewCenter viewQuarter) (MAPCAR (FUNCTION +) viewCenter viewQuarter))
)

;| Salva os pontos do contorno em variáveis e dá zoom
   @global
   @param boundaries [lst] - Lista com os pontos do contorno
   @returns [nil] - Salva as variáveis e dá o zoom
   |;
(DEFUN ATS:SaveBoundaries (boundaries)
  (SETQ bottom (CAR boundaries))
  (SETQ top (CADR boundaries))
  (SETQ xBottom (CAR bottom))
  (SETQ yBottom (CADR bottom))
  (SETQ xTop (CAR top))
  (SETQ yTop (CADR top))
  (COMMAND-S "_.ZOOM" bottom top)
)

;| Limpa as variáveis dos pontos do contorno
   @global
   @returns [nil] - Limpa as variáveis de contornos
   |;
(DEFUN ATS:ClearBoundaries ()
  (SETQ bottom nil)
  (SETQ top nil)
  (SETQ xBottom nil)
  (SETQ yBottom nil)
  (SETQ xTop nil)
  (SETQ yTop nil)
)

;| Encontra o bloco de distância mais próximo dentro dos limites da tela
   @global
   @param axis [str] - 'X' ou 'Y'
   @param forward [bool] - 'T' para frente, ou 'nil' para trás
   @returns [real] - Valor da distância do bloco mais próximo
   |;
(DEFUN ATS:GetClosestDistanceBlockValue (axis forward / distanceBlocks referencePoint comparison minAngle maxAngle)
  (IF (AND
        (SETQ distanceBlocks (SSGET "_X" (LIST (CONS 0 "INSERT") (CONS 410 (IF (EQ (GETVAR "CVPORT") 1) "Layout" "Model")))))
        (SETQ distanceBlocks (ATS:FilterSelection nil nil distanceBlocks (LIST (CONS 2 (ATS:GetPropertiesValues "Name" *distanceBlockList*)))))
        (SETQ distanceBlocks (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (distanceBlock)
                                                           (EQ (ATS:GetDynamicBlockProperties nil nil (ATS:SaveObject (CADR distanceBlock)) (ATS:GetPropertiesValues "AxisPropertyName" *distanceBlockList*)) (IF (EQ axis "X")
                                                                                                                                                                                                             "Horizontal"
                                                                                                                                                                                                             "Vertical")))) (ATS:GetSelectionProperties (LIST 10 -1) distanceBlocks)))
      )
    (PROGN
      (COND
        ((AND (EQ axis "X") forward) (PROGN (SETQ comparison (FUNCTION OR)) (SETQ minAngle (/ (* PI 7) 4)) (SETQ maxAngle (/ PI 4))))
        ((AND (EQ axis "Y") forward) (PROGN (SETQ comparison (FUNCTION AND)) (SETQ minAngle (/ PI 4)) (SETQ maxAngle (/ (* PI 3) 4))))
        ((AND (EQ axis "X") (NOT forward)) (PROGN (SETQ comparison (FUNCTION AND)) (SETQ minAngle (/ (* PI 3) 4)) (SETQ maxAngle (/ (* PI 5) 4))))
        ((AND (EQ axis "Y") (NOT forward)) (PROGN (SETQ comparison (FUNCTION AND)) (SETQ minAngle (/ (* PI 5) 4)) (SETQ maxAngle (/ (* PI 7) 4))))
      )
      ;; Identifica o centro da vista atual
      (SETQ referencePoint (ATS:GetViewExtents))
      (SETQ referencePoint (LIST (/ (+ (CAR (CAR referencePoint)) (CAR (CADR referencePoint))) 2) (/ (+ (CADR (CAR referencePoint)) (CADR (CADR referencePoint))) 2)))
      (IF (SETQ distanceBlocks (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (distanceBlock / pointsAngle) (SETQ pointsAngle (ANGLE referencePoint (CAR distanceBlock))) (APPLY comparison (LIST (> pointsAngle minAngle) (< pointsAngle maxAngle))))) distanceBlocks))
        (PROGN
          (SETQ distanceBlocks (MAPCAR (FUNCTION (LAMBDA (distanceBlock) (LIST (DISTANCE referencePoint (CAR distanceBlock)) (CADR distanceBlock)))) distanceBlocks))
          (ATOF (ATS:GetPropertiesValues 1 (ATS:SearchAttribute nil (CADR (ASSOC (APPLY (FUNCTION MIN) (MAPCAR (FUNCTION CAR) distanceBlocks)) distanceBlocks)) (LIST (CONS 2 (ATS:GetPropertiesValues "DistanceAttributeName" *distanceBlockList*))))))
        )
      )
    )
  )
)

;| Configura o movimento de tela com distância predefinida
   @global
   @returns [real] - Valor da distância fixa
   |;
(DEFUN ATS:ConfigFixedPan ()
  (SETQ *fixedPanAxis* (ATS:GetKeyword *fixedPanAxis* (LIST "X" "Y") "\nDeseja mover a tela em qual eixo?\n"))
  (SETQ *fixedPanOffset* (PROGN (INITGET 6) (GETREAL (STRCAT "\nInsira a distância " (IF *fixedPanOffset*
                                                                                       (STRCAT ", Enter para deslocamento automático ou Esc para manter o valor atual: <" (RTOS *fixedPanOffset*) ">")
                                                                                       "ou Enter para deslocamento automático: <Automático>") "\n"))))
)

;| Movimenta a tela em uma distância predefinida
   @global
   @param axis [str] - 'X' ou 'Y'
   @param forward [bool] - 'T' para frente, ou 'nil' para trás
   @param offset [real] - Valor da distância
   @returns [nil] - Movimenta a tela com a distância predefinida
   |;
(DEFUN ATS:FixedPan (axis forward offset)
  (IF (OR offset (SETQ offset (ATS:GetClosestDistanceBlockValue axis forward)))
    (PROGN
      (IF forward
        (SETQ offset (- offset))
      )
      (SETQ selection (SSGET "_I"))
      (COMMAND-S "_.PAN" (LIST 0.0 0.0 0.0) (IF (EQ axis "X") (LIST offset 0.0 0.0) (LIST 0.0 offset 0.0)))
      (IF selection
        (PROGN
          (SETQ offset (- offset))
          (COMMAND-S "_COPY" selection "" (LIST 0.0 0.0 0.0) (IF (EQ axis "X") (LIST offset 0.0 0.0) (LIST 0.0 offset 0.0)))
        )
      )
    )
    (PROMPT "\nNenhum bloco de distância encontrado ou distância inválida.\n")
  )
)

;| Configura o movimento de tela com distância predefinida
   @returns nil
   |;
(DEFUN C:PC ()
  (ATS:WriteLog "PC" nil)
  (ATS:SetDefaultValues
    (LIST
      (CONS (QUOTE *fixedPanAxis*) "X")
    )
  )
  (ATS:ConfigFixedPan)
)

;| Movimenta a tela em uma distância predefinida para frente
   @returns nil
   |;
(DEFUN C:PF ()
  (ATS:WriteLog "PF" nil)
  (ATS:SetDefaultValues
    (LIST
      (CONS (QUOTE *fixedPanAxis*) "X")
    )
  )
  (ATS:FixedPan *fixedPanAxis* T *fixedPanOffset*)
)

;| Movimenta a tela em uma distância predefinida para trás
   @returns nil
   |;
(DEFUN C:PT ()
  (ATS:WriteLog "PT" nil)
  (ATS:SetDefaultValues
    (LIST
      (CONS (QUOTE *fixedPanAxis*) "X")
    )
  )
  (ATS:FixedPan *fixedPanAxis* nil *fixedPanOffset*)
)
