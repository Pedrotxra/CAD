;| Adquire os valores de uma lista de propriedade-valor
   @global
   @param indexesList [any/lst] - Índice ou lista de índices das propriedades a serem obtidas
   @param entityName [ename/lst] - Nome da entidade ou entidade
   @returns [any/lst] - Valor da propriedade ou lista de valores das propriedades
   |;
(DEFUN ATS:GetPropertiesValues (indexesList entityName / entity entityType)
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
  (SETQ entityType (CDR (ASSOC 0 entity)))
  ;; Obtém a propriedade
  (IF (LISTP indexesList)
    (MAPCAR (FUNCTION (LAMBDA (index / property)
                        ;; Verifica se busca pelo conteúdo de um atributo
                        (IF (AND (EQ index 1) entityType (WCMATCH entityType "ATTRIB,*TEXT") entityName)
                          (VLAX-GET-PROPERTY (ATS:SaveObject entityName) "TextString")
                          (PROGN
                            (SETQ property (CDR (ASSOC index entity)))
                            (IF (EQ (TYPE property) (READ "SYM"))
                              (EVAL property)
                              property))))) indexesList)
    ;; Verifica se busca pelo conteúdo de um atributo
    (IF (AND (EQ indexesList 1) entityType (WCMATCH entityType "ATTRIB,*TEXT") entityName)
      (VLAX-GET-PROPERTY (ATS:SaveObject entityName) "TextString")
      (PROGN
        (SETQ entity (CDR (ASSOC indexesList entity)))
        (IF (EQ (TYPE entity) (READ "SYM"))
          (EVAL entity)
          entity
        )
      )
    )
  )
)

;| Busca as propriedades com base nos valores
   @global
   @param propertiesValues [any/lst] - Valores ou lista de valores das propriedades a serem procuradas
   @param entityName [ename/lst] - Nome da entidade ou entidade
   @returns [any/lst] - Propriedade ou lista de propriedades
   |;
(DEFUN ATS:FindPropertiesValues (propertiesValues entityName / entity properties)
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
  (SETQ properties (MAPCAR (FUNCTION CDR) entity))
  (IF (LISTP propertiesValues)
    (MAPCAR (FUNCTION (LAMBDA (propertiesValues) (IF (SETQ propertiesValues (VL-POSITION propertiesValues properties)) (NTH propertiesValues entity)))) propertiesValues)
    (IF (SETQ propertiesValues (VL-POSITION propertiesValues properties))
      (NTH propertiesValues entity)
    )
  )
)

;| Verifica se uma lista de propriedade-valor tem os valores procurados
   @global
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param entityName [ename/lst] - Nome da entidade ou entidade
   @param property-valueList [lst] - Lista de propriedade-valor a serem comparadas
   @returns [bool] - 'T' se a entidade possui todas as propriedades
   |;
(DEFUN ATS:CheckPropertiesValuesMatches (wildcardMatch entityName property-valueList / entity searchProperty property-value indexProperty property entityType name effectiveName)
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
  ;; Itera sobre cada propriedade da lista e caso alguma delas não corresponda, a busca é interrompida.
  (SETQ searchProperty (LENGTH property-valueList))
  (WHILE (> searchProperty 0)
    (SETQ searchProperty (1- searchProperty))
    (SETQ property-value (NTH searchProperty property-valueList))
    (SETQ indexProperty (CAR property-value))
    (SETQ property (CDR property-value))
    (SETQ entityType (CDR (ASSOC 0 entity)))
    (COND
      ;; Verifica se está buscando o nome de bloco. Se sim, é preciso comparar com seu nome efetivo
      ((AND (EQ indexProperty 2) (EQ entityType "INSERT") entityName)
        (SETQ name (ATS:GetPropertiesValues 2 entity))
        (SETQ effectiveName (ATS:GetEffectiveName (ATS:SaveObject entityName)))
        (IF wildcardMatch
          (COND
            ((WCMATCH (STRCASE name) (STRCASE property)))
            ((WCMATCH (STRCASE effectiveName) (STRCASE property)))
            ((SETQ searchProperty nil))
          )
          (COND
            ((EQ name property))
            ((EQ effectiveName property))
            ((SETQ searchProperty nil))
          )
        )
      )
      ;; Verifica se está buscando o conteúdo de um atributo
      ((AND (EQ indexProperty 1) entityType (WCMATCH entityType "ATTRIB,*TEXT") entityName)
        (SETQ name (ATS:GetPropertiesValues 1 entity))
        (SETQ effectiveName (VLAX-GET-PROPERTY (ATS:SaveObject entityName) "TextString"))
        (IF wildcardMatch
          (COND
            ((WCMATCH (STRCASE name) (STRCASE property)))
            ((WCMATCH (STRCASE effectiveName) (STRCASE property)))
            ((SETQ searchProperty nil))
          )
          (COND
            ((EQ name property))
            ((EQ effectiveName property))
            ((SETQ searchProperty nil))
          )
        )
      )
      ((AND wildcardMatch (EQ (TYPE property) (READ "STR")))
        (COND
          ((AND (SETQ indexProperty (ATS:GetPropertiesValues indexProperty entity)) (WCMATCH indexProperty property)))
          ((SETQ searchProperty nil))
        )
      )
      ((COND
         ((MEMBER property-value entity))
         ((SETQ searchProperty nil))
       )
      )
    )
  )
  (NOT (NOT searchProperty))
)

