;| Exclui layouts vazios
   @global
   @returns [nil] - Exclui os layouts vazios
   |;
(DEFUN ATS:DeleteEmptyLayouts (/ layoutName)
  (VLAX-FOR layout (ATS:SaveObject (VLA-GET-LAYOUTS *activeDocument*))
    (ATS:SaveObject layout)
    (SETQ layoutName (VLA-GET-NAME layout))
    (COND
      ((EQ layoutName "Model"))
      ((SSGET "_A" (LIST (CONS 410 layoutName) (CONS -4 "<NOT") (CONS 69 1) (CONS -4 "NOT>"))))
      ((NOT (EQ (LENGTH (LAYOUTLIST)) 1))
       (IF (EQ layoutName (GETVAR "CTAB"))
         (COMMAND-S "_.-LAYOUT" "_SET" "Model"))
       (VLA-DELETE layout))
    )
  )
  (IF (AND (EQ (LENGTH (SETQ layoutName (LAYOUTLIST))) 1) (WCMATCH (SETQ layoutName (CAR layoutName)) "Layout[1-99]"))
    (COMMAND-S "_.-LAYOUT" "_RENAME" layoutName "Layout")
  )
)

;| Exclui layouts restantes, exceto o atual
   @global
   @returns [nil] - Exclui os layouts restantes
   |;
(DEFUN ATS:DeleteRemainingLayouts (/ layoutName)
  (VLAX-FOR layout (ATS:SaveObject (VLA-GET-LAYOUTS *activeDocument*))
    (ATS:SaveObject layout)
    (SETQ layoutName (VLA-GET-NAME layout))
    (COND
      ((EQ layoutName (GETVAR "CTAB")))
      ((EQ layoutName "Model"))
      ((EQ (LENGTH (LAYOUTLIST)) 1) (COMMAND-S "_.-LAYOUT" "_RENAME" layoutName "Layout1"))
      ((VLA-DELETE layout))
    )
  )
)

;| Seleciona folhas
   @global
   @param selection [ss/str/lst] - Seleção de folhas ou método de seleção
   @returns [ss] - Seleção de folhas
   |;
(DEFUN ATS:SelectSheets (selection)
  (IF (OR (ATS:VerifySelectionSets selection)
          (SETQ selection (APPLY (FUNCTION SSGET) ((IF (LISTP selection) APPEND CONS) selection (LIST (LIST (CONS 0 "INSERT") (CONS 410 (GETVAR "CTAB"))))))))
    (COND
      ;; Procura pelos blocos com o nome padrão sem prefixo
      ((ATS:FilterSelection nil T selection (LIST (CONS 2 (STRCAT "*" (VL-STRING-SUBST "" (STRCAT *standardPrefix* *affixSeparator*) (ATS:GetPropertiesValues "Name" *titleBlockBlockList*)) "*")))))
      ;; Se não encontrar, procura pelos blocos com o nome do tamanho da folha
      ((ATS:FilterSelection nil T selection (LIST (CONS 2 "A[0-5]*,*.A[0-5]*"))))
    )
  )
)

;| Seleciona viewports
   @global
   @param selectionMethod [str/lst] - Método de seleção
   @returns [ss] - Seleção de viewports
   |;
(DEFUN ATS:SelectViewports (selectionMethod)
  (APPLY (FUNCTION SSGET) ((IF (LISTP selectionMethod) APPEND CONS) selectionMethod (LIST (LIST (CONS 0 "VIEWPORT") (CONS -4 "<NOT") (CONS 69 1) (CONS -4 "NOT>") (CONS 8 (ATS:EvaluateStringSymbolList *viewportLayer*)) (CONS 410 (GETVAR "CTAB"))))))
)

;| Obtém o contorno de uma folha
   @global
   @param sheetEntityName [ename] - Nome da entidade da folha
   @returns [lst] - Lista com os pontos mínimo e máximo
   |;
(DEFUN ATS:GetSheetBoundaries (sheetEntityName / bottom top xBottom yBottom xTop yTop)
  (SETQ bottom (ATS:GetPropertiesValues 10 sheetEntityName))
  (SETQ top (CDR (ASSOC (ATS:GetSheetSize sheetEntityName) *sheetsSizes*)))
  (SETQ top (IF top
              (ATS:TranslatePoint bottom (MAPCAR (FUNCTION *) top (LIST (ATS:GetPropertiesValues 41 sheetEntityName) (ATS:GetPropertiesValues 42 sheetEntityName))))
              ;; Dá um zoom out desproprocional para tentar selecionar o canto da folha com 'OSNAP', tentando evitar elementos circundantes
              (PROGN
                (SETQ top (ATS:GetObjectBoundaries (ATS:SaveObject sheetEntityName)))
                (SETQ xBottom (CAR (CAR top)))
                (SETQ yBottom (CADR (CAR top)))
                (SETQ xTop (CAR (CADR top)))
                (SETQ yTop (CADR (CADR top)))
                (COMMAND-S "_.ZOOM" (LIST (- xBottom (* *paperUnitsFactor* 300)) (- yBottom (* *paperUnitsFactor* 300))) (LIST (+ xTop (* *paperUnitsFactor* 300)) (+ yTop (* *paperUnitsFactor* 300))))
                (OSNAP (LIST (IF (> (ABS (- xTop (CAR bottom))) (ABS (- xBottom (CAR bottom)))) xTop xBottom) (IF (> (ABS (- yTop (CADR bottom))) (ABS (- yBottom (CADR bottom)))) yTop yBottom)) "_END"))))
  (LIST bottom top)
)

