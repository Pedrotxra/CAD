;| Verifica se os conjuntos de seleção são válidos
   @global
   @param selectionSet [ss/lst] - Seleção ou lista de seleções
   @returns [ss/lst] - Seleções válidas
   |;
(DEFUN ATS:VerifySelectionSets (selectionSet)
  (COND
    ((EQ (TYPE selectionSet) (READ "PICKSET")) (IF (> (SSLENGTH selectionSet) 0) selectionSet))
    ((LISTP selectionSet) (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (selectionSet) (ATS:VerifySelectionSets selectionSet))) selectionSet))
  )
)

;| Seleciona um único objeto com base em um filtro
   @global
   @param filterList [lst] - Lista de filtros
   @returns [ename] - Nome da entidade selecionada
   |;
(DEFUN ATS:SelectSingleObject (filterList / selection)
  (SETQ selection (SSGET "_I" filterList))
  (SSSETFIRST nil nil)
  (IF (OR (AND selection (EQ (SSLENGTH selection) 1)) (SETQ selection (SSGET "_:S" filterList)))
    (SSNAME selection 0)
  )
)

;| Aplica uma função a uma seleção
   @global
   @param selection [ss] - Seleção
   @param applyFunction [subr] - Função
   @returns [any] - Resultado da última iteração da função
   |;
(DEFUN ATS:ApplyToSelection (selection applyFunction / count)
  (SETQ count (SSLENGTH selection))
  (SETQ *iterationsCount* (+ count *iterationsCount*))
  (REPEAT count
    (SETQ count (1- count))
    (APPLY (FUNCTION applyFunction) (LIST (SSNAME selection count)))
  )
)

;| Obtém as propriedades das entidades de uma seleção
   @global
   @param indexesList [int/lst] - Índice ou lista de índices das propriedades, ou 'nil' para obter todas as propriedades
   @param selection [ss] - Seleção
   @returns [any/lst] - Propriedade ou lista de propriedades das entidades
   |;
(DEFUN ATS:GetSelectionProperties (indexesList selection / count entityName propertiesList)
  (SETQ count (SSLENGTH selection))
  (REPEAT count
    (SETQ count (1- count))
    (SETQ entityName (SSNAME selection count))
    (ENTUPD entityName)
    (SETQ propertiesList (CONS (IF indexesList (ATS:GetPropertiesValues indexesList entityName) (ENTGET entityName)) propertiesList))
  )
)

;| Altera as propriedades de uma seleção
   @global
   @param selection [ss] - Seleção dos objetos a serem modificados
   @param property-valueList [lst] - Lista de propriedade-valor a substituir
   @returns [lst] - Última entidade com as propriedades alteradas
   |;
(DEFUN ATS:ChangeSelectionProperties (selection property-valueList / count entityName)
  (SETQ count (SSLENGTH selection))
  (SETQ *iterationsCount* (+ count (COND (*iterationsCount*) (0))))
  (REPEAT count
    (SETQ count (1- count))
    (SETQ entityName (SSNAME selection count))
    (ATS:ChangePropertiesValues entityName property-valueList)
  )
)

;| Filtra entidades com base em propriedades emparelhadas
   @global
   @param remainNonMatching [bool] - 'T' para filtrar os elementos que não atendem ao filtro
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param selection [ss] - Seleção
   @param property-valueList [lst] - Lista de propriedade-valor a comparar
   @returns [ss] - Seleção filtrada
   |;
(DEFUN ATS:FilterSelection (remainNonMatching wildcardMatch selection property-valueList / newSelection count entityName)
  (IF (ATS:VerifySelectionSets selection)
    (PROGN
      (SETQ newSelection (SSADD))
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityName (SSNAME selection count))
        (IF (EQ (NOT remainNonMatching) (NOT (NOT (ATS:CheckPropertiesValuesMatches wildcardMatch entityName property-valueList))))
          (SSADD entityName newSelection)
        )
      )
      (IF (ATS:VerifySelectionSets newSelection)
        newSelection
      )
    )
  )
)

