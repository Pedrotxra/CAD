;| Salva um objeto em uma lista para ser liberado posteriormente
   @global
   @param object [obj/ename]- Objeto ou nome da entidade
   @returns [obj] - Objeto salvo
   |;
(DEFUN ATS:SaveObject (object)
  (IF (EQ (TYPE object) (READ "ENAME"))
    (SETQ object (VLAX-ENAME->VLA-OBJECT object))
  )
  (IF (EQ (TYPE object) (READ "VLA-OBJECT"))
    (IF (NOT (MEMBER object *objectsToReleaseList*))
      (SETQ *objectsToReleaseList* (CONS object *objectsToReleaseList*))
    )
    (SETQ object nil)
  )
  object
)

;| Restaura as preferências salvas do usuário
   @global
   @returns [nil] - Restaura as preferências salvas do usuário
   |;
(DEFUN ATS:ResetPreferencesVariables ()
  (IF *currentView*
    (PROGN
      (IF (AND (EQ (GETVAR "BLOCKEDITOR") 0) (MEMBER *currentTab* (CONS "Model" (LAYOUTLIST))))
        (PROGN
          (SETVAR "CTAB" *currentTab*)
          (COMMAND-S "_.ZOOM" (CAR *currentView*) (CADR *currentView*))
        )
        (IF (AND (NOT *currentTab*) (EQ (GETVAR "BLOCKEDITOR") 1))
          (COMMAND-S "_.ZOOM" (CAR *currentView*) (CADR *currentView*))
        )
      )
      (SETQ *currentView* nil)
      (SETQ *currentTab* nil)
    )
  )
  (IF *deactivatedLayers*
    (PROGN
      (ATS:RestoreLayers)
      (SETQ *deactivatedLayers* nil)
    )
  )
  (IF *currentLayer*
    (PROGN
      (IF (TBLOBJNAME "LAYER" *currentLayer*)
        (SETVAR "CLAYER" *currentLayer*)
        (SETVAR "CLAYER" "0")
      )
      (SETQ *currentLayer* nil)
    )
  )
  (IF *currentOsnap*
    (PROGN
      (SETVAR "OSMODE" *currentOsnap*)
      (SETQ *currentOsnap* nil)
    )
  )
  (IF *currentUCS*
    (PROGN
      (VLA-PUT-ACTIVEUCS *activeDocument* *currentUCS*)
      (SETQ *currentUCS* nil)
    )
  )
)

;| Salva as preferências do usuário
   @global
   @param flags [int] - Máscara de bits para as preferências a serem salvas:
                        1 - UCS
                        2 - Pontos de referência
                        4 - Camada atual
                        8 - Configuração das camadas
                        16 - Visualização atual
   @returns [any] - Valor da última preferência salva
   |;
(DEFUN ATS:SaveUsersPreferences (flags)
  (SETVAR "CMDECHO" 0)
  (SETVAR "NOMUTT" 1)
  (SETQ *currentSelection* (SSGET "_I"))
  (ATS:ResetPreferencesVariables)
  ;; Define um ponto de retorno
  (IF *fullyUndo*
    (COMMAND-S "_.UNDO" "_BEGIN")
  )
  (IF (AND (EQ (TYPE flags) (READ "INT")) (> flags 0))
    (PROGN
      ;; Armazena o UCS atual
      (IF (NOT (ZEROP (LOGAND flags 1)))
        (IF (AND (EQ (GETVAR "BLOCKEDITOR") 0) (NOT (GETVAR "REFEDITNAME")))
          (PROGN
            (SETQ *currentUCS* (ATS:SaveObject (VLA-ADD (VLA-GET-USERCOORDINATESYSTEMS *activeDocument*)
                                                       (VLAX-3D-POINT (TRANS (LIST 0 0 0) 1 0))
                                                       (VLAX-3D-POINT (TRANS (LIST 1 0 0) 1 0))
                                                       (VLAX-3D-POINT (TRANS (LIST 0 1 0) 1 0))
                                                       "SAVEDUCS")))
            (COMMAND-S "_.UCS" "_WORLD")
          )
        )
      )
      ;; Armazena os pontos de referência atuais
      (IF (NOT (ZEROP (LOGAND flags 2)))
        (PROGN
          (SETQ *currentOsnap* (GETVAR "OSMODE"))
          (SETVAR "OSMODE" 16384)
        )
      )
      ;; Armazena a camada atual
      (IF (NOT (ZEROP (LOGAND flags 4)))
        (PROGN
          (SETQ *currentLayer* (GETVAR "CLAYER"))
          (SETVAR "CLAYER" "0")
        )
      )
      ;; Armazena as camadas inativas
      (IF (NOT (ZEROP (LOGAND flags 8)))
        (ATS:ActivateLayers)
      )
      ;; Armazena a visualização atual
      (IF (NOT (ZEROP (LOGAND flags 16)))
        (PROGN
          (SETQ *currentTab* (GETVAR "CTAB"))
          (SETQ *currentView* (ATS:GetViewExtents))
        )
      )
    )
  )
)

;| Restaura as preferências do usuário
   @global
   @param commandName [str] - Nome do comando a ser registrado no log
   @param errorMessage [str] - Mensagem de erro, ou 'nil' para não registrar no log
   @returns [nil] - Restaura as preferências do usuário
   |;
