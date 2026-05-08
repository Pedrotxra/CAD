;| Define valores padrão para variáveis não definidas
   @global
   @param valuesList [lst] - Lista de variáveis e seus valores padrão
   @returns [any] - Valor da última variável iterada
   |;
(DEFUN ATS:SetDefaultValues (valuesList)
  (FOREACH value valuesList
    (IF (NOT (EVAL (CAR value)))
      (SET (CAR value) (CDR value))
    )
  )
)

;| Formata palavras-chave para prefixos de caixa alta únicos
   @global
   @param keywords [lst] - Lista de palavras-chave
   @returns [lst] - Lista de palavras-chave únicas
   |;
(DEFUN ATS:UniqueKeywords (keywords / upperCurrentKeyword prefixLength totalLength minimalPrefixLength compareKeywords)
  ;; Compara a ambiguidade dos prefixos das palavras-chave
  (FOREACH currentKeyword keywords
    (SETQ upperCurrentKeyword (STRCASE currentKeyword))
    (SETQ prefixLength 1)
    (SETQ totalLength (STRLEN currentKeyword))
    (SETQ minimalPrefixLength totalLength)
    (SETQ compareKeywords (MAPCAR (FUNCTION STRCASE) (VL-REMOVE currentKeyword keywords)))
    ;; Procura o menor prefixo que não conflita com nenhuma outra palavra
    (WHILE (<= prefixLength totalLength)
      ;; Verifica se, com o tamanho do prefixo atual, existe alguma ambiguidade
      (IF (VL-SOME (FUNCTION (LAMBDA (compareKeyword)
                               (AND (>= (STRLEN compareKeyword) prefixLength)
                                    (EQ (SUBSTR upperCurrentKeyword 1 prefixLength) (SUBSTR compareKeyword 1 prefixLength))))) compareKeywords)
        ;; Se sim, aumenta o comprimento do prefixo para nova comparação
        (SETQ prefixLength (1+ prefixLength))
        ;; Se não, define o comprimento mínimo do prefixo e encerra a busca
        (PROGN
          (SETQ minimalPrefixLength prefixLength)
          (SETQ prefixLength (1+ totalLength))
        )
      )
    )
    ;; Substitui a palavra-chave com o prefixo único
    (SETQ keywords (SUBST (STRCAT (SUBSTR upperCurrentKeyword 1 minimalPrefixLength) (SUBSTR currentKeyword (1+ minimalPrefixLength))) currentKeyword keywords))
  )
)

;| Apara o sufixo de uma string
   @global
   @param string [str] - String
   @returns [str] - String sem o sufixo
   |;
(DEFUN ATS:TrimSuffix (string)
  (COND
    ;; Verifica se a string possui sufixo numérico
    ((WCMATCH string "*#")
      (VL-STRING-RIGHT-TRIM (STRCAT *affixSeparator* *secondaryAffixSeparator* "0" (ITOA (LAST (ATS:IntegersFromString string)))) string)
    )
    ;; Verifica se a string termina com o sufixo de bloco na versão frontal/lateral
    ((WCMATCH string (STRCAT "*" *affixSeparator* *frontViewSuffix* ",*" *affixSeparator* *sideViewSuffix*))
      (SUBSTR string 1 (ATS:FindLastOccurrence *affixSeparator* string))
    )
    (string)
  )
)

;| Agrupa as palavras-chave por prefixos comuns
   @global
   @param defaultAnswer [str] - Resposta padrão
   @param keywords [lst] - Lista de palavras-chave
   @returns [lst] - Palavras-chave agrupadas
   |;