;| Altera as propriedades de uma entidade
   @global
   @param entityName [ename/lst] - Nome da entidade ou entidade
   @param property-valueList [lst] - Lista de propriedade-valor a substituir
   @returns [ename/lst] - Nome da entidade ou a lista de propriedades da tabela
   |;
(DEFUN ATS:ChangePropertiesValues (entityName property-valueList / entity entityType object dynamicBlockPropertiesList)
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
  (SETQ entityType (ATS:GetPropertiesValues 0 entity))
  (COND
    ;; Salva as propriedades dinâmicas
    ((AND (ASSOC 2 property-valueList) (EQ entityType "INSERT") entityName)
      (SETQ object (ATS:SaveObject entityName))
      (SETQ dynamicBlockPropertiesList (ATS:GetDynamicBlockProperties T nil object nil))
    )
    ;; Ajusta o conteúdo de um atributo
    ((AND (ASSOC 1 property-valueList) (WCMATCH entityType "ATTRIB,*TEXT") entityName)
      (SETQ object (ATS:SaveObject entityName))
      (VLAX-PUT-PROPERTY object "TextString" (ATS:GetPropertiesValues 1 property-valueList))
      (SETQ entity (ENTGET entityName))
    )
  )
  ;; Altera as propriedades
  (FOREACH property-value property-valueList
    (SETQ entity (SUBST property-value (ASSOC (CAR property-value) entity) entity))
  )
  ;; Verifica se é uma entidade ou um item de uma tabela
  (IF (AND entityName (ENTMOD entity))
    (PROGN
      (ENTUPD entityName)
      ;; Aplica as propriedades dinâmicas salvas
      (IF dynamicBlockPropertiesList
        (ATS:ChangeDynamicBlockPropertiesValues nil object dynamicBlockPropertiesList)
      )
      entityName
    )
    entity
  )
)

;| Remove duplicadas de uma lista
   @global
   @param fullList [lst] - Lista a ser iterada
   @returns [lst] - Lista sem elementos duplicados
   |;
(DEFUN ATS:RemoveDuplicates (fullList / firstItem)
  (IF fullList
    (PROGN
      (SETQ firstItem (CAR fullList))
      (CONS firstItem (ATS:RemoveDuplicates (VL-REMOVE-IF (FUNCTION (LAMBDA (item) (EQUAL firstItem item *minimalFuzz*))) (CDR fullList))))
    )
  )
)

;| Isola os itens diferentes entre listas
   @global
   @param compareLists [lst] - Lista com as listas a serem comparadas
   @returns [lst] - Lista com as listas sem elementos comuns
   |;