(DEFUN ATS:RestoreUsersPreferences (commandName errorMessage)
  (ATS:ResetPreferencesVariables)
  (SETQ *currentSelection* nil)
  (FOREACH object *objectsToReleaseList*
    (IF (EQ (TYPE object) (READ "VLA-OBJECT"))
      (VLAX-RELEASE-OBJECT object)
    )
  )
  (SETQ *objectsToReleaseList* nil)
  (ATS:ClearBoundaries)
  (IF commandName
    (ATS:WriteLog commandName errorMessage)
  )
  (COMMAND-S "_.UNDO" "_END")
  (IF errorMessage
    (PROGN
      (IF *automaticallyUndo*
        (COMMAND-S "_.UNDO" 1)
      )
      (SETVAR "NOMUTT" 0)
      (SETVAR "CMDECHO" 1)
      (PRINC)
      (PROMPT (STRCAT "\n" errorMessage "\n"))
    )
    (PROGN
      (SETVAR "NOMUTT" 0)
      (SETVAR "CMDECHO" 1)
    )
  )
  (PRINC)
)

;| Verifica se a entidade é anotativa
   @global
   @param entityName [ename] - Nome da entidade
   @returns [bool] - 'T' se a entidade for anotativa
   |;
(DEFUN ATS:IsAnnotative (entityName)
  (AND (SETQ entityName (CADR (ASSOC -3 (ENTGET entityName (LIST "AcadAnnotative")))))
       (EQ (CDR (NTH 4 entityName)) 1))
)

;| Limpa e audita o arquivo
   @global
   @returns [nil] - Limpa e audita o arquivo
   |;
(DEFUN ATS:CleanFile ()
  (COMMAND-S "_.-SCALELISTEDIT" "_DELETE" "*" "_EXIT")
  (REPEAT 5 (COMMAND-S "_.-PURGE" "_ALL" "*" "_NO"))
  (COMMAND-S "_.AUDIT" "_YES")
)

;| Altera padrões em todos os espaços com base na inserção de um bloco
   @global
   @param blockName [str] - Nome do bloco a ser inserido
   @returns [nil] - Altera os padrões do arquivo
   |;
(DEFUN ATS:ChangeStandardsByBlockInsertion (blockName / fileDirectory layoutsNames selection files)
  (ATS:SetSystemVariables T nil) ; Reseta as configurações para os padrões do CAD
  (SETQ fileDirectory (GETVAR "DWGPREFIX"))
  (SETQ layoutsNames (CONS "Model" (LAYOUTLIST)))
  (FOREACH layout layoutsNames
    (COMMAND-S "_.-LAYOUT" "_SET" layout)
    (ATS:RemoveDots nil)
    (IF (SETQ selection (SSGET "_A" (LIST (CONS 0 "*DIMENSION"))))
      (COMMAND-S "_.DIMDISASSOCIATE" selection "")
    )
    (IF (SETQ selection (SSGET "_A" (LIST (CONS 410 layout) (CONS -4 "<NOT") (CONS 69 1) (CONS -4 "NOT>"))))
      (PROGN
        (SSSETFIRST nil selection)
        (SETQ layout (ATS:NameFileUniquely nil *duplicateAffix* (STRCAT fileDirectory (ATS:FixFileName nil layout) ".dwg")))
        (COMMAND-S "_.-WBLOCK" layout "0,0")
        (SETQ files (CONS layout files))
      )
    )
  )
  (ATS:CleanFile)
  (COMMAND "_.-INSERT" blockName ^C^C)
  (SETQ files (REVERSE files))
  (FOREACH file files
    (COMMAND-S "_.-LAYOUT" "_SET" (NTH (VL-POSITION file files) layoutsNames))
    (COMMAND "_.-INSERT" file "0,0,0" (WHILE (> (GETVAR "CMDACTIVE") 0) (COMMAND "")))
    (COMMAND-S "_.EXPLODE" (ENTLAST))
    (VL-FILE-DELETE file)
  )
  (ATS:SetSystemVariables nil *systemVariables*)
  (ATS:CleanFile)
)

;| Desanexa referências externas
   @global
   @returns [nil] - Desanexa as referências externas
   |;
(DEFUN ATS:DetachExternalReferences ()
  (COMMAND-S "_.-XREF" "_DETACH" "*")
  (COMMAND-S "_.-IMAGE" "_DETACH" "*")
)

;| Limpa fontes ausentes
   @global
   @returns [obj] - Objeto da última fonte iterada
   |;
(DEFUN ATS:PurgeMissingFonts (/ fontName)
  (VLAX-FOR fontFile (ATS:SaveObject (VLA-GET-TEXTSTYLES *activeDocument*))
    (IF (NOT (VL-FILENAME-EXTENSION (SETQ fontName (VLA-GET-FONTFILE fontFile))))
      (SETQ fontName (STRCAT fontName ".shx"))
    )
    (COND
      ((FINDFILE fontName))
      ((FINDFILE (STRCAT (GETENV "WINDIR") "\\FONTS\\" fontName)))
      (T
       (VLA-PUT-FONTFILE fontFile *standardTextFont*)
       (PROMPT (STRCAT "\n" fontName " alterado para " *standardTextFont* "\n"))
      )
    )
    (ATS:SaveObject fontFile)
  )
)