(DEFUN ATS:GroupKeywords (defaultAnswer keywords / prefixes prefix minorDefaultAnswer)
  ;; Gera a lista de prefixos que se difere da lista original completa
  (SETQ prefixes keywords)
  (FOREACH keyword prefixes
    ;; Extrai o prefixo
    (SETQ prefix (ATS:TrimSuffix keyword))
    ;; Verifica se o prefixo se repete
    (IF (VL-SOME (FUNCTION (LAMBDA (otherKeyword) (EQ (STRCASE prefix) (STRCASE (ATS:TrimSuffix otherKeyword))))) (VL-REMOVE keyword keywords))
      (PROGN
        (COND
          ;; Verifica se o prefixo já está presente, senão o adiciona
          ((NOT (MEMBER prefix prefixes))
            (SETQ prefixes (SUBST prefix keyword prefixes))
          )
          ;; Verifica se o prefixo é igual à palavra-chave, senão a remove
          ((NOT (EQ prefix keyword))
            (SETQ prefixes (VL-REMOVE keyword prefixes))
          )
        )
        ;; Armazena a resposta padrão menor e ajusta a resposta padrão para o prefixo
        (IF (EQ keyword defaultAnswer)
          (PROGN
            (SETQ minorDefaultAnswer (STRCASE defaultAnswer T))
            (SETQ defaultAnswer prefix)
          )
        )
      )
    )
  )
  (LIST defaultAnswer prefixes minorDefaultAnswer)
)

;| Separa a lista de palavras-chave em sublistas de tamanhos máximos
   @global
   @param keywords [lst] - Lista de palavras-chave
   @returns [lst] - Palavras-chave separadas
   |;
(DEFUN ATS:SplitKeywords (keywords / count keywordsList)
  (SETQ keywords (ATS:SplitListByLength *keywordsListMaxLength* keywords))
  (SETQ count (LENGTH keywords))
  (REPEAT count
    (SETQ count (1- count))
    (SETQ keywordsList (NTH count keywords))
    ;; Acrescenta a opção de prosseguir para as sublistas anteriores à última
    (IF (< count (1- (LENGTH keywords)))
      (PROGN
        (SETQ keywords (SUBST (CONS *nextKeywordSublist* keywordsList) keywordsList keywords))
        (SETQ keywordsList (CONS *nextKeywordSublist* keywordsList))
      )
    )
    ;; Acrescenta a opção de regredir para as sublistas posteriores à primeira
    (IF (> count 0)
      (SETQ keywords (SUBST (CONS *previousKeywordSublist* keywordsList) keywordsList keywords))
    )
  )
  keywords
)

;| Obtém a resposta do usuário de uma lista de palavras-chave
   @global
   @param defaultAnswer [str] - Resposta padrão
   @param keywords [lst] - Lista de palavras-chave
   @param message [str] - Mensagem a ser exibida ao usuário
   @returns [str] - Palavra-chave escolhida pelo usuário
   |;
