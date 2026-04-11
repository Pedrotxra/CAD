;| Obtém os valores das propriedades dinâmicas de um bloco
   @global
   @param asVariant [bool] - 'T' para obter os valores em variant
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param blockObject [obj] - Objeto do bloco
   @param searchNames [str/lst] - Nome da propriedade, ou lista com os nomes, ou 'nil' para todas
   @returns [any] - Valor da propriedade ou lista dos valores
   |;
(DEFUN ATS:GetDynamicBlockProperties (asVariant wildcardMatch blockObject searchNames / blockProperties foundProperty searchNamesLength property propertyName)
  (IF (AND (VLAX-METHOD-APPLICABLE-P blockObject "GetDynamicBlockProperties")
           ;; Obtém todas as propriedades em forma de objetos
           (SETQ blockProperties (VLAX-INVOKE-METHOD blockObject "GetDynamicBlockProperties"))
           (SETQ blockProperties (VLAX-SAFEARRAY->LIST (VLAX-VARIANT-VALUE blockProperties))))
    (PROGN
      (IF (EQ (TYPE searchNames) (READ "STR"))
        (PROGN
          ;; Itera as propriedades até encontrar a de nome procurado
          (VL-SOME
            (FUNCTION
              (LAMBDA (property)
                (SETQ property (ATS:SaveObject property))
                (IF (IF wildcardMatch
                      (WCMATCH (STRCASE (VLA-GET-PROPERTYNAME property)) (STRCASE searchNames))
                      (EQ searchNames (VLA-GET-PROPERTYNAME property)))
                  ((IF asVariant VLAX-GET-PROPERTY VLAX-GET) property "Value")
                )
              )
            )
            blockProperties
          )
        )
        (IF searchNames
          ;; Obtém o nome das propriedades procuradas em propriedade-valor
          (PROGN
            (SETQ foundProperty 0)
            (SETQ searchNamesLength (LENGTH searchNames))
            (WHILE (AND (< foundProperty searchNamesLength) blockProperties)
              (SETQ property (CAR blockProperties))
              (SETQ blockProperties (VL-REMOVE property blockProperties))
              (IF wildcardMatch
                (PROGN
                  (SETQ propertyName (STRCASE (VLA-GET-PROPERTYNAME property)))
                  (SETQ propertyName (VL-SOME
                                       (FUNCTION
                                         (LAMBDA (searchName)
                                           (IF (WCMATCH propertyName (STRCASE searchName))
                                             searchName))) searchNames)))
                (SETQ propertyName (VLA-GET-PROPERTYNAME property))
              )
              (IF (OR (AND wildcardMatch propertyName) (MEMBER propertyName searchNames))
                (PROGN
                  (SETQ searchNames (SUBST (CONS propertyName ((IF asVariant VLAX-GET-PROPERTY VLAX-GET) property "Value")) propertyName searchNames))
                  (SETQ foundProperty (1+ foundProperty))
                )
              )
            )
            ;; Retira as propriedades não encontradas
            (MAPCAR (FUNCTION (LAMBDA (searchName)
                                (IF (LISTP searchName)
                                  searchName))) searchNames))
          ;; Retorna todas as propriedades
          (VL-REMOVE nil (MAPCAR
                           (FUNCTION
                             (LAMBDA (property / propertyName)
                               (ATS:SaveObject property)
                               (SETQ propertyName (VLA-GET-PROPERTYNAME property))
                               (IF (NOT (EQ propertyName "Origin"))
                                 (CONS propertyName ((IF asVariant VLAX-GET-PROPERTY VLAX-GET) property "Value")))))
                           blockProperties))
        )
      )
    )
  )
)

;| Altera os valores de propriedades dinâmicas de um bloco
   @global
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param blockObject [obj] - Objeto do bloco
   @param property-valueList [lst] - Lista de propriedade-valor a substituir
   @returns [any] - Valor da propriedade ou lista dos valores
   |;