;| Aplica o fator de escala a objetos selecionados, ou altera as variáveis do sistema para aplicarem o fator de escala atual
   @global
   @param selection [ss] - Seleção, ou 'nil' para aplicar nas variáveis do sistema
   @param scaleFactor [str/real] - Fator de escala
   @returns [nil] - Aplica o fator de escala
   |;
(DEFUN ATS:ApplyScaleFactor (selection scaleFactor / count entityName object entityProperties dynamicBlockPropertiesList titlesHeight secondaryTextsHeight textHeight)
  (IF (NOT (EQ (GETVAR "CVPORT") 1)) ; Verifica se não está na aba layout sem viewport aberta
    (IF (EQ (TYPE scaleFactor) (READ "STR")) ; Verifica se usa o padrão anotativo
      (IF selection
        (PROGN
          (SETQ count (SSLENGTH selection))
          (REPEAT count
            (SETQ count (1- count))
            (SETQ entityName (SSNAME selection count))
            ;; Trata bloco de título para ajustar o conteúdo da escala
            (IF (EQ (ATS:GetEffectiveName (ATS:SaveObject entityName)) (ATS:GetPropertiesValues "Name" *titleBlockList*))
              (PROGN
                (SETQ object (ATS:GetPropertiesValues "AdjustTitle" *titleBlockList*))
                (APPLY (FUNCTION dynamicBlockPropertiesList) (LIST entityName))
              )
            )
            ;; Obtém as escalas anotativas
            (SETQ entityProperties (APPEND (ATS:GetEntityScalesList entityName) entityProperties))
            ;; Obtém as propriedades dinâmicas
            (SETQ dynamicBlockPropertiesList (CONS (CONS object (ATS:GetDynamicBlockProperties T nil object nil)) dynamicBlockPropertiesList))
          )
          (ATS:AddAnnotativeScale selection scaleFactor)
          (COMMAND "_.-OBJECTSCALE" selection "" "_DELETE")
          (FOREACH scale (ATS:RemoveDuplicates (VL-REMOVE scaleFactor entityProperties))
            (COMMAND scale)
          )
          (COMMAND "")
          (FOREACH dynamicBlockProperty (VL-REMOVE-IF (FUNCTION (LAMBDA (object) (EQ (LENGTH object) 1))) dynamicBlockPropertiesList)
            (ATS:ChangeDynamicBlockPropertiesValues nil (CAR dynamicBlockProperty) (CDR dynamicBlockProperty))
          )
        )
        (PROGN
          ;; Adiciona a escala à lista de escalas
          (ATS:AddAnnotativeScale nil scaleFactor)
          (SETVAR "CANNOSCALE" scaleFactor)
        )
      )
      (PROGN
        (SETQ textHeight (* *primaryTextsHeight* scaleFactor))
        (IF selection
          (PROGN
            (SETQ titlesHeight (* *titlesHeight* scaleFactor))
            (SETQ secondaryTextsHeight (* *secondaryTextsHeight* scaleFactor))
            (SETQ count (SSLENGTH selection))
            (REPEAT count
              (SETQ count (1- count))
              (SETQ entityName (SSNAME selection count))
              (SETQ entityProperties (ATS:GetPropertiesValues 0 entityName))
              (COND
                ((ATS:IsAnnotative entityName))
                ((EQ entityProperties "INSERT")
                  (SETQ object (ATS:SaveObject entityName))
                  ;; Trata bloco de título para ajustar o conteúdo da escala
                  (IF (OR (AND (EQ (ATS:GetEffectiveName object) (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Name" *titleBlockList*)))
                               (SETQ dynamicBlockPropertiesList (ATS:GetPropertiesValues "AdjustTitle" *titleBlockList*))
                               (APPLY (FUNCTION dynamicBlockPropertiesList) (LIST entityName)))
                          (EQ (ATS:GetEffectiveName object) (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Name" *breakLineBlockList*)))
                          (WCMATCH (ATS:GetPropertiesValues 8 entityName) (ATS:ListToString "," (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (VL-REMOVE nil (LIST *symbolPen1* *symbolPen2* *symbolPen3* *symbolPen4* *symbolPen5* *symbolPen6*))))))
                    (PROGN
                      (SETQ dynamicBlockPropertiesList (ATS:GetDynamicBlockProperties T nil object nil))
                      (COMMAND-S "_.SCALE" entityName "" (ATS:GetPropertiesValues 10 entityName) (/ scaleFactor (ATS:GetPropertiesValues 41 entityName)))
                      (ATS:ChangeDynamicBlockPropertiesValues nil object dynamicBlockPropertiesList))))
                ((EQ entityProperties "MULTILEADER")
                  (VLA-PUT-SCALEFACTOR (ATS:SaveObject entityName) scaleFactor))
                ((WCMATCH entityProperties "*TEXT")
                  (SETQ entityProperties (ATS:GetPropertiesValues 8 entityName))
                  (ATS:ChangePropertiesValues entityName (LIST (CONS 40 (COND
                                                                          ((EQ entityProperties (ATS:EvaluateStringSymbolList *titlesLayer*)) titlesHeight)
                                                                          ((EQ entityProperties (ATS:EvaluateStringSymbolList *secondaryTextsLayer*)) secondaryTextsHeight)
                                                                          (textHeight))))))
                ((WCMATCH entityProperties "*DIMENSION")
                  (VLA-PUT-SCALEFACTOR (ATS:SaveObject entityName) scaleFactor))
                ((EQ entityProperties "HATCH")
                  (COND
                    ;; Filtra hachuras não sólidas e procura seu padrão na lista de hachuras
                    ((EQ (SETQ entityProperties (ATS:GetPropertiesValues 2 entityName)) "SOLID"))
                    ((SETQ entityProperties (VL-SOME (FUNCTION (LAMBDA (hatchList)
                                                                  (IF (AND (EQ entityProperties (ATS:GetPropertiesValues "Pattern" hatchList)) ; pode haver redundâncias para hachuras com o mesmo padrão
                                                                          (NOT (EQ (TYPE (ATS:GetPropertiesValues "PresetScale" hatchList)) (READ "REAL")))) ; quando 'presetScale' é um número decimal, a hachura não deve ser influenciada pela escala do desenho
                                                                    hatchList))) (MAPCAR (FUNCTION (LAMBDA (hatchList) (EVAL (CDR hatchList)))) *hatchesList*)))
                      (COMMAND-S "_.-HATCHEDIT" entityName "_PROPERTIES" "" (* (ATS:GetPropertiesValues "Scale" entityProperties) scaleFactor) "")))))))
          (PROGN
            (SETVAR "TEXTSIZE" textHeight)
            (SETVAR "DIMSCALE" scaleFactor)
            (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "MLEADERSCALE" scaleFactor))
            (SETVAR "REVCLOUDMAXARCLENGTH" (* 1.0 scaleFactor))
            (SETVAR "REVCLOUDMINARCLENGTH" (* 2.0 scaleFactor))
          )
        )
      )
    )
  )
)

;| Define variáveis do sistema
   @global
   @param nativeStandards [bool] - Indica se as normas nativas devem ser aplicadas
   @param systemVariables [lst] - Lista de variáveis do sistema a serem definidas
   @returns [nil] - Define as variáveis do sistema
   |;
(DEFUN ATS:SetSystemVariables (nativeStandards systemVariables)
  (ATS:DeleteEmptyLayouts)
  (FOREACH systemVariable systemVariables
    (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (MAPCAR (FUNCTION EVAL) systemVariable))
  )
  (IF nativeStandards
    (PROGN
      (SETVAR "CLAYER" "0")
      (IF (EQ (GETVAR "BLOCKEDITOR") 0)
        (SETVAR "CTAB" "Model")
      )
      (IF (ATS:CheckAnnotativeScale "1:1")
        (SETVAR "CANNOSCALE" "1:1")
      )
      (SETVAR "CMLSTYLE" "Standard")
      (SETVAR "TEXTSTYLE" "Standard")
      (SETVAR "TEXTSIZE" 2.5)
      (IF (TBLOBJNAME "DIMSTYLE" "Standard")
        (COMMAND-S "_.-DIMSTYLE" "_RESTORE" "Standard")
      )
      (SETVAR "DIMLAYER" "use current")
      (SETVAR "DIMSCALE" 1)
      (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "CMLEADERSTYLE" "Standard"))
      (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "MLEADERLAYER" "use current"))
      (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "MLEADERSCALE" 1))
      (SETVAR "CTABLESTYLE" "Standard")
      (SETVAR "REVCLOUDMAXARCLENGTH" 0.5)
      (SETVAR "REVCLOUDMINARCLENGTH" 0.5)
      (VLAX-FOR space (ATS:SaveObject (VLA-GET-LAYOUTS *activeDocument*))
        (ATS:SaveObject space)
        (VLA-PUT-STYLESHEET space "")
      )
    )
    (PROGN
      (IF (AND (EQ (GETVAR "CTAB") "Model") (ATS:CheckAnnotativeScale *standardAnnotationScale*))
        (SETVAR "CANNOSCALE" *standardAnnotationScale*)
      )
      (IF (AND *standardTextStyle* (TBLOBJNAME "STYLE" *standardTextStyle*))
        (SETVAR "TEXTSTYLE" *standardTextStyle*)
      )
      (IF (AND *standardDimensionStyle* (TBLOBJNAME "DIMSTYLE" *standardDimensionStyle*))
        (COMMAND-S "_.-DIMSTYLE" "_RESTORE" *standardDimensionStyle*)
      )
      (IF (AND *dimensionLayer* (TBLOBJNAME "LAYER" (ATS:EvaluateStringSymbolList *dimensionLayer*)))
        (SETVAR "DIMLAYER" (ATS:EvaluateStringSymbolList *dimensionLayer*))
      )
      (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "CMLEADERSTYLE" *standardLeaderStyle*))
      (IF (AND *standardLeaderLayer* (TBLOBJNAME "LAYER" (ATS:EvaluateStringSymbolList *standardLeaderLayer*)))
        (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "MLEADERLAYER" (ATS:EvaluateStringSymbolList *standardLeaderLayer*))) ; adição recente ao CAD
      )
      (VL-CATCH-ALL-APPLY (FUNCTION SETVAR) (LIST "CTABLESTYLE" *standardTableStyle*))
      (ATS:ApplyScaleFactor nil *scaleFactor*)
      (VLAX-FOR space (ATS:SaveObject (VLA-GET-LAYOUTS *activeDocument*))
        (ATS:SaveObject space)
        (VLA-PUT-STYLESHEET space (IF (EQ (VLA-GET-NAME space) "Model") "" *standardPlotStyle*))
      )
    )
  )
)