(DEFUN ATS:GetKeyword (defaultAnswer keywords message / fixedKeywords prefixes minorDefaultAnswer position count keywordsList answer minorKeywordsList minorPosition)
  ;; Remove os espaços de cada palavra-chave
  (SETQ fixedKeywords (MAPCAR (FUNCTION (LAMBDA (keyword) (ATS:ReplaceAllInString "" " " keyword))) keywords))
  ;; Agrupa as palavras-chave por prefixos comuns
  (SETQ minorDefaultAnswer (ATS:GroupKeywords (ATS:ReplaceAllInString "" " " defaultAnswer) fixedKeywords))
  (SETQ defaultAnswer (NTH 0 minorDefaultAnswer))
  (SETQ prefixes (NTH 1 minorDefaultAnswer))
  (SETQ minorDefaultAnswer (NTH 2 minorDefaultAnswer))
  ;; Verifica se a lista de palavras-chave excede o tamanho máximo
  (IF (> (LENGTH prefixes) *keywordsListMaxLength*)
    (PROGN
      ;; Obtém a posição da sublista correspondente à resposta padrão
      (SETQ position (/ (VL-POSITION defaultAnswer prefixes) *keywordsListMaxLength*))
      ;; Separa a lista de palavras-chave em sublistas de tamanhos máximos e formata as palavras-chave para prefixos de caixa alta únicos
      (SETQ prefixes (MAPCAR (FUNCTION ATS:UniqueKeywords) (ATS:SplitKeywords prefixes)))
      ;; Obtém a sublista de palavras-chave correspondente à resposta padrão
      (SETQ keywordsList (NTH position prefixes))
    )
    (PROGN
      (SETQ prefixes (ATS:UniqueKeywords prefixes))
      (SETQ keywordsList prefixes)
    )
  )
  ;; Ajusta a resposta padrão para a palavra-chave formatada
  (SETQ defaultAnswer (STRCASE defaultAnswer))
  (SETQ defaultAnswer (VL-SOME (FUNCTION (LAMBDA (keyword) (IF (EQ defaultAnswer (STRCASE keyword)) keyword))) keywordsList))
  ;; Solicita a resposta ao usuário até que uma válida seja fornecida
  (WHILE (NOT answer)
    ;; Solicita a resposta ao usuário
    (INITGET (ATS:ListToString " " keywordsList))
    (SETQ answer (COND
                   ((GETKWORD (STRCAT message "[" (ATS:ListToString "/" keywordsList) "]<" defaultAnswer ">")))
                   (defaultAnswer)))
    (IF (COND
          ;; Verifica se a resposta foi uma das opções de navegação
          ((EQ (STRCASE answer) (STRCASE *previousKeywordSublist*))
            ;; Verifica se está em uma sublista menor
            (IF minorPosition
              (PROGN
                (SETQ minorPosition (1- minorPosition))
                (SETQ keywordsList (NTH minorPosition prefixes))
              )
              (PROGN
                (SETQ position (1- position))
                (SETQ keywordsList (NTH position prefixes))
              )
            )
            (SETQ defaultAnswer (CAR keywordsList)))
          ((EQ (STRCASE answer) (STRCASE *nextKeywordSublist*))
            ;; Verifica se está em uma sublista menor
            (IF minorPosition
              (PROGN
                (SETQ minorPosition (1+ minorPosition))
                (SETQ keywordsList (NTH minorPosition prefixes))
              )
              (PROGN
                (SETQ position (1+ position))
                (SETQ keywordsList (NTH position prefixes))
              )
            )
            (SETQ defaultAnswer (CAR keywordsList)))
          ((EQ (STRCASE answer) (STRCASE *upperKeywordSublist*))
            ;; Obtém o prefixo da palavra-chave selecionada e a atribui como resposta padrão
            (SETQ defaultAnswer (CADR keywordsList))
            (SETQ defaultAnswer (STRCASE (ATS:TrimSuffix defaultAnswer)))
            (SETQ defaultAnswer (VL-SOME (FUNCTION (LAMBDA (keyword) (IF (EQ defaultAnswer (STRCASE keyword)) keyword))) prefixes))
            ;; Verifica se há sublistas principais
            (IF position
              (SETQ keywordsList (NTH position prefixes))
              (SETQ keywordsList prefixes)))
          ;; Verifica se a resposta está em caixa baixa ou não possui prefixo comum
          ((AND (NOT (EQ answer (STRCASE answer T)))
                (SETQ answer (STRCASE answer))
                (SETQ minorKeywordsList (VL-REMOVE-IF-NOT (FUNCTION (LAMBDA (keyword) (EQ answer (STRCASE (ATS:TrimSuffix keyword))))) fixedKeywords))
                (> (LENGTH minorKeywordsList) 1))
            ;; Se não, formata a lista menor
            (SETQ minorKeywordsList (MAPCAR (FUNCTION (LAMBDA (keyword) (STRCASE keyword T))) minorKeywordsList))
            ;; Verifica se a resposta padrão faz parte da lista menor
            (IF (MEMBER minorDefaultAnswer minorKeywordsList)
              (SETQ defaultAnswer minorDefaultAnswer)
              (SETQ defaultAnswer (CAR minorKeywordsList))
            )
            ;; Verifica se a lista de palavras-chave excede o tamanho máximo
            (IF (> (LENGTH minorKeywordsList) *keywordsListMaxLength*)
              (PROGN
                (SETQ minorPosition (VL-POSITION minorDefaultAnswer minorKeywordsList))
                (SETQ minorPosition (IF minorPosition (/ minorPosition *keywordsListMaxLength*) 0))
                ;; Separa a lista de palavras-chave em sublistas de tamanhos máximos e acrescenta a opção de regressar à lista principal
                (SETQ minorKeywordsList (MAPCAR (FUNCTION (LAMBDA (keywordsList) (CONS *upperKeywordSublist* keywordsList))) (ATS:SplitKeywords minorKeywordsList)))
                ;; Altera a sublista a ser exibida ao usuário
                (SETQ keywordsList (NTH minorPosition minorKeywordsList))
              )
              (SETQ keywordsList (CONS *upperKeywordSublist* minorKeywordsList))
            )
          )
        )
      ;; Repete a solicitação se a resposta for inválida
      (SETQ answer nil)
    )
  )
  ;; Busca a palavra-chave pela entrada original
  (SETQ answer (STRCASE answer))
  (VL-SOME (FUNCTION (LAMBDA (keyword) (IF (EQ answer (STRCASE (ATS:ReplaceAllInString "" " " keyword))) keyword))) keywords)
)

