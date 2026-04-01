;| Verifica se a entidade é um bloco com atributo ou um atributo
   @global
   @param blockEntityName [ename] - Nome da entidade do bloco
   @returns [ename] - nome da entidade do atributo ou nil se não houver atributo
   |;
(DEFUN ATS:VerifyBlockWithAttribute (blockEntityName / attributeEntityName)
  (IF (AND (SETQ attributeEntityName (ENTNEXT blockEntityName)) (WCMATCH (ATS:GetPropertiesValues 0 (ENTGET attributeEntityName)) "ATTRIB,SEQEND"))
    blockEntityName
  )
)

;| Gera uma nova seleção apenas de blocos com atributos
   @global
   @param selection [ss] - Seleção
   @returns [ss] - Nova seleção contendo apenas blocos com atributos
   |;
(DEFUN ATS:FilterBlocksWithAttributes (selection / trimSelection count blockEntityName)
  (SETQ trimSelection (SSADD))
  (SETQ count (SSLENGTH selection))
  (REPEAT count
    (SETQ count (1- count))
    (SETQ blockEntityName (SSNAME selection count))
    (IF (ATS:VerifyBlockWithAttribute blockEntityName)
      (SSADD blockEntityName trimSelection)
    )
  )
  (ATS:VerifySelectionSets trimSelection)
)

;| Busca um atributo em um bloco a partir de suas propriedades
   @global
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param blockEntityName [ename] - Nome da entidade do bloco
   @param searchProperty-valueList [lst] - Lista de propriedades do atributo a serem buscadas
   @returns [ename] - Nome da entidade do atributo ou nil se não houver atributo correspondente
   |;
(DEFUN ATS:SearchAttribute (wildcardMatch blockEntityName searchProperty-valueList / attributeEntityName)
  (WHILE (AND (NOT attributeEntityName) (ATS:VerifyBlockWithAttribute blockEntityName))
    (SETQ blockEntityName (ENTNEXT blockEntityName))
    (IF (ATS:CheckPropertiesValuesMatches wildcardMatch blockEntityName searchProperty-valueList)
      (SETQ attributeEntityName blockEntityName)
    )
  )
  attributeEntityName
)

;| Obtém as propriedades de um atributo
   @global
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param indexesList [any/lst] - Índice ou lista de índices das propriedades a serem obtidas
   @param blockEntityName [ename] - Nome da entidade do bloco
   @param searchProperty-valueList [lst] - Lista de propriedades do atributo a serem buscadas, ou 'nil' para buscar em todos os atributos
   @returns [any/lst] - Valor ou lista de valores
   |;
(DEFUN ATS:GetAttributeProperties (wildcardMatch indexesList blockEntityName searchProperty-valueList / attributesList)
  (IF searchProperty-valueList
    (ATS:GetPropertiesValues indexesList (ATS:SearchAttribute wildcardMatch blockEntityName searchProperty-valueList))
    (PROGN
      (WHILE (EQ (ATS:GetPropertiesValues 0 (SETQ blockEntityName (ENTNEXT blockEntityName))) "ATTRIB")
        (SETQ attributesList (CONS (ATS:GetPropertiesValues indexesList blockEntityName) attributesList))
      )
      (REVERSE attributesList)
    )
  )
)

;| Edita atributos de um bloco
   @global
   @param wildcardMatch [bool] - 'T' para usar correspondência de caracteres curinga
   @param blockEntityName [ename] - Nome da entidade do bloco
   @param searchProperty-valueList [lst] - Lista de propriedades do atributo a serem buscadas
   @param property-valueList [lst] - Lista de propriedades a serem alteradas
   @returns [ename] - Nome da entidade do bloco com atributos alterados
   |;
(DEFUN ATS:EditBlockAttributes (wildcardMatch blockEntityName searchProperty-valueList property-valueList)
  (IF (SETQ blockEntityName (ATS:SearchAttribute wildcardMatch blockEntityName searchProperty-valueList))
    (PROGN
      (ATS:ChangePropertiesValues blockEntityName property-valueList)
      (ATS:EditBlockAttributes wildcardMatch blockEntityName searchProperty-valueList property-valueList)
    )
  )
)

;| Adquire os prompts dos atributos de um bloco
   @global
   @param blockName [str] - Nome do bloco
   @returns [lst] - Lista dos prompts dos atributos do bloco
   |;
(DEFUN ATS:GetAttributePrompts (blockName / promptsList)
  (VLAX-FOR object (ATS:SaveObject (VLA-ITEM (ATS:SaveObject (VLA-GET-BLOCKS *activeDocument*)) blockName))
    (IF (EQ (VLAX-GET object "ObjectName") "AcDbAttributeDefinition")
      (SETQ promptsList (CONS (VLAX-GET-PROPERTY object "PromptString") promptsList))
    )
    (ATS:SaveObject object)
  )
  (REVERSE promptsList)
)