;| Obtém o nome efetivo de um bloco
   @global
   @param object [obj] - Objeto do bloco
   @returns [str] - Nome efetivo do bloco
   |;
(DEFUN ATS:GetEffectiveName (object)
  (COND
    ((VLAX-PROPERTY-AVAILABLE-P object "EffectiveName") (VLAX-GET-PROPERTY object "EffectiveName"))
    ((VLAX-PROPERTY-AVAILABLE-P object "Name") (VLAX-GET-PROPERTY object "Name"))
  )
)

;| Obtém o contorno de um objeto
   @global
   @param object [obj] - Objeto
   @returns [lst] - Lista com os pontos mínimo e máximo
   |;
(DEFUN ATS:GetObjectBoundaries (object / minPoint maxPoint)
  (IF (VLAX-METHOD-APPLICABLE-P object "GETBOUNDINGBOX")
    (PROGN
      (VLA-GETBOUNDINGBOX object (QUOTE minPoint) (QUOTE maxPoint))
      (LIST (VLAX-SAFEARRAY->LIST minPoint) (VLAX-SAFEARRAY->LIST maxPoint))
    )
  )
)

;| Obtém o fator de escala de inserção atual
   @global
   @returns [int] - Fator de escala de inserção atual
   |;
(DEFUN ATS:GetInsertionScale ()
  (IF (EQ (GETVAR "CTAB") "Model")
    (IF (EQ (TYPE *scaleFactor*) (READ "STR"))
      1
      *scaleFactor*
    )
    *paperUnitsFactor*
  )
)