(DEFUN ATS:IsolateDifferences (compareLists / otherLists listLength count)
  (SETQ otherLists (CDR compareLists))
  (SETQ listLength (LENGTH otherLists))
  (FOREACH item (CAR compareLists)
    (SETQ count 0)
    (WHILE (AND count (< count listLength))
      (IF (NOT (MEMBER item (NTH count otherLists)))
        (SETQ count nil)
        (SETQ count (1+ count))
      )
    )
    (IF count
      (FOREACH compareList compareLists
        (SETQ compareLists (SUBST (VL-REMOVE item compareList) compareList compareLists))
      )
    )
  )
  compareLists
)

;| Converte uma lista de strings em uma única string, separada por um delimitador
   @global
   @param delimiter [str] - Delimitador das strings
   @param stringList [lst] - Lista de strings a serem concatenadas
   @returns [str] - String concatenada
   |;
(DEFUN ATS:ListToString (delimiter stringList / concatenatedString)
  (SETQ concatenatedString (CAR stringList))
  (FOREACH item (CDR stringList)
    (SETQ concatenatedString (STRCAT concatenatedString delimiter item))
  )
  concatenatedString
)

;| Converte uma string em uma lista, usando um delimitador
   @global
   @param delimiter [str] - Delimitador para dividir a string
   @param string [str] - String a ser dividida
   @returns [lst] - Lista com as partes da string
   |;
(DEFUN ATS:StringToList (delimiter string / position)
  (IF (SETQ position (VL-STRING-SEARCH delimiter string))
    (CONS (SUBSTR string 1 position) (ATS:StringToList delimiter (SUBSTR string (+ position 1 (STRLEN delimiter)))))
    (LIST string)
  )
)

;| Operador lógico XOR
   @global
   @param items [lst] - Lista de itens
   @returns [bool] - 'T' se apenas um item for verdadeiro
   |;
(DEFUN ATS:XOR (items)
  (AND (APPLY (FUNCTION OR) items) (NOT (APPLY (FUNCTION AND) items)))
)

;| Converte uma lista em uma variant array
   @global
   @param ordinaryList [lst] - Lista a ser convertida
   @returns [var:arrdb] - Variant da array de double
   |;
(DEFUN ATS:ListToVariantArray (ordinaryList)
  (VLAX-MAKE-VARIANT
    (VLAX-SAFEARRAY-FILL
      (VLAX-MAKE-SAFEARRAY VLAX-VBDOUBLE (CONS 0 (- (LENGTH ordinaryList) 1)))
      ordinaryList
    )
  )
)

;| Insere um item em uma lista em uma posição específica
   @global
   @param item [any] - Item a inserir
   @param index [int] - Posição do item a ser inserido
   @param fullList [lst] - Lista a ser iterada
   @returns [lst] - Lista com o item inserido
   |;
(DEFUN ATS:InsertItemByPosition (item index fullList)
  ;; Tratamento para admitir índices negativos
  (IF (< index 0)
    (SETQ index (+ 1 (LENGTH fullList) index))
  )
  ;; Itera a lista até o índice zerar, e concatena as partes anterior e seguinte da lista ao item
  (IF (AND fullList (NOT (ZEROP index)))
    (CONS (CAR fullList) (ATS:InsertItemByPosition item (1- index) (CDR fullList)))
    (CONS item fullList)
  )
)

;| Remove um item de uma lista pela posição
   @global
   @param index [int] - Posição do item a ser removido
   @param fullList [lst] - Lista a ser iterada
   @returns [lst] - Lista sem o item removido
   |;
(DEFUN ATS:RemoveItemByPosition (index fullList)
  ;; Tratamento para admitir índices negativos
  (IF (< index 0)
    (SETQ index (+ (LENGTH fullList) index))
  )
  ;; Itera a lista até o índice zerar, e concatena as partes anterior e seguinte da lista
  (IF (AND fullList (NOT (ZEROP index)))
    (CONS (CAR fullList) (ATS:RemoveItemByPosition (1- index) (CDR fullList)))
    (CDR fullList)
  )
)

;| Substitui um item de uma lista pela posição
   @global
   @param item [any] - Item a substituir
   @param index [int] - Posição do item a ser substituído
   @param fullList [lst] - Lista a ser iterada
   @returns [lst] - Lista com o item substituído
   |;