;| Converte uma lista de entidades em uma seleção
   @global
   @param selectionList [lst] - Lista de entidades
   @returns [ss] - Seleção
   |;
(DEFUN ATS:ListToSelectionSet (selectionList / selectionSet entity)
  (SETQ selectionSet (SSADD))
  (FOREACH entity selectionList
    ;; Verifica se o item é uma lista de propriedades ou de propriedade-valor
    ; Primeiramente, verifica se é uma lista, senão verifica se é o nome de uma entidade
    ; Depois, vê se o item da lista é outra lista e tem o nome da entidade (lista de propriedade-valor)
    ; Senão, verifica se o item da lista é um nome da entidade (lista de propriedades)
    (IF (LISTP entity)
      (IF (NOT (SETQ entityName (VL-SOME (FUNCTION (LAMBDA (item)
                                                     (IF (LISTP item)
                                                       (SETQ item (CDR item)))
                                                     (IF (EQ (TYPE item) (READ "ENAME"))
                                                       item))) entity)))
        (SETQ entityName (CAR entity))
      )
      (SETQ entityName entity)
    )
    (IF (EQ (TYPE entityName) (READ "ENAME"))
      (SSADD entityName selectionSet)
    )
  )
  (ATS:VerifySelectionSets selectionSet)
)

;| Une seleções em uma única seleção
   @global
   @param selectionSetsList [lst] - Lista de seleções
   @returns [ss] - Seleção unificada
   |;
(DEFUN ATS:JoinSelectionSets (selectionSetsList / newSelectionSet count)
  (SETQ selectionSetsList (ATS:VerifySelectionSets selectionSetsList))
  (IF selectionSetsList
    (PROGN
      (SETQ newSelectionSet (SSADD))
      (FOREACH selectionSet selectionSetsList
        (SETQ count (SSLENGTH selectionSet))
        (REPEAT count
          (SETQ count (1- count))
          (SSADD (SSNAME selectionSet count) newSelectionSet)
        )
      )
      newSelectionSet
    )
  )
)

;| Remove as entidades da seleção de corte de outras seleções
   @global
   @param selectionSetsList [ss/lst] - Seleção ou lista de seleções
   @param trimSelectionSet [ss] - Seleções com entidades a serem removidas das outras seleções
   @returns [ss/lst] - Seleção ou lista de seleções resultantes
   |;
(DEFUN ATS:TrimSelectionSets (selectionSetsList trimSelectionSet / newSelectionSet count entityName newSelectionSetsList)
  (IF (NOT (ATS:VerifySelectionSets trimSelectionSet))
    (SETQ trimSelectionSet (SSADD))
  )
  (IF (EQ (TYPE selectionSetsList) (READ "PICKSET"))
    (PROGN
      (SETQ newSelectionSet (SSADD))
      (SETQ count (SSLENGTH selectionSetsList))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ entityName (SSNAME selectionSetsList count))
        (IF (NOT (SSMEMB entityName trimSelectionSet))
          (SSADD entityName newSelectionSet)
        )
      )
      (ATS:VerifySelectionSets newSelectionSet)
    )
    (PROGN
      (FOREACH selectionSet selectionSetsList
        (SETQ newSelectionSet (SSADD))
        (SETQ count (SSLENGTH selectionSet))
        (REPEAT count
          (SETQ count (1- count))
          (SETQ entityName (SSNAME selectionSet count))
          (IF (NOT (SSMEMB entityName trimSelectionSet))
            (SSADD entityName newSelectionSet)
          )
        )
        (SETQ newSelectionSetsList (CONS (ATS:VerifySelectionSets newSelectionSet) newSelectionSetsList))
      )
      (REVERSE newSelectionSetsList)
    )
  )
)

