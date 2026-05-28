;| Obtém os vértices de uma polilinha
   @global
   @param polylineEntity [lst] - Entidade da polilinha
   @returns [lst] - Lista de vértices da polilinha
   |;
(DEFUN ATS:GetPolylineVertices (polylineEntity)
  (IF (SETQ polylineEntity (MEMBER (ASSOC 10 polylineEntity) polylineEntity))
    (CONS
      (CDR (ASSOC 10 polylineEntity))
      (ATS:GetPolylineVertices (CDR polylineEntity))
    )
  )
)

;| Remove textos duplicados em uma seleção
   @global
   @param textsSelection [ss] - Seleção de textos
   @returns [nil] - Remove textos duplicados
   |;
(DEFUN ATS:RemoveDuplicatedTexts (textsSelection / textsProperties)
  (SETQ textsSelection (ATS:GetSelectionProperties (LIST -1 1 10 11) textsSelection))
  (SETQ textsProperties (MAPCAR (FUNCTION CDR) textsSelection))
  (FOREACH text textsSelection
    (SETQ textsProperties (CDR textsProperties))
    (IF (MEMBER (CDR text) textsProperties)
      (ENTDEL (CAR text))
    )
  )
)

;| Obtém uma lista de pontos
   @global
   @param listLength [int] - Número de pontos a serem obtidos, ou 'nil' para obter pontos indefinidamente
   @returns [lst] - Lista de pontos obtidos
   |;
(DEFUN ATS:GetPointsList (listLength / pointsList point)
  (IF listLength
    (REPEAT listLength (SETQ pointsList (CONS (GETPOINT) pointsList)))
    (PROGN
      (WHILE point (SETQ pointsList (CONS (SETQ point (GETPOINT)) pointsList)))
      (VL-REMOVE nil pointsList)
    )
  )
)

;| Deleta entidades invisíveis
   @global
   @returns [nil] - Deleta as entidades invisíveis
   |;
(DEFUN ATS:DeleteInvisibleEntities (/ layers)
  (SETQ layers (ATS:ListToString "," (MAPCAR (FUNCTION CAR) (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (layer) (OR (< (CADR layer) 0) (EQ (LOGAND (CADDR layer) 1) 1)))) (ATS:GetTableProperties nil "LAYER" (LIST 2 62 70) nil)))))
  (IF layers
    (PROGN
      (COMMAND-S "_.-LAYER" "_UNLOCK" layers "")
      (SETQ layers (SSGET "_A" (LIST (CONS 8 layers) (CONS 410 (GETVAR "CTAB")))))
      (IF layers
        (COMMAND-S "_.ERASE" layers "")
      )
    )
  )
)

;| Remove 'pontos' ou entidades desnecessárias no desenho
   @global
   @param selection [ss] - Seleção, ou nil para aplicar em todo o desenho
   @returns [nil] - Exclui os objetos 'ruins'
   |;
(DEFUN ATS:RemoveDots (selection / count entityName entity entityType bad)
  (IF (NOT (ATS:VerifySelectionSets selection))
    (SETQ selection (SSGET "_A" (LIST (CONS 0 "*LINE,CIRCLE,ARC,*TEXT,ATTDEF") (CONS 410 (GETVAR "CTAB")))))
  )
  (IF selection
    (PROGN
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityName (SSNAME selection count))
        (SETQ entity (ENTGET entityName))
        (SETQ entityType (ATS:GetPropertiesValues 0 entity))
        ;; Verifica diferentes tipos de entidades e define se são entidades 'ruins'
        (COND
          ((AND (EQ entityType "LINE")
                (EQUAL (ATS:GetPropertiesValues 10 entity) (ATS:GetPropertiesValues 11 entity) *minimalFuzz*))
           (ENTDEL entityName))
          ((AND (EQ entityType "LWPOLYLINE")
                (< (LENGTH (ATS:RemoveDuplicates (VL-REMOVE nil (MAPCAR (FUNCTION (LAMBDA (property) (IF (EQ (CAR property) 10) (CDR property)))) entity)))) 2))
           (ENTDEL entityName))
          ((AND (EQ entityType "POLYLINE")
                (PROGN
                  (SETQ entity (ENTNEXT entityName))
                  (SETQ entityType (ATS:GetPropertiesValues 10 entity))
                  (WHILE (AND
                           (SETQ bad (EQUAL (ATS:GetPropertiesValues 10 entity) entityType *minimalFuzz*))
                           (SETQ entity (ENTNEXT entity))
                           (EQ (ATS:GetPropertiesValues 0 entity) "VERTEX")))
                  bad))
           (ENTDEL entityName))
          ((AND (EQ entityType "CIRCLE")
                (EQUAL (ATS:GetPropertiesValues 40 entity) 0.0 *minimalFuzz*))
           (ENTDEL entityName))
          ((AND (EQ entityType "ARC")
                (OR (EQUAL (ATS:GetPropertiesValues 40 entity) 0.0 *minimalFuzz*) (EQUAL (ATS:GetPropertiesValues 50 entity) (ATS:GetPropertiesValues 51 entity) *minimalFuzz*)))
           (ENTDEL entityName))
          ((AND (OR (EQ entityType "TEXT") (EQ entityType "MTEXT"))
                (EQ (VL-STRING-TRIM " " (ATS:GetPropertiesValues 1 entity)) ""))
           (ENTDEL entityName))
          ((AND (EQ entityType "ATTDEF")
                (EQ (VL-STRING-TRIM " " (ATS:GetPropertiesValues 2 entity)) ""))
           (ENTDEL entityName))
        )
      )
    )
  )
)