;| Obtém uma lista de escalas de anotação de uma entidade
   @global
   @param entityName [ename/lst] - Nome da entidade ou entidade
   @returns [lst] - Lista de escalas de anotação da entidade
   |;
(DEFUN ATS:GetEntityScalesList (entityName / entity dictionary annotationList scalesList)
  ;; Obtém a entidade depois de atualizá-la no banco de dados
  (IF (LISTP entityName)
    (PROGN
      (SETQ entity entityName)
      (IF (SETQ entityName (CDR (ASSOC -1 entity)))
        (PROGN
          (ENTUPD entityName)
          (SETQ entity (ENTGET entityName))
        )
      )
    )
    (PROGN
      (ENTUPD entityName)
      (SETQ entity (ENTGET entityName))
    )
  )
  (COND
    ((NOT (SETQ dictionary (CDR (ASSOC 360 (MEMBER (CONS 102 "{ACAD_XDICTIONARY") entity))))))
    ((NOT (SETQ dictionary (DICTSEARCH dictionary "ACDBCONTEXTDATAMANAGER"))))
    ((SETQ dictionary (DICTSEARCH (CDR (ASSOC -1 dictionary)) "ACDB_ANNOTATIONSCALES"))
     (IF (EQ (TYPE dictionary) (READ "ENAME"))
       (SETQ dictionary (ENTGET dictionary))
     )
     (WHILE (SETQ dictionary (VL-MEMBER-IF (FUNCTION (LAMBDA (property-value) (EQ (CAR property-value) 3))) (CDR dictionary)))
       (SETQ annotationList (CONS (CONS (CDAR dictionary) (CDADR dictionary)) annotationList))
     )
     (FOREACH annotation annotationList
       (SETQ scalesList (CONS (CDR (ASSOC 300 (ENTGET (CDR (ASSOC 340 (ENTGET (CDR annotation))))))) scalesList))
     )
    )
  )
  scalesList
)

;| Verifica a existência de uma escala anotativa
   @global
   @param scaleFactor [str] - Fator de escala
   @returns [str] - Fator de escala, se encontrado
   |;
(DEFUN ATS:CheckAnnotativeScale (scaleFactor / annotativeScales count)
  (SETQ annotativeScales (ATS:SaveObject (CDAR (DICTSEARCH (NAMEDOBJDICT) "ACAD_SCALELIST"))))
  (SETQ count (VLA-GET-COUNT annotativeScales))
  ; Verifica as escalas anotativas existentes e adiciona a nova escala se não existir
  (WHILE (AND (>= (SETQ count (1- count)) 0) (NOT (EQ scaleFactor (CDR (ASSOC 300 (ENTGET (VLAX-VLA-OBJECT->ENAME (ATS:SaveObject (VLAX-INVOKE-METHOD annotativeScales "ITEM" count))))))))))
  (IF (>= count 0)
    scaleFactor
  )
)

;| Adiciona uma nova escala anotativa a uma seleção ou ao desenho
   @global
   @param selection [ss] - Seleção ou 'nil' para adicionar ao desenho
   @param scaleFactor [str] - Fator de escala
   @returns [nil] - Adiciona a nova escala à entidade ou ao desenho
   |;
(DEFUN ATS:AddAnnotativeScale (selection scaleFactor / count entityName newSelection)
  (IF (NOT (ATS:CheckAnnotativeScale scaleFactor))
    (COMMAND-S "_.-SCALELISTEDIT" "_ADD" scaleFactor scaleFactor "_EXIT")
  )
  (IF selection
    (PROGN
      (SETQ newSelection (SSADD))
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityName (SSNAME selection count))
        (IF (ATS:IsAnnotative entityName)
          (SSADD entityName newSelection)
        )
      )
      (IF (ATS:VerifySelectionSets newSelection)
        (COMMAND-S "_.-OBJECTSCALE" newSelection "" "_ADD" scaleFactor "")
      )
    )
  )
)