(DEFUN ATS:SubstituteItemByPosition (item index fullList)
  ;; Tratamento para admitir índices negativos
  (IF (< index 0)
    (SETQ index (+ (LENGTH fullList) index))
  )
  ;; Itera a lista até o índice zerar, e concatena as partes anterior e seguinte da lista
  (IF (AND fullList (NOT (ZEROP index)))
    (CONS (CAR fullList) (ATS:SubstituteItemByPosition item (1- index) (CDR fullList)))
    (CONS item (CDR fullList))
  )
)

;| Converte um dicionário em uma lista
   @global
   @param dictionary [dict] - Dicionário a ser convertido
   @returns [lst] - Lista com os itens do dicionário
   |;
(DEFUN ATS:DictionaryToList (dictionary / dictionaryList)
  (VLAX-FOR item dictionary
    (SETQ dictionaryList (CONS item dictionaryList))
  )
)

;| Retorna uma sublista de uma lista
   @global
   @param index [int] - Posição do item a iniciar a sublista
   @param listLength [int] - Tamanho da sublista a ser retornada
   @param fullList [lst] - Lista a ser recortada
   @returns [lst] - Retorna a sublista
   |;
(DEFUN ATS:GetSublist (index listLength fullList / GetSublist)
  (DEFUN GetSublist (index listLength fullList)
    (COND
      ((NULL fullList) nil)
      ;; Elimina os elementos iniciais, até 'index' chegar a 0
      ((> index 0) (ATS:GetSublist (1- index) listLength (CDR fullList)))
      ;; Constrói a lista com os elementos seguintes, até 'listLength' chegar a 0
      ((NULL listLength) fullList)
      ((> listLength 0) (CONS (CAR fullList) (GetSublist index (1- listLength) (CDR fullList))))
    )
  )
  (IF (MINUSP index)
    (SETQ index (+ (LENGTH fullList) index))
  )
  (IF (<= listLength 0)
    (SETQ listLength (+ (LENGTH fullList) listLength))
  )
  (GetSublist index listLength fullList)
)

;| Divide uma lista em duas a partir de uma posição
   @global
   @param position [int] - Índice do primeiro item da segunda lista
   @param listToSplit [lst] - Lista a ser dividida
   @returns [lst] - Retorna uma lista com duas sublistas
   |;
(DEFUN ATS:SplitListByPosition (position listToSplit / firstList secondList count)
  (IF (MINUSP position)
    (SETQ position (+ (LENGTH listToSplit) position))
  )
  (SETQ count -1)
  (LIST
    (REVERSE
      (REPEAT position
        (SETQ count (1+ count))
        (SETQ firstList (CONS (NTH count listToSplit) firstList))
      )
    )
    (REVERSE
      (REPEAT (- (LENGTH listToSplit) position)
        (SETQ count (1+ count))
        (SETQ secondList (CONS (NTH count listToSplit) secondList))
      )
    )
  )
)

;| Divide uma lista em sublistas de tamanho máximo
   @global
   @param maxLength [int] - Índice do primeiro item da segunda lista
   @param listToSplit [lst] - Lista a ser dividida
   @returns [lst] - Retorna uma lista com as sublistas
   |;
(DEFUN ATS:SplitListByLength (maxLength listToSplit / lastList)
  (IF (> (LENGTH listToSplit) maxLength)
    (PROGN
      (SETQ listToSplit (ATS:SplitListByPosition maxLength listToSplit))
      (WHILE (> (LENGTH (SETQ lastList (LAST listToSplit))) maxLength)
        (SETQ listToSplit (APPEND (VL-REMOVE lastList listToSplit) (ATS:SplitListByPosition maxLength lastList)))
      )
    )
  )
  listToSplit
)

;| Converte os símbolos de uma lista para seus valores armazenados
   @global
   @param symbolList [lst] - Lista de símbolos
   @returns [lst] - Lista com os valores dos símbolos
   |;
(DEFUN ATS:EvaluateSymbolList (symbolList)
  (ATS:RemoveDuplicates (VL-REMOVE nil (MAPCAR (FUNCTION (LAMBDA (symbol) (WHILE (EQ (TYPE symbol) (READ "SYM")) (SETQ symbol (EVAL symbol))) symbol)) symbolList)))
)