;| Recorta as extremidades em uma polilinha e seleciona o conteúdo
   @returns nil
   |;
(DEFUN C:RPL (/ *error* commandName entityName point selection)
  (SETQ commandName "RPL")
  (COND
    ((NOT (SETQ entityName (ATS:SelectSingleObject (LIST (CONS 0 "*POLYLINE"))))) (PROMPT "\nNenhuma polilinha selecionada.\n"))
    ((NOT (SETQ point (GETPOINT "\nSelecione o ponto de corte.\n"))) (PROMPT "\nNenhuma polilinha selecionada.\n"))
    (T
      (ATS:SaveUsersPreferences 11)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (APPLY (FUNCTION COMMAND-S) (CONS "_.ZOOM" (ATS:GetObjectBoundaries (ATS:SaveObject entityName))))
      (SETQ selection (SSGET "_CP" (ATS:GetPolylineVertices (ENTGET entityName))))
      (ATS:Extrim entityName point)
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)

;| Insere o bloco de corte
   @returns nil
   |;
(DEFUN C:SEC (/ *error* commandName method)
  (SETQ commandName "SEC")
  (IF (SETQ method (ATS:GetPropertiesValues "Insert" *sectionBlockList*))
    (APPLY (FUNCTION method) nil)
    (PROMPT "\nMétodo de inserção de corte não encontrado.\n")
  )
)

;| Cria um corte de uma parede simples
   @returns nil
   |;
(DEFUN C:FAZCORTE (/ *error* commandName sectionBlock sectionBlockObject sectionName sectionLength sectionRange sectionAngle bottomLeft bottomRight topLeft topRight lastEntity count entity basePoint scale blockAngle dynamicProperties blockCorner blockObject blockName sectionedBlock)
  (SETQ commandName "FAZCORTE")
  (ATS:SetDefaultValues
    (LIST
      (CONS (QUOTE *ceilingHeight*) 260)
      (CONS (QUOTE *slabThickness*) 15)
    )
  )
  (COND
    ((NOT (IF (SETQ sectionBlock (ATS:SelectSingleObject (LIST (CONS 0 "INSERT"))))
            (PROGN
              (SETQ sectionBlockObject (ATS:SaveObject sectionBlock))
              (EQ (ATS:GetEffectiveName sectionBlockObject) (ATS:GetPropertiesValues "Name" *sectionBlockList*))))) (PROMPT "\nO bloco de corte não foi selecionado.\n"))
    (T
      (SETQ *ceilingHeight* (COND ((PROGN (INITGET 6) (GETREAL (STRCAT "\nInsira o pé direito: <" (RTOS *ceilingHeight*) ">\n")))) (*ceilingHeight*)))
      (SETQ *slabThickness* (COND ((PROGN (INITGET 6) (GETREAL (STRCAT "\nInsira a espessura da laje: <" (RTOS *slabThickness*) ">\n")))) (*slabThickness*)))
      ;; Define o nome do corte
      (IF (AND (TBLOBJNAME "BLOCK" (SETQ sectionName (STRCAT "Corte" *affixSeparator*
                                                             (ATS:GetPropertiesValues 1 (ATS:SearchAttribute nil sectionBlock (LIST (CONS 2 (ATS:GetPropertiesValues "StartNameAttributeName" *sectionBlockList*)))))
                                                             (ATS:GetPropertiesValues 1 (ATS:SearchAttribute nil sectionBlock (LIST (CONS 2 (ATS:GetPropertiesValues "EndNameAttributeName" *sectionBlockList*))))))))
               ;; Caso já exista a definição do bloco de corte, pergunta se deve ser atualizado, senão um nome único é gerado
               (EQ (ATS:GetKeyword "Sim" (LIST "Sim" "Não") "\nDeseja atualizar o corte existente?\n") "Não"))
        (PROGN
          (COMMAND-S "_-PURGE" "_BLOCKS" sectionName "_NO")
          (SETQ sectionName (ATS:NameTableUniquely "BLOCK" *duplicateAffix* sectionName))
        )
      )
      (ATS:SaveUsersPreferences 31)
      (DEFUN *error* (errorMessage) 
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      ;; Identifica os limites do bloco de corte
      (SETQ sectionLength (ATS:GetDynamicBlockProperties nil nil sectionBlockObject (ATS:GetPropertiesValues "LengthPropertyName" *sectionBlockList*)))
      (SETQ sectionRange (ATS:GetDynamicBlockProperties nil nil sectionBlockObject (ATS:GetPropertiesValues "RangePropertyName" *sectionBlockList*)))
      (SETQ sectionAngle (+ (ATS:GetPropertiesValues 50 sectionBlock) (IF (ATS:XOR (LIST (MINUSP (ATS:GetPropertiesValues 42 sectionBlock))
                                                                                       (EQ (ATS:GetDynamicBlockProperties nil nil sectionBlockObject (ATS:GetPropertiesValues "FlipPropertyName" *sectionBlockList*)) 1)))
                                                                       PI
                                                                       0))) ; Se o bloco estiver espelhado, adiciona 180° ao ângulo
      (SETQ bottomLeft (POLAR (ATS:GetPropertiesValues 10 sectionBlock) sectionAngle (- (/ sectionLength 2))))
      (SETQ bottomRight (POLAR bottomLeft sectionAngle sectionLength))
      (SETQ topLeft (POLAR bottomLeft (+ sectionAngle (/ PI 2)) sectionRange))
      (SETQ topRight (POLAR bottomRight (+ sectionAngle (/ PI 2)) sectionRange))
      ;; Seleciona os itens dentro da região e cria um bloco
      (COMMAND-S "_.ZOOM" bottomLeft topRight)
      (SETQ sectionBlock (ATS:JoinSelectionSets (LIST (SSGET "_CP" (LIST bottomLeft bottomRight topRight topLeft) (LIST (CONS 0 "INSERT") (CONS 8 (ATS:ListToString "," (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (ATS:RemoveDuplicates (ATS:EvaluateSymbolList (CADR *layersDrawOrderList*))))))))
                                                      (SSGET "_C" bottomLeft bottomRight (LIST (CONS 0 "*LINE") (CONS 8 (ATS:EvaluateStringSymbolList *wallLayer*)))))))
      ;; Exclui da seleção portas selecionadas apenas pela projeção de abertura
      (IF (AND sectionBlock (SETQ sectionBlockObject (ATS:FilterSelection nil nil sectionBlock (LIST (CONS 2 (ATS:GetPropertiesValues "Name" *doorBlockList*))))))
        (PROGN
          (SETQ lastEntity (ENTLAST))
          (SETQ count (SSLENGTH sectionBlockObject))
          (REPEAT count
            (SETQ count (1- count))
            (SETQ entity (SSNAME sectionBlockObject count))
            ;; Armazena o ponto base e orientação da porta
            (SETQ basePoint (ATS:GetPropertiesValues 10 entity))
            (SETQ scale (ATS:GetPropertiesValues 42 entity))
            (SETQ blockAngle (ATS:GetPropertiesValues 50 entity))
            (SETQ dynamicProperties (MAPCAR (FUNCTION CDR) (ATS:GetDynamicBlockProperties nil nil (ATS:SaveObject entity) (LIST (ATS:GetPropertiesValues "LengthPropertyName" *doorBlockList*)
                                                                                                                              (ATS:GetPropertiesValues "ThicknessPropertyName" *doorBlockList*)
                                                                                                                              (ATS:GetPropertiesValues "DoorKnobSideFlipPropertyName" *doorBlockList*)
                                                                                                                              (ATS:GetPropertiesValues "WallSideFlipPropertyName" *doorBlockList*)))))
            (SETQ blockCorner (POLAR basePoint (+ blockAngle (IF (ATS:XOR (LIST (> (ATS:GetPropertiesValues 41 entity) 0) (ZEROP (CADDR dynamicProperties)))) PI 0)) (CAR dynamicProperties)))
            ;; Cria uma polilinha na projeção da parede
            (COMMAND-S "_.PLINE" basePoint
                                 blockCorner
                                 (POLAR blockCorner ((IF (ATS:XOR (LIST (> scale 0) (ZEROP (CADDDR dynamicProperties)))) + -) blockAngle (/ PI 2)) (CADR dynamicProperties))
                                 (POLAR basePoint ((IF (ATS:XOR (LIST (> scale 0) (ZEROP (CADDDR dynamicProperties)))) + -) blockAngle (/ PI 2)) (CADR dynamicProperties)) "_CLOSE")
          )
          ;; Seleciona as polilinhas que não estão na região do corte e remove a porta correspondente da seleção principal
          (SETQ lastEntity (ATS:SelectNextEntities lastEntity))
          (SETQ entity (ATS:TrimSelectionSets lastEntity (SSGET "_CP" (LIST bottomLeft bottomRight topRight topLeft) (LIST (CONS 0 "LWPOLYLINE") (CONS 8 "0") (CONS 70 1)))))
          (IF entity
            (PROGN
              (SETQ count (SSLENGTH entity))
              (REPEAT count
                (SETQ count (1- count))
                (SETQ sectionBlock (ATS:TrimSelectionSets sectionBlock (ATS:FilterSelection nil nil (SSGET "_CP" (ATS:GetPolylineVertices (ENTGET (SSNAME entity count))) (LIST (CONS 0 "INSERT"))) (LIST (CONS 2 (ATS:GetPropertiesValues "Name" *doorBlockList*))))))
              )
            )
          )
          ;; Apaga as polilinhas
          (COMMAND-S "_.ERASE" lastEntity "")
        )
      )
      (IF sectionBlock
        (PROGN
          ;; Seleciona os itens copiados
          (IF (TBLOBJNAME "BLOCK" sectionName)
            (PROGN
              (COMMAND-S "_.COPYBASE" bottomLeft sectionBlock "")
              (COMMAND-S "_.-BEDIT" sectionName)
              (SETQ sectionBlock (SSGET "_A" (LIST (CONS 410 (GETVAR "CTAB")))))
              (IF sectionBlock
                (COMMAND-S "_.ERASE" sectionBlock "")
              )
              (COMMAND-S "_.PASTECLIP" (LIST 0.0 0.0))
            )
            (PROGN
              (COMMAND-S "_.-BLOCK" sectionName "_MODE" "_RETAIN" bottomLeft sectionBlock "")
              (COMMAND-S "_.-BEDIT" sectionName)
            )
          )
          ;; Define as coordenadas dos cantos
          (SETQ bottomLeft (LIST 0.0 0.0))
          (SETQ bottomRight (LIST sectionLength 0.0))
          (SETQ topLeft (LIST 0.0 *ceilingHeight*))
          (SETQ topRight (LIST sectionLength *ceilingHeight*))
          (IF (NOT (EQ sectionAngle 0.0))
            (COMMAND-S "_.ROTATE" "_ALL" "" bottomLeft (- (/ (* sectionAngle 180) PI)))
          )
          (COMMAND-S "_.ZOOM" (ATS:TranslatePoint bottomLeft (LIST (- (* 30 *unitsFactor*)) (- (* 30 *unitsFactor*)))) (ATS:TranslatePoint topRight (LIST (* 30 *unitsFactor*) (* 30 *unitsFactor*))))
          ;; Explode polilinhas
          (SETQ sectionBlock (SSGET "_A" (LIST (CONS 0 "*POLYLINE") (CONS 8 (ATS:EvaluateStringSymbolList *wallLayer*)) (CONS 410 (GETVAR "CTAB")))))
          (IF sectionBlock
            (PROGN
              (SETQ count (SSLENGTH sectionBlock))
              (REPEAT count
                (SETQ count (1- count))
                (COMMAND-S "_.EXPLODE" (SSNAME sectionBlock count))
              )
            )
          )
          ;; Posiciona as paredes do piso ao teto
          (SETQ sectionBlock (ATS:FilterLinesByAngle nil (/ PI 2) (/ PI 60) (SSGET "_C" bottomLeft bottomRight (LIST (CONS 0 "LINE") (CONS 8 (ATS:EvaluateStringSymbolList *wallLayer*))))))
          (IF sectionBlock
            (PROGN
              (SETQ count (SSLENGTH sectionBlock))
              (REPEAT count
                (SETQ count (1- count))
                (SETQ entity (ATS:GetPropertiesValues (LIST -1 10 11) (SSNAME sectionBlock count)))
                (ATS:ChangePropertiesValues (CAR entity) (LIST (CONS 10 (ATS:SubstituteItemByPosition 0.0 1 (CADR entity))) (CONS 11 (ATS:SubstituteItemByPosition *ceilingHeight* 1 (CADDR entity)))))
              )
            )
          )
          ;; Apaga as demais linhas de parede
          (SETQ sectionBlock (ATS:TrimSelectionSets (SSGET "_A" (LIST (CONS 0 "LINE") (CONS 8 (ATS:EvaluateStringSymbolList *wallLayer*)) (CONS 410 (GETVAR "CTAB")))) sectionBlock))
          (IF sectionBlock
            (COMMAND-S "_.ERASE" sectionBlock "")
          )
          ;; Converte os blocos para suas versões frontais e laterais, mantendo os valores das propriedades e atributos
          (SETQ sectionBlock (SSGET "_A" (LIST (CONS 0 "INSERT") (CONS 410 (GETVAR "CTAB")))))
          (IF sectionBlock
            (PROGN
              (SETQ count (SSLENGTH sectionBlock))
              (REPEAT count
                (SETQ count (1- count))
                (SETQ entity (SSNAME sectionBlock count))
                (SETQ blockObject (ATS:SaveObject entity))
                (SETQ blockAngle (ATS:GetPropertiesValues 50 entity))
                ;; Verifica a versão do bloco a ser inserida: 'frontal' (entre 45° e 135°, inclusive 45° e 135°, ou entre 215° e 315°, inclusive 215° e 315°) ou 'lateral'
                (SETQ blockName (ATS:GetEffectiveName blockObject))
                (SETQ blockName (STRCAT blockName *affixSeparator* (IF (ATS:XOR (LIST (OR (AND (>= blockAngle (/ PI 4)) (<= blockAngle (/ (* PI 3) 4))) (AND (>= blockAngle (/ (* PI 5) 4)) (<= blockAngle (/ (* PI 7) 4))))
                                                                                    (WCMATCH (STRCASE blockName) (STRCASE (STRCAT (ATS:GetPropertiesValues "Name" *windowBlockList*) "," (ATS:GetPropertiesValues "Name" *doorBlockList*))))))
                                                                     *frontViewSuffix*
                                                                     *sideViewSuffix*)))
                ;; Procura pela versão do bloco em vista
                (IF (ATS:InsertBlockFromSupportPaths blockName)
                  (PROGN
                    ;; Armazena o ponto base e os valores das propriedades dinâmicas
                    (SETQ basePoint (ATS:GetPropertiesValues 10 entity))
                    ;; Retira a visibilidade de identificações
                    (ATS:ChangeDynamicBlockPropertiesValues nil blockObject (LIST (CONS "Visibilidade Identificação" "Sem Identificação")))
                    ;; Verifica se o bloco está sendo cortado
                    (SETQ sectionedBlock (MINUSP (CADR (CAR (ATS:GetObjectBoundaries blockObject)))))
                    ;; Altera o bloco para sua versão em vista
                    (ATS:ChangePropertiesValues entity (LIST (CONS 2 blockName) (CONS 42 (ABS (ATS:GetPropertiesValues 42 entity))) (CONS 50 0.0)))
                    ;; Verifica se o bloco possui visibilidade em corte e, se ele estiver sendo cortado, modifica sua visibilidade
                    ; Admite-se que o padrão do bloco é "Em Projeção"
                    (IF sectionedBlock
                      (ATS:ChangeDynamicBlockPropertiesValues nil blockObject (LIST (CONS (ATS:GetPropertiesValues "Name" *sectionVisibilityProperty*) (ATS:GetPropertiesValues "Sectioned" *sectionVisibilityProperty*))))
                    )
                    ;; Reposiciona o bloco, caso as propriedades dinâmicas tenham deslocado o ponto base
                    (ATS:ChangePropertiesValues entity (LIST (LIST 10 (CAR basePoint) 0.0 0.0)))
                    ;; Verifica se o bloco está na vista lateral
                    (IF (WCMATCH (STRCASE blockName) (STRCASE (STRCAT "*" *affixSeparator* *sideViewSuffix*)))
                      ;; Corrige a escala no eixo X
                      (ATS:ChangePropertiesValues entity (LIST (CONS 41 (ABS (ATS:GetPropertiesValues 41 entity)))))
                    )
                    (IF (SETQ BlockForSection (ATS:FindBlockProperty "BlockForSection" (ATS:TrimSuffix blockName)))
                      (APPLY (FUNCTION BlockForSection) nil)
                    )
                    (COMMAND-S "_.ATTSYNC" "_NAME" (ATS:GetEffectiveName blockObject))
                  )
                  ;; Deleta o bloco, caso não tenha versão em vista
                  (ENTDEL entity)
                )
              )
            )
          )
          ;; Explode blocos na margem
          (SETQ sectionBlock (ATS:TrimSelectionSets (SSGET "_F" (LIST bottomLeft bottomRight topRight topLeft) (LIST (CONS 0 "INSERT"))) (SSGET "_W" bottomLeft topRight (LIST (CONS 0 "INSERT")))))
          (IF sectionBlock
            (PROGN
              (IF (EQ *CADSoftware* "AutoCAD")
                (PROGN
                  (SSSETFIRST nil sectionBlock)
                  (C:BURST)
                )
                (COMMAND-S "BURST" sectionBlock "")
              )
              (SETQ sectionBlock (SSGET "_A" (LIST (CONS 0 "*TEXT,WIPEOUT") (CONS 410 (GETVAR "CTAB")))))
              (IF sectionBlock
                (COMMAND-S "_.ERASE" sectionBlock "")
              )
            )
          )
          ;; Executa corte das extremidades
          (COMMAND-S "_.PLINE" bottomLeft bottomRight topRight topLeft "_CLOSE")
          (SETQ lastEntity (ENTLAST))
          (ATS:Extrim lastEntity (LIST (- *unitsFactor*) (- *unitsFactor*)))
          (ENTDEL lastEntity)
          ;; Apaga os demais elementos
          (COMMAND-S "_.ZOOM" bottomLeft topRight)
          (SETQ sectionBlock (ATS:TrimSelectionSets (SSGET "_A" (LIST (CONS 410 (GETVAR "CTAB")))) (SSGET "_C" bottomLeft topRight)))
          (IF sectionBlock
            (COMMAND-S "_.ERASE" sectionBlock "")
          )
          (ATS:RemoveDots nil)
          (COMMAND-S "_.-OVERKILL" "_ALL" "" "_DONE")
          ;; Cria a laje de teto
          (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" *breakLineBlockList*)))
          (COMMAND-S "_.-INSERT" (ATS:GetPropertiesValues "Name" *breakLineBlockList*) (LIST 0.0 (+ *ceilingHeight* (/ *slabThickness* 2))) (ATS:GetInsertionScale) "90")
          (COMMAND-S "_.COPY" "_LAST" "" bottomLeft bottomRight)
          (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *pen6*))
          (COMMAND-S "_.LINE" (LIST 0.0 *ceilingHeight*) (LIST sectionLength *ceilingHeight*) "")
          (COMMAND-S "_.COPY" "_LAST" "" bottomLeft (LIST 0.0 *slabThickness*))
          (ATS:MakeHatch (LIST (LIST (/ sectionLength 2) (+ *ceilingHeight* (/ *slabThickness* 2)))) *concreteHatchList*)
          ;; Cria a laje de piso
          (COMMAND-S "_.LINE" bottomLeft bottomRight "")
          ;; Ajusta a ordem dos layers e fecha o editor de blocos
          (ATS:SetDrawOrder T T)
          (COMMAND-S "_.BCLOSE" "_SAVE")
        )
        (PROMPT "\nNenhum elemento encontrado.\n")
      )
      (ATS:RestoreUsersPreferences commandName nil)
      (IF (AND (TBLOBJNAME "BLOCK" sectionName) (NOT (SSGET "_X" (LIST (CONS 2 sectionName)))))
        (COMMAND-S "_.-INSERT" sectionName "_SCALE" 1.0 "_ROTATE" 0.0)
      )
    )
  )
)