(DEFUN ATS:ChangeDynamicBlockPropertiesValues (wildcardMatch blockObject property-valueList / entityName basePoint blockProperties property propertyName property-value)
  (IF (AND (VLAX-METHOD-APPLICABLE-P blockObject "GetDynamicBlockProperties")
           ;; Obtém todas as propriedades em forma de objetos
           (SETQ blockProperties (VLAX-INVOKE-METHOD blockObject "GetDynamicBlockProperties"))
           (SETQ blockProperties (VLAX-SAFEARRAY->LIST (VLAX-VARIANT-VALUE blockProperties))))
    (PROGN
      (SETQ entityName (VLAX-VLA-OBJECT->ENAME blockObject))
      ;; Salva o ponto base, caso ele seja movido no processo
      (SETQ basePoint (ATS:GetPropertiesValues 10 entityName))
      ;; Ordena as propriedades para que a de visibilidade seja alterada primeiramente
      (SETQ blockProperties (VL-SORT blockProperties (FUNCTION (LAMBDA (property1 property2) (EQ (TYPE (VLAX-GET property1 "Value")) (READ "STR"))))))
      (WHILE (AND property-valueList blockProperties)
        (SETQ property (ATS:SaveObject (CAR blockProperties)))
        (SETQ blockProperties (VL-REMOVE property blockProperties))
        (IF wildcardMatch
          (PROGN
            (SETQ propertyName (STRCASE (VLA-GET-PROPERTYNAME property)))
            (SETQ property-value (VL-SOME
                                   (FUNCTION
                                     (LAMBDA (property-value)
                                       (IF (WCMATCH propertyName (STRCASE (CAR property-value)))
                                         property-value))) property-valueList))
          )
          (SETQ property-value (ASSOC (VLA-GET-PROPERTYNAME property) property-valueList))
        )
        (IF property-value
          (PROGN
            (SETQ property-valueList (VL-REMOVE property-value property-valueList))
            (VLAX-PUT-PROPERTY property "Value" (CDR property-value))
          )
        )
      )
      (ATS:ChangePropertiesValues entityName (LIST (CONS 10 basePoint)))
      (COMMAND-S "_.ATTSYNC" "_NAME" (ATS:GetPropertiesValues 2 entityName))
      blockObject
    )
  )
)

;| Permite explosão de blocos
   @global
   @param namesList [lst] - Lista com os nomes a serem utilizados, ou 'nil' para aplicar para todos os blocos
   @returns [obj] - Último bloco iterado
   |;
(DEFUN ATS:AllowExplosion (namesList / name)
  (VLAX-FOR block (ATS:SaveObject (VLA-GET-BLOCKS *activeDocument*))
    (SETQ name (VLA-GET-NAME block))
    (IF (AND (IF namesList (MEMBER name namesList) T) (WCMATCH name "~`**_Space*")) ; Verifica se o bloco não é um espaço (Model Space ou Paper Space)
      (VLA-PUT-EXPLODABLE block :VLAX-TRUE)
    )
    (ATS:SaveObject block)
  )
)

;| Insere um bloco dos arquivos de suporte na memória
   @global
   @param blockName [str] - Nome do bloco
   @returns [bool] - Retorna 'T' se o bloco foi inserido com sucesso, 'nil' caso contrário
   |;
(DEFUN ATS:InsertBlockFromSupportPaths (blockName)
  (COND
    ((TBLOBJNAME "BLOCK" blockName))
    ((FINDFILE (STRCAT blockName ".dwg")) (COMMAND "_.-INSERT" blockName ^C^C) T)
  )
)

;| Presume o nome de um nome bloco
   @global
   @param blockName [str] - Nome do bloco
   @returns [str/sym] - Nome ou símbolo do bloco
   |;
