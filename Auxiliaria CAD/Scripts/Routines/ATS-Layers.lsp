;| Insere a camada
   @global
   @param layer [str] - Nome da camada
   @returns [str] - Nome do layer, se encontrado
   |;
(DEFUN ATS:InsertLayer (layer)
  (IF (OR
        (TBLOBJNAME "LAYER" layer)
        (PROGN
          (ATS:Steal (STRCAT (ATS:EvaluateStringSymbolList *templatesFolder*) *template*) (LIST (LIST "Layers" (LIST layer))))
          (TBLOBJNAME "LAYER" layer)
        )
      )
    layer
    (PROMPT (STRCAT "\nLayer \"" layer "\" não encontrado em " *template* ".\n"))
  )
)

;| Altera a camada atual
   @global
   @param layer [str] - Nome da camada
   @returns [str] - Nome da camada, se encontrada
   |;
(DEFUN ATS:SetCurrentLayer (layer)
  (IF (ATS:InsertLayer layer)
    (SETVAR "CLAYER" layer)
  )
)

;| Mescla uma camada em outra
   @global
   @param layersToMerge [str/lst] - Nome da camada ou lista de camadas a serem mescladas
   @param targetLayer [str] - Nome da camada alvo
   @returns [nil] - Mescla as camadas
   |;
(DEFUN ATS:LayerMerge (layersToMerge targetLayer)
  (COMMAND "_.-LAYMRG")
  (IF (EQ (TYPE layersToMerge) (READ "STR"))
    (COMMAND "_NAME" layersToMerge)
    (FOREACH layerToMerge layersToMerge
      (COMMAND "_NAME" layerToMerge)
    )
  )
  (COMMAND "" "_NAME" targetLayer "_YES")
)

;| Salva a configuração atual das camadas
   @global
   @returns [lst] - Lista de camadas desligadas, congeladas e travadas, nesta ordem
   |;
(DEFUN ATS:SaveDeactivaredLayers (/ offLayers frozenLayers lockedLayers)
  (FOREACH layer (ATS:GetTableProperties nil "LAYER" (LIST 2 62 70) nil)
    (IF (< (CADR layer) 0) ; se o layer estiver desligado
      (SETQ offLayers (CONS (CAR layer) offLayers))
    )
    (IF (EQ (LOGAND (CADDR layer) 1) 1) ; se o layer estiver congelado
      (SETQ frozenLayers (CONS (CAR layer) frozenLayers))
    )
    (IF (EQ (LOGAND (CADDR layer) 4) 4) ; se o layer estiver travado
      (SETQ lockedLayers (CONS (CAR layer) lockedLayers))
    )
  )
  (SETQ *deactivatedLayers* (LIST offLayers frozenLayers lockedLayers))
)

;| Ativa todos as camadas
   @global
   @returns [nil] - Salva a configuração anterior das camadas e as ativa
   |;
(DEFUN ATS:ActivateLayers ()
  (ATS:SaveDeactivaredLayers)
  (COMMAND-S "_.-LAYER" "_ON" "*" "_THAW" "*" "_UNLOCK" "*" "")
)

;| Restaura a configuração salva de camadas
   @global
   @returns [nil] - Restaura a configuração salva das camadas
   |;
(DEFUN ATS:RestoreLayers (/ offLayers frozenLayers lockedLayers)
  (IF (SETQ offLayers (CAR *deactivatedLayers*))
    (PROGN
      (FOREACH layer offLayers
        (IF (NOT (TBLOBJNAME "LAYER" layer))
          (VL-REMOVE layer offLayers)
        )
      )
      (IF (SETQ offLayers (ATS:ListToString "," offLayers))
        (COMMAND-S "_.-LAYER" "_OFF" offLayers "")
      )
    )
  )
  (IF (SETQ frozenLayers (CADR *deactivatedLayers*))
    (PROGN
      (FOREACH layer frozenLayers
        (IF (NOT (TBLOBJNAME "LAYER" layer))
          (VL-REMOVE layer frozenLayers)
        )
      )
      (IF (SETQ frozenLayers (ATS:ListToString "," frozenLayers))
        (COMMAND-S "_.-LAYER" "_FREEZE" frozenLayers "")
      )
    )
  )
  (IF (SETQ lockedLayers (CADDR *deactivatedLayers*))
    (PROGN
      (FOREACH layer lockedLayers
        (IF (NOT (TBLOBJNAME "LAYER" layer))
          (VL-REMOVE layer lockedLayers)
        )
      )
      (IF (SETQ lockedLayers (ATS:ListToString "," lockedLayers))
        (COMMAND-S "_.-LAYER" "_LOCK" lockedLayers "")
      )
    )
  )
)

;| Altera a camada dos objetos selecionados, ou da camada atual
   @global
   @param layer [str] - Nome da camada
   @returns [nil] - Altera a camada dos objetos selecionados ou a camada atual
   |;
