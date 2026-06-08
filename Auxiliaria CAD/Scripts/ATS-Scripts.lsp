(SETVAR "CMDECHO" 0)

;| Instruções para primeira configuração
   Copie o caminho da pasta Autots e, entre aspas e com barras duplas invertidas '\\' separando as pastas, inclusive no final,
   cole-o na frente de '*autotsFolder', logo abaixo neste arquivo, substituindo o valor anterior
   e, de acordo com suas preferências, configure as próximas 3 variáveis: '*preset*', '*sharedFolders*' e '*automaticCADConfig*'
|;

(SETQ *autotsFolder* (STRCAT (GETENV "USERPROFILE") "\\OneDrive\\Autots\\")) ; Caminho da pasta Autots
(SETQ *preset* T) ; Nome do preset padrão, ou 'T' para deduzir do arquivo atual
(SETQ *sharedFolders* T) ; 'T' para usar as pastas compartilhadas da Autots, ou 'nil' para manter as pastas padrões locais
(SETQ *automaticCADConfig* T) ; 'T' para automaticamente configurar as variáveis de sistema do CAD

;; Define variáveis globais
(SETQ *CADSoftware* (GETVAR "PRODUCT"))
(SETQ *CADLanguage* (IF (EQ *CADSoftware* "AutoCAD")
                      (VL-REGISTRY-READ (STRCAT "HKEY_LOCAL_MACHINE\\" (VLAX-PRODUCT-KEY)) "Language")))
(SETQ *acadObject* (VLAX-GET-ACAD-OBJECT))
(SETQ *activeDocument* (VLA-GET-ACTIVEDOCUMENT *acadObject*))

;| Carrega as automações Autots
   @global
   @param preset [str/bool] - Nome do preset a ser carregado, ou 'T' para deduzir do arquivo atual, ou 'nil' para carregar nenhum preset
   @returns [nil] - Carrega as automações
   |;
(DEFUN ATS:LoadScripts (preset / routinesFolder presetPath)
  ;; Carrega o preset Autots
  (SETQ presetPath (ATS:EvaluateStringSymbolList *presetsFolder*))
  (IF (AND *firstStart* (VL-CATCH-ALL-ERROR-P (VL-CATCH-ALL-APPLY (FUNCTION LOAD) (LIST (STRCAT presetPath "Autots.lsp")))))
    (PROGN
      (SETQ *failedLoads* (CONS "Autots.lsp" *failedLoads*))
      (ALERT "Erro ao carregar: Autots.lsp")
    )
  )
  ;; Carrega as rotinas
  (SETQ routinesFolder (ATS:EvaluateStringSymbolList *routinesFolder*))
  (SETQ *failedLoads* nil)
  (FOREACH routine (VL-DIRECTORY-FILES routinesFolder "*.lsp" 1)
    (IF (VL-CATCH-ALL-ERROR-P (VL-CATCH-ALL-APPLY (FUNCTION LOAD) (LIST (STRCAT routinesFolder routine))))
      (SETQ *failedLoads* (CONS routine *failedLoads*))
    )
  )
  ;; Carrega o preset
  (IF (EQ preset "Autots")
    (SETQ *preset* preset)
    (IF (VL-CATCH-ALL-ERROR-P (VL-CATCH-ALL-APPLY (FUNCTION LOAD) (LIST (STRCAT presetPath preset ".lsp"))))
      (PROGN
        (SETQ *preset* "Autots")
        (SETQ *failedLoads* (CONS (STRCAT preset ".lsp") *failedLoads*))
      )
      (SETQ *preset* preset)
    )
  )
  (IF *failedLoads*
    ;; Alerta erros de carregamento
    (ALERT (STRCAT "Erro ao carregar: " (ATS:ListToString ", " (REVERSE *failedLoads*))))
    (PROGN
      ;; Configura o CAD
      (ATS:SetPaths *sharedFolders* *automaticCADConfig*)
      (IF *automaticCADConfig*
        (ATS:SetSystemVariables nil *systemVariables*)
      )
    )
  )
)

