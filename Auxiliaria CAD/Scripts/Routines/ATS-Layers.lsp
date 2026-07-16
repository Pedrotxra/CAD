;| Insere o layer
   @global
   @param layer [str] - Nome do layer
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

;| Altera o layer atual
   @global
   @param layer [str] - Nome do layer
   @returns [str] - Nome do layer, se encontrada
   |;
(DEFUN ATS:SetCurrentLayer (layer)
  (IF (ATS:InsertLayer layer)
    (SETVAR "CLAYER" layer)
  )
)

;| Mescla um layer em outra
   @global
   @param layersToMerge [str/lst] - Nome do layer ou lista de layers a serem mescladas
   @param targetLayer [str] - Nome do layer alvo
   @returns [nil] - Mescla os layers
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

;| Salva a configuração atual dos layers
   @global
   @returns [lst] - Lista de layers desligadas, congeladas e travadas, nesta ordem
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

;| Ativa todos os layers
   @global
   @returns [nil] - Salva a configuração anterior dos layers e as ativa
   |;
(DEFUN ATS:ActivateLayers ()
  (ATS:SaveDeactivaredLayers)
  (COMMAND-S "_.-LAYER" "_ON" "*" "_THAW" "*" "_UNLOCK" "*" "")
)

;| Restaura a configuração salva de layers
   @global
   @returns [nil] - Restaura a configuração salva dos layers
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

;| Altera o layer dos objetos selecionados, ou do layer atual
   @global
   @param layer [str] - Nome do layer
   @returns [nil] - Altera o layer dos objetos selecionados ou o layer atual
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

;| Trava os layers
   @global
   @param layersList [lst] - Lista de layers a travar
   @returns [nil] - Trava os layers
   |;
(DEFUN ATS:LockLayers (layersList)
  (IF (MEMBER (GETVAR "CLAYER") layersList)
    (SETVAR "CLAYER" "0")
  )
  (COMMAND-S "_.-LAYER" "_LOCK" (ATS:ListToString "," layersList) "")
)

;| Destrava os layers
   @global
   @param layersList [lst] - Lista de layers a destravar
   @returns [nil] - Destrava os layers
   |;
(DEFUN ATS:UnlockLayers (layersList)
  (COMMAND-S "_.-LAYER" "_UNLOCK" (ATS:ListToString "," layersList) "")
)

;| Isola os layers
   @global
   @param layersList [lst] - Lista de layers a isolar
   @returns [nil] - Isola os layers
   |;
(DEFUN ATS:IsolateLayers (layersList)
  (ATS:SaveDeactivaredLayers)
  (IF (NOT (MEMBER (GETVAR "CLAYER") layersList))
    (SETVAR "CLAYER" "0")
  )
  (COMMAND-S "_.-LAYER" "_LOCK" (STRCAT "~" (GETVAR "CLAYER")) "_UNLOCK" (ATS:ListToString "," layersList) "")
)

;| Define a ordem de visualização dos objetos de acordo com as suos layers ou nomes particulares de blocos
   @global
   @param layersDrawOrderList [lst] - Lista com nomes dos layers, da mais prioritária à menos, divididas em layers de anotação e layers de desenho, ou 'T' para configuração padrão
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
  ;; Traz os elementos dos layers de anotação
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
  ;; Traz os elementos dos layers restantes
  (FOREACH layerName (CADR layersDrawOrderList)
    (SETQ selection (ATS:TrimSelectionSets (SSGET "_A" (LIST (CONS 8 layerName) (CONS 410 (GETVAR "CTAB")))) blocksSelection))
    (IF selection
      (COMMAND-S "_.DRAWORDER" selection "" "_BACK")
    )
  )
  (COMMAND-S "_.REGENALL")
)

;| Organiza a ordem de visualização dos layers e blocos
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

;| Liga, descongela e destrava todos os layers e salva a configuração anterior
   @returns nil
   |;
(DEFUN C:LL ()
  (ATS:WriteLog "LL" nil)
  (ATS:ActivateLayers)
  (SETQ *extendedDeactivatedLayers* *deactivatedLayers*)
  (SETQ *deactivatedLayers* nil)
)

;| Restaura a configuração anterior dos layers
   @returns nil
   |;
(DEFUN C:RL (/ *deactivatedLayers*)
  (ATS:WriteLog "RL" nil)
  (COMMAND-S "_.-LAYER" "_ON" "*" "_THAW" "*" "_UNLOCK" "*" "")
  (SETQ *deactivatedLayers* *extendedDeactivatedLayers*)
  (ATS:RestoreLayers)
  (SETQ *extendedDeactivatedLayers* nil)
)