;| Converte um ponto do espaço papel para o espaço modelo com base em uma viewport
   @global
   @param pointsList [lst] - Lista de pontos
   @param entityName [ename] - Nome da entidade da viewport
   @returns [ss] - Seleção de viewports
   |;
(DEFUN ATS:TranslatePaperPoints (pointsList entityName / viewportAngle normal scale newPoint)
  (SETQ viewportAngle (- (ATS:GetPropertiesValues 51 entityName)))
  (SETQ normal (ATS:GetPropertiesValues 16 entityName))
  (SETQ scale (/ (ATS:GetPropertiesValues 45 entityName) (ATS:GetPropertiesValues 41 entityName)))
  (FOREACH point pointsList
    (SETQ newPoint (TRANS (MAPCAR (FUNCTION +) (MAPCAR (FUNCTION (LAMBDA (r) (APPLY (FUNCTION +) (MAPCAR (FUNCTION *) r (MAPCAR (FUNCTION +) (MAPCAR (FUNCTION (LAMBDA (n) (* n scale))) (TRANS point 0 0)) (MAPCAR (FUNCTION (LAMBDA (n) (* n (- scale)))) (ATS:GetPropertiesValues 10 entityName)) (ATS:GetPropertiesValues 12 entityName)))))) ((LAMBDA (a) (MAPCAR (FUNCTION (LAMBDA (r2) (MAPCAR (FUNCTION (LAMBDA (r) (APPLY (FUNCTION +) (MAPCAR (FUNCTION *) r r2)))) a))) (MAPCAR (FUNCTION (LAMBDA (v) (TRANS v 0 normal T))) (LIST (LIST 1.0 0.0 0.0) (LIST 0.0 1.0 0.0) (LIST 0.0 0.0 1.0))))) (APPLY (FUNCTION MAPCAR) (CONS (QUOTE LIST) (LIST (LIST (COS viewportAngle) (- (SIN viewportAngle)) 0.0) (LIST (SIN viewportAngle) (COS viewportAngle) 0.0) (LIST 0.0 0.0 1.0)))))) (ATS:GetPropertiesValues 17 entityName)) 0 normal))
    (SETQ pointsList (SUBST (LIST (CAR newPoint) (CADR newPoint)) point pointsList))
  )
)

;| Seleciona a tabela de revisões
   @global
   @param sheetEntityName [ename] - Nome da entidade da folha
   @returns [ename] - Nome da entidade da tabela
   |;
(DEFUN ATS:SelectRevisionTable (sheetEntityName / bottom top revisionTable)
  (SETQ bottom (ATS:TranslatePoint (ATS:GetPropertiesValues 10 sheetEntityName) (LIST -13 73)))
  (SETQ top (ATS:TranslatePoint bottom (LIST -169 1.5)))
  (COMMAND-S "_.ZOOM" bottom top)
  (SETQ revisionTable (SSGET "_C" bottom top (LIST (CONS 0 "ACAD_TABLE"))))
  (IF revisionTable
    (SSNAME revisionTable 0)
  )
)

;| Seleciona os títulos dentro de uma folha
   @global
   @param sheetEntityName [ename] - Nome da entidade da folha
   @returns [lst] - Lista dos títulos contidos na folha
   |;
