;| Cria uma hachura
   @global
   @param selection [ss/lst] - Seleção do contorno da hachura, ou uma lista de pontos, ou nil para ser introduzido pelo usuário
   @param hatchProperties [lst] - Lista de propriedade-valor nomeadas da hachura
   @returns [nil] - Cria a hachura conforme especificações
   |;
(DEFUN ATS:MakeHatch (selection hatchProperties / pattern scale presetScale rotation layer color backgroundColor transparency)
  ;; Armazena as propriedades da hachura
  (SETQ pattern (ATS:GetPropertiesValues "Pattern" hatchProperties))
  (SETQ scale (ATS:GetPropertiesValues "Scale" hatchProperties))
  ;; Obtém a escala
  (IF scale
    (PROGN
      (SETQ scale (* scale *unitsFactor*))
      ;; Verifica se a escala é fixa
      (IF (SETQ presetScale (ATS:GetPropertiesValues "PresetScale" hatchProperties))
        ;; Se for um número decimal, solicita o tamanho e posição do quadrado
        (IF (EQ (TYPE presetScale) (READ "REAL"))
          (PROGN
            (ATS:SetDefaultValues
              (LIST
                (CONS (QUOTE *squareSize*) presetScale)
                (CONS (QUOTE *squareOrigin*) "IE")
              )
            )
            (SETQ scale (/ (COND ((PROGN (INITGET 6) (SETQ *squareSize* (GETREAL (STRCAT "\nInsira o tamanho do lado: <" (RTOS *squareSize*) ">\n"))))) (presetScale)) scale))
            (SETQ *squareOrigin* (ATS:GetKeyword *squareOrigin* (LIST "IE" "ID" "SE" "SD") "\nEscolha a origem da hachura: \n"))
          )
        )
        (SETQ scale (COND ((PROGN (INITGET 6) (GETREAL (STRCAT "\nInsira a escala: <" (RTOS scale) ">\n")))) (scale)))
      )
    )
    (SETQ scale "")
  )
  ;; Obtém o ângulo de rotação
  (SETQ rotation (ATS:GetPropertiesValues "Rotation" hatchProperties))
  (IF rotation
    ;; Verifica se a rotação é fixa
    (IF (NOT (ATS:GetPropertiesValues "PresetRotation" hatchProperties))
      (SETQ rotation (COND ((GETREAL (STRCAT "\nInsira a rotação: <" (RTOS rotation) ">\n"))) (rotation)))
    )
    (SETQ rotation "")
  )
  ;; Obtém a cor
  (SETQ color (ATS:GetPropertiesValues "Color" hatchProperties))
  (IF (NOT color)
    (SETQ color "")
  )
  ;; Obtém a cor de fundo
  (SETQ backgroundColor (ATS:GetPropertiesValues "BackgroundColor" hatchProperties))
  (IF (NOT backgroundColor)
    (SETQ backgroundColor "")
  )
  (SETQ layer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" hatchProperties)))
  ;; Verifica se existe um layer padrão e se ele está no arquivo
  (IF (NOT (ATS:InsertLayer layer))
    ;; Se não, utiliza o layer atual
    (SETQ layer (GETVAR "CLAYER"))
  )
  ;; Obtém a transparência
  (SETQ transparency (ATS:GetPropertiesValues "Transparency" hatchProperties))
  ;; Define a origem
  (COMMAND "_.-HATCH" "_ORIGIN" "_DEFAULT")
  (IF (EQ (TYPE presetScale) (READ "REAL"))
    (COMMAND (STRCAT "_" (COND
                           ((EQ *squareOrigin* "IE") "L")
                           ((EQ *squareOrigin* "ID") "R")
                           ((EQ *squareOrigin* "SE") "E")
                           ((EQ *squareOrigin* "SD") "I"))) "_NO")
    (COMMAND "_CENTER" "_YES")
  )
  ;; Define se a hachura é anotativa
  (COMMAND "_ANNOTATIVE")
  (IF (AND (EQ (TYPE *scaleFactor*) (READ "STR")) (NOT (EQ (TYPE presetScale) (READ "REAL")))) ; quando 'presetScale' é um número decimal, a hachura não deve ser influenciada pela escala do desenho
    (COMMAND "_YES")
    (PROGN
      (COMMAND "_NO")
      ;; Define a escala da hachura
      (IF (AND (EQ (TYPE scale) (READ "REAL"))
               (EQ (TYPE *scaleFactor*) (READ "REAL"))
               (NOT (EQ (TYPE presetScale) (READ "REAL"))))
        (SETQ scale (* scale *scaleFactor*))
      )
    )
  )
  (COMMAND "_PROPERTIES")
  (COND
    ;; Caso seja uma hachura sólida, aplica a cor
    ((EQ pattern "SOLID")
      (COMMAND pattern "" "_.-HATCH" "_COLOR") ; É preciso reiniciar o comando, pois a quantidade de argumentos muda caso o último padrão foi sólido ou não, pois se sim, não tem cor de fundo e vice-versa
      (IF (LISTP color)
        (COMMAND (CAR color) (CADR color))
        (COMMAND color)
      )
      (IF (EQ *CADSoftware* "ZWCAD")
        (COMMAND ".")
      )
    )
    ;; Caso seja um gradiente, aplica o tipo e a(s) cor(es)
    ((EQ pattern "_GRADIENT")
      (COMMAND "SOLID" "" "_.-HATCH" "_PROPERTIES" pattern (CAR backgroundColor) rotation "_YES" "_PROPERTIES" pattern) ; É preciso reiniciar o comando com a hachura anterior sólida para não perguntar cor de fundo, pois reiniciar com hachura gradiente não fica salvo o padrão
      (APPLY (FUNCTION COMMAND) (CDR backgroundColor))
     (IF (NOT (EQ *CADSoftware* "ZWCAD"))
       (PROGN
          (COMMAND "_COLOR")
          (IF (LISTP color)
            (COMMAND (CAR color) (CADR color))
            (COMMAND color)
          )
       )
     )
    )
    ;; Caso contrário, aplica a escala, rotação, cor e cor de fundo
    (T
      (COMMAND pattern scale rotation "" "_.-HATCH" "_COLOR")
      (IF (LISTP color)
        (COMMAND (CAR color) (CADR color))
        (COMMAND color)
      )
      (IF (LISTP backgroundColor)
        (COMMAND (CAR backgroundColor) (CADR backgroundColor))
        (COMMAND backgroundColor)
      )
    )
  )
  ;; Aplica o layer
  (COMMAND "_LAYER" layer)
  ;; Aplica a transparência
  (IF transparency
    (COMMAND "_TRANSPARENCY" transparency)
  )
  (IF selection
    (IF (LISTP selection) ; Tratamento caso seja uma lista de pontos
      (PROGN
        (FOREACH point selection
          (COMMAND point)
        )
        (COMMAND "")
      )
      (COMMAND "_SELECT" selection "" "")
    )
    (WHILE (> (GETVAR "CMDACTIVE") 0)
      (COMMAND PAUSE)
    )
  )
  ;; Aplica a escala anotativa
  (IF (AND (EQ (TYPE *scaleFactor*) (READ "STR")) (NOT (EQ (TYPE presetScale) (READ "REAL"))))
    (ATS:ApplyScaleFactor (SSADD (ENTLAST)) *scaleFactor*)
  )
)

;| Edita uma hachura
   @global
   @param hatchesSelection [ss] - Seleção de hachuras existentes
   @param hatchProperties [lst] - Lista de propriedade-valor nomeadas da hachura
   @returns [nil] - Edita a hachura conforme especificações
   |;
(DEFUN ATS:EditHatch (hatchesSelection hatchProperties / pattern scale presetScale rotation layer transparency color backgroundColor count entityName)
  ;; Armazena as propriedades da hachura
  (SETQ pattern (ATS:GetPropertiesValues "Pattern" hatchProperties))
  (SETQ scale (ATS:GetPropertiesValues "Scale" hatchProperties))
  ;; Obtém a escala
  (IF scale
    (PROGN
      (SETQ scale (* scale *unitsFactor*))
      ;; Verifica se a escala é fixa
      (IF (SETQ presetScale (ATS:GetPropertiesValues "PresetScale" hatchProperties))
        ;; Se for um número decimal, solicita o tamanho e posição do quadrado
        (IF (EQ (TYPE presetScale) (READ "REAL")) ; quando 'presetScale' é um número decimal, a hachura não deve ser influenciada pela escala do desenho
          ;; Caso a hachura seja quadriculada
          (PROGN
            (ATS:SetDefaultValues
              (LIST
                (CONS (QUOTE *squareSize*) presetScale)
                (CONS (QUOTE *squareOrigin*) "IE")
              )
            )
            (SETQ scale (/ (COND ((PROGN (INITGET 6) (SETQ *squareSize* (GETREAL (STRCAT "\nInsira o tamanho do lado: <" (RTOS *squareSize*) ">\n"))))) (presetScale)) scale))
            (SETQ *squareOrigin* (ATS:GetKeyword *squareOrigin* (LIST "IE" "ID" "SE" "SD") "\nEscolha a origem da hachura: \n"))
          )
          (IF (EQ (TYPE *scaleFactor*) (READ "REAL"))
            (SETQ scale (* scale *scaleFactor*))
          )
        )
        (SETQ scale (COND ((PROGN (INITGET 6) (GETREAL (STRCAT "\nInsira a escala: <" (RTOS scale) ">\n")))) (scale)))
      )
    )
    (SETQ scale "")
  )
  ;; Obtém o ângulo de rotação
  (SETQ rotation (ATS:GetPropertiesValues "Rotation" hatchProperties))
  (IF rotation
    ;; Verifica se a rotação é fixa
    (IF (AND rotation (NOT (ATS:GetPropertiesValues "PresetRotation" hatchProperties)))
      (SETQ rotation (COND ((GETREAL (STRCAT "\nInsira a rotação: <" (RTOS rotation) ">\n"))) (rotation)))
    )
    (SETQ rotation "")
  )
  ;; Obtém a cor
  (SETQ color (ATS:GetPropertiesValues "Color" hatchProperties))
  (IF (NOT color)
    (SETQ color "")
  )
  ;; Obtém a cor de fundo
  (SETQ backgroundColor (ATS:GetPropertiesValues "BackgroundColor" hatchProperties))
  (IF (NOT backgroundColor)
    (SETQ backgroundColor "")
  )
  (SETQ layer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" hatchProperties)))
  ;; Verifica se existe um layer padrão e se ele está no arquivo
  (IF (NOT (ATS:InsertLayer layer))
    ;; Se não, não altera o layer
    (SETQ layer nil)
  )
  ;; Obtém a transparência
  (SETQ transparency (ATS:GetPropertiesValues "Transparency" hatchProperties))
  ;; Aplica as alterações para cada hachura da seleção
  (SETQ count (SSLENGTH hatchesSelection))
  (REPEAT count
    (SETQ count (1- count))
    (SETQ entityName (SSNAME hatchesSelection count))
    ;; Define a origem
    (COMMAND "_.-HATCHEDIT" entityName "_ORIGIN" "_DEFAULT")
    (IF (EQ (TYPE presetScale) (READ "REAL"))
      (COMMAND (STRCAT "_" (COND
                             ((EQ *squareOrigin* "IE") "L")
                             ((EQ *squareOrigin* "ID") "R")
                             ((EQ *squareOrigin* "SE") "E")
                             ((EQ *squareOrigin* "SD") "I"))) "_NO")
      (COMMAND "_CENTER" "_YES")
    )
    ;; Define se a hachura é anotativa
    (COMMAND "_.-HATCHEDIT" entityName "_ANNOTATIVE")
    (IF (AND (EQ (TYPE *scaleFactor*) (READ "STR")) (NOT (EQ (TYPE presetScale) (READ "REAL")))) ; quando 'presetScale' é um número decimal, a hachura não deve ser influenciada pela escala do desenho
      (COMMAND "_YES")
      (COMMAND "_NO")
    )
    ;; Altera o padrão da hachura
    (COMMAND "_.-HATCHEDIT" entityName "_PROPERTIES" pattern)
    (COND
      ;; Caso seja uma hachura sólida, altera a cor
      ((EQ pattern "SOLID")
        (COMMAND "_.-HATCHEDIT" entityName "_COLOR")
        (IF (LISTP color)
          (COMMAND (CAR color) (CADR color))
          (COMMAND color)
        )
      )
      ;; Caso seja um gradiente, altera o tipo e a(s) cor(es)
      ((EQ pattern "_GRADIENT")
        (COMMAND (CAR backgroundColor) rotation "_YES")
        (COMMAND "_.-HATCHEDIT" entityName "_PROPERTIES" pattern)
        (APPLY (FUNCTION COMMAND) (CDR backgroundColor))
      )
      ;; Caso contrário, altera a escala, rotação, cor e cor de fundo
      (T
        (COMMAND scale rotation)
        (COMMAND "_.-HATCHEDIT" entityName "_COLOR")
        (IF (LISTP color)
          (COMMAND (CAR color) (CADR color))
          (COMMAND color)
        )
        (IF (LISTP backgroundColor)
          (COMMAND (CAR backgroundColor) (CADR backgroundColor))
          (COMMAND backgroundColor)
        )
      )
    )
    ;; Altera o layer
    (IF layer
      (COMMAND "_.-HATCHEDIT" entityName "_LAYER" layer)
    )
    ;; Altera a transparência
    (IF transparency
      (COMMAND-S "_.-HATCHEDIT" entityName "_TRANSPARENCY" transparency)
    )
  )
)

;| Abre uma lista de padrões e cria a hachura a partir de pontos selecionados, ou cria a hachura a partir de um contorno selecionado, ou edita uma hachura selecionada
   @returns nil
   |;
(DEFUN C:HH (/ *error* commandName hatchProperties)
  (SETQ commandName "HH")
  ;; Verifica se o padrão de hachura armazenado está na lista de hachuras, pois pode variar na troca de preset
  (SETQ hatchProperties (MAPCAR (FUNCTION CAR) *hatchesList*))
  (IF (NOT (MEMBER *hatchPattern* hatchProperties))
    (SETQ *hatchPattern* nil)
  )
  (ATS:SetDefaultValues
    (LIST
      (CONS (QUOTE *hatchPattern*) "Sólida")
    )
  )
  (COND
    ((NOT (SETQ hatchProperties (ATS:GetKeyword *hatchPattern* hatchProperties "\nEscolha o padrão de hachura predefinido: \n"))) (PROMPT "\nNenhum padrão de hachura especificado.\n"))
    (T
      (ATS:SaveUsersPreferences 6)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ *hatchPattern* hatchProperties)
      (SETQ hatchProperties (EVAL (CDR (ASSOC *hatchPattern* *hatchesList*))))
      (IF (AND *currentSelection* (SETQ *currentSelection* (ATS:FilterSelection nil nil *currentSelection* (LIST (CONS 0 "HATCH")))))
        (ATS:EditHatch *currentSelection* hatchProperties)
        (ATS:MakeHatch *currentSelection* hatchProperties)
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