(DEFUN ATS:ChangeLayer (layer / selection)
  (IF (SETQ selection (SSGET "_I"))
    (IF (ATS:InsertLayer layer)
      (PROGN
        (SSSETFIRST nil nil)
        (ATS:ChangeSelectionProperties selection (LIST (CONS 8 layer)))
      )
    )
    (ATS:SetCurrentLayer layer)
  )
)

;| Trava as camadas
   @global
   @param layersList [lst] - Lista de camadas a travar
   @returns [nil] - Trava as camadas
   |;
(DEFUN ATS:LockLayers (layersList)
  (IF (MEMBER (GETVAR "CLAYER") layersList)
    (SETVAR "CLAYER" "0")
  )
  (COMMAND-S "_.-LAYER" "_LOCK" (ATS:ListToString "," layersList) "")
)

;| Destrava as camadas
   @global
   @param layersList [lst] - Lista de camadas a destravar
   @returns [nil] - Destrava as camadas
   |;
(DEFUN ATS:UnlockLayers (layersList)
  (COMMAND-S "_.-LAYER" "_UNLOCK" (ATS:ListToString "," layersList) "")
)

;| Isola as camadas
   @global
   @param layersList [lst] - Lista de camadas a isolar
   @returns [nil] - Isola as camadas
   |;
(DEFUN ATS:IsolateLayers (layersList)
  (ATS:SaveDeactivaredLayers)
  (IF (NOT (MEMBER (GETVAR "CLAYER") layersList))
    (SETVAR "CLAYER" "0")
  )
  (COMMAND-S "_.-LAYER" "_LOCK" (STRCAT "~" (GETVAR "CLAYER")) "_UNLOCK" (ATS:ListToString "," layersList) "")
)

;| Define a ordem de visualização dos objetos de acordo com as suas camadas ou nomes particulares de blocos
   @global
   @param layersDrawOrderList [lst] - Lista com nomes das camadas, da mais prioritária à menos, divididas em camadas de anotação e camadas de desenho, ou 'T' para configuração padrão
   @param blocksDrawOrderList [lst] - Lista com nomes dos blocos, do mais prioritário ao menos, ou 'T' para configuração padrão
   @returns [nil] - Organiza a ordem de visualização dos objetos
   |;
(DEFUN ATS:SetDrawOrder (layersDrawOrderList blocksDrawOrderList / blocksSelection selection)
  ;; Caso 'layersDrawOrderList' seja T, utiliza a configuração padrão
  (IF (EQ layersDrawOrderList T)
    (SETQ layersDrawOrderList (MAPCAR (FUNCTION (LAMBDA (layersList) (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (ATS:EvaluateSymbolList layersList)))) *layersDrawOrderList*))
  )
  ;; Caso 'blocksDrawOrderList' seja T, utiliza a configuração padrão
  (IF (EQ blocksDrawOrderList T)
    (SETQ blocksDrawOrderList (MAPCAR (FUNCTION (LAMBDA (block) (IF (LISTP block) (ATS:GetPropertiesValues "Name" block) block))) (ATS:EvaluateSymbolList *blocksDrawOrderList*)))
  )
  ;; Traz os elementos das camadas de anotação
  (FOREACH layerName (CAR layersDrawOrderList)
    (IF (SETQ selection (SSGET "_A" (LIST (CONS 8 layerName) (CONS 410 (GETVAR "CTAB")))))
      (COMMAND-S "_.DRAWORDER" selection "" "_BACK")
    )
  )
  ;; Traz os blocos prioritários, normalmente com wipeouts
  (IF (AND
        (SETQ blocksSelection (SSGET "_A" (LIST (CONS 0 "INSERT") (CONS 410 (GETVAR "CTAB")))))
        (SETQ blocksSelection (ATS:FilterSelection nil T blocksSelection (LIST (CONS 2 (ATS:ListToString "," blocksDrawOrderList)))))
      )
    (COMMAND-S "_.DRAWORDER" blocksSelection "" "_BACK")
  )
  ;; Traz os elementos das camadas restantes
  (FOREACH layerName (CADR layersDrawOrderList)
    (SETQ selection (ATS:TrimSelectionSets (SSGET "_A" (LIST (CONS 8 layerName) (CONS 410 (GETVAR "CTAB")))) blocksSelection))
    (IF selection
      (COMMAND-S "_.DRAWORDER" selection "" "_BACK")
    )
  )
  (COMMAND-S "_.REGENALL")
)

;| Organiza a ordem de visualização das camadas e blocos
   @returns nil
   |;