;| Ordena alfanumericamente uma lista de strings
   @global
   @param stringList [lst] - Lista de strings
   @returns [lst] - Lista de strings ordenada alfabeticamente
   |;
(DEFUN ATS:SortAlphanumerically (stringList)
  (VL-SORT stringList (FUNCTION (LAMBDA (firstWord secondWord / minLength count firstWordLetter secondWordLetter)
                                  (SETQ firstWord (VL-STRING->LIST (STRCASE firstWord)))
                                  (SETQ secondWord (VL-STRING->LIST (STRCASE secondWord)))
                                  (SETQ minLength (MIN (LENGTH firstWord) (LENGTH secondWord)))
                                  (SETQ count 0)
                                  (WHILE (AND (<= count minLength)
                                              (EQ (SETQ firstWordLetter (NTH count firstWord))
                                                  (SETQ secondWordLetter (NTH count secondWord))))
                                    (SETQ count (1+ count))
                                  )
                                  (IF (> count minLength)
                                    (< (LENGTH firstWord) (LENGTH secondWord))
                                    (< firstWordLetter secondWordLetter)))))
)

;| Converte um texto para o formato de frase (apenas a primeira letra maiúscula)
   @global
   @param inputText [str] - String com as caixas originais
   @returns [str] - String em formato de frase
   |;
(DEFUN ATS:ConvertToSentenceCase (inputText / specialCharacter)
  (VL-LIST->STRING
    (MAPCAR
      (FUNCTION
        (LAMBDA (previousCharacter upperCaseCharacter lowerCaseCharacter)
          (IF (OR specialCharacter (MEMBER previousCharacter (LIST 33 46 63))) ; Verifica se o caractere anterior é: !, . ou ?
            (PROGN
              (SETQ specialCharacter (EQ upperCaseCharacter lowerCaseCharacter))
              upperCaseCharacter
            )
            lowerCaseCharacter
          )
        )
      )
      (CONS 46 (VL-STRING->LIST inputText))
      (VL-STRING->LIST (STRCASE inputText))
      (VL-STRING->LIST (STRCASE inputText T))
    )
  )
)

;| Converte um texto para o formato de título (iniciais maiúsculas)
   @global
   @param inputText [str] - String com as caixas originais
   @returns [str] - String em formato de título
   |;
(DEFUN ATS:ConvertToTitleCase (inputText)
  (IF inputText
    (VL-LIST->STRING (MAPCAR
                       (FUNCTION (LAMBDA (previousCharacter upperCaseCharacter lowerCaseCharacter)
                                   (IF (EQ 32 previousCharacter) ; Verifica se o caractere anterior é um espaço
                                     upperCaseCharacter
                                     lowerCaseCharacter)))
                       (CONS 32 (VL-STRING->LIST inputText))
                       (VL-STRING->LIST (STRCASE inputText))
                       (VL-STRING->LIST (STRCASE inputText T))))
  )
)

;| Alterna as letras entre minúsculas e maiúsculas
   @global
   @param inputText [str] - String com as caixas originais
   @returns [str] - String com as caixas alternadas
   |;
(DEFUN ATS:ToggleCase (inputText)
  (IF inputText
    (VL-LIST->STRING (MAPCAR
                       (FUNCTION (LAMBDA (character upperCaseCharacter lowerCaseCharacter)
                                   (IF (< 96 character 123) ; Verifica se o caractere é maiúsculo
                                     upperCaseCharacter
                                     lowerCaseCharacter)))
                       (VL-STRING->LIST inputText)
                       (VL-STRING->LIST (STRCASE inputText))
                       (VL-STRING->LIST (STRCASE inputText T))))
  )
)

;| Substitui todas as ocorrências de um padrão em uma string
   @global
   @param newPattern [str] - Padrão a substituir
   @param oldPattern [str] - Padrão a ser substituído
   @param fullString [str] - String completa onde a substituição será feita
   @returns [str] - String com as substituições realizadas
   |;