;| Ordena uma seleção ou lista de entidades baseada na posição
   @global
   @param fuzz [real] - Tolerância para a ordenação
   @param selection [ss/lst] - Seleção ou uma lista no formato: nome da entidade e ponto base
   @returns [lst] - Lista ordenada com os nomes das entidades
   |;
(DEFUN ATS:SortSelectionByPosition (fuzz selection)
  (IF (IF (EQ (TYPE selection) (READ "PICKSET"))
        (SETQ selection (ATS:GetSelectionProperties (LIST -1 10) selection))
        selection)
    (PROGN
      (SETQ selection (VL-SORT selection (FUNCTION (LAMBDA (entity1 entity2 / x1 x2)
                                                    (SETQ x1 (CAR (CADR entity1)))
                                                    (SETQ x2 (CAR (CADR entity2)))
                                                    (AND (< x1 x2) (> (ABS (- x1 x2)) fuzz))))))
      (SETQ selection (VL-SORT selection (FUNCTION (LAMBDA (entity1 entity2 / y1 y2)
                                                    (SETQ y1 (CADR (CADR entity1)))
                                                    (SETQ y2 (CADR (CADR entity2)))
                                                    (AND (> y1 y2) (> (ABS (- y1 y2)) fuzz))))))
      (MAPCAR (FUNCTION CAR) selection)
    )
  )
)

;| Obtém o contorno de uma seleção
   @global
   @param selection [ss/lst] - Seleção
   @returns [lst] - Lista com os pontos mínimo e máximo
   |;
(DEFUN ATS:GetSelectionBoundaries (selection / count boundaries xMin yMin xMax yMax)
  (SETQ count (SSLENGTH selection))
  ;; Faz a primeira iteração
  (SETQ count (1- count))
  (SETQ boundaries (ATS:GetObjectBoundaries (ATS:SaveObject (SSNAME selection count))))
  (IF boundaries
    (PROGN
      (SETQ xMin (CAR (CAR boundaries)))
      (SETQ yMin (CADR (CAR boundaries)))
      (SETQ xMax (CAR (CADR boundaries)))
      (SETQ yMax (CADR (CADR boundaries)))
    )
  )
  ;; Compara os primeiros resultados obtidos com os próximos e armazena o menor e maior valor de cada coordenada
  (REPEAT count
    (SETQ count (1- count))
    (SETQ boundaries (ATS:GetObjectBoundaries (ATS:SaveObject (SSNAME selection count))))
    (IF boundaries
      (PROGN
        (SETQ xMin (MIN (CAR (CAR boundaries)) xMin))
        (SETQ yMin (MIN (CADR (CAR boundaries)) yMin))
        (SETQ xMax (MAX (CAR (CADR boundaries)) xMax))
        (SETQ yMax (MAX (CADR (CADR boundaries)) yMax))
      )
    )
  )
  (LIST (LIST xMin yMin) (LIST xMax yMax))
)

;| Obtém a próxima entidade no banco de dados, ignorando atributos
   @global
   @param entityName [ename] - Nome da entidade a iniciar a busca no banco de dados
   @returns [ename] - Próxima entidade encontrada
   |;
(DEFUN ATS:NextEntitySkippingAttributes (entityName)
  (IF (ATS:VerifyBlockWithAttribute entityName)
    (PROGN
      (WHILE (IF (SETQ entityName (ENTNEXT entityName)) (ATS:VerifyBlockWithAttribute entityName)))
      (IF entityName
        (ENTNEXT entityName)
      )
    )
    (ENTNEXT entityName)
  )
)

;| Seleciona as próximas entidades no banco de dados
   @global
   @param entityName [ename] - Nome da entidade a iniciar a busca no banco de dados
   @returns [ss] - Seleção das entidades seguintes
   |;