;| Retorna as propriedades de cada item uma tabela
   @global
   @param wildcardMatch [bool] 'T' para usar correspondência de caracteres curinga
   @param tableName [str] - Nome da tabela. Exemplo: "LAYER", "BLOCK", etc.
   @param indexesList [int/lst] - Índice ou lista de índices das propriedades a serem obtidas
   @param property-valueList [lst] - Lista de propriedade-valor a ser verificada, ou 'nil' para retornar todos os itens da tabela
   @returns [lst] - Lista com as propriedades de cada item da tabela
   |;
(DEFUN ATS:GetTableProperties (wildcardMatch tableName indexesList property-valueList / entity tableList)
  (IF (SETQ entity (TBLNEXT tableName T))
    (PROGN
      (IF (IF property-valueList
            (ATS:CheckPropertiesValuesMatches wildcardMatch entity property-valueList)
            T)
        (SETQ tableList (LIST (ATS:GetPropertiesValues indexesList entity)))
      )
      (WHILE (SETQ entity (TBLNEXT tableName))
        (IF (IF property-valueList
              (ATS:CheckPropertiesValuesMatches wildcardMatch entity property-valueList)
              T)
          (SETQ tableList (CONS (IF indexesList (ATS:GetPropertiesValues indexesList entity) entity) tableList))
        )
      )
      (SETQ tableList (VL-REMOVE nil tableList))
    )
  )
)

;| Verifica a existência de um item em uma tabela
   @global
   @param wildcardMatch [bool] - Indica se a busca deve considerar curingas
   @param tableName [str] - Nome da tabela a ser verificada
   @param property-valueList [lst] - Lista de propriedade-valor a ser verificada
   @returns [lst] - Entidade da tabela
   |;
(DEFUN ATS:CheckExistenceInTable (wildcardMatch tableName property-valueList / tableEntity)
  (SETQ tableEntity (TBLNEXT tableName T))
  (WHILE (AND tableEntity (NOT (ATS:CheckPropertiesValuesMatches wildcardMatch tableEntity property-valueList)))
    (SETQ tableEntity (TBLNEXT tableName))
  )
  tableEntity
)

;| Gera um nome único para uma tabela adicionando um afixo
   @global
   @param tableName [str] - Nome da tabela, como "LAYER", "BLOCK", etc.
   @param affix [str/int] - Afixo a ser adicionado. Caso seja um número, o novo nome será ele +1
   @param name [str] - Nome ao qual o afixo será adicionado
   @returns [str] - Nome com o afixo adicionado
   |;
(DEFUN ATS:NameTableUniquely (tableName affix name / affixNumber newAffix)
  (IF (TBLOBJNAME tableName name)
    (ATS:NameTableUniquely tableName affix (ATS:AffixName *affixSeparator* nil affix name))
    name
  )
)

;| Adiciona um afixo aos elementos de uma tabela
   @global
   @param tableName [str] - Nome da tabela, como "LAYER", "BLOCK", etc.
   @param affixPosition [bool] - 'T' para prefixo, ou 'nil' para sufixo
   @param affix [str/int] - Afixo a ser adicionado. Caso seja um número, o novo nome será ele +1
   @param namesList [lst] - Lista com os nomes a serem renomeados, ou 'nil' para aplicar para toda a tabela
   @returns [nil] - Renomeia os elementos na tabela
   |;
(DEFUN ATS:AddTableAffix (tableName affixPosition affix namesList / integerAffix name)
  ;; Se 'namesList' não for fornecida, obtém todos os nomes da tabela
  (IF (NOT namesList)
    (SETQ namesList (ATS:GetTableProperties nil tableName 2 nil))
  )
  ;; Remove nomes padrão que não devem ser alterados
  (COND
    ((EQ tableName "LAYER")
      (SETQ namesList (VL-REMOVE "0" (VL-REMOVE "Defpoints" namesList)))
    )
    ((EQ tableName "BLOCK")
      (SETQ namesList (VL-REMOVE "_Dot" (VL-REMOVE "_DOTSMALL" namesList)))
    )
  )
  ;; Se o afixo for um inteiro, seu acréscimo único será somando 1
  (IF (EQ (TYPE affix) (READ "INT"))
    (PROGN
      (SETQ integerAffix affix)
      (SETQ affix (ITOA affix))
    )
  )
  ;; Altera o nome do item na tabela
  (FOREACH name namesList
    (COMMAND-S "_.-RENAME" (STRCAT "_" tableName) name (ATS:NameTableUniquely tableName (COND (integerAffix) (*duplicateAffix*)) (IF affixPosition (STRCAT affix *affixSeparator* name) (STRCAT name *affixSeparator* affix))))
  )
)

;| Altera o afixo dos elementos de uma tabela
   @global
   @param tableName [str] - Nome da tabela, como "LAYER", "BLOCK", etc.
   @param affixPosition [bool] - 'T' para prefixo, ou 'nil' para sufixo
   @param oldAffix [str] - Afixo a ser substituído
   @param newAffix [str] - Afixo a substituir
   @param namesList [lst] - Lista com os nomes a serem renomeados, ou 'nil' para aplicar para toda a tabela
   @returns [nil] - Renomeia os elementos na tabela
   |;