(DEFUN ATS:GetDrawingsTitles (sheetEntityName / titleBlockName titleAttributeName boundaries selection count entityName currentTab currentView titlesList)
  (DEFUN GetDrawingsTitles (boundary / selection count entityName)
    (SETQ selection (SSGET "_C" (CAR boundary) (CADR boundary) (LIST (CONS 0 "INSERT"))))
    (IF (AND selection (SETQ selection (ATS:FilterSelection nil nil selection (LIST (CONS 2 titleBlockName)))))
      (PROGN
        (SETQ count (SSLENGTH selection))
        (REPEAT count
          (SETQ count (1- count))
          (SETQ entityName (SSNAME selection count))
          (COMMAND-S "_.ATTSYNC" "_SELECT" entityName "_YES")
          (SETQ titlesList (CONS (ATS:GetAttributeProperties nil 1 entityName (LIST (CONS 2 titleAttributeName))) titlesList))
        )
      )
    )
  )
  (SETQ titleBlockName (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Name" *titleBlockList*)))
  (SETQ titleAttributeName (ATS:GetPropertiesValues "TitleAttributeName" *titleBlockList*))
  (SETQ boundaries (ATS:GetSheetBoundaries sheetEntityName))
  (APPLY (FUNCTION COMMAND-S) (CONS "_.ZOOM" boundaries))
  (IF (AND (EQ (GETVAR "CVPORT") 1)
           (SETQ selection (ATS:SelectViewports (CONS "_C" boundaries))))
    (PROGN
      (GetDrawingsTitles boundaries)
      (SETQ boundaries nil)
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityName (SSNAME selection count))
        (SETQ boundaries (CONS (ATS:TranslatePaperPoints (ATS:GetObjectBoundaries (ATS:SaveObject entityName)) entityName) boundaries))
      )
      (SETQ currentTab (GETVAR "CTAB"))
      (SETVAR "CTAB" "Model")
      (SETQ currentView (ATS:GetViewExtents))
    )
    (SETQ boundaries (LIST boundaries))
  )
  (FOREACH boundary boundaries
    (APPLY (FUNCTION COMMAND-S) (CONS "_.ZOOM" boundary))
    (GetDrawingsTitles boundary)
  )
  (IF (AND currentTab currentView)
    (PROGN
      (APPLY (FUNCTION COMMAND-S) (CONS "_.ZOOM" currentView))
      (SETVAR "CTAB" currentTab)
    )
  )
  titlesList
)

;| Deduz o tamanho da folha pelas dimensões
   @global
   @param bottom [lst] - Coordenadas do fundo da folha
   @param top [lst] - Coordenadas do topo da folha
   @returns [str] - Tamanho da folha
   |;
(DEFUN ATS:PredictSheetSize (bottom top / sheetDimensions)
  (SETQ sheetDimensions (MAPCAR (FUNCTION ABS) (ATS:GetSublist 0 2 (MAPCAR (FUNCTION -) top bottom))))
  (COND
    ;; Compara o tamanho com os tamanhos listados na lista de folhas
    ((VL-SOME (FUNCTION (LAMBDA (listedSheetSize / listedDimensions)
                          (SETQ listedDimensions (MAPCAR (FUNCTION ABS) (CDR listedSheetSize)))
                          (IF (OR 
                                (EQUAL sheetDimensions listedDimensions *minimalFuzz*)
                                (EQUAL sheetDimensions (MAPCAR (FUNCTION (LAMBDA (dimension) (* dimension *paperUnitsFactor*))) listedDimensions) *minimalFuzz*))
                            (CAR listedSheetSize)))) *sheetsSizes*))
    ;; Se não encontrar, busca pela equivalência de propoções, caso as dimensões estejam apenas escaladas
    ; Obs: As proporções da A2 e A4, na mesma orientação, são as mesmas e podem ser confundidas
    ((SETQ sheetDimensions (APPLY (FUNCTION /) sheetDimensions))
     (VL-SOME (FUNCTION (LAMBDA (listedSheetSize)
                          (IF (EQUAL sheetDimensions (ABS (APPLY (FUNCTION /) (CDR listedSheetSize))) *minimalFuzz*)
                            (CAR listedSheetSize)))) *sheetsSizes*))
  )
)

;| Obtém o tamanho da folha
   @global
   @param sheetEntityName [ename] - Nome da entidade da folha
   @returns [str] - Tamanho da folha
   |;
(DEFUN ATS:GetSheetSize (sheetEntityName / sheetObject sheetSize)
  (SETQ sheetObject (ATS:SaveObject sheetEntityName))
  (COND
    ;; Verifica se a folha possui a propriedade dinâmica com o tamanho
    ((ATS:GetDynamicBlockProperties nil nil sheetObject (ATS:GetPropertiesValues "SizePropertyName" *titleBlockBlockList*)))
    ;; Se não possuir, verifica se algum bloco no ponto de inserção possui o tamanho da folha no nome
    ((PROGN
       (SETQ sheetSize (ATS:GetPropertiesValues 10 sheetEntityName))
       (COMMAND-S "_.ZOOM" (ATS:TranslatePoint sheetSize (LIST (- *paperUnitsFactor*) (- *paperUnitsFactor*))) (ATS:TranslatePoint sheetSize (LIST *paperUnitsFactor* *paperUnitsFactor*)))
       (IF (SETQ sheetSize (ATS:FilterSelection nil T (SSGET "_C" sheetSize sheetSize (LIST (CONS 0 "INSERT"))) (LIST (CONS 2 "*A#*"))))
         (SETQ sheetObject (ATS:SaveObject (SSNAME sheetSize 0)))
       )
       (SETQ sheetSize (STRCASE (ATS:GetEffectiveName sheetObject)))
       (VL-SOME (FUNCTION (LAMBDA (listedSheetSize)
                            (IF (WCMATCH sheetSize (STRCASE (STRCAT listedSheetSize ",*." listedSheetSize "," listedSheetSize ".*,*." listedSheetSize ".*")))
                              listedSheetSize))) (MAPCAR (FUNCTION CAR) *sheetsSizes*))))
    ;; Se não possuir, verifica o tamanho da folha de acordo com a proporção do seu tamanho
    ((APPLY (FUNCTION ATS:PredictSheetSize) (ATS:GetObjectBoundaries sheetObject)))
    ;; Se não encontrar, retorna o nome da folha como está
    (sheetSize)
  )
)