(DEFUN C:DRA (/ *error* commandName)
  (SETQ commandName "DRA")
  (ATS:SaveUsersPreferences nil)
  (DEFUN *error* (errorMessage)
    (ATS:RestoreUsersPreferences commandName errorMessage)
  )
  (ATS:SetDrawOrder T T)
  (COMMAND-S "_.REGENALL")
  (ATS:RestoreUsersPreferences commandName nil)
)

;| Liga, descongela e destrava todos as camadas e salva a configuração anterior
   @returns nil
   |;
(DEFUN C:LL ()
  (ATS:WriteLog "AL" nil)
  (ATS:ActivateLayers)
  (SETQ *extendedDeactivatedLayers* *deactivatedLayers*)
  (SETQ *deactivatedLayers* nil)
)

;| Restaura a configuração anterior das camadas
   @returns nil
   |;
(DEFUN C:RL (/ *deactivatedLayers*)
  (ATS:WriteLog "RL" nil)
  (COMMAND-S "_.-LAYER" "_ON" "*" "_THAW" "*" "_UNLOCK" "*" "")
  (SETQ *deactivatedLayers* *extendedDeactivatedLayers*)
  (ATS:RestoreLayers)
  (SETQ *extendedDeactivatedLayers* nil)
)

;| Trava as camadas principais
   @returns nil
   |;
(DEFUN C:TL ()
  (ATS:WriteLog "TL" nil)
  (ATS:LockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *pen1* *pen2* *pen3* *pen4* *pen5* *pen6*))))
)

;| Destrava as camadas principais
   @returns nil
   |;
(DEFUN C:DL ()
  (ATS:WriteLog "DL" nil)
  (ATS:UnlockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *pen1* *pen2* *pen3* *pen4* *pen5* *pen6*))))
)

;| Isola as camadas principais
   @returns nil
   |;
(DEFUN C:IL ()
  (ATS:WriteLog "IL" nil)
  (ATS:IsolateLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *pen1* *pen2* *pen3* *pen4* *pen5* *pen6*))))
)

;| Trava as camadas de simbologia
   @returns nil
   |;
(DEFUN C:TS ()
  (ATS:WriteLog "TS" nil)
  (ATS:LockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))
)

;| Destrava as camadas de simbologia
   @returns nil
   |;
(DEFUN C:DS ()
  (ATS:WriteLog "DS" nil)
  (ATS:UnlockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))
)

;| Isola as camadas de simbologia
   @returns nil
   |;
(DEFUN C:IS ()
  (ATS:WriteLog "IS" nil)
  (ATS:IsolateLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))
)

;| Travar a camada de cotas
   @returns nil
   |;
(DEFUN C:TC ()
  (ATS:WriteLog "TC" nil)
  (ATS:LockLayers (LIST (ATS:EvaluateStringSymbolList *dimensionLayer*)))
)

;| Destravar a camada de cotas
   @returns nil
   |;
(DEFUN C:DC ()
  (ATS:WriteLog "DC" nil)
  (ATS:UnlockLayers (LIST (ATS:EvaluateStringSymbolList *dimensionLayer*)))
)

;| Muda para a camada "0"
   @returns nil
   |;
(DEFUN C:0 ()
  (ATS:WriteLog "0" nil)
  (ATS:ChangeLayer "0")
)

(IF *pen1*
  ;| Muda para a camada da pena 1
     @returns nil
     |;
  (DEFUN C:1 ()
    (ATS:WriteLog "1" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen1*))
  )
)

(IF *pen2*
  ;| Muda para a camada da pena 2
     @returns nil
     |;
  (DEFUN C:2 ()
    (ATS:WriteLog "2" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen2*))
  )
)

(IF *pen3*
  ;| Muda para a camada da pena 3
     @returns nil
     |;
  (DEFUN C:3 ()
    (ATS:WriteLog "3" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen3*))
  )
)

(IF *pen4*
  ;| Muda para a camada da pena 4
     @returns nil
     |;
  (DEFUN C:4 ()
    (ATS:WriteLog "4" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen4*))
  )
)

(IF *pen5*
  ;| Muda para a camada da pena 5
     @returns nil
     |;
  (DEFUN C:5 ()
    (ATS:WriteLog "5" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen5*))
  )
)

(IF *pen6*
  ;| Muda para a camada da pena 6
     @returns nil
     |;
  (DEFUN C:6 ()
    (ATS:WriteLog "6" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen6*))
  )
)

(IF *symbolPen1*
  ;| Muda para a camada de simbologia da pena 1
     @returns nil
     |;
  (DEFUN C:S1 ()
    (ATS:WriteLog "S1" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen1*))
  )
)

(IF *symbolPen2*
  ;| Muda para a camada de simbologia da pena 2
     @returns nil
     |;
  (DEFUN C:S2 ()
    (ATS:WriteLog "S2" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen2*))
  )
)