(DEFUN ATS:ChangeTableAffix (tableName affixPosition oldAffix newAffix namesList / name)
  (IF (NOT namesList)
    (SETQ namesList (ATS:GetTableProperties nil tableName 2 nil))
  )
  (FOREACH name namesList
    (IF (WCMATCH name (IF affixPosition (STRCAT oldAffix "*") (STRCAT "*" oldAffix)))
      (COMMAND-S "_.-RENAME" (STRCAT "_" tableName) name (ATS:NameTableUniquely tableName *duplicateAffix* (VL-STRING-SUBST newAffix oldAffix name)))
    )
  )
)

;| Obtém dados de uma entidade selecionada pelo usuário e armazena como variável global
   @global
   @param nestedEntity [bool] - Se a entidade selecionada será aninhada
   @returns [lst] - Entidade selecionada, mais as propriedades e métodos de seu objeto
   |;
(DEFUN ATS:SelectEntity (nestedEntity)
  (IF (AND (EQ (TYPE *object*) (READ "VLA-OBJECT")) (NOT (VLAX-OBJECT-RELEASED-P *object*)))
    (VLAX-RELEASE-OBJECT *object*)
  )
  (IF (SETQ *entityName* (IF nestedEntity (NENTSEL) (ENTSEL)))
    (PROGN
      (SETQ *entityName* (CAR *entityName*))
      (ENTUPD *entityName*)
      (SETQ *object* (VLAX-ENAME->VLA-OBJECT *entityName*))
      (VLAX-DUMP-OBJECT *object* T)
      (SETQ *entity* (ENTGET *entityName*))
    )
    (PROGN
      (SETQ *object* nil)
      (SETQ *entity* nil)
    )
  )
)

;| Obtém dados de uma entidade selecionada pelo usuário
   @returns nil
   |;
(DEFUN C:ENT ()
  (ATS:WriteLog "ENT" nil)
  (ATS:SelectEntity nil)
)

;| Obtém dados de uma entidade aninhada selecionada pelo usuário
   @returns nil
   |;
(DEFUN C:NENT ()
  (ATS:WriteLog "NENT" nil)
  (ATS:SelectEntity T)
)

;| Compara os grupos DXF de *entity* com outra entidade selecionada pelo usuário
   @returns nil
   |;
(DEFUN C:CENT (/ entityName)
  (ATS:WriteLog "CENT" nil)
  (SETQ entityName (CAR (ENTSEL)))
  (IF entityName
    (PROGN
      (ENTUPD entityName)
      (ATS:IsolateDifferences (LIST *entity* (ENTGET entityName)))
    )
  )
)

;| Recarrega todos os scripts
   @returns nil
   |;