(DEFUN ATS:SelectNextEntities (entityName / selection)
  (IF (SETQ entityName (ATS:NextEntitySkippingAttributes entityName))
    (PROGN
      (SETQ selection (SSADD entityName))
      (WHILE (SETQ entityName (ATS:NextEntitySkippingAttributes entityName))
        (SSADD entityName selection)
      )
      selection
    )
  )
)

;| Filtra linhas pelo seu ângulo
   @global
   @param remainNonMatching [bool] - 'T' para filtrar os elementos que não atendem ao filtro
   @param filterAngle [real] - Ângulo de filtro
   @param fuzz [real] - Tolerância para comparação de ângulos
   @param linesSelection [ss] - Seleção de linhas
   @returns [ss] - Seleção das linhas filtradas
   |;
(DEFUN ATS:FilterLinesByAngle (remainNonMatching filterAngle fuzz linesSelection / newLinesSelection count line lineAngle)
  (IF (ATS:VerifySelectionSets linesSelection)
    (PROGN
      (SETQ newLinesSelection (SSADD))
      (SETQ count (SSLENGTH linesSelection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ line (SSNAME linesSelection count))
        (SETQ lineAngle (APPLY (FUNCTION ANGLE) (ATS:GetPropertiesValues (LIST 10 11) line)))
        (IF (>= lineAngle PI)
          (SETQ lineAngle (- lineAngle PI))
        )
        (IF (EQ (EQUAL lineAngle filterAngle fuzz) (NOT remainNonMatching))
          (SSADD line newLinesSelection)
        )
      )
      (ATS:VerifySelectionSets newLinesSelection)
    )
  )
)

;| Filtra blocos com o mesmo nome do bloco de referência
   @returns nil
   |;