(DEFUN ATS:ReplaceAllInString (newPattern oldPattern fullString / lengthDifference startPosition)
  (SETQ lengthDifference (- (STRLEN newPattern) (STRLEN oldPattern)))
  (SETQ startPosition 0)
  (WHILE (SETQ startPosition (VL-STRING-SEARCH oldPattern fullString startPosition))
    (SETQ fullString (VL-STRING-SUBST newPattern oldPattern fullString startPosition))
    (SETQ startPosition (1+ (+ startPosition lengthDifference)))
  )
  fullString
)

;| Formata uma string para ignorar caracteres especiais em uma busca coringa
   @global
   @param stringForWildcardMatch [str] - String sem caracteres especiais escapados
   @returns [str] - String com caracteres especiais escapados
   |;
(DEFUN ATS:EscapesSpecialCharacters (stringForWildcardMatch)
  (FOREACH specialCharacter (LIST "`" "#" "@" "." "*" "?" "~" "[" "]" "-" ",")
    (SETQ stringForWildcardMatch (ATS:ReplaceAllInString (STRCAT "`" specialCharacter) specialCharacter stringForWildcardMatch))
  )
)

;| Coloca um afixo no nome, sequenciando caso seja um número
   @global
   @param separator [str] - Separador entre o afixo e o nome
   @param affixPosition [bool] - 'T' para prefixo, ou 'nil' para sufixo
   @param affix [str/int] - Afixo a ser adicionado. Caso seja um número, o novo nome será ele +1
   @param name [str] - Nome ao qual o afixo será adicionado
   @returns [str] - Nome com o afixo adicionado
   |;
(DEFUN ATS:AffixName (separator affixPosition affix name / affixNumber newAffix)
  (IF affixPosition
    (IF (EQ (TYPE affix) (READ "INT"))
      (PROGN
        (SETQ affixNumber (CAR (ATS:IntegersFromString name)))
        (IF (AND affixNumber (WCMATCH name (STRCAT (ITOA affixNumber) (ATS:EscapesSpecialCharacters separator) "*")))
          (PROGN
            (SETQ newAffix (1+ affixNumber))
            (SETQ name (VL-STRING-LEFT-TRIM (STRCAT (ITOA affixNumber) separator) name))
          )
          (SETQ newAffix (1+ affix))
        )
        (SETQ name (STRCAT (ITOA newAffix) separator name))
      )
      (SETQ name (STRCAT affix separator name))
    )
    (IF (EQ (TYPE affix) (READ "INT"))
      (PROGN
        (SETQ affixNumber (LAST (ATS:IntegersFromString name)))
        (IF (AND affixNumber (WCMATCH name (STRCAT "*" (ATS:EscapesSpecialCharacters separator) (ITOA affixNumber))))
          (PROGN
            (SETQ newAffix (1+ affixNumber))
            (SETQ name (VL-STRING-RIGHT-TRIM (STRCAT separator (ITOA affixNumber)) name))
          )
          (SETQ newAffix (1+ affix))
        )
        (SETQ name (STRCAT name separator (ITOA newAffix)))
      )
      (SETQ name (STRCAT name separator affix))
    )
  )
)

;| Encontra a última ocorrência de um padrão em uma string
   @global
   @param pattern [str] - Padrão a ser encontrado
   @param fullString [str] - String completa onde o padrão será buscado
   @returns [int] - Posição da última ocorrência do padrão
   |;
(DEFUN ATS:FindLastOccurrence (pattern fullString / searchPosition patternLength lastPosition)
  (SETQ searchPosition 0)
  (SETQ patternLength (STRLEN pattern))
  (WHILE (SETQ searchPosition (VL-STRING-SEARCH pattern fullString searchPosition))
    (SETQ lastPosition searchPosition)
    (SETQ searchPosition (+ searchPosition patternLength))
  )
  lastPosition
)

;| Retorna a substring entre dois padrões em uma string
   @global
   @param startPattern [str] - Padrão da string que indica o início da substring
   @param endPattern [str] - Padrão da string que indica o final da substring
   @param fullString [str] - String com a substring
   @returns [str] - Substring encontrada entre os padrões
   |;