(IF *symbolPen3*
  ;| Muda para a camada de simbologia da pena 3
     @returns nil
     |;
  (DEFUN C:S3 ()
    (ATS:WriteLog "S3" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen3*))
  )
)

(IF *symbolPen4*
  ;| Muda para a camada de simbologia da pena 4
     @returns nil
     |;
  (DEFUN C:S4 ()
    (ATS:WriteLog "S4" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen4*))
  )
)

(IF *symbolPen5*
  ;| Muda para a camada de simbologia da pena 5
     @returns nil
     |;
  (DEFUN C:S5 ()
    (ATS:WriteLog "S5" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen5*))
  )
)

(IF *symbolPen6*
  ;| Muda para a camada de simbologia da pena 6
     @returns nil
     |;
  (DEFUN C:S6 ()
    (ATS:WriteLog "S6" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen6*))
  )
)

(IF *projectionLayer*
  ;| Muda para a camada de projeção
     @returns nil
     |;
  (DEFUN C:PROJ ()
    (ATS:WriteLog "PROJ" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *projectionLayer*))
  )
)

(IF *areaLayer*
  ;| Muda para a camada de área
     @returns nil
     |;
  (DEFUN C:AREAS ()
    (ATS:WriteLog "AREAS" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *areaLayer*))
  )
)

(IF *falseCeilingLayer*
  ;| Muda para a camada de forro
     @returns nil
     |;
  (DEFUN C:FOR ()
    (ATS:WriteLog "FOR" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *falseCeilingLayer*))
  )
)

(IF *structuralLayer*
  ;| Muda para a camada de estrutural
     @returns nil
     |;
  (DEFUN C:EST ()
    (ATS:WriteLog "EST" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *structuralLayer*))
  )
)

(IF *layoutLayer*
  ;| Muda para a camada de layout
     @returns nil
     |;
  (DEFUN C:LAY ()
    (ATS:WriteLog "LAY" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *layoutLayer*))
  )
)

(IF *electricalLayer*
  ;| Muda para a camada de elétrica
     @returns nil
     |;
  (DEFUN C:ELE ()
    (ATS:WriteLog "ELE" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *electricalLayer*))
  )
)

(IF *fireLayer*
  ;| Muda para a camada de incêndio
     @returns nil
     |;
  (DEFUN C:INC ()
    (ATS:WriteLog "INC" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *fireLayer*))
  )
)

(IF *plumbingLayer*
  ;| Muda para a camada de louças
     @returns nil
     |;
  (DEFUN C:HID ()
    (ATS:WriteLog "HID" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *plumbingLayer*))
  )
)

(IF *lightingLayer*
  ;| Muda para a camada de luminotécnico
     @returns nil
     |;
  (DEFUN C:LUM ()
    (ATS:WriteLog "LUM" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *lightingLayer*))
  )
)

(IF *trafficLayer*
  ;| Muda para a camada de tráfego
     @returns nil
     |;
  (DEFUN C:TRA ()
    (ATS:WriteLog "TRA" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *trafficLayer*))
  )
)

(IF *vegetationLayer*
  ;| Muda para a camada de vegetação
     @returns nil
     |;
  (DEFUN C:VEG ()
    (ATS:WriteLog "VEG" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *vegetationLayer*))
  )
)

(IF *siteLayer*
  ;| Muda para a camada de terreno
     @returns nil
     |;
  (DEFUN C:TER ()
    (ATS:WriteLog "TER" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *siteLayer*))
  )
)

(IF *constructionLayer*
  ;| Muda para a camada de construção
     @returns nil
     |;
  (DEFUN C:CONS ()
    (ATS:WriteLog "CONS" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *constructionLayer*))
  )
)

(IF *demolitionLayer*
  ;| Muda para a camada de demolição
     @returns nil
     |;
  (DEFUN C:DEM ()
    (ATS:WriteLog "DEM" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *demolitionLayer*))
  )
)

(IF *handrailLayer*
  (PROGN
    ;| Muda para a camada de corrimão
      @returns nil
      |;
    (DEFUN C:CORR ()
      (ATS:WriteLog "CORR" nil)
      (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *handrailLayer*))
    )
    ;| Muda para a camada de corrimão para incêndio e aplica a cor 10
      @returns nil
      |;
    (DEFUN C:CORRINC (/ layerName)
      (ATS:WriteLog "CORRINC" nil)
      (SETQ layerName (ATS:EvaluateStringSymbolList *handrailLayer*))
      (IF (ATS:ChangeLayer layerName)
        (ATS:ChangePropertiesValues (TBLOBJNAME "LAYER" layerName) (LIST (CONS 62 10)))
      )
    )
  )
)

(IF *draftLayer*
  ;| Muda para a camada de rascunho
     @returns nil
     |;
  (DEFUN C:RAS ()
    (ATS:WriteLog "RAS" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *draftLayer*))
  )
)