(DEFUN C:FB (/ *error* commandName usersMessage selection name)
  (SETQ commandName "FB")
  (COND
    ((NOT (SETQ selection (ATS:SelectSingleObject (LIST (CONS 0 "INSERT"))))) (PROMPT "\nNenhum bloco foi selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ name (ATS:GetEffectiveName (ATS:SaveObject selection)))
      (SETQ selection (LIST (CONS 0 "INSERT")))
      (PROMPT "\nSelecione os blocos a serem filtrados, ou Enter para selecionar todos.\n")
      (IF (AND (SETQ selection (COND ((SSGET selection)) ((SSGET "_A" (APPEND selection (LIST (CONS 410 (GETVAR "CTAB"))))))))
               (SETQ selection (ATS:FilterSelection nil nil selection (LIST (CONS 2 name)))))
        (SETQ *iterationsCount* (SSLENGTH selection))
      )
      (SETQ usersMessage (STRCAT "\n" (ITOA *iterationsCount*) " blocos selecionados.\n"))
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)

;| Filtra objetos com o mesmo padrão de hachura da entidade de referência
   @returns nil
   |;
(DEFUN C:FH (/ *error* commandName usersMessage selection)
  (SETQ commandName "FH")
  (COND
    ((NOT (SETQ selection (ATS:SelectSingleObject (CONS 0 "HATCH")))) (PROMPT "\nNenhuma hachura foi selecionada.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (/ message)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ selection (LIST (CONS 0 "HATCH") (CONS 2 (ATS:GetPropertiesValues 2 selection))))
      (PROMPT "\nSelecione as hachuras a serem filtradas, ou Enter para selecionar todas.\n")
      (IF (SETQ selection (COND ((SSGET selection)) ((SSGET "_A" (APPEND selection (LIST (CONS 410 (GETVAR "CTAB"))))))))
        (SETQ *iterationsCount* (SSLENGTH selection))
      )
      (SETQ usersMessage (STRCAT "\n" (ITOA *iterationsCount*) " hachuras selecionadas.\n"))
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)

;| Filtra objetos com o mesmo layer da entidade de referência
   @returns nil
   |;
(DEFUN C:FL (/ *error* commandName usersMessage selection)
  (SETQ commandName "FL")
  (COND
    ((NOT (SETQ selection (ATS:SelectSingleObject nil))) (PROMPT "\nNenhum objeto foi selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (/ message)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ selection (LIST (CONS 8 (ATS:GetPropertiesValues 8 selection))))
      (PROMPT "\nSelecione os objetos a serem filtrados, ou Enter para selecionar todos.\n")
      (IF (SETQ selection (COND ((SSGET selection)) ((SSGET "_A" (APPEND selection (LIST (CONS 410 (GETVAR "CTAB"))))))))
        (SETQ *iterationsCount* (SSLENGTH selection))
      )
      (SETQ usersMessage (STRCAT "\n" (ITOA *iterationsCount*) " objetos selecionados.\n"))
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)

;| Filtra blocos com o trecho de referência no nome
   @returns nil
   |;
(DEFUN C:FNB (/ *error* commandName usersMessage searchValue selection)
  (SETQ commandName "FNB")
  (COND
    ((NOT (SETQ searchValue (ATS:GetString 1 T nil "\nInsira o trecho a ser contido no nome do bloco:\n"))) (PROMPT "\nO trecho não foi introduzido.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (/ message)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ selection (LIST (CONS 0 "INSERT")))
      (PROMPT "\nSelecione os blocos a serem filtrados, ou Enter para selecionar todos.\n")
      (IF (AND (SETQ selection (COND ((SSGET selection)) ((SSGET "_A" (APPEND selection (LIST (CONS 410 (GETVAR "CTAB"))))))))
               (SETQ selection (ATS:FilterSelection nil T selection (LIST (CONS 2 (STRCAT "*" searchValue "*"))))))
        (SETQ *iterationsCount* (SSLENGTH selection))
      )
      (SETQ usersMessage (STRCAT "\n" (ITOA *iterationsCount*) " blocos selecionados.\n"))
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)

;| Filtra hachuras com o trecho de referência no nome
   @returns nil
   |;
(DEFUN C:FNH (/ *error* commandName usersMessage selection)
  (SETQ commandName "FNH")
  (COND
    ((NOT (SETQ selection (ATS:GetString 1 T nil "\nInsira o trecho a ser contido no nome da hachura:\n"))) (PROMPT "\nO trecho não foi introduzido.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (/ message)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ selection (LIST (CONS 0 "HATCH") (CONS 2 (STRCAT "*" selection "*"))))
      (PROMPT "\nSelecione as hachuras a serem filtradas, ou Enter para selecionar todas.\n")
      (IF (SETQ selection (COND ((SSGET selection)) ((SSGET "_A" (APPEND selection (LIST (CONS 410 (GETVAR "CTAB"))))))))
        (SETQ *iterationsCount* (SSLENGTH selection))
      )
      (SETQ usersMessage (STRCAT "\n" (ITOA *iterationsCount*) " hachuras selecionadas.\n"))
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)

;| Filtra objetos de layers com o trecho de referência no nome
   @returns nil
   |;
(DEFUN C:FNL (/ *error* commandName usersMessage selection)
  (SETQ commandName "FNL")
  (COND
    ((NOT (SETQ selection (ATS:GetString 1 T nil "\nInsira o trecho a ser contido no nome do layer:\n"))) (PROMPT "\nO trecho não foi introduzido.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (/ message)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ selection (LIST (CONS 8 (STRCAT "*" selection "*"))))
      (PROMPT "\nSelecione os objetos a serem filtrados, ou Enter para selecionar todos.\n")
      (IF (SETQ selection (COND ((SSGET selection)) ((SSGET "_A" (APPEND selection (LIST (CONS 410 (GETVAR "CTAB"))))))))
        (SETQ *iterationsCount* (SSLENGTH selection))
      )
      (SETQ usersMessage (STRCAT "\n" (ITOA *iterationsCount*) " objetos selecionados.\n"))
      (ATS:RestoreUsersPreferences commandName nil)
      (SSSETFIRST nil selection)
    )
  )
)