(DEFUN ATS:GetSubstring (startPattern endPattern fullString / stringLength startPosition endPosition)
  (SETQ stringLength (STRLEN fullString))
  (IF (AND
        (SETQ startPosition (IF (> (STRLEN startPattern) 0)
                              (VL-STRING-SEARCH startPattern fullString)
                              0))
        (SETQ startPosition (+ 1 (STRLEN startPattern) startPosition))
        (<= startPosition stringLength)
        (SETQ endPosition (IF (> (STRLEN endPattern) 0)
                            (VL-STRING-SEARCH endPattern fullString startPosition)
                            stringLength))
      )
    (SUBSTR fullString startPosition (- (1+ endPosition) startPosition))
  )
)

;| Extrai números inteiros de uma string
   @global
   @param fullString [str] - String com os números a serem extraídos
   @returns [lst] - Lista de números inteiros extraídos
   |;
(DEFUN ATS:IntegersFromString (fullString / IsDigit ExtractIntegers)
  ;; Função auxiliar para verificar se um caractere é um dígito.
  (DEFUN IsDigit (digitChar)
    (AND (>= digitChar 48) (<= digitChar 57))
  )
  ;; Função auxiliar para coletar números inteiros de uma lista de caracteres.
  (DEFUN ExtractIntegers (charactersList / collectedDigits integerChar)
    (WHILE (AND charactersList (NOT (IsDigit (CAR charactersList))))
      (SETQ charactersList (CDR charactersList))
    )
    (WHILE (AND charactersList (IsDigit (CAR charactersList)))
      (SETQ collectedDigits (CONS (CAR charactersList) collectedDigits))
      (SETQ charactersList (CDR charactersList))
    )
    (IF collectedDigits
      (CONS (ATOI (VL-LIST->STRING (REVERSE collectedDigits))) (ExtractIntegers charactersList))
    )
  )
  (ExtractIntegers (VL-STRING->LIST fullString))
)

;| Adiciona 0s à esquerda de um número
   @global
   @param totalDigits [int] - Quantidade total de dígitos
   @param number [str] - Número a receber 0s a esquerda
   @returns [str] - Número formatado com 0s à esquerda
   |;
(DEFUN ATS:AddLeftZeros (totalDigits number)
  (WHILE (< (STRLEN number) totalDigits)
    (SETQ number (STRCAT "0" number))
  )
  number
)

;| Adiciona o separador de milhar
   @global
   @param number [str] - Número
   @returns [str] - Número formatado
   |;
(DEFUN ATS:AddThousandsSeparator (number / decimal)
  (IF (VL-STRING-POSITION 46 number)
    (PROGN
      (SETQ decimal (ATS:GetSubstring "." "" number))
      (SETQ number (ATS:GetSubstring "" "." number))
    )
  )
  (SETQ count (STRLEN number))
  (SETQ fullNumber "")
  (WHILE (> count 3)
    (SETQ fullNumber (STRCAT "." (SUBSTR number (- count 2) 3) fullNumber))
    (SETQ count (- count 3))
  )
  (SETQ fullNumber (STRCAT (SUBSTR number 1 count) fullNumber))
  (IF decimal
    (STRCAT fullNumber "," decimal)
    fullNumber
  )
)

;| Formata o valor de área para o texto padrão
   @global
   @param prefix [str] - Prefixo
   @param suffix [str] - Sufixo
   @param area [real] - Área
   @returns [str] - Área formatada
   |;
(DEFUN ATS:FormatArea (prefix suffix area)
  (STRCAT prefix (ATS:AddThousandsSeparator (RTOS (* area (/ (EXPT *unitsFactor* 2) 10000)) 2 2)) suffix)
)

;| Escreve um nome com o sobrenome abreviado
   @global
   @param fullName [str] - Nome completo do usuário
   @returns [str] - Nome com o sobrenome abreviado
   |;
(DEFUN ATS:WriteShortenedName (fullName / lastSpacePosition)
  (SETQ lastSpacePosition (VL-STRING-POSITION 32 fullName 0 T))
  (IF lastSpacePosition
    (STRCAT (SUBSTR fullName 1 (+ lastSpacePosition 2)) ".")
    fullName
  )
)

;| Escreve as iniciais do nome do usuário
   @global
   @param fullName [str] - Nome completo do usuário
   @returns [str] - Iniciais do nome do usuário
   |;