;| Trava os layers principais
   @returns nil
   |;
(DEFUN C:TL ()
  (ATS:WriteLog "TL" nil)
  (ATS:LockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *pen1* *pen2* *pen3* *pen4* *pen5* *pen6*))))
)

;| Destrava os layers principais
   @returns nil
   |;
(DEFUN C:DL ()
  (ATS:WriteLog "DL" nil)
  (ATS:UnlockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *pen1* *pen2* *pen3* *pen4* *pen5* *pen6*))))
)

;| Isola os layers principais
   @returns nil
   |;
(DEFUN C:IL ()
  (ATS:WriteLog "IL" nil)
  (ATS:IsolateLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *pen1* *pen2* *pen3* *pen4* *pen5* *pen6*))))
)

;| Trava os layers de simbologia
   @returns nil
   |;
(DEFUN C:TS ()
  (ATS:WriteLog "TS" nil)
  (ATS:LockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))
)

;| Destrava os layers de simbologia
   @returns nil
   |;
(DEFUN C:DS ()
  (ATS:WriteLog "DS" nil)
  (ATS:UnlockLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))
)

;| Isola os layers de simbologia
   @returns nil
   |;
(DEFUN C:IS ()
  (ATS:WriteLog "IS" nil)
  (ATS:IsolateLayers (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))
)

;| Travar o layer de cotas
   @returns nil
   |;
(DEFUN C:TC ()
  (ATS:WriteLog "TC" nil)
  (ATS:LockLayers (LIST (ATS:EvaluateStringSymbolList *dimensionLayer*)))
)

;| Destravar o layer de cotas
   @returns nil
   |;
(DEFUN C:DC ()
  (ATS:WriteLog "DC" nil)
  (ATS:UnlockLayers (LIST (ATS:EvaluateStringSymbolList *dimensionLayer*)))
)

;| Muda para o layer "0"
   @returns nil
   |;
(DEFUN C:0 ()
  (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
  (ATS:WriteLog "0" nil)
  (ATS:ChangeLayer "0")
)

(IF *pen1*
  ;| Muda para o layer da pena 1
     @returns nil
     |;
  (DEFUN C:1 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "1" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen1*))
  )
)

(IF *pen2*
  ;| Muda para o layer da pena 2
     @returns nil
     |;
  (DEFUN C:2 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "2" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen2*))
  )
)

(IF *pen3*
  ;| Muda para o layer da pena 3
     @returns nil
     |;
  (DEFUN C:3 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "3" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen3*))
  )
)

(IF *pen4*
  ;| Muda para o layer da pena 4
     @returns nil
     |;
  (DEFUN C:4 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "4" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen4*))
  )
)

(IF *pen5*
  ;| Muda para o layer da pena 5
     @returns nil
     |;
  (DEFUN C:5 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "5" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen5*))
  )
)

(IF *pen6*
  ;| Muda para o layer da pena 6
     @returns nil
     |;
  (DEFUN C:6 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "6" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *pen6*))
  )
)

(IF *symbolPen1*
  ;| Muda para o layer de simbologia da pena 1
     @returns nil
     |;
  (DEFUN C:S1 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "S1" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen1*))
  )
)

(IF *symbolPen2*
  ;| Muda para o layer de simbologia da pena 2
     @returns nil
     |;
  (DEFUN C:S2 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "S2" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen2*))
  )
)

(IF *symbolPen3*
  ;| Muda para o layer de simbologia da pena 3
     @returns nil
     |;
  (DEFUN C:S3 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "S3" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen3*))
  )
)

(IF *symbolPen4*
  ;| Muda para o layer de simbologia da pena 4
     @returns nil
     |;
  (DEFUN C:S4 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "S4" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen4*))
  )
)

(IF *symbolPen5*
  ;| Muda para o layer de simbologia da pena 5
     @returns nil
     |;
  (DEFUN C:S5 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "S5" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen5*))
  )
)

(IF *symbolPen6*
  ;| Muda para o layer de simbologia da pena 6
     @returns nil
     |;
  (DEFUN C:S6 ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "S6" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *symbolPen6*))
  )
)

(IF *projectionLayer*
  ;| Muda para o layer de projeção
     @returns nil
     |;
  (DEFUN C:PROJ ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "PROJ" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *projectionLayer*))
  )
)