(DEFUN ATS:PredictBlockName (blockName / predictedBlockName)
  (COND
    ;; Verifica se o bloco existe com o nome introduzido
    ((OR (TBLOBJNAME "BLOCK" blockName) (FINDFILE (STRCAT blockName ".dwg")))
     blockName
    )
    ;; Se não encontrar da forma introduzida, procura na lista de nomes abreviados
    ((SETQ predictedBlockName (CDR (ASSOC (STRCASE blockName) *shortenedBlocksNames*)))
     (SETQ blockName predictedBlockName)
     (IF (EQ (TYPE predictedBlockName) (READ "SYM"))
       (SETQ predictedBlockName (ATS:GetPropertiesValues "Name" (EVAL predictedBlockName)))
     )
     (IF (OR (TBLOBJNAME "BLOCK" predictedBlockName) (FINDFILE (STRCAT predictedBlockName ".dwg")))
       blockName
     )
    )
    ;; Se não encontrar na lista de nomes abreviados, acrescenta o prefixo Autots
    ((AND
       (SETQ predictedBlockName (STRCAT "ATS" *affixSeparator* blockName))
       (OR (TBLOBJNAME "BLOCK" predictedBlockName) (FINDFILE (STRCAT predictedBlockName ".dwg")))
     )
     predictedBlockName
    )
    ;; Se também não encontrar com o prefixo Autots, acrescenta o prefixo padrão, se diferente
    ((AND
       (NOT (EQ *standardPrefix* "ATS"))
       (SETQ predictedBlockName (STRCAT *standardPrefix* *affixSeparator* blockName))
       (OR (TBLOBJNAME "BLOCK" predictedBlockName) (FINDFILE (STRCAT predictedBlockName ".dwg")))
     )
     predictedBlockName
    )
  )
)

;| Procura a propriedade de um bloco
   @global
   @param property [str] - Nome da propriedade
   @param blockName [str] - Nome do bloco
   @returns [any] - Valor da propriedade
   |;
(DEFUN ATS:FindBlockProperty (property blockName)
  (ATS:GetPropertiesValues property (VL-SOME (FUNCTION (LAMBDA (block)
                                                         (SETQ block (CDR block))
                                                         (IF (AND (EQ (TYPE block) (READ "SYM"))
                                                                  (SETQ block (EVAL block))
                                                                  (EQ blockName (ATS:GetPropertiesValues "Name" block)))
                                                           block))) *shortenedBlocksNames*))
)

;| Substitui todas as instâncias de um bloco
   @global
   @param newBlockList [lst] - Lista de propriedade-valor nomeadas do novo bloco
   @param oldBlockList [lst] - Lista de propriedade-valor nomeadas do bloco antigo
   @returns [nil] - Substitui as instâncias do bloco
   |;