(DEFUN ATS:WriteNameInitials (fullName / lastSpacePosition)
  (SETQ lastSpacePosition (VL-STRING-POSITION 32 fullName 0 T))
  (IF lastSpacePosition
    (STRCAT (SUBSTR fullName 1 1) "." (SUBSTR fullName (+ lastSpacePosition 2) 1) ".")
    fullName
  )
)

;| Escreve a data atual
   @global
   @param backwards [bool] - 'T' para ANO/MÊS/DIA, ou 'nil' para DIA/MÊS/ANO
   @param time [bool] - 'T' para incluir a hora
   @returns 
   |;
(DEFUN ATS:WriteCurrentDate (backwards time / currentDateAndTime currentDate)
  (SETQ currentDateAndTime (RTOS (GETVAR "CDATE") 2 6))
  (SETQ year (SUBSTR currentDateAndTime 1 4))
  (SETQ month (SUBSTR currentDateAndTime 5 2))
  (SETQ day (SUBSTR currentDateAndTime 7 2))
  (IF backwards
    (SETQ currentDate (STRCAT year "/" month "/" day))
    (SETQ currentDate (STRCAT day "/" month "/" year))
  )
  (IF time
    (PROGN
      (WHILE (< (STRLEN currentDateAndTime) 15)
        (SETQ currentDateAndTime (STRCAT currentDateAndTime "0"))
      )
      (STRCAT currentDate " " (SUBSTR currentDateAndTime 10 2) "h" (SUBSTR currentDateAndTime 12 2) "min" (SUBSTR currentDateAndTime 14 2) "s")
    )
    currentDate
  )
)

;| Registra a entrada de um comando
   @global
   @param commandName [str] - Nome do comando que gerou o log
   @param errorMessage [str] - Mensagem de erro a ser registrada, ou 'nil' para não registrar entrada
   @returns [nil] - Registra a entrada no log
   |;
(DEFUN ATS:WriteLog (commandName errorMessage / currentDateAndTime dwgFile scriptsLogFile)
  (SETQ scriptsLogFile (OPEN (ATS:EvaluateStringSymbolList (APPEND *scriptsLogFolder* *scriptsLog*)) "A"))
  (WRITE-LINE (STRCAT (VL-STRING-SUBST "|" " " (ATS:WriteCurrentDate T T)) "|" *preset* "|" (GETVAR "DWGPREFIX") "|" (GETVAR "DWGNAME") "|" commandName "|" (COND (errorMessage) (""))) scriptsLogFile)
  (CLOSE scriptsLogFile)
)

;| Cria uma sequência numérica em textos
   @returns nil
   |;