;| Converte atributos de texto em definições de atributo
   @returns nil
   |;
(DEFUN C:ATTD (/ *error* commandName selection count textEntityName textEntity content tag position)
  (SETQ commandName "ATTD")
  (COND
    ((NOT (SETQ selection (SSGET (LIST (CONS 0 "*TEXT"))))) (PROMPT "\nNenhum texto selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (SETQ textEntityName (SSNAME selection count))
        (SETQ textEntity (ENTGET textEntityName))
        (SETQ content (ATS:GetPropertiesValues 1 textEntity))
        (IF (EQ (ATS:GetPropertiesValues 0 textEntity) "MTEXT")
          (COMMAND-S "_.EXPLODE" entityName)
        )
        (SETQ tag (ATS:ReplaceAllInString "_." " " (IF (AND (EQ (ATS:GetPropertiesValues 0 textEntity) "MTEXT") (VL-STRING-SEARCH "\\P" content))
                                                    (SUBSTR content 1 (1- (VL-STRING-SEARCH "\\P" content)))
                                                    content)))
        (IF (WCMATCH (ATS:ReplaceAllInString "" "_." tag) "*.*")
          (PROMPT "\nO texto contém caractess) especial(is)!\n")
          (PROGN
            (SETQ position (ATS:GetPropertiesValues 11 textEntity))
            (COMMAND-S "_.-ATTDEF" "" tag tag content (LIST
                                                        (CAR (ATS:GetPropertiesValues 10 textEntity))
                                                        (+ (CADR (ATS:GetPropertiesValues 10 textEntity)) (ATS:GetPropertiesValues 40 textEntity)))
                    (ATS:GetPropertiesValues 40 textEntity)
                    (/ (* 180 (ATS:GetPropertiesValues 50 textEntity)) PI))
            (ATS:ChangePropertiesValues
              (ENTLAST)
              (LIST
                (CONS 72 (ATS:GetPropertiesValues 72 textEntity))
                (CONS 74 (ATS:GetPropertiesValues 73 textEntity))
                (CONS 7 (ATS:GetPropertiesValues 7 textEntity))
                (CONS 8 (ATS:GetPropertiesValues 8 textEntity))
                (IF (AND (EQ (CAR position) 0) (EQ (CADR position) 0))
                  (CONS 10 (ATS:GetPropertiesValues 10 textEntity))
                  (CONS 11 position)
                )
              )
            )
            (ENTDEL textEntityName)
          )
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Limpa o conteúdo dos atributos dos blocos
   @returns nil
   |;
(DEFUN C:LATT (/ *error* commandName selection count)
  (SETQ commandName "LATT")
  (COND
    ((NOT (SETQ selection (ATS:FilterBlocksWithAttributes (SSGET (LIST (CONS 0 "INSERT")))))) (PROMPT "\nNenhum bloco com atributo selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (ATS:EditBlockAttributes nil (SSNAME selection count) (LIST (CONS 0 "ATTRIB")) (LIST (CONS 1 "")))
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Rotaciona um atributo de um bloco
   @returns nil
   |;
(DEFUN C:RATT (/ *error* commandName entityName rotation count)
  (SETQ commandName "RATT")
  (COND
    ((NOT (SETQ entityName (CAR (NENTSEL "\nSelecione o atributo.\n")))) (PROMPT "\nNenhum bloco com atributo selecionado.\n"))
    ((NOT (SETQ rotation (COND ((GETANGLE "\nInsira a rotação: <0>\n")) (0)))))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (ATS:ChangePropertiesValues entityName (LIST (CONS 50 rotation)))
      (COMMAND-S "_.REGEN")
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Rotacionar atributos de blocos
   @returns nil
   |;
(DEFUN C:RATTS (/ *error* commandName selection rotation count)
  (SETQ commandName "RATTS")
  (COND
    ((NOT (SETQ selection (ATS:FilterBlocksWithAttributes (SSGET (LIST (CONS 0 "INSERT")))))) (PROMPT "\nNenhum bloco com atributo selecionado.\n"))
    ((NOT (SETQ rotation (COND ((GETANGLE "\nInsira a rotação: <0>\n")) (0)))))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ count (SSLENGTH selection))
      (REPEAT count
        (SETQ count (1- count))
        (ATS:EditBlockAttributes nil (SSNAME selection count) (LIST (CONS 0 "ATTRIB")) (LIST (CONS 50 rotation)))
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