(DEFUN C:RELOAD (/ *error* commandName preset presetVariables)
  (SETQ commandName "RELOAD")
  ;; Solicita ao usuário o preset
  (SETQ preset (VL-DIRECTORY-FILES (ATS:EvaluateStringSymbolList *presetsFolder*) "*.lsp" 1))
  (IF (> (LENGTH preset) 1)
    (PROGN
      (SETQ preset (MAPCAR (FUNCTION VL-FILENAME-BASE) preset))
      (SETQ preset (ATS:GetKeyword *preset* preset "\nSelecione o preset:\n"))
      ;; Verifica a necessidade de fazer a conversão completa
      (IF (AND (NOT (EQ *preset* preset)) (EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nVocê está trocando de preset. Deseja fazer uma conversão completa? Prossiga apenas se conhecer a funcionalidade!\n") "Sim"))
        (SETQ presetVariables (ATS:SavePresetVariables nil))
      )
    )
    (SETQ preset "Autots")
  )
  (ATS:SaveUsersPreferences 12)
  (DEFUN *error* (errorMessage)
    (ATS:RestoreUsersPreferences commandName errorMessage)
  )
  ;; Carrega as rotinas
  (IF (VL-CATCH-ALL-ERROR-P (VL-CATCH-ALL-APPLY (FUNCTION LOAD) (LIST (STRCAT (ATS:EvaluateStringSymbolList *scriptsFolder*) *scriptsMain*))))
    (PROGN
      (SETQ *failedLoads* (CONS *scriptsMain* *failedLoads*))
      (ALERT (STRCAT "Erro ao carregar: " *scriptsMain*))
    )
    (ATS:LoadScripts preset)
  )
  ;; Aplica a conversão completa
  (IF presetVariables
    (ATS:ApplyPresetVariablesChanges presetVariables)
  )
  (ATS:RestoreUsersPreferences commandName nil)
  (IF (NOT *failedLoads*)
    (PROMPT "\nTodas as rotinas foram carregadas com sucesso.\n")
  )
)

;| Define um novo fator de escala, ou apenas o aplica a viewport atual ou aos objetos de anotação selecionados
   @returns nil
   |;
(DEFUN C:ESC (/ *error* commandName scaleDenominator)
  (SETQ commandName "ESC")
  (IF (NOT (EQ (GETVAR "CVPORT") 1)) ; Verifica se não está na aba layout sem viewport aberta
    (PROGN
      ;; Solicita a escala desejada
      (IF (EQ (TYPE *scaleFactor*) (READ "STR")) ; Verifica se usa o padrão anotativo
        (PROGN
          ;; Solicita a escala desejada
          (SETQ scaleDenominator (SUBSTR *scaleFactor* (+ (VL-STRING-POSITION 58 *scaleFactor*) 2)))
          (SETQ scaleDenominator (ITOA (COND ((PROGN (INITGET 4) (GETINT (STRCAT "\nInsira o denominador de escala, ou 0 para escala padrão: <" scaleDenominator ">\n")))) ((ATOI scaleDenominator)))))
        )
        (PROGN
          (SETQ scaleDenominator (RTOS (* *paperUnitsFactor* *scaleFactor*)))
          (SETQ scaleDenominator (COND ((PROGN (INITGET 6) (GETINT (STRCAT "\nInsira o denominador de escala: <" scaleDenominator ">\n")))) ((ATOI scaleDenominator))))
        )
      )
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (IF (EQ (TYPE *scaleFactor*) (READ "STR")) ; Verifica se usa o padrão anotativo
        (SETQ *scaleFactor* (IF (EQ scaleDenominator "0") "1:1" (STRCAT (RTOS *paperUnitsFactor*) ":" scaleDenominator)))
        (SETQ *scaleFactor* (/ scaleDenominator *paperUnitsFactor*))
      )
      (ATS:ApplyScaleFactor *currentSelection* *scaleFactor*)
      (IF (NOT (OR *currentSelection* (EQ (GETVAR "CTAB") "Model"))) ; Verifica se está sem seleção em uma viewport aberta
        (IF (EQ (TYPE *scaleFactor*) (READ "STR")) ; Verifica se usa o padrão anotativo
          (COMMAND-S "_.ZOOM" "_SCALE" (STRCAT (VL-STRING-SUBST "/" ":" *scaleFactor*) "XP"))
          (PROGN
            ;; Adiciona a escala à lista de escalas
            (ATS:AddAnnotativeScale nil (STRCAT (RTOS *paperUnitsFactor*) ":" (ITOA scaleDenominator)))
            (COMMAND-S "_.ZOOM" "_SCALE" (STRCAT (RTOS (/ 1.0 *scaleFactor*)) "XP"))
          )
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
    (PROMPT "\nO comando não pode ser executado na aba layout.\n")
  )
)

;| Limpa e audita o arquivo
   @returns nil
   |;
(DEFUN C:LIMPA ()
  (ATS:WriteLog "LIMPA" nil)
  (ATS:RemoveDots nil)
  (ATS:CleanFile)
)

;| Conserta padrões em layouts e blocos
   @returns nil
   |;
(DEFUN C:CONSERTAPADROES (/ *error* commandName FixSpace)
  (SETQ commandName "CONSERTAPADROES")
  (COND
    ((EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nProssiga apenas se conhecer o comando! Deseja prosseguir?\n") "Não"))
    ((EQ (ATS:GetKeyword "Sim" (LIST "Sim" "Não") "\nDeseja apenas atualizar o arquivo com base nos padrões do bloco de estilo?\n") "Sim")
      (ATS:SaveUsersPreferences 2)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:ChangeStandardsByBlockInsertion (FINDFILE "ATS-Estilo.dwg"))
      (ATS:RestoreUsersPreferences commandName nil)
    )
    (T
      (ATS:SaveUsersPreferences 24)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:ApplyToAllNestedItems nil (LAMBDA (item)
                                       (FOREACH property-value (LIST (CONS "Color" 256)
                                                                     (CONS "Elevation" 0.0)
                                                                     (CONS "Linetype" "ByLayer")
                                                                     (CONS "LinetypeScale" 1)
                                                                     (CONS "Lineweight" -1)
                                                                     (CONS "Thickness" 0.0)
                                                                     (CONS "Material" "ByLayer"))
                                         (IF (VLAX-PROPERTY-AVAILABLE-P item (CAR property-value))
                                           (VLAX-PUT-PROPERTY item (CAR property-value) (CDR property-value))))))
      ;; Itera todos os layouts
      (FOREACH layout (CONS "Model" (LAYOUTLIST))
        (COMMAND-S "_.-LAYOUT" "_SET" layout)
        (COMMAND "_.CHANGE" "_ALL" "" "_PROPERTIES" "_COLOR" "BYLAYER" "_ELEV" "0" "_LTYPE" "BYLAYER" "_LTSCALE" "1" "_LWEIGHT" "BYLAYER" "_THICKNESS" "0")
        (IF (NOT (EQ *CADSoftware* "ZWCAD"))
          (COMMAND "_MATERIAL" "ByLayer")
        )
        (COMMAND "")
        (IF (AND (TBLOBJNAME "STYLE" *standardTextStyle*) (SETQ selection (SSGET "_A" (LIST (CONS 0 "*TEXT,ATTDEF") (CONS 410 (GETVAR "CTAB"))))))
          (ATS:ChangeSelectionProperties selection (LIST (CONS 7 *standardTextStyle*)))
        )
        (IF (AND (TBLOBJNAME "DIMSTYLE" *standardDimensionStyle*) (SETQ selection (SSGET "_A" (LIST (CONS 0 "*DIMENSION") (CONS 410 (GETVAR "CTAB"))))))
          (ATS:ChangeSelectionProperties selection (LIST (CONS 3 *standardDimensionStyle*)))
        )
      )
      ;; Sincroniza atributos em todos os blocos
      (COMMAND-S "_.ATTSYNC" "_NAME" "*")
      (COMMAND-S "_.REGENALL")
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