;| Preenche os dados das folhas
   @global
   @returns nil
   |;
(DEFUN ATS:FillSheetsInfo (/ *error* projectIdentification projectName client selection count entityname)
  (COND
    ((NOT (SETQ selection (ATS:SelectSheets "_A"))) (PROMPT "\nNenhuma folha foi identificada.\n"))
    (T
      (ATS:SaveUsersPreferences 8)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ projectIdentification (ATS:GetSubstring "" *fileSeparator* (GETVAR "DWGNAME")))
      (SETQ projectName (GETVAR "DWGPREFIX"))
      (SETQ client (ATS:GetSubstring (ATS:EvaluateStringSymbolList *customersFolder*) "\\" projectName))
      (IF (AND client (SETQ client (ATS:GetSubstring " - " "" client)))
        (SETQ client (STRCASE client))
      )
      (SETQ projectName (ATS:GetSubstring " - " "" (VL-FILENAME-BASE (VL-STRING-RIGHT-TRIM "\\" projectName))))
      (IF projectName
        (SETQ projectName (STRCASE projectName))
      )
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityname (SSNAME selection count))
        (IF projectIdentification
          (ATS:EditBlockAttributes nil entityname (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectIdentificationAttributeName" *titleBlockBlockList*))) (LIST (CONS 1 projectIdentification)))
        )
        (IF projectName
          (ATS:EditBlockAttributes nil entityname (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectNameAttributeName" *titleBlockBlockList*))) (LIST (CONS 1 projectName)))
        )
        (IF client
          (ATS:EditBlockAttributes nil entityname (LIST (CONS 2 (ATS:GetPropertiesValues "ClientAttributeName" *titleBlockBlockList*))) (LIST (CONS 1 client)))
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Preenche o conteúdo das folhas
   @global
   @returns nil
   |;
(DEFUN ATS:FillSheetsContent (/ *error* selection count entityName titlesList)
  (COND
    ;; Seleciona as folhas
    ((NOT (OR (SETQ selection (ATS:SelectSheets "_I"))
              (SETQ selection (ATS:SelectSheets (IF (EQ (ATS:GetKeyword "Sim" (LIST "Sim" "Não") "\nDeseja preencher o conteúdo de todas as folhas do layout?\n") "Sim") "_A"))))) (PROMPT "\nNenhuma folha foi selecionada.\n"))
    (T
      (ATS:SaveUsersPreferences 26)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (PROGN(SETQ count (1- count))
        (SETQ entityName (SSNAME selection count))
        (SETQ titlesList (ATS:GetDrawingsTitles entityName)))
        (progn (ATS:EditBlockAttributes nil entityName (LIST (CONS 2 (ATS:GetPropertiesValues "ContentAttributeName" *titleBlockBlockList*))) (LIST (CONS 1 (ATS:ListToString "\\P" titlesList))))
        (SETQ titlesList (VL-SOME (FUNCTION (LAMBDA (projectType) (IF (VL-SOME (FUNCTION (LAMBDA (title) (WCMATCH (STRCASE title) (STRCAT "*" (STRCASE projectType) "*")))) titlesList) projectType))) (MAPCAR (FUNCTION CAR) *projectTypes*)))
        (IF titlesList
          (ATS:EditBlockAttributes nil entityName (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectTypeAttributeName" *titleBlockBlockList*))) (LIST (CONS 1 titlesList)))
        ))
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Ajusta o controle de revisões das folhas
   @global
   @returns nil
   |;
(DEFUN ATS:UpdateSheetsRevision (/ *error* revisionChange selection revisionDescription revisionAttribute dateAttribute sheetNotesAttribute currentDate responsible count sheetEntityName revisionNumber row rowHeight sheetObject)
  (COND
    ((NOT (SETQ revisionChange (ATS:GetKeyword "Subir" (LIST "Subir" "Atualizar") "\nDeseja subir ou atualizar a revisão das folhas?\n"))))
    ((PROGN
      (IF (AND (SETQ selection (SSGET "_A" (LIST (CONS 0 "ACAD_TABLE") (CONS 410 (GETVAR "CTAB")))))
               (VL-SOME (FUNCTION (LAMBDA (table) (EQ (VLA-GET-STYLENAME (ATS:SaveObject table)) *revisionTableStyle*))) (ATS:GetSelectionProperties -1 selection)))
        (SETQ revisionDescription (GETSTRING T "\nInsira a descrição da revisão:\n"))
      )
      (NOT (OR (SETQ selection (ATS:SelectSheets "_I"))
               (SETQ selection (ATS:SelectSheets (IF (EQ (ATS:GetKeyword "Sim" (LIST "Sim" "Não") (STRCAT "\nDeseja " (STRCASE revisionChange T) " a revisão de todas as folhas do layout?\n")) "Sim") "_A")))))) (PROMPT "\nNenhuma folha foi selecionada.\n"))
    (T
      (ATS:SaveUsersPreferences 26)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ revisionAttribute (ATS:GetPropertiesValues "RevisionAttributeName" *titleBlockBlockList*))
      (SETQ dateAttribute (ATS:GetPropertiesValues "DateAttributeName" *titleBlockBlockList*))
      (SETQ sheetNotesAttribute (ATS:GetPropertiesValues "SheetNotesDistancePropertyName" *titleBlockBlockList*))
      (SETQ currentDate (ATS:WriteCurrentDate nil nil))
      (SETQ responsible (STRCASE (ATS:WriteShortenedName *loginName*)))
      (SETQ count (SSLENGTH selection))
      (IF (EQ revisionChange "Subir")
        (REPEAT count
          (SETQ count (1- count))
          (SETQ sheetEntityName (SSNAME selection count))
          ;; Sobe o número da revisão na folha e atualiza a data
          (SETQ revisionNumber (ATS:SearchAttribute nil sheetEntityName (LIST (CONS 2 revisionAttribute))))
          (ATS:ChangePropertiesValues revisionNumber (LIST (CONS 1 (SETQ revisionNumber (ATS:AddLeftZeros 2 (ITOA (1+ (ATOI (ATS:GetPropertiesValues 1 revisionNumber)))))))))
          (ATS:EditBlockAttributes nil sheetEntityName (LIST (CONS 2 dateAttribute)) (LIST (CONS 1 currentDate)))
          ;; Faz o mesmo para a tabela, e também acrescenta a descrição e responsável pela revisão
          (IF (SETQ revisionTable (ATS:SaveObject (ATS:SelectRevisionTable sheetEntityName)))
            (PROGN
              (SETQ row (VLA-GET-ROWS revisionTable))
              (SETQ rowHeight (VLA-GETROWHEIGHT revisionTable (1- row)))
              ;; Move os elementos acima da tabela
              (IF sheetNotesAttribute
                (PROGN
                  (SETQ sheetObject (ATS:SaveObject sheetEntityName))
                  (ATS:ChangeDynamicBlockPropertiesValues nil sheetObject (LIST (CONS sheetNotesAttribute (+ (ATS:GetDynamicBlockProperties nil nil sheetObject sheetNotesAttribute) rowHeight))))
                )
              )
              ;; Insere a linha e preenche seu conteúdo
              (VLA-INSERTROWS revisionTable row rowHeight 1)
              (VLA-SETTEXT revisionTable row 0 revisionNumber)
              (VLA-SETTEXT revisionTable row 1 revisionDescription)
              (VLA-SETTEXT revisionTable row 2 currentDate)
              (VLA-SETTEXT revisionTable row 4 responsible)
            )
          )
        )
        (REPEAT count
          (SETQ count (1- count))
          (SETQ sheetEntityName (SSNAME selection count))
          ;; Atualiza a data na folha
          (ATS:EditBlockAttributes nil sheetEntityName (LIST (CONS 2 dateAttribute)) (LIST (CONS 1 currentDate)))
          ;; Faz o mesmo para a tabela, e também acrescenta a descrição e responsável pela revisão
          (IF (SETQ revisionTable (ATS:SaveObject (ATS:SelectRevisionTable sheetEntityName)))
            (PROGN
              (SETQ row (1- (VLA-GET-ROWS revisionTable)))
              (IF (> (STRLEN revisionDescription) 0)
                (VLA-SETTEXT revisionTable row 1 revisionDescription)
              )
              (VLA-SETTEXT revisionTable row 2 currentDate)
              (VLA-SETTEXT revisionTable row 4 responsible)
            )
          )
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Renumera folhas
   @global
   @returns nil
   |;
(DEFUN ATS:RenumberSheets (/ *error* selection selectionMethod count sheetNumberTotalDigits sheetNumberSuffix)
  (COND
    ;; Seleciona as folhas
    ((NOT (OR (SETQ selection (ATS:SelectSheets "_I"))
              (PROGN
                (SETQ selectionMethod (IF (EQ (ATS:GetKeyword "Sim" (LIST "Sim" "Não") "\nDeseja renumerar todas as folhas do layout?\n") "Sim") "_A"))
                (SETQ selection (ATS:SelectSheets selectionMethod))))) (PROMPT "\nNenhuma folha foi selecionada.\n"))
    ;; Define o número total de folhas
    ((NOT (PROGN
            (SETQ count (SSLENGTH selection))
            (SETQ sheetNumberTotalDigits (MAX (STRLEN (ITOA count)) *minimalSheetNumberTotalDigits*))
            (SETQ sheetNumberSuffix (IF *totalSheetNumberSeparator*
                                      (STRCAT *totalSheetNumberSeparator* (ATS:AddLeftZeros sheetNumberTotalDigits (IF (AND (OR (NOT selectionMethod) (> (LENGTH (LAYOUTLIST)) 1)) (EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nDeseja inserir o número total de folhas?\n") "Sim"))
                                                                                                                     (PROGN (INITGET 7) (ITOA (GETINT "\nInsira o número total de folhas:\n")))
                                                                                                                     (ITOA count)))) "")))))
    (T
      (ATS:SaveUsersPreferences 8)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      ;; Altera a numeração das folhas
      (FOREACH sheet (REVERSE (ATS:SortSelectionByPosition (* *paperUnitsFactor* 0.15) selection))
        (ATS:EditBlockAttributes nil sheet (LIST (CONS 2 (ATS:GetPropertiesValues "SheetNumberAttributeName" *titleBlockBlockList*))) (LIST (CONS 1 (STRCAT (ATS:AddLeftZeros sheetNumberTotalDigits (ITOA count)) sheetNumberSuffix))))
        (SETQ count (1- count))
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Procura pelo método de nomeação de folha de um carimbo na lista de carimbos
   @global
   @param sheetObject [obj] - Objeto da folha
   @returns [subr] - Função de nomeação de folha
   |;
(DEFUN ATS:FindMakeSheetMethod (sheetObject)
  (IF (AND
        (SETQ sheetObject (ATS:GetEffectiveName sheetObject))
        (SETQ sheetObject (VL-SOME (FUNCTION (LAMBDA (titleBlock)
                                               (SETQ titleBlock (EVAL titleBlock))
                                               (IF (EQ sheetObject (ATS:GetPropertiesValues "Name" titleBlock))
                                                 titleBlock))) *titleBlocksList*)))
    (ATS:GetPropertiesValues "NameSheet" sheetObject)
  )
)

;| Obtém o nome da folha
   @global
   @param sheetEntityName [ename] - Nome da entidade da folha
   @returns [str] - Nome da folha
   |;
(DEFUN ATS:GetSheetName (sheetEntityName / sheetObject method)
  (SETQ sheetObject (ATS:SaveObject sheetEntityName))
  (SETQ method (ATS:FindMakeSheetMethod sheetObject))
  ;; Caso não encontre o método de nomeação de folha, procura pelo carimbo
  (IF (AND
        (NOT method)
        (NOT (ATS:SaveBoundaries (ATS:GetObjectBoundaries sheetObject)))
        (SETQ xBottom (ATS:TranslatePoint (LIST xTop yBottom) (LIST (* *paperUnitsFactor* -1.5) (* *paperUnitsFactor* 1.5))))
        (SETQ xBottom (SSGET "_C" xBottom (ATS:TranslatePoint xBottom (LIST (* *paperUnitsFactor* -3.0) (* *paperUnitsFactor* 3.0))) (LIST (CONS 0 "INSERT")))))
    (PROGN
      (SETQ sheetEntityName (SSNAME xBottom 0))
      (SETQ method (ATS:FindMakeSheetMethod (ATS:SaveObject sheetEntityName)))
    )
  )
  ;; Retorna o nome através do método de nomeação de folha ou solicita ao usuário
  (IF method
    (APPLY (FUNCTION method) (LIST sheetEntityName))
    (PROGN
      (COMMAND-S "_.ZOOM" bottom top)
      (ATS:ClearBoundaries)
      (GETSTRING T "\nInsira o nome desta folha, ou 'Enter' para ignorar:\n")
    )
  )
)

;| Obtém o caminho da pasta de emissão
   @global
   @param projectPhase [str] - Fase do projeto
   @param revisionNumber [str] - Número da revisão
   @returns [str] - Caminho da pasta de emissão
   |;
(DEFUN ATS:GetEmissionFolder (projectPhase revisionNumber)
  (SETQ projectPhase (ASSOC projectPhase *projectPhases*))
  (IF projectPhase
    (PROGN
      (SETQ projectPhase (STRCAT (GETVAR "DWGPREFIX") (CADR *emissionFolderName*) (ATS:GetPropertiesValues "ProjectPhaseFolderName" (CDR projectPhase))))
      (VL-MKDIR projectPhase)
      (SETQ projectPhase (STRCAT projectPhase (IF (EQ revisionNumber "00")
                                                "Emissão Inicial"
                                                (STRCAT "Revisão " revisionNumber)) "\\"))
      (VL-MKDIR projectPhase)
      projectPhase
    )
  )
)

;| Plota uma folha
   @global
   @param plotter [str] - Nome da plotadora
   @param plotStyle [str] - Nome do estilo de plotagem
   @param savePath [str] - Caminho para salvar o arquivo, ou 'nil' para apenas aplicar as configurações ao layout
   @param sheetEntityName [ename/lst] - Nome da entidade da folha, ou uma lista com: nome do tamanho, coordenadas do contorno e nome da folha
   @returns [nil] - Plota a folha
   |;
(DEFUN ATS:PlotSheet (plotter plotStyle savePath sheetEntityName / sheetSize bottom top sheetName sheetOrientation)
  (IF (EQ (TYPE sheetEntityName) (READ "ENAME"))
    (PROGN
      (SETQ sheetSize (ATS:GetSheetSize sheetEntityName))
      (SETQ bottom (ATS:GetSheetBoundaries sheetEntityName))
      (SETQ top (CADR bottom))
      (SETQ bottom (CAR bottom))
      (SETQ sheetName (ATS:GetSheetName sheetEntityName))
    )
    (AND
      (SETQ sheetSize (CAR sheetEntityName))
      (SETQ bottom (CADR sheetEntityName))
      (SETQ top (CADDR sheetEntityName))
      (SETQ sheetName (COND ((CADDDR sheetEntityName)) ("ATS")))
    )
  )
  (IF sheetName
    (PROGN
      (SETQ sheetOrientation (IF (> (ABS (APPLY (FUNCTION /) (ATS:GetSublist 0 2 (MAPCAR (FUNCTION -) top bottom)))) 1)
                              "_LANDSCAPE"
                              "_PORTRAIT"))
      (COMMAND "_.-PLOT" "_YES" (GETVAR "CTAB") plotter sheetSize "_MILLIMETERS" sheetOrientation "_NO" "_WINDOW" bottom top "_FIT" "_CENTER" "_YES" plotStyle "_YES")
      (IF (EQ (GETVAR "CTAB") "Model")
        (COMMAND "_AS")
        (COMMAND "_NO" "_YES" "_NO")
      )
      (IF savePath
        (COMMAND (STRCAT savePath sheetName) "_YES" "_YES")
        (COMMAND (STRCAT (GETVAR "DWGPREFIX") sheetName) "_YES" "_NO")
      )
    )
    (PROMPT "\nNão foi possível concluir a plotagem.\n")
  )
)

;| Gera uma viewport, ou altera a camada atual ou do objeto selecionado
   @returns nil
   |;
(DEFUN C:VV ()
  (ATS:WriteLog "VV" nil)
  (IF (SETQ selection (SSGET "_I"))
    (PROGN
      (SSSETFIRST nil nil)
      (ATS:ChangeSelectionProperties selection (LIST (CONS 8 (ATS:EvaluateStringSymbolList *viewportLayer*))))
    )
    (PROGN
      (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *viewportLayer*))
      (IF (NOT (EQ (GETVAR "CTAB") "Model"))
        (COMMAND-S "_.-VPORTS")
      )
    )
  )
)

;| Transfere objetos do layout para o modelo
   @returns nil
   |;
(DEFUN C:LF (/ *error* commandName selection)
  (SETQ commandName "LF")
  (COND
    ((EQ (GETVAR "CTAB") "Model") (PROMPT "\nO comando não pode ser utilizado no Model.\n"))
    (T
      (PROGN
        (PROMPT "\nAtenção! O comando pode não enviar os objetos para a viewport desejada. Garanta que ela esteja visível na tela. Em caso de problema, entra e saia da viewport antes de executar o comando.\n")
        (SETQ selection (SSGET))
        (ATS:SaveUsersPreferences nil)
        (DEFUN *error* (errorMessage)
          (ATS:RestoreUsersPreferences commandName errorMessage)
        )
        (COMMAND-S "_.CHSPACE" selection "" "") 
        (COMMAND-S "_.PSPACE")
        (ATS:RestoreUsersPreferences commandName nil)
      )
    )
  )
)

;| Transfere objetos do modelo para o layout
   @returns nil
   |;
(DEFUN C:TF (/ *error* commandName selection)
  (SETQ commandName "TF")
  (COND
    ((EQ (GETVAR "CTAB") "Model") (PROMPT "\nO comando não pode ser utilizado no Model.\n"))
    ((EQ (GETVAR "CVPORT") 1) (PROMPT "\nO comando deve ser utilizado com uma viewport aberta.\n"))
    (T
      (PROGN
        (SETQ selection (SSGET))
        (ATS:SaveUsersPreferences nil)
        (DEFUN *error* (errorMessage)
          (ATS:RestoreUsersPreferences commandName errorMessage)
        )
        (COMMAND-S "_.CHSPACE" selection "" "") 
        (COMMAND-S "_.MSPACE")
        (ATS:RestoreUsersPreferences commandName nil)
      )
    )
  )
)

;| Altera automaticamente informações de folhas
   @returns nil
   |;
(DEFUN C:FF (/ commandName)
  (SETQ commandName "FF")
  (SETQ selection (ATS:GetKeyword "Revisão" (LIST "Informações" "Conteúdo" "Revisão" "Numeração") "\nEscolha o que deseja alterar nas folhas:\n"))
  (COND
    ((EQ selection "Informações")
      (ATS:FillSheetsInfo)
    )
    ((EQ selection "Conteúdo")
      (ATS:FillSheetsContent)
    )
    ((EQ selection "Revisão")
      (ATS:UpdateSheetsRevision)
    )
    ((EQ selection "Numeração")
      (ATS:RenumberSheets)
    )
  )
)

;| Gera PDF das folhas
   @returns nil
   |;
(DEFUN C:PDF (/ *error* commandName savePath selection sheetEntityName count sheetObject bottom top xBottom yBottom xTop yTop sheetName)
  (SETQ commandName "PDF")
  (COND
    ((NOT (OR (AND (SETQ selection (SSGET "_I")) (SETQ selection (ATS:SelectSheets selection))) (PROGN (SSSETFIRST nil nil) (SETQ selection (ATS:SelectSheets (IF (EQ (ATS:GetKeyword "Sim" (LIST "Sim" "Não") "\nDeseja gerar PDF de todas as folhas do layout?\n") "Sim") "_A")))))) (PROMPT "\nNenhuma folha foi selecionada.\n"))
    ;; Verifica se a pasta de emissão existe e pergunta se deseja salvar nela
    ((NOT (IF (AND (VL-FILE-DIRECTORY-P (STRCAT (SETQ savePath (GETVAR "DWGPREFIX")) (CADR *emissionFolderName*))) (EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nDeseja salvar na pasta de emissão?\n") "Sim"))
            (PROGN
              (SETQ sheetEntityName (SSNAME selection 0))
              (SETQ savePath (ATS:GetEmissionFolder (ATS:GetAttributeProperties nil 1 sheetEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectPhaseAttributeName" *titleBlockBlockList*)))) (ATS:GetAttributeProperties nil 1 sheetEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "RevisionAttributeName" *titleBlockBlockList*))))))
            )
            ;; Escolhe a pasta para salvar os arquivos, ou salva no diretório do arquivo
            (IF (EQ (ATS:GetKeyword "Não" (LIST "Sim" "Não") "\nDeseja escolher onde salvar os arquivos gerados?\n") "Sim")
              (SETQ savePath (ATS:BrowseForFolder "Escolha a pasta" 16 nil))
              savePath))) (PROMPT "\nNenhuma pasta foi selecionada.\n"))
    (T
      (ATS:SaveUsersPreferences 27)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ sheetEntityName (SSNAME selection count))
        (ATS:PlotSheet *standardPlotter* *standardPlotStyle* savePath sheetEntityName)
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Gera PDF das folhas a partir de uma janela
   @returns nil
   |;
(DEFUN C:PDFW (/ *error* commandName bottom top sheetName savePath)
  (SETQ commandName "PDFW")
  (COND
    ((NOT (PROGN (INITGET 1) (SETQ bottom (GETPOINT "\nClique em um canto da folha.\n")))) (PROMPT "\nNenhum ponto foi selecionado.\n"))
    ((NOT (PROGN (INITGET 1) (SETQ top (GETCORNER bottom "\nClique no canto oposto da folha.\n")))) (PROMPT "\nNenhum contorno foi selecionado.\n"))
    ((NOT (PROGN (INITGET 1) (SETQ sheetName (GETSTRING T "\nInsira o nome da folha:\n")))) (PROMPT "\nNenhum nome foi introduzido.\n"))
    ((NOT (SETQ savePath (ATS:BrowseForFolder "Escolha a pasta" 16 nil))) (PROMPT "\nNenhuma pasta foi selecionada.\n"))
    (T
      (ATS:SaveUsersPreferences 27)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:PlotSheet *standardPlotter* *standardPlotStyle* savePath (LIST (ATS:PredictSheetSize bottom top) bottom top sheetName))
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Configura a plotagem em PDF de uma folha
   @returns nil
   |;
(DEFUN C:PDFC (/ *error* commandName bottom top)
  (SETQ commandName "PDFC")
  (COND
    ((NOT (PROGN (INITGET 1) (SETQ bottom (GETPOINT "\nClique em um canto da folha.\n")))) (PROMPT "\nNenhum ponto foi selecionado.\n"))
    ((NOT (PROGN (INITGET 1) (SETQ top (GETCORNER bottom "\nClique no canto oposto da folha.\n")))) (PROMPT "\nNenhum contorno foi selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences 3)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:PlotSheet *standardPlotter* *standardPlotStyle* nil (LIST (ATS:PredictSheetSize bottom top) bottom top nil))
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