(DEFUN ATS:ReplaceAllBlocksInstances (newBlockList oldBlockList / property-value layer blocks)
  (SETQ property-value (LIST (CONS 2 (ATS:GetPropertiesValues "Name" newBlockList))))
  (IF (SETQ layer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" newBlockList)))
    (SETQ property-value (CONS (CONS 8 layer) property-value))
  )
  (IF (AND
        (SETQ blocks (SSGET "_A" (LIST (CONS 0 "INSERT"))))
        (SETQ blocks (ATS:FilterSelection nil nil blocks (LIST (CONS 2 (ATS:GetPropertiesValues "Name" oldBlockList)))))
      )
    (PROGN
      (ATS:ChangeSelectionProperties blocks property-value)
      (COMMAND-S "_.ATTSYNC" "_NAME" (ATS:GetPropertiesValues 2 (SSNAME blocks 0)))
    )
  )
)

;| Converte os símbolos de nível explodidos em blocos
   @global
   @param referenceSelection [ss] - Seleção de referência
   @param circleSelection [ss] - Seleção de círculos dos níveis a serem convertidos em blocos
   @returns [nil] - Converte os símbolos de nível explodidos em blocos
   |;
(DEFUN ATS:ConvertExplodedLevelSymbols (referenceSelection circleSelection / referenceCircle circlesRadius linesLengths hatchesAreas textsDistances count entityName start end lastEntity selection)
  (SETQ referenceSelection (ATS:GetSelectionProperties (LIST 0 -1 10 11 40) referenceSelection))
  (IF (SETQ referenceCircle (ASSOC "CIRCLE" referenceSelection))
    (PROGN
      ;; Armazena o raio do círculo de referência
      (SETQ circlesRadius (NTH 4 referenceCircle))
      ;; Armazena o comprimento das linhas de referência
      (IF (SETQ linesLengths (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (entity) (EQ (CAR entity) "LINE"))) referenceSelection))
        (SETQ linesLengths (ATS:RemoveDuplicates (MAPCAR (FUNCTION (LAMBDA (line) (DISTANCE (CADDR line) (CADDDR line)))) linesLengths)))
      )
      ;; Armazena as áreas das hachuras de referência
      (IF (SETQ hatchesAreas (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (entity) (EQ (CAR entity) "HATCH"))) referenceSelection))
        (SETQ hatchesAreas (ATS:RemoveDuplicates (MAPCAR (FUNCTION (LAMBDA (hatch) (VLA-GET-AREA (ATS:SaveObject (CADR hatch))))) hatchesAreas)))
      )
      ;; Armazena as distâncias do canto inferior esquerdo dos textos do centro do círculo de referência, em ordem crescente
      (IF (SETQ textsDistances (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (entity) (EQ (CAR entity) "TEXT"))) referenceSelection))
        (PROGN
          (SETQ referenceCircle (CADDR referenceCircle))
          (SETQ textsDistances (ATS:RemoveDuplicates (MAPCAR (FUNCTION (LAMBDA (text) (DISTANCE referenceCircle (IF (EQ (CADDDR text) (LIST 11 0.0 0.0 0.0)) (CADDR text) (CADDDR text))))) textsDistances)))
        )
      )
      ;; Armazena o comprimento da maior linha de referência
      (SETQ referenceSelection (APPLY (FUNCTION MAX) linesLengths))
      (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" *levelBlockList*)))
      (SETQ count (SSLENGTH circleSelection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityName (SSNAME circleSelection count))
        (IF (EQUAL (ATS:GetPropertiesValues 40 entityName) circlesRadius *minimalFuzz*)
          (PROGN
            (SETQ referenceCircle (ATS:GetPropertiesValues 10 entityName))
            (ENTDEL entityName)
            ;; Armazena os limites a partir do centro do círculo e alcance da maior linha de referência
            (SETQ start (POLAR referenceCircle (* 5 (/ PI 4)) referenceSelection))
            (SETQ end (POLAR referenceCircle (/ PI 4) referenceSelection))
            (COMMAND-S "_.ZOOM" start end)
            (COMMAND "_.-INSERT" (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Name" *levelBlockList*)) referenceCircle (ATS:GetInsertionScale))
            (WHILE (> (GETVAR "CMDACTIVE") 0) (COMMAND ""))
            (IF textsDistances
              (SETQ lastEntity (ENTLAST))
            )
            ;; Seleção ordenada para manter a correspondência dos atributos
            (COMMAND-S "_.ZOOM" start end)
            (FOREACH entityName (ATS:SortSelectionByPosition (* *unitsFactor* 3.0) (SSGET "_C" start end (LIST (CONS 0 (STRCAT "LINE" (IF hatchesAreas ",HATCH" "") (IF textsDistances ",TEXT" ""))))))
              (COND
                ((EQ (ATS:GetPropertiesValues 0 entityName) "LINE")
                 (SETQ start (ATS:GetPropertiesValues 10 entityName))
                 (SETQ end (ATS:GetPropertiesValues 11 entityName))
                 (IF (VL-SOME (FUNCTION (LAMBDA (lineDistance) (EQUAL (DISTANCE start end) lineDistance *minimalFuzz*))) linesLengths)
                   (ENTDEL entityName)
                 )
                )
                ((EQ (ATS:GetPropertiesValues 0 entityName) "HATCH")
                 (SETQ end (VLA-GET-AREA (ATS:SaveObject entityName)))
                 (IF (VL-SOME (FUNCTION (LAMBDA (hatchArea) (EQUAL end hatchArea *minimalFuzz*))) hatchesAreas)
                   (ENTDEL entityName)
                 )
                )
                ((EQ (ATS:GetPropertiesValues 0 entityName) "TEXT")
                 (SETQ end (ATS:GetPropertiesValues 11 entityName))
                 (SETQ end (DISTANCE referenceCircle (IF (EQ end (LIST 11 0.0 0.0 0.0)) (ATS:GetPropertiesValues 10 entityName) end)))
                 (IF (VL-SOME (FUNCTION (LAMBDA (textDistance) (EQUAL end textDistance *minimalFuzz*))) textsDistances)
                   (PROGN
                     (SETQ end (ATS:SearchAttribute nil lastEntity (LIST (CONS 2 (ATS:GetPropertiesValues "LevelAttributeName" *levelBlockList*)))))
                     (IF (EQ (ATS:GetPropertiesValues 1 end) "")
                       (ATS:ChangePropertiesValues end (LIST (CONS 1 (ATS:GetPropertiesValues 1 entityName))))
                       (ATS:EditBlockAttributes nil lastEntity (LIST (CONS 2 (ATS:GetPropertiesValues "Level2AttributeName" *levelBlockList*))) (LIST (CONS 1 (ATS:GetPropertiesValues 1 entityName))))
                     )
                     (ENTDEL entityName)
                   )
                 )
                )
              )
            )
          )
        )
      )
    )
    (PROMPT "\nNão foi possível identificar o círculo de referência.\n")
  )
)