(IF *sectionLayer*
  ;| Muda para o layer de corte
     @returns nil
     |;
  (DEFUN C:CRT ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "CRT" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *sectionLayer*))
  )
)

(IF *areaLayer*
  ;| Muda para o layer de área
     @returns nil
     |;
  (DEFUN C:AREAS ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "AREAS" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *areaLayer*))
  )
)

(IF *falseCeilingLayer*
  ;| Muda para o layer de forro
     @returns nil
     |;
  (DEFUN C:FOR ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "FOR" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *falseCeilingLayer*))
  )
)

(IF *architectureLayer*
  ;| Muda para o layer de arquitetura
     @returns nil
     |;
  (DEFUN C:ARQ ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "ARQ" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *architectureLayer*))
  )
)

(IF *structureLayer*
  ;| Muda para o layer de estrutural
     @returns nil
     |;
  (DEFUN C:EST ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "EST" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *structureLayer*))
  )
)

(IF *layoutLayer*
  ;| Muda para o layer de layout
     @returns nil
     |;
  (DEFUN C:LAY ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "LAY" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *layoutLayer*))
  )
)

(IF *electricalLayer*
  ;| Muda para o layer de elétrica
     @returns nil
     |;
  (DEFUN C:ELE ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "ELE" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *electricalLayer*))
  )
)

(IF *fireLayer*
  ;| Muda para o layer de incêndio
     @returns nil
     |;
  (DEFUN C:INC ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "INC" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *fireLayer*))
  )
)

(IF *plumbingLayer*
  ;| Muda para o layer de louças
     @returns nil
     |;
  (DEFUN C:HID ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "HID" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *plumbingLayer*))
  )
)

(IF *lightingLayer*
  ;| Muda para o layer de luminotécnico
     @returns nil
     |;
  (DEFUN C:LUM ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "LUM" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *lightingLayer*))
  )
)

(IF *trafficLayer*
  ;| Muda para o layer de tráfego
     @returns nil
     |;
  (DEFUN C:TRA ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "TRA" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *trafficLayer*))
  )
)

(IF *vegetationLayer*
  ;| Muda para o layer de vegetação
     @returns nil
     |;
  (DEFUN C:VEG ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "VEG" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *vegetationLayer*))
  )
)

(IF *siteLayer*
  ;| Muda para o layer de terreno
     @returns nil
     |;
  (DEFUN C:TER ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "TER" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *siteLayer*))
  )
)

(IF *constructionLayer*
  ;| Muda para o layer de construção
     @returns nil
     |;
  (DEFUN C:CONS ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "CONS" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *constructionLayer*))
  )
)

(IF *demolitionLayer*
  ;| Muda para o layer de demolição
     @returns nil
     |;
  (DEFUN C:DEM ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "DEM" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *demolitionLayer*))
  )
)

(IF *handrailLayer*
  (PROGN
    ;| Muda para o layer de corrimão
      @returns nil
      |;
    (DEFUN C:CORR ()
      (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
      (ATS:WriteLog "CORR" nil)
      (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *handrailLayer*))
    )
    ;| Alterna a cor do layer de corrimãos entre 10 e a padrão
      @returns nil
      |;
    (DEFUN C:CORRINC (/ layerName layer standardColor)
      (SETQ *iterationsCount* 1)
      (ATS:WriteLog "CORRINC" nil)
      (SETQ layerName (ATS:EvaluateStringSymbolList *handrailLayer*))
      (IF (SETQ layer (TBLOBJNAME "LAYER" layerName))
        (IF (EQ (ATS:GetPropertiesValues 62 layer) 10)
          (PROGN
            (SETQ standardColor (ATS:InsertLayer (ATS:EvaluateStringSymbolList *architectureLayer*)))
            (ATS:ChangePropertiesValues layer (LIST (CONS 62 (ATS:GetPropertiesValues 62 (TBLOBJNAME "LAYER" standardColor)))))
          )
          (ATS:ChangePropertiesValues layer (LIST (CONS 62 10)))
        )
        (PROMPT "\nLayer de corrimãos não encontrado.\n")
      )
    )
  )
)

(IF *draftLayer*
  ;| Muda para o layer de rascunho
     @returns nil
     |;
  (DEFUN C:RAS ()
    (SETQ *iterationsCount* (SSLENGTH (COND ((SSGET "_I")) ((SSADD)))))
    (ATS:WriteLog "RAS" nil)
    (ATS:ChangeLayer (ATS:EvaluateStringSymbolList *draftLayer*))
  )
)