;;; Carrega as automações
(IF (NOT *firstStart*)
  (PROGN
    (IF (OR
          ;; Verifica se o caminho da pasta Autots está adequado
          (AND
            (EQ (TYPE *autotsFolder*) (READ "STR"))
            (WCMATCH *autotsFolder* "*\\Autots\\"))
          ;; Senão, abre uma caixa de diálogo para selecionar a pasta Autots e, em seguida, libera os objetos e as variáveis
          (PROGN
            (SETQ o1 (VLAX-GET-ACAD-OBJECT))
            (SETQ o2 (VLA-GETINTERFACEOBJECT o1 "SHELL.APPLICATION"))
            (IF (SETQ o3 (VLAX-INVOKE-METHOD o2 "BROWSEFORFOLDER" (VLA-GET-HWND o1) "Selecione a pasta Autots" 16 nil))
              (PROGN
                (SETQ o4 (VLAX-GET-PROPERTY o3 "SELF"))
                (SETQ *autotsFolder* (STRCAT (VLAX-GET-PROPERTY o4 "PATH") "\\"))
                (FOREACH object (LIST (QUOTE o3) (QUOTE o4))
                  (VLAX-RELEASE-OBJECT (EVAL object))
                  (SET object nil))))
            (FOREACH object (LIST (QUOTE o1) (QUOTE o2))
              (VLAX-RELEASE-OBJECT (EVAL object))
              (SET object nil))
            (AND
              (EQ (TYPE *autotsFolder*) (READ "STR"))
              (WCMATCH *autotsFolder* "*\\Autots\\")
              (SETQ dialogBox T))))
      (PROGN
        ;; Carrega as extensões de VisualLISP e ExpressTools
        (VL-LOAD-COM)
        (VL-CATCH-ALL-APPLY (FUNCTION VL-CATCH-ALL-APPLY) (LIST (FUNCTION ACET-LOAD-EXPRESSTOOLS)))
        ;; Carrega o preset Autots para carregar as demais rotinas
        (IF (VL-CATCH-ALL-ERROR-P (VL-CATCH-ALL-APPLY (FUNCTION LOAD) (LIST (STRCAT *autotsFolder* "CAD\\Auxiliaria CAD\\Scripts\\Presets\\Autots.lsp"))))
          (ALERT "Erro ao carregar: Autots.lsp")
          (PROGN
            (IF (NOT (AND ;; Se o preset estiver definido como automático, procura, no nome do arquivo, o nome de algum preset
                       (EQ *preset* T)
                       (SETQ *preset* (GETVAR "DWGPREFIX"))
                       (SETQ *preset* (VL-SOME (FUNCTION (LAMBDA (preset)
                                                           (IF (WCMATCH *preset* (STRCAT "*" preset "*"))
                                                             preset)))
                                               (REVERSE (MAPCAR
                                                          (FUNCTION VL-FILENAME-BASE)
                                                          (VL-DIRECTORY-FILES (ATS:EvaluateStringSymbolList *presetsFolder*) "*.lsp" 1)))))))
              ;; Se o preset não for encontrado, define como Autots
              (IF *preset*
                (IF (NOT (FINDFILE (STRCAT (ATS:EvaluateStringSymbolList *presetsFolder*) *preset* ".lsp")))
                  (PROGN
                    (ALERT (STRCAT *preset* ".lsp não encontrado."))
                    (SETQ *preset* "Autots")
                  )
                )
                (SETQ *preset* "Autots")
              )
            )
            ;; Carrega as rotinas e o preset padrão
            (ATS:LoadScripts *preset*)
            ;; Cria o arquivo de log
            (SETQ *loginName* (ATS:FixLoginName *loginName*))
            (SETQ logName (ATS:EvaluateStringSymbolList (APPEND *scriptsLogFolder* *scriptsLog*)))
            (IF (NOT (FINDFILE logName))
              (PROGN
                (SETQ logName (OPEN logName "W"))
                (WRITE-LINE "Data|Horário|Preset|Diretório|Arquivo|Comando|Iterações|Erro" logName)
                (CLOSE logName)
              )
            )
            (SETQ logName nil)
            (SETQ *firstStart* T)
          )
        )
      )
      (SETQ *autotsFolder* nil)
    )
    (SETVAR "CMDECHO" 1)
    (IF *autotsFolder*
      (PROGN
        (IF (NOT *failedLoads*)
          (PRINC "\nTodas as rotinas foram carregadas com sucesso.\n")
        )
        (IF dialogBox
          (PROGN
            (SETQ dialogBox nil)
            (ALERT (STRCAT "Para finalizar sua configuração:"
                           "\n1 - Copie o caminho (com as aspas) presente na barra de comandos logo abaixo;"
                           "\n2 - Abra o arquivo \"" *scriptsMain* "\"; e"
                           "\n3 - Substitua o campo da pasta Autots \"*autotsFolder*\" com o caminho copiado.\n"
                           "\nO resultado, no arquivo editado, se dará da seguinte forma:"
                           "\n(SETQ *autotsFolder* \"C:\\\\Caminho\\\\Entre Aspas\\\\E Barras Duplas\\\\)"))
            (PRINC (STRCAT "\n\"" *autotsFolder* "\"\n"))
          )
        )
      )
      (PRINC "\nNão foi possível identificar a pasta Autots.\n")
    )
  )
)