;| Aplica uma função em todos os níveis de um bloco
   @global
   @param blockName [str] - Nome do bloco
   @param applyFunction [subr] - Função
   @returns [any] - Função aplicada
   |;
(DEFUN ATS:ApplyToAllNestedItems (blockName applyFunction / ApplyToAllNestedItems blocksCollection blocksList)
  (DEFUN ApplyToAllNestedItems (blockName)
    (VLAX-FOR item (ATS:SaveObject (VLA-ITEM blocksCollection blockName))
      (ATS:SaveObject item)
      (IF (EQ (VLA-GET-ObjectName item) "AcDbBlockReference")
        (PROGN
          (SETQ blockName (VLAX-GET-PROPERTY item "EffectiveName"))
          (IF (NOT (MEMBER blockName blocksList))
            (PROGN
              (ApplyToAllNestedItems blockName)
              (SETQ blocksList (CONS blockName blocksList))
            )
          )
        )
      )
      (APPLY (FUNCTION applyFunction) (LIST item))
    )
  )
  (SETQ blocksCollection (ATS:SaveObject (VLA-GET-BLOCKS *activeDocument*)))
  (ApplyToAllNestedItems blockName)
)

;| Cria um bloco com nome aleatório
   @returns nil
   |;
(DEFUN C:BA (/ *error* commandName blockName point selection)
  (SETQ commandName "BA")
  (COND
    ((NOT (SETQ selection (SSGET))) (PROMPT "\nNada foi selecionado.\n"))
    ((NOT (SETQ point (PROGN (INITGET 1) (GETPOINT "\nSelecione o ponto base:\n")))) (PROMPT "\nPonto base inválido.\n"))
    (T
      (ATS:SaveUsersPreferences 2)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (COMMAND-S "_.COPYBASE" point selection "")
      (COMMAND-S "_.ERASE" selection "")
      (COMMAND-S "_.PASTEBLOCK" point)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Altera os blocos selecionados para outros
   @returns nil
   |;
(DEFUN C:CB (/ *error* commandName blocks blockName blockProperties layer)
  (SETQ commandName "CB")
  (COND
    ((NOT (SETQ blocks (SSGET (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco selecionado.\n"))
    ((NOT (ATS:InsertBlockFromSupportPaths (SETQ blockName (IF (LISTP (SETQ blockProperties (EVAL (ATS:PredictBlockName (IF (AND (SETQ blockProperties (ATS:GetEffectiveName (ATS:SaveObject (SSNAME blocks 0))))
                                                                                                                                 ;; Verifica se há apenas um prefixo em comum entre os blocos selecionados
                                                                                                                                 (EQ (LENGTH (SETQ blockName (ATS:RemoveDuplicates (VL-REMOVE nil (MAPCAR (FUNCTION (LAMBDA (entityName) (ATS:GetSubstring "" *affixSeparator* (ATS:GetEffectiveName (ATS:SaveObject entityName))))) (ATS:GetSelectionProperties -1 blocks)))))) 1)
                                                                                                                                 ;; Busca os blocos com o prefixo em comum
                                                                                                                                 (SETQ blockName (ATS:SortAlphanumerically (ATS:GetTableProperties T "BLOCK" 2 (LIST (CONS 2 (STRCAT (CAR blockName) *affixSeparator* "*"))))))
                                                                                                                                 ;; Solicita ao usuário o nome do bloco
                                                                                                                                 (EQ (SETQ blockName (ATS:GetKeyword (IF (VL-SOME (FUNCTION (LAMBDA (keyword) (EQ (STRCASE (ATS:TrimSuffix (ATS:ReplaceAllInString "" " " blockProperties))) (STRCASE (ATS:TrimSuffix keyword))))) (VL-REMOVE blockProperties (MAPCAR (FUNCTION (LAMBDA (keyword) (ATS:ReplaceAllInString "" " " keyword))) blockName))) blockProperties "Inserir") (CONS "Inserir" blockName) "\nSelecione o nome do bloco, ou 'Inserir' para introduzir manualmente:\n")) "Inserir"))
                                                                                                                          ;; Se não tiver prefixo em comum, ou o usuário optar por inserir manualmente
                                                                                                                          (COND ((GETSTRING T (STRCAT "\nInsira o nome do bloco: <" blockProperties ">\n"))) (blockProperties))
                                                                                                                          blockName)))))
                                                            (PROGN
                                                              (SETQ layer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" blockProperties)))
                                                              (ATS:GetPropertiesValues "Name" blockProperties))
                                                            (PROGN
                                                              (SETQ layer nil)
                                                              blockProperties))))) (PROMPT "\nBloco não encontrado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:ChangeSelectionProperties blocks (APPEND (LIST (CONS 2 blockName)) (APPEND (IF (WCMATCH blockName (STRCAT "*" *affixSeparator* *frontViewSuffix* ",*" *affixSeparator* *sideViewSuffix*)) (LIST (CONS 50 0.0))) (IF (AND layer (ATS:InsertLayer layer)) (LIST (CONS 8 layer))))))
      (COMMAND-S "_.ATTSYNC" "_NAME" blockName)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Duplica um bloco, criando um novo nome para a instância do bloco selecionado
   @returns nil
   |;
(DEFUN C:DB (/ *error* commandName entityName newBlockName oldBlockName)
  (SETQ commandName "DB")
  (COND
    ((NOT (SETQ entityName (ATS:SelectSingleObject (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ oldBlockName (ATS:GetEffectiveName (ATS:SaveObject entityName)))
      (SETQ newBlockName (ATS:NameTableUniquely "BLOCK" 1 oldBlockName))
      (COMMAND-S "_.-BEDIT" oldBlockName)
      (COMMAND-S "_.BSAVEAS" newBlockName)
      (COMMAND-S "_.BCLOSE")
      (ATS:ChangePropertiesValues entityName (LIST (CONS 2 newBlockName)))
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Altera o ponto base de um bloco
   @returns nil
   |;
(DEFUN C:PB (/ *error* commandName entityName basePoint translatePoint)
  (SETQ commandName "PB")
  (COND
    ((NOT (SETQ entityName (ATS:SelectSingleObject (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco selecionado.\n"))
    ((NOT (SETQ basePoint (PROGN (INITGET 1) (GETPOINT "\nSelecione o novo ponto base:\n")))) (PROMPT "\nPonto base inválido.\n"))
    (T
      (SETQ translatePoint (EQ (ATS:GetKeyword "Desenho" (LIST "Desenho" "PontoBase") "\nDeseja manter a posição do desenho ou do ponto base?\n") "Desenho"))
      (ATS:SaveUsersPreferences 11)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:ChangeBlockBasePoint translatePoint basePoint entityName)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Copia um bloco para outros
   @returns nil
   |;
(DEFUN C:CCB (/ *error* commandName copyBlock blocks blockName)
  (SETQ commandName "CCB")
  (COND
    ((NOT (SETQ copyBlock (ATS:SelectSingleObject (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco selecionado.\n"))
    ((PROGN (PROMPT "\nSelecione os blocos a serem trocados.\n") (NOT (SETQ blocks (SSGET (LIST (CONS 0 "INSERT")))))) (PROMPT "\nNome de bloco inválido.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ blockName (ATS:GetEffectiveName (ATS:SaveObject copyBlock)))
      (ATS:ChangeSelectionProperties blocks (LIST (CONS 2 blockName) (CONS 8 (ATS:GetPropertiesValues 8 copyBlock))))
      (COMMAND-S "_.ATTSYNC" "_NAME" blockName)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Atalho para renomear um bloco
   @returns nil
   |;
(DEFUN C:RB (/ *error* commandName entityName oldBlockName newBlockName)
  (SETQ commandName "RB")
  (COND
    ((NOT (SETQ entityName (ATS:SelectSingleObject (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco selecionado.\n"))
    ((PROGN
       (SETQ oldBlockName (ATS:GetEffectiveName (ATS:SaveObject entityName)))
       (NOT (SETQ newBlockName (GETSTRING T (STRCAT "\nInsira o novo nome: <" oldBlockName ">\n"))))) (PROMPT "\nNenhum nome inserido.\n"))
    ((EQ oldBlockName newBlockName) (PROMPT "\nO nome do bloco não foi alterado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (COMMAND-S "_.-RENAME" "_BLOCK" oldBlockName newBlockName)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Renomea vários blocos com prefixo ou sufixo
   @returns nil
   |;
(DEFUN C:RBS (/ *error* commandName affixPosition affix selection count blockName blocksNames)
  (SETQ commandName "RBS")
  (COND
    ((NOT (SETQ affixPosition (ATS:GetKeyword "Sufixo" (LIST "Prefixo" "Sufixo") "\nDeseja acrescentar prefixo ou sufixo aos blocos?\n"))) (PROMPT "\nNenhum afixo foi especificado.\n"))
    ((NOT (SETQ affix (GETSTRING T (STRCAT "\nInsira o " (STRCASE affixPosition T) ":<" (IF (EQ affixPosition "Prefixo") *standardPrefix* "Obsoleto") ">\n")))) (PROMPT (STRCAT "\nNenhum " (STRCASE affixPosition T) " foi especificado.\n")))
    ((AND (EQ affix "") (NOT (SETQ affix (IF (EQ affixPosition "Prefixo") *standardPrefix* "Obsoleto")))))
    ((NOT (IF (EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nDeseja aplicar em todos os blocos do arquivo?\n") "Não") (SETQ selection (SSGET (LIST (CONS 0 "INSERT")))))) (PROMPT "\nNenhum bloco foi selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (IF selection
        (PROGN
          (SETQ count (SSLENGTH selection))
          (REPEAT count
            (SETQ count (1- count))
            (SETQ blockName (ATS:GetEffectiveName (ATS:SaveObject (SSNAME selection count))))
            (IF (NOT (MEMBER blockName blocksNames))
              (SETQ blocksNames (CONS blockName blocksNames))
            )
          )
        )
      )
      (ATS:AddTableAffix "BLOCK" (EQ affixPosition "Prefixo") affix blocksNames)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Atualizar os blocos do arquivo para os dos arquivos de suporte
   @returns nil
   |;
(DEFUN C:ATTB (/ *error* commandName blocksNames selection count blockPath)
  (SETQ commandName "ATTB")
  (COND
    ((NOT (IF (EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nDeseja aplicar em todos os blocos do arquivo?\n") "Sim")
            (SETQ blocksNames (VL-REMOVE-IF (FUNCTION (LAMBDA (blockName) (WCMATCH blockName "`*@#*"))) (ATS:GetTableProperties nil "BLOCK" 2 nil)))
            (PROGN
              (SETQ selection (SSGET (LIST (CONS 0 "INSERT"))))
              (SETQ count (SSLENGTH selection))
              (REPEAT count
                (SETQ count (1- count))
                (SETQ blocksNames (CONS (ATS:GetEffectiveName (ATS:SaveObject (SSNAME selection count))) blocksNames))
              )
              (SETQ blocksNames (ATS:RemoveDuplicates blocksNames))
            )
          )) (PROMPT "\nNenhum bloco foi selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (FOREACH blockName (VL-REMOVE-IF (FUNCTION (LAMBDA (blockName) (WCMATCH blockName "_*"))) blocksNames)
        (IF (SETQ blockPath (FINDFILE (STRCAT blockName ".dwg")))
          (PROGN
            (COMMAND "_.-INSERT" (STRCAT blockName "=" blockPath) ^C^C)
            (COMMAND-S "_.ATTSYNC" "_NAME" blockName)
          )
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| 'Detona' (explode) todos os blocos em todos os níveis
   @returns nil
   |;
(DEFUN C:DETONATE (/ *error* commandName selection)
  (SETQ commandName "DETONATE")
  (COND
    ((NOT (SETQ selection (COND
                            ((SSGET "_I"))
                            ((EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nDeseja detonar tudo?\n") "Sim") (SSGET "_A" (LIST (CONS 410 (GETVAR "CTAB")))))
                            ((SSGET))))))
    (T
      (ATS:SaveUsersPreferences 8)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:BurstNested selection)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Restaura os blocos para o layer '0' e 'ByLayer'
   @returns nil
   |;
(DEFUN C:RESTAURABLOCOS (/ *error* commandName)
  (SETQ commandName "RESTAURABLOCOS")
  (COND
    ((EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nProssiga apenas se conhecer o comando! Deseja prosseguir?\n") "Não"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      ; Itera sobre os blocos, alterando propriedades de subentidades
      (VLAX-FOR block (ATS:SaveObject (VLA-GET-BLOCKS *activeDocument*))
        (IF (AND (EQ (VLA-GET-ISLAYOUT block) :VLAX-FALSE)
                 (EQ (VLA-GET-ISXREF block) :VLAX-FALSE))
          (VLAX-FOR subEntity block
            (VLA-PUT-LAYER subEntity "0")
            (VLA-PUT-COLOR subEntity acByLayer)
            (VLA-PUT-LINEWEIGHT subEntity acLnWtByLayer)
            (VLA-PUT-LINETYPE subEntity "ByLayer")
            (ATS:SaveObject subEntity)
          )
        )
        (ATS:SaveObject block)
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Converte os símbolos de nível explodidos em blocos
   @returns nil
   |;
(DEFUN C:CORRIGENIVEIS (/ *error* commandName referenceSelection selection)
  (SETQ commandName "CORRIGENIVEIS")
  (COND
    ((PROGN
       (PROMPT "\nSelecione um bloco de nível explodido como referência.\n")
       (NOT (SETQ referenceSelection (SSGET (LIST (CONS 0 "LINE,CIRCLE,HATCH,TEXT")))))
     )
     (PROMPT "\nNão foi possível identificar a referência do bloco de nível explodido.\n")
    )
    ((PROGN
       (PROMPT "\nSelecione a região para corrigir os blocos explodidos.\n")
       (NOT (SETQ circleSelection (SSGET (LIST (CONS 0 "CIRCLE")))))
     )
    )
    (T
      (ATS:SaveUsersPreferences 31)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:ConvertExplodedLevelSymbols referenceSelection circleSelection)
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