(DEFUN C:SEQ (/ *error* commandName textEntity)
  (SETQ commandName "SEQ")
  (ATS:SetDefaultValues
    (LIST
      (CONS (QUOTE *prefix*) "")
      (CONS (QUOTE *suffix*) "")
      (CONS (QUOTE *startNumber*) 1)
      (CONS (QUOTE *increment*) 1)
    )
  )
  (COND
    ((NOT (SETQ *prefix* (COND ((GETSTRING T (STRCAT "\nInsira o PREFIXO do texto: <" *prefix* ">\n"))) (*prefix*)))) (PROMPT "\nPrefixo inválido.\n"))
    ((NOT (SETQ *suffix* (COND ((GETSTRING T (STRCAT "\nInsira o SUFIXO do texto: <" *suffix* ">\n"))) (*suffix*)))) (PROMPT "\nSufixo inválido.\n"))
    ((NOT (SETQ *startNumber* (COND ((GETINT (STRCAT "\nInsira o NÚMERO INICIAL: <" (ITOA *startNumber*) ">\n"))) (*startNumber*)))) (PROMPT "\nNúmero inicial inválido.\n"))
    ((NOT (SETQ *increment* (COND ((GETINT (STRCAT "\nInsira o INCREMENTO: <" (ITOA *increment*) ">\n"))) (*increment*)))) (PROMPT "\nIncremento inválido.\n"))
    ((NOT (SETQ textEntity (ATS:GetKeyword "Sim" (LIST "Sim" "Não") "\nDeseja selecionar todos os textos de uma vez?\n"))) (PROMPT "\nResposta inválida.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (IF (EQ textEntity "Sim")
        (IF (SETQ textEntity (SSGET (LIST (CONS 0 "ATTRIB,ATTDEF,*TEXT"))))
          (FOREACH textEntity (ATS:SortSelectionByPosition (* *paperUnitsFactor* 0.15) textEntity)
            (ATS:ChangePropertiesValues textEntity (LIST (CONS 1 (STRCAT *prefix* (ITOA *startNumber*) *suffix*))))
            (SETQ *startNumber* (+ *startNumber* *increment*))
          )
        )
        (WHILE (IF (SETQ textEntity (NENTSEL "\nSelecione o texto:\n"))
                (PROGN
                  (SETQ textEntity (ENTGET (CAR textEntity)))
                  (WCMATCH (CDR (ASSOC 0 textEntity)) "ATTRIB,ATTDEF,*TEXT")))
          (ATS:ChangePropertiesValues textEntity (LIST (CONS 1 (STRCAT *prefix* (ITOA *startNumber*) *suffix*))))
          (SETQ *startNumber* (+ *startNumber* *increment*))
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Copia o conteúdo de um texto para outros
   @returns nil
   |;
(DEFUN C:CCTXT (/ *error* commandName entityName entityType text)
  (SETQ commandName "CCTXT")
  (COND
    ((NOT (AND
            (SETQ entityName (CAR (NENTSEL "\nSelecione o texto de origem:\n")))
            (SETQ entityType (ATS:GetPropertiesValues 0 entityName))
            (WCMATCH entityType "ATTRIB,ATTDEF,*TEXT"))) (PROMPT "\nNenhum texto selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      ;; Verifica se o texto é uma definição de atributo
      (SETQ text (IF (EQ entityType "ATTDEF")
                   (ATS:GetPropertiesValues 2 entityName)
                   (ATS:GetPropertiesValues 1 entityName)))
      (WHILE (SETQ entityName (CAR (NENTSEL "\nSelecione o texto de destino:\n")))
        (SETQ entityType (ATS:GetPropertiesValues 0 entityName))
        (COND
          ((EQ entityType "ATTDEF") (ATS:ChangePropertiesValues entityName (LIST (CONS 2 text))))
          ((ATS:ChangePropertiesValues entityName (LIST (CONS 1 text))))
        )
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Justifica um texto multilinha
   @returns nil
   |;
(DEFUN C:JMTXT (/ *error* commandName entityName text)
  (SETQ commandName "JMTXT")
  (COND
    ((NOT (AND
            (SETQ entityName (CAR (NENTSEL "\nSelecione o texto multilinha\n")))
            (WCMATCH (ATS:GetPropertiesValues 0 entityName) "ATTRIB,MTEXT"))) (PROMPT "\nNenhum texto multilinha selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (SETQ text (ATS:GetPropertiesValues 1 entityName))
      (IF (WCMATCH text "~\\pxqj;*")
        (ATS:ChangePropertiesValues entityName (LIST (CONS 1 (STRCAT "\\pxqj;" text))))
        (PROMPT "\nO texto multilinha já está justificado.\n")
      )
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)

;| Transfere a área de um polígono fechado para um texto
   @returns nil
   |;
(DEFUN C:TAREA (/ *error* commandName selection text)
  (SETQ commandName "TAREA")
  (COND
    ((PROGN (PROMPT "\nSelecione a hachura ou polilinha fechada.\n") (NOT (SETQ selection (ATS:SelectSingleObject (LIST (CONS -4 "<OR") (CONS 0 "HATCH,SOLID") (CONS -4 "<AND") (CONS 0 "*POLYLINE") (CONS 70 1) (CONS -4 "AND>") (CONS -4 "OR>")))))) (PROMPT "\nNenhuma hachura ou polilinha fechada selecionada.\n"))
    ((NOT (AND (SETQ text (CAR (NENTSEL "\nClique no texto de destino.\n")))
               (WCMATCH (ATS:GetPropertiesValues 0 text) "ATTRIB,*TEXT"))) (PROMPT "\nNenhum texto selecionado.\n"))
    (T
      (ATS:SaveUsersPreferences nil)
      (DEFUN *error* (errorMessage)
        (ATS:RestoreUsersPreferences commandName errorMessage)
      )
      (VLA-PUT-TEXTSTRING (ATS:SaveObject text) (ATS:FormatArea "A=" "m²" (VLA-GET-AREA (ATS:SaveObject selection))))
      (ATS:RestoreUsersPreferences commandName nil)
    )
  )
)
