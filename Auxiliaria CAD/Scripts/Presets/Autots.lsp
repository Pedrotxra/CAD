;; Acesse a lista de comandos personalizados no link abaixo:
;; https://autots.notion.site/comandos-cad?v=1bc7787814ee4570bcd9c3a4d1fc6884&source=copy_link

;| Definições do arquivo 'Main'
(SETQ *autotsFolder* (STRCAT (GETENV "USERPROFILE") "\\OneDrive\\Autots\\")) ; Caminho da pasta Autots
(SETQ *preset* T) ; Nome do preset padrão, ou 'T' para deduzir do arquivo atual
(SETQ *sharedFolders* T) ; 'T' para usar as pastas compartilhadas da Autots, ou 'nil' para manter as pastas padrões locais
(SETQ *automaticCADConfig* T) ; 'T' para automaticamente configurar as variáveis de sistema do CAD
|;

;;; Caminhos das pastas
(SETQ *enterpriseFolder* (STRCAT (GETENV "USERPROFILE") "\\OneDrive\\"))
  (SETQ *designsFolder* (LIST (QUOTE *enterpriseFolder*) "Construção Civil\\"))
    (SETQ *customersFolder* (LIST (QUOTE *designsFolder*) "Clientes\\"))
      ;; Pasta do cliente
        ;; Pasta do projeto
          (SETQ *analysisFolderName* (LIST (QUOTE *designFolder*) "Análises\\"))
            ;; Análise 01, Análise 02, Análise 03...
          (SETQ *attachmentsFolderName* (LIST (QUOTE *designFolder*) "Anexos\\"))
          (SETQ *backupFolderName* (LIST (QUOTE *designFolder*) "Backup\\"))
          (SETQ *projectGuidelinesFolderName* (LIST (QUOTE *designFolder*) "Diretrizes\\"))
            (SETQ *sketchesFolderName* (LIST (QUOTE *projectGuidelinesFolderName*) "Esboços\\"))
            (SETQ *referencesFolderName* (LIST (QUOTE *projectGuidelinesFolderName*) "Referências\\"))
          (SETQ *emissionFolderName* (LIST (QUOTE *designFolder*) "Emissões\\"))
            ;; Pasta da etapa
              ;; Emissão Inicial, Revisão 01, Revisão 02...
          (SETQ *recievedFilesFolderName* (LIST (QUOTE *designFolder*) "Recebidos\\"))
            ;; Recebido 01, Recebido 02, Recebido 03...
          (SETQ *photosFolderName* (LIST (QUOTE *designFolder*) "Fotos\\"))
            ;; Visita 01, Visita 02, Visita 03...
  ;; Pasta Autots
    (SETQ *CADFolder* (LIST (QUOTE *autotsFolder*) "CAD\\"))
      (SETQ *auxiliaryFolder* (LIST (QUOTE *CADFolder*) "Auxiliaria CAD\\"))
        (SETQ *blocksFolder* (LIST (QUOTE *auxiliaryFolder*) "Blocos\\"))
        (SETQ *customUserInterfaceFolder* (LIST (QUOTE *auxiliaryFolder*) "Custom User Interface\\"))
          ;(SETQ *parcialCUI* "ATS-CustomUserInterface.cuix") ; Não pode conter espaços
          (SETQ *customIconsFolder* (LIST (QUOTE *customUserInterfaceFolder*) "Icons\\"))
        (SETQ *fontsFolder* (LIST (QUOTE *auxiliaryFolder*) "Fonts\\"))
        (SETQ *hatchesFolder* (LIST (QUOTE *auxiliaryFolder*) "Hachuras\\"))
        (SETQ *linetypesFolder* (LIST (QUOTE *auxiliaryFolder*) "Linetypes\\"))
        (SETQ *plottersFolder* (LIST (QUOTE *auxiliaryFolder*) "Plotters\\"))
          (SETQ *standardPlotter* (STRCAT "ATS-DWG To PDF.pc" (IF (EQ *CADSoftware* "ZWCAD") "5" "3")))
            (SETQ *sheetsSizes* (LIST ; Nome do bloco da folha e suas dimensões a partir do ponto base
                                  (CONS "A0 Estendido" (LIST -155.9 84.1))
                                  (CONS "A0" (LIST -118.9 84.1))
                                  (CONS "A1 Estendido" (LIST -118.9 59.4))
                                  (CONS "A1 Alongado" (LIST -102.5 59.4))
                                  (CONS "A1" (LIST -84.1 59.4))
                                  (CONS "A2" (LIST -59.4 42.0))
                                  (CONS "A3" (LIST -42.0 29.7))
                                  (CONS "A4" (LIST -21.0 29.7))))
          (SETQ *plotStylesFolder* (LIST (QUOTE *plottersFolder*) "Plot Styles\\"))
            (SETQ *standardPlotStyle* "ATS-Colorido.ctb")
          (SETQ *printerDescriptionFolder* (LIST (QUOTE *plottersFolder*) "PMP Files\\"))
            (SETQ *standardPrinterDescription* "ATS-DWG To PDF.pmp")
        (SETQ *profilesFolder* (LIST (QUOTE *auxiliaryFolder*) "Profiles\\"))
        (SETQ *scriptsFolder* (LIST (QUOTE *auxiliaryFolder*) "Scripts\\"))
          (SETQ *scriptsMain* "ATS-Scripts.lsp")
          (SETQ *routinesFolder* (LIST (QUOTE *scriptsFolder*) "Routines\\"))
          (SETQ *presetsFolder* (LIST (QUOTE *scriptsFolder*) "Presets\\"))
        (SETQ *templatesFolder* (LIST (QUOTE *auxiliaryFolder*) "Templates\\"))
          (SETQ *template* "ATS-Template.dwt")
          (SETQ *standards* "ATS-Standards.dws")
        (SETQ *toolPaletteFolder* (LIST (QUOTE *auxiliaryFolder*) "Tool Palette\\"))
      (SETQ *scriptsLogFolder* (LIST (QUOTE *CADFolder*) "Logs\\"))
        (SETQ *scriptsLog* (LIST (QUOTE *loginName*) ".log"))

(SETQ *projectTypes* (LIST ;; Em ordem de prioridade. Exemplo: em uma folha com desenhos 'ARQ' e 'LUM', o tipo 'ARQ' prevalece
                       (CONS "ARQUITETÔNICO" "ARQ")
                       (CONS "LEVANTAMENTO" "LEV")
                       (CONS "DEMOLIÇÃO" "DEM")
                       (CONS "LAYOUT" "LAY")
                       (CONS "FORRO" "FOR")
                       (CONS "ELÉTRICA" "ELE")
                       (CONS "TOMADAS" "ELE")
                       (CONS "HIDRÁULICA" "HID")
                       (CONS "LUMINOTÉCNICO" "LUM")
                       (CONS "PAGINAÇÃO" "PAG")
                       (CONS "DETALHAMENTO" "DET")))

(SETQ *projectPhases* (LIST
                        (LIST "LEVANTAMENTO"
                              (CONS "ShortenedProjectPhase" "LEV")
                              (CONS "ProjectPhaseFolderName" "00 - Levantamento\\"))
                        (LIST "ESTUDO PRELIMINAR"
                              (CONS "ShortenedProjectPhase" "EP")
                              (CONS "ProjectPhaseFolderName" "01 - Estudo Preliminar\\"))
                        (LIST "ANTEPROJETO"
                              (CONS "ShortenedProjectPhase" "AP")
                              (CONS "ProjectPhaseFolderName" "10 - Anteprojeto\\"))
                        (LIST "LEGAL"
                              (CONS "ShortenedProjectPhase" "LE")
                              (CONS "ProjectPhaseFolderName" "11 - Legal\\"))
                        (LIST "PRÉ-EXECUTIVO"
                              (CONS "ShortenedProjectPhase" "PRE")
                              (CONS "ProjectPhaseFolderName" "12 - Pré-executivo\\"))
                        (LIST "EXECUTIVO"
                              (CONS "ShortenedProjectPhase" "EX")
                              (CONS "ProjectPhaseFolderName" "20 - Executivo\\"))
                        (LIST "AS BUILT"
                              (CONS "ShortenedProjectPhase" "AB")
                              (CONS "ProjectPhaseFolderName" "30 - As Built\\"))
                        (LIST "BÁSICO"
                              (CONS "ShortenedProjectPhase" "BA")
                              (CONS "ProjectPhaseFolderName" "31 - Básico\\"))))

;;; Variáveis do sistema
(SETQ *systemVariables* (LIST
                          (LIST "TIMEZONE" -3000) ; Horário de Brasília
                          (LIST "OSMODE" 5375)
                          (LIST "POLARANG" (/ PI 4)) ; Polar de 45°
                          (LIST "GRIDMODE" 0)
                          (LIST "UCSICON" 1) ; Ícone do UCS sempre no canto inferior esquerdo
                          (LIST "NAVBARDISPLAY" 0)
                          (LIST "NAVVCUBEDISPLAY" 0)
                          (LIST "EDGEMODE" 1) ; Extend e Trim usam a extensão infinita da linha de referência
                          (LIST "LTSCALE" (QUOTE *standardLineTypeScale*))
                          (LIST "REVCLOUDCREATEMODE" 1)
                          (LIST "LUNITS" 2) ; Decimal
                          (LIST "LUPREC" 4) ; 4 casas depois da vírgula
                          (LIST "DIMZIN" 8) ; Apenas zeros a direita são suprimidos
                          (LIST "DIMAZIN" 2) ; Apenas zeros a direita são suprimidos de ângulos
                          (LIST "AUNITS" 0) ; Ângulo decimal
                          (LIST "AUPREC" 4) ; 4 casas depois da vírgula
                          (LIST "ANGBASE" 0)
                          (LIST "ANGDIR" 0)
                          (LIST "INSUNITS" 5)
                          (LIST "CECOLOR" "ByLayer")
                          (LIST "CLAYER" "0")
                          (LIST "CELTYPE" "ByLayer")
                          (LIST "CELTSCALE" 1)
                          (LIST "CELWEIGHT" -1)
                          (LIST "THICKNESS" 0)
                          (LIST "MSLTSCALE" 0)
                          (LIST "PSLTSCALE" 0)
                          (LIST "PSTYLEMODE" 1) ; Utiliza CTB ao invés de STB
                          (LIST "FIELDDISPLAY" 0)
                          (LIST "PDMODE" 35) ; Representação dos pontos
                          (LIST "PDSIZE" 0.25) ; Tamanho dos pontos
                          (LIST "STARTMODE" 1) ; Habilita a tela inicial do CAD
                          (LIST "STARTUP" 2) ; Inicia o CAD com a tela inicial e não um desenho em branco
                          (LIST "WSAUTOSAVE" 0))) ; Salvamento automático de alterações no espaço de trabalho

;;; Padrões de projeto
(SETQ *standardPrefix* "ATS")
(SETQ *affixSeparator* "-") ; Não usar nenhum destes caracteres: < > / \ " : ; ? * | , = `
(SETQ *secondaryAffixSeparator* " ") ; Não usar nenhum destes caracteres: < > / \ " : ; ? * | , = `
(SETQ *fileSeparator* " ") ; Não usar nenhum destes caracteres: . \ / : * ? " < > |
(SETQ *secondaryFileSeparator* "-") ; Não usar nenhum destes caracteres: . \ / : * ? " < > |
(SETQ *unitsFactor* 1.0) ; Fator da unidade adotada em relação a centímetros. Exemplo: 0.01 para um modelo em metros
(SETQ *paperUnitsFactor* 10.0) ; Fator da unidade adotada no papel em relação à adotada no modelo (sempre com uma casa decimal). Exemplo: 10.0 para milimetros em um modelo em centímetros
(SETQ *scaleFactor* (/ 50.0 *paperUnitsFactor*)) ; Escala anotativa em texto, como '1:1', ou não anotativa em número (sempre com uma casa decimal), como 5.0 para 50 unidades no modelo equivalerem a 10 no papel
(SETQ *minimalFuzz* 1e-6)
(SETQ *duplicateAffix* "Duplicata")
(IF (SETQ *fullyUndo* T) ; Comandos personalizados são revertidos por inteiro ao desfazer (Ctrl + Z)
  (SETQ *automaticallyUndo* nil) ; Comandos personalizados são revertidos automaticamente em um erro
)

;;; Abreviações
(SETQ *architectureTag* "ARQ")
(SETQ *auxiliarTag* "AUX")
(SETQ *symbolTag* "SIM")
(SETQ *furnitureTag* "LAY")
(SETQ *vegetationTag* "VEG")
(SETQ *fireTag* "INC")
(SETQ *mechanicalTag* "MEC")
(SETQ *electricalTag* "ELE")
(SETQ *plumbingTag* "HID")
(SETQ *lightingTag* "LUM")

;;; Plot
(SETQ *standardLineTypeScale* 1.0)
(SETQ *minimalSheetNumberTotalDigits* 2) ; Quantidade mínima de dígitos na numeração de pranchas
(SETQ *totalSheetNumberSeparator* nil) ; Separador da numeração da prancha e o número total de pranchas, ou nil para não mostrar a quantidade total
(SETQ *nameFileTotalSheetNumberSeparator* nil) ; Separador da numeração da prancha e o número total de pranchas no nome do arquivo, ou nil para não mostrar a quantidade total

;;; Layers
(SETQ *pen1*                  (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Pena 1"))
(SETQ *pen2*                  (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Pena 2"))
(SETQ *pen3*                  (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Pena 3"))
(SETQ *pen4*                  (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Pena 4"))
(SETQ *pen5*                  (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Pena 5"))
(SETQ *pen6*                  (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Pena 6"))
(SETQ *symbolPen1*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Símbolo 1"))
(SETQ *symbolPen2*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Símbolo 2"))
(SETQ *symbolPen3*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Símbolo 3"))
(SETQ *symbolPen4*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Símbolo 4"))
(SETQ *symbolPen5*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Símbolo 5"))
(SETQ *symbolPen6*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Símbolo 6"))
(SETQ *dimensionLayer*        (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Cotas"))
(SETQ *sectionLayer*          (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Cortes"))
(SETQ *projectionLayer*       (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Projeções"))
(SETQ *hatchLayer*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Hachuras"))
(SETQ *solidLayer*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Sólidos"))
(SETQ *viewportLayer*         (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Viewports"))
(SETQ *wipeoutLayer*          (QUOTE *solidLayer*))
(SETQ *draftLayer*            (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Rascunho"))
(SETQ *areaLayer*             (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Áreas"))
(SETQ *wallLayer*             (QUOTE *pen5*))
(SETQ *wallFinishesLayer*     (QUOTE *pen1*))
(SETQ *handrailLayer*         (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Corrimão"))
(SETQ *falseCeilingLayer*     (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Forro"))
(SETQ *architectureLayer*     (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Arquitetura"))
(SETQ *structureLayer*        (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Estrutura"))
(SETQ *lightingLayer*         (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Luminotécnico"))
(SETQ *fireLayer*             (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Incêndio"))
(SETQ *layoutLayer*           (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Layout"))
(SETQ *trafficLayer*          (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Tráfego"))
(SETQ *vegetationLayer*       (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Vegetação"))
(SETQ *siteLayer*             (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Terreno"))
(SETQ *constructionLayer*     (QUOTE *pen4*))
(SETQ *demolitionLayer*       (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Demolição"))
(SETQ *mechanicalLayer*       (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Mecânica"))
(SETQ *electricalLayer*       (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Elétrica"))
(SETQ *plumbingLayer*         (LIST (QUOTE *standardPrefix*) (QUOTE *affixSeparator*) "Hidráulica"))

;; Lista de prioridade de layers, do mais prioritário, ao menos, dividida entre layers de anotação e de desenho
(SETQ *layersDrawOrderList*
  (LIST
    (LIST ; Layers de anotação e auxiliares
      "0" (QUOTE *draftLayer*) (QUOTE *areaLayer*)
      (QUOTE *sectionLayer*) (QUOTE *dimensionLayer*) (QUOTE *symbolPen6*) (QUOTE *symbolPen5*) (QUOTE *symbolPen4*) (QUOTE *symbolPen3*) (QUOTE *symbolPen2*) (QUOTE *symbolPen1*)
      (QUOTE *viewportLayer*)
    )
    (LIST ; Layers de desenho
      (QUOTE *projectionLayer*) (QUOTE *structureLayer*) (QUOTE *constructionLayer*) (QUOTE *demolitionLayer*)
      (QUOTE *fireLayer*) (QUOTE *mechanicalLayer*) (QUOTE *electricalLayer*) (QUOTE *plumbingLayer*) (QUOTE *lightingLayer*)
      (QUOTE *handrailLayer*) (QUOTE *layoutLayer*) (QUOTE *vegetationLayer*) (QUOTE *trafficLayer*) (QUOTE *falseCeilingLayer*) (QUOTE *siteLayer*)
      (QUOTE *pen6*) (QUOTE *pen5*) (QUOTE *pen4*) (QUOTE *pen3*) (QUOTE *pen2*) (QUOTE *pen1*)
      (QUOTE *hatchLayer*) (QUOTE *solidLayer*) (QUOTE *wipeoutLayer*)
    )
  )
)

;;; Palavras-chave
(SETQ *keywordsListMaxLength* 25) ; Quantidade máxima de itens por vez em listas suspensas de palavras-chave
(SETQ *previousKeywordSublist* "ListaAnterior") ; Nome do item para carregar a sublista anterior de palavras-chave, sem caractere especial
(SETQ *nextKeywordSublist* "PróximaLista") ; Nome do item para carregar a próxima sublista de palavras-chave, sem caractere especial
(SETQ *upperKeywordSublist* "ListaPrincipal") ; Nome do item para carregar a sublista principal de palavras-chave, sem caractere especial

;;; Padrões de anotações
(SETQ *standardTextFont* "segoeuil.ttf")
(SETQ *standardTextStyle* "Standard")
(SETQ *boldTextStyle* "Standard Bold")
(SETQ *titlesHeight* 5.0)
(SETQ *titlesLayer* (QUOTE *symbolPen3*))
(SETQ *primaryTextsHeight* 2.5)
(SETQ *primaryTextsLayer* (QUOTE *symbolPen2*))
(SETQ *secondaryTextsHeight* 1.8)
(SETQ *secondaryTextsLayer* (QUOTE *symbolPen1*))
(SETQ *standardAnnotationScale* "1:1")
(SETQ *standardMultiLineStyle* "Standard")
(SETQ *standardDimensionStyle* "Standard")
(SETQ *standardLeaderStyle* "Standard")
(SETQ *levelLeaderStyle* "Nível")
(SETQ *tagLeaderStyle* "Identificação")
(SETQ *standardLeaderLayer* (QUOTE *symbolPen1*))
(SETQ *standardTableStyle* "Standard")
(SETQ *revisionTableStyle* "Revisões")

;;; Hachuras
(SETQ *sandHatchList* (LIST
                        (CONS "Pattern" "AR-SAND")
                        (CONS "PresetScale" T)
                        (CONS "Scale" 0.1)
                        (CONS "PresetRotation" T)
                        (CONS "Rotation" 0.0)
                        (CONS "Color" "_BYLAYER")
                        (CONS "BackgroundColor" ".")
                        (CONS "Layer" (QUOTE *hatchLayer*))
                        (CONS "Transparency" "_BYLAYER")))

(SETQ *concreteHatchList* (LIST
                            (CONS "Pattern" "AR-CONC")
                            (CONS "PresetScale" T)
                            (CONS "Scale" 0.02)
                            (CONS "PresetRotation" T)
                            (CONS "Rotation" 0.0)
                            (CONS "Color" "_BYLAYER")
                            (CONS "BackgroundColor" ".")
                            (CONS "Layer" (QUOTE *hatchLayer*))
                            (CONS "Transparency" "_BYLAYER")))

(SETQ *diagonalHatchList* (LIST
                            (CONS "Pattern" "ANSI31")
                            (CONS "PresetScale" T)
                            (CONS "Scale" 0.5)
                            (CONS "PresetRotation" T)
                            (CONS "Rotation" 0.0)
                            (CONS "Color" "_BYLAYER")
                            (CONS "BackgroundColor" ".")
                            (CONS "Layer" (QUOTE *hatchLayer*))
                            (CONS "Transparency" "_BYLAYER")))

(SETQ *doubleDiagonalHatchList* (LIST
                                  (CONS "Pattern" "ANSI32")
                                  (CONS "PresetScale" T)
                                  (CONS "Scale" 0.5)
                                  (CONS "PresetRotation" T)
                                  (CONS "Rotation" 0.0)
                                  (CONS "Color" "_BYLAYER")
                                  (CONS "BackgroundColor" ".")
                                  (CONS "Layer" (QUOTE *hatchLayer*))
                                  (CONS "Transparency" "_BYLAYER")))

(SETQ *grassHatchList* (LIST
                         (CONS "Pattern" "GRASS")
                         (CONS "PresetScale" T)
                         (CONS "Scale" 0.1)
                         (CONS "PresetRotation" T)
                         (CONS "Rotation" 0.0)
                         (CONS "Color" "_BYLAYER")
                         (CONS "BackgroundColor" ".")
                         (CONS "Layer" (QUOTE *hatchLayer*))
                         (CONS "Transparency" "_BYLAYER")))

(SETQ *tileHatchList* (LIST
                        (CONS "Pattern" "ANGLE")
                        (CONS "PresetScale" T)
                        (CONS "Scale" 0.3)
                        (CONS "PresetRotation" T)
                        (CONS "Rotation" 0.0)
                        (CONS "Color" "_BYLAYER")
                        (CONS "BackgroundColor" ".")
                        (CONS "Layer" (QUOTE *hatchLayer*))
                        (CONS "Transparency" "_BYLAYER")))

(SETQ *woodHatchList* (LIST
                        (CONS "Pattern" "GOST_WOOD")
                        (CONS "PresetScale" T)
                        (CONS "Scale" 1)
                        (CONS "PresetRotation" T)
                        (CONS "Rotation" 0.0)
                        (CONS "Color" "_BYLAYER")
                        (CONS "BackgroundColor" ".")
                        (CONS "Layer" (QUOTE *hatchLayer*))
                        (CONS "Transparency" "_BYLAYER")))

(SETQ *stoneHatchList* (LIST
                         (CONS "Pattern" "GRAVEL")
                         (CONS "PresetScale" T)
                         (CONS "Scale" 0.4)
                         (CONS "PresetRotation" T)
                         (CONS "Rotation" 0.0)
                         (CONS "Color" "_BYLAYER")
                         (CONS "BackgroundColor" ".")
                         (CONS "Layer" (QUOTE *hatchLayer*))
                         (CONS "Transparency" "_BYLAYER")))

(SETQ *poolHatchList* (LIST
                        (CONS "Pattern" "_GRADIENT")
                        (CONS "PresetRotation" T)
                        (CONS "Rotation" 0.0)
                        (CONS "Color" "_BYLAYER")
                        (CONS "BackgroundColor" (LIST (STRCAT (IF (EQ *CADSoftware* "ZWCAD") "" "GR_") "LINEAR") "_TWO" "_TRUE" "16,86,137" "_TRUE" "122,175,223"))
                        (CONS "Layer" (QUOTE *solidLayer*))
                        (CONS "Transparency" "_BYLAYER")))

(SETQ *slattedHatchList* (LIST
                           (CONS "Pattern" "LINE")
                           (CONS "PresetScale" T)
                           (CONS "Scale" 0.5)
                           (CONS "PresetRotation" T)
                           (CONS "Rotation" 0.0)
                           (CONS "Color" "_BYLAYER")
                           (CONS "BackgroundColor" ".")
                           (CONS "Layer" (QUOTE *hatchLayer*))
                           (CONS "Transparency" "_BYLAYER")))

(SETQ *solidHatchList* (LIST
                         (CONS "Pattern" "SOLID")
                         (CONS "Color" "_BYLAYER")
                         (CONS "Layer" (QUOTE *solidLayer*))))

(SETQ *parquetHatchList* (LIST
                           (CONS "Pattern" "AR-HBONE")
                           (CONS "PresetScale" T)
                           (CONS "Scale" 0.02)
                           (CONS "PresetRotation" T)
                           (CONS "Rotation" 0.0)
                           (CONS "Color" "_BYLAYER")
                           (CONS "BackgroundColor" ".")
                           (CONS "Layer" (QUOTE *hatchLayer*))
                           (CONS "Transparency" "_BYLAYER")))

(SETQ *earthHatchList* (LIST
                         (CONS "Pattern" "EARTH")
                         (CONS "PresetScale" T)
                         (CONS "Scale" 0.6)
                         (CONS "PresetRotation" T)
                         (CONS "Rotation" 0.0)
                         (CONS "Color" "_BYLAYER")
                         (CONS "BackgroundColor" ".")
                         (CONS "Layer" (QUOTE *hatchLayer*))
                         (CONS "Transparency" "_BYLAYER")))

(SETQ *brickHatchList* (LIST
                         (CONS "Pattern" "AR-B816C")
                         (CONS "PresetScale" T)
                         (CONS "Scale" 0.01)
                         (CONS "PresetRotation" T)
                         (CONS "Rotation" 0.0)
                         (CONS "Color" "_BYLAYER")
                         (CONS "BackgroundColor" ".")
                         (CONS "Layer" (QUOTE *hatchLayer*))
                         (CONS "Transparency" "_BYLAYER")))

(SETQ *glassHatchList* (LIST
                         (CONS "Pattern" "AR-RROOF")
                         (CONS "PresetScale" T)
                         (CONS "Scale" 0.2)
                         (CONS "PresetRotation" T)
                         (CONS "Rotation" 45.0)
                         (CONS "Color" "_BYLAYER")
                         (CONS "BackgroundColor" ".")
                         (CONS "Layer" (QUOTE *hatchLayer*))
                         (CONS "Transparency" "_BYLAYER")))

(SETQ *checkeredHatchList* (LIST
                             (CONS "Pattern" "ANSI37")
                             (CONS "PresetScale" T)
                             (CONS "Scale" 0.6)
                             (CONS "PresetRotation" T)
                             (CONS "Rotation" 0.0)
                             (CONS "Color" "_BYLAYER")
                             (CONS "BackgroundColor" ".")
                             (CONS "Layer" (QUOTE *hatchLayer*))
                             (CONS "Transparency" "_BYLAYER")))

(SETQ *squaredHatchList* (LIST
                           (CONS "Pattern" "ANSI37")
                           (CONS "PresetScale" 100.0)
                           (CONS "Scale" 3.175)
                           (CONS "PresetRotation" T)
                           (CONS "Rotation" 45.0)
                           (CONS "Color" "_BYLAYER")
                           (CONS "BackgroundColor" ".")
                           (CONS "Layer" (QUOTE *hatchLayer*))
                           (CONS "Transparency" "_BYLAYER")))

(SETQ *hatchesList* (LIST
                      (CONS "Areia" (QUOTE *sandHatchList*))
                      (CONS "Concreto" (QUOTE *concreteHatchList*))
                      (CONS "Diagonal" (QUOTE *diagonalHatchList*))
                      (CONS "Dupla-Diagonal" (QUOTE *doubleDiagonalHatchList*))
                      (CONS "Grama" (QUOTE *grassHatchList*))
                      (CONS "Ladrilho" (QUOTE *tileHatchList*))
                      (CONS "Madeira" (QUOTE *woodHatchList*))
                      (CONS "Pedra" (QUOTE *stoneHatchList*))
                      (CONS "Piscina" (QUOTE *poolHatchList*))
                      (CONS "Quadriculado" (QUOTE *squaredHatchList*))
                      (CONS "Ripado" (QUOTE *slattedHatchList*))
                      (CONS "Sólida" (QUOTE *solidHatchList*))
                      (CONS "Taco" (QUOTE *herringboneHatchList*))
                      (CONS "Terra" (QUOTE *earthHatchList*))
                      (CONS "Tijolo" (QUOTE *brickHatchList*))
                      (CONS "Vidro" (QUOTE *glassHatchList*))
                      (CONS "Xadrez" (QUOTE *checkeredHatchList*))))

;;; Blocos
(SETQ *frontViewSuffix* "Frontal")
(SETQ *sideViewSuffix* "Lateral")
(SETQ *sectionVisibilityProperty* (LIST
                                    (CONS "Name" "Visibilidade em Corte")
                                    (CONS "Projectioned" "Em Projeção")
                                    (CONS "Sectioned" "Em Corte")))

(SETQ *breakLineBlockList* (LIST
                             (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Interrupção"))
                             (CONS "Layer" (QUOTE *symbolPen1*))
                             (CONS "LengthPropertyName" "Comprimento")))

(SETQ *sectionBlockList* (LIST
                           (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Corte"))
                           (CONS "Layer" (QUOTE *symbolPen3*))
                           (CONS "LengthPropertyName" "Comprimento")
                           (CONS "RangePropertyName" "Alcance")
                           (CONS "FlipPropertyName" "Estado de reflexão1")
                           (CONS "StartNameAttributeName" "CORTE1")
                           (CONS "EndNameAttributeName" "CORTE2")
                           (CONS "Insert" (LAMBDA (/ blockName point1 point2 basePoint point3 startName endName sectionLength sectionAngle)
                                            (COND
                                              ((NOT (ATS:InsertBlockFromSupportPaths (SETQ blockName (ATS:GetPropertiesValues "Name" *sectionBlockList*)))) (PROMPT "\nBloco não encontrado.\n"))
                                              ((NOT (SETQ point1 (GETPOINT "\nSelecione a primeira extremidade.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
                                              ((NOT (SETQ point2 (GETPOINT point1 "\nSelecione a segunda extremidade.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
                                              ((NOT (SETQ point3 (GETPOINT (SETQ basePoint (ATS:GetPointsMiddle (LIST point1 point2))) "\nInsira a profundidade do corte.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
                                              (T
                                                (SETQ startName (ATS:GetString nil nil "-" "\nInsira o ínicio do nome do corte:\n"))
                                                (SETQ endName (ATS:GetString nil nil "-" "\nInsira o final do nome do corte:\n"))
                                                (ATS:SaveUsersPreferences 7)
                                                (DEFUN *error* (errorMessage)
                                                  (ATS:RestoreUsersPreferences commandName errorMessage)
                                                )
                                                (SETQ sectionLength (MAX (DISTANCE point1 point2) (* (ATS:GetInsertionScale) 5.0)))
                                                (SETQ sectionAngle (ANGLE point1 point2))
                                                (ATS:ChangeLayer (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" *sectionBlockList*)))
                                                (COMMAND-S "_.-INSERT" blockName basePoint (ATS:GetInsertionScale) (ANGTOS sectionAngle 0 4))
                                                (SETQ blockName (ENTLAST))
                                                (IF (EQ (TYPE *scaleFactor*) (READ "STR"))
                                                  (ATS:ApplyScaleFactor (SSADD blockName) *scaleFactor*)
                                                )
                                                (SETQ sectionAngle (ATS:GetDistanceFromPointToLine point1 point2 point3))
                                                (IF (< sectionAngle 0.0)
                                                  (ATS:ChangeDynamicBlockPropertiesValues nil (ATS:SaveObject blockName) (LIST (CONS (ATS:GetPropertiesValues "FlipPropertyName" *sectionBlockList*) (VLAX-MAKE-VARIANT 1 VLAX-VBINTEGER))))
                                                )
                                                (ATS:ChangeDynamicBlockPropertiesValues nil (ATS:SaveObject blockName) (LIST (CONS (ATS:GetPropertiesValues "LengthPropertyName" *sectionBlockList*) sectionLength) (CONS (ATS:GetPropertiesValues "RangePropertyName" *sectionBlockList*) (MAX (ABS sectionAngle) (* (ATS:GetInsertionScale) 5.0)))))
                                                (IF startName
                                                  (ATS:ChangePropertiesValues (ATS:SearchAttribute nil blockName (LIST (CONS 2 (ATS:GetPropertiesValues "StartNameAttributeName" *sectionBlockList*)))) (LIST (CONS 1 (STRCASE startName))))
                                                )
                                                (IF endName
                                                  (ATS:ChangePropertiesValues (ATS:SearchAttribute nil blockName (LIST (CONS 2 (ATS:GetPropertiesValues "EndNameAttributeName" *sectionBlockList*)))) (LIST (CONS 1 (STRCASE endName))))
                                                )
                                                (ATS:RestoreUsersPreferences commandName nil)))))))

(SETQ *doorBlockList* (LIST
                        (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Porta"))
                        (CONS "Layer" (QUOTE *pen3*))
                        (CONS "LengthPropertyName" "Comprimento")
                        (CONS "ThicknessPropertyName" "Espessura")
                        (CONS "HeightPropertyName" "Altura")
                        (CONS "DoorKnobSideFlipPropertyName" "Inversão Lado Maçaneta")
                        (CONS "WallSideFlipPropertyName" "Inversão Lado Parede")
                        (CONS "TagVisibilityPropertyName" "Visibilidade Identificação")
                        (CONS "SizeAttributeName" "DIMENSÕES")
                        (CONS "BlockForSection" (LAMBDA (/ dynamicBlockPropertiesList thickness height flipState)
                                                  ;; Verifica se o bloco está na vista frontal
                                                  (IF (EQ (STRCASE blockName) (STRCASE (STRCAT (ATS:GetPropertiesValues "Name" *doorBlockList*) *affixSeparator* *frontViewSuffix*)))
                                                    ;; Troca a layer para pena 2
                                                    (ATS:ChangePropertiesValues entity (LIST (CONS 8 (ATS:EvaluateStringSymbolList *pen2*))))
                                                    (PROGN
                                                      (SETQ dynamicBlockPropertiesList (ATS:GetDynamicBlockProperties T nil blockObject nil))
                                                      (SETQ thickness (VLAX-VARIANT-VALUE (CDR (ASSOC (ATS:GetPropertiesValues "ThicknessPropertyName" *doorBlockList*) dynamicBlockPropertiesList))))
                                                      (SETQ height (VLAX-VARIANT-VALUE (CDR (ASSOC (ATS:GetPropertiesValues "HeightPropertyName" *doorBlockList*) dynamicBlockPropertiesList))))
                                                      ;; Verifica se a porta não está espelhada
                                                      (SETQ flipState (ATS:GetPropertiesValues "WallSideFlipPropertyName" *doorBlockList*))
                                                      (SETQ sectionedBlock (ZEROP (VLAX-VARIANT-VALUE (CDR (ASSOC flipState dynamicBlockPropertiesList)))))
                                                      (COMMAND-S "_.ZOOM" basePoint (ATS:TranslatePoint basePoint (LIST thickness height)))
                                                      ;; Ajusta a posição da porta, caso ela esteja espelhada, pois seu ponto base não está no eixo de simetria
                                                      (IF (AND (>= blockAngle (/ (* PI 5) 4)) (<= blockAngle (/ (* PI 7) 4)))
                                                        (PROGN
                                                          (IF sectionedBlock
                                                            (ATS:ChangeDynamicBlockPropertiesValues nil blockObject (LIST (CONS flipState (VLAX-MAKE-VARIANT 1 VLAX-VBINTEGER))))
                                                            (ATS:ChangeDynamicBlockPropertiesValues nil blockObject (LIST (CONS flipState (VLAX-MAKE-VARIANT 0 VLAX-VBINTEGER))))
                                                          )
                                                          (SETQ sectionedBlock (NOT sectionedBlock))
                                                        )
                                                      )
                                                      ;; Recria as linhas de parede acima
                                                      (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *wallLayer*))
                                                      (FOREACH point (LIST (LIST (CAR basePoint) height) (LIST ((IF sectionedBlock + -) (CAR basePoint) thickness) height))
                                                        (SETQ sectionedBlock (SSGET "_C" point point (LIST (CONS 0 "LINE") (CONS 8 (ATS:EvaluateStringSymbolList *wallLayer*)))))
                                                        (IF sectionedBlock
                                                          (COMMAND-S "_.ERASE" sectionedBlock "")
                                                        )
                                                        (COMMAND-S "_.LINE" point (LIST (CAR point) *ceilingHeight*) ""))))))))

(SETQ *windowBlockList* (LIST
                          (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Janela"))
                          (CONS "Layer" (QUOTE *pen5*))
                          (CONS "LengthPropertyName" "Comprimento")
                          (CONS "ThicknessPropertyName" "Espessura")
                          (CONS "HeightPropertyName" "Altura")
                          (CONS "SillPropertyName" "Peitoril")
                          (CONS "TagVisibilityPropertyName" "Visibilidade Identificação")
                          (CONS "SizeAttributeName" "DIMENSÕES")
                          (CONS "BlockForSection" (LAMBDA (/ dynamicBlockPropertiesList thickness height)
                                                    ;; Verifica se o bloco está na vista frontal
                                                    (IF (EQ (STRCASE blockName) (STRCASE (STRCAT (ATS:GetPropertiesValues "Name" *windowBlockList*) *affixSeparator* *frontViewSuffix*)))
                                                      ;; Troca a layer para pena 2
                                                      (ATS:ChangePropertiesValues entity (LIST (CONS 8 (ATS:EvaluateStringSymbolList *pen2*))))
                                                      (PROGN
                                                        (SETQ dynamicBlockPropertiesList (ATS:GetDynamicBlockProperties T nil blockObject nil))
                                                        (SETQ thickness (/ (VLAX-VARIANT-VALUE (CDR (ASSOC (ATS:GetPropertiesValues "ThicknessPropertyName" *windowBlockList*) dynamicBlockPropertiesList))) 2))
                                                        (SETQ height (+ (VLAX-VARIANT-VALUE (CDR (ASSOC (ATS:GetPropertiesValues "HeightPropertyName" *windowBlockList*) dynamicBlockPropertiesList))) (VLAX-VARIANT-VALUE (CDR (ASSOC (ATS:GetPropertiesValues "SillPropertyName" *windowBlockList*) dynamicBlockPropertiesList)))))
                                                        ;; Recria as linhas de parede acima
                                                        (ATS:SetCurrentLayer (ATS:EvaluateStringSymbolList *wallLayer*))
                                                        (COMMAND-S "_.ZOOM" basePoint (ATS:TranslatePoint basePoint (LIST thickness height)))
                                                        (FOREACH point (LIST (LIST (- (CAR basePoint) thickness) height) (LIST (+ (CAR basePoint) thickness) height))
                                                          (SETQ sectionedBlock (SSGET "_C" point point (LIST (CONS 0 "LINE") (CONS 8 (ATS:EvaluateStringSymbolList *wallLayer*)))))
                                                          (IF sectionedBlock
                                                            (COMMAND-S "_.ERASE" sectionedBlock "")
                                                          )
                                                          (COMMAND-S "_.LINE" point (LIST (CAR point) *ceilingHeight*) ""))))))))

(SETQ *tagBlockList* (LIST
                       (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Identificação"))
                       (CONS "Layer" (QUOTE *symbolPen1*))
                       (CONS "TagAttributeName" "IDENTIFICAÇÃO")))

(SETQ *distanceBlockList* (LIST
                            (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Distância"))
                            (CONS "Layer" (QUOTE *symbolPen3*))
                            (CONS "AxisPropertyName" "Direção")
                            (CONS "DistanceAttributeName" "DISTÂNCIA")))

(SETQ *titleBlockList* (LIST
                         (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Título"))
                         (CONS "Layer" (QUOTE *symbolPen3*))
                         (CONS "TitleDistancePropertyName" "Distância Título")
                         (CONS "NotesDistancePropertyName" "Distância Notas")
                         (CONS "LineDistancePropertyName" "Distância Linha")
                         (CONS "ScaleVisibilityPropertyName" "Visibilidade Escala")
                         (CONS "TitleAttributeName" "TÍTULO")
                         (CONS "ScaleAttributeName" "ESCALA")
                         (CONS "NotesAttributeName" "NOTAS")
                         (CONS "AdjustTitle" (LAMBDA (entityName / object scale attribute scaleVisibility titleBoundaries boundaries)
                                               (SETQ object (ATS:SaveObject entityName))
                                               (SETQ scale (VLAX-GET-PROPERTY object "XScaleFactor"))
                                               (COMMAND-S "_.ATTSYNC" "_SELECT" entityName "")
                                               (SETQ attribute (ATS:SearchAttribute nil entityName (LIST (CONS 2 (ATS:GetPropertiesValues "ScaleAttributeName" *titleBlockList*)))))
                                               (SETQ scaleVisibility (EQ (ATS:GetDynamicBlockProperties nil nil object (ATS:GetPropertiesValues "ScaleVisibilityPropertyName" *titleBlockList*)) "Com Escala"))
                                               ;; Ajusta o texto da escala
                                               (IF scaleVisibility
                                                 (PROGN
                                                   (SETQ boundaries (* scale *paperUnitsFactor*))
                                                   (ATS:ChangePropertiesValues attribute (LIST (CONS 1 (IF (< boundaries 1.0)
                                                                                                         (STRCAT (VL-STRING-SUBST "," "." (RTOS (EXPT boundaries -1))) ":1")
                                                                                                         (STRCAT "1:" (RTOS boundaries)))))))
                                               )
                                               ;; Obtém os limites do atributo de título
                                               (SETQ titleBoundaries (ATS:GetObjectBoundaries (ATS:SaveObject (ATS:SearchAttribute nil entityName (LIST (CONS 2 (ATS:GetPropertiesValues "TitleAttributeName" *titleBlockList*)))))))
                                               (ATS:ChangeDynamicBlockPropertiesValues nil object (LIST (CONS (ATS:GetPropertiesValues "NotesDistancePropertyName" *titleBlockList*) (ATS:RoundUp (* 3.0 scale) (* 9.0 scale) (IF titleBoundaries
                                                                                                                                                                                                                                (- (CADR (CADR titleBoundaries)) (CADR (CAR titleBoundaries)) (* 5.0 scale))
                                                                                                                                                                                                                                0.0)))))
                                               ;; Obtém o x máximo do atributo de título ou de escala, o que for maior, e subtrai pelo x do ponto base do bloco
                                               (ATS:ChangeDynamicBlockPropertiesValues nil object (LIST (CONS (ATS:GetPropertiesValues "LineDistancePropertyName" *titleBlockList*) (VLAX-MAKE-VARIANT (ATS:RoundUp 0.0 scale (+ (* 0.5 scale) ; Recuo antes do início do texto
                                                                                                                                                                                                                                 (MAX
                                                                                                                                                                                                                                   ;; Obtém o comprimento do atributo de título
                                                                                                                                                                                                                                   (IF titleBoundaries
                                                                                                                                                                                                                                     (- (CAR (CADR titleBoundaries)) (CAR (CAR titleBoundaries)))
                                                                                                                                                                                                                                     0.0)
                                                                                                                                                                                                                                   ;; Obtém o comprimento do atributo de escala
                                                                                                                                                                                                                                   (IF scaleVisibility
                                                                                                                                                                                                                                     (PROGN
                                                                                                                                                                                                                                       (SETQ boundaries (ATS:GetObjectBoundaries (ATS:SaveObject attribute)))
                                                                                                                                                                                                                                       (+ (* 10.2 scale) ; Tamanho de "ESCALA "
                                                                                                                                                                                                                                          (- (CAR (CADR boundaries)) (CAR (CAR boundaries)))) ; Tamanho do valor da escala
                                                                                                                                                                                                                                     )
                                                                                                                                                                                                                                     (* 16.0 scale))))))))) ; Tamanho de "SEM ESCALA"
                                               (SETQ boundaries (ATS:GetObjectBoundaries object))
                                               (IF (EQ (ATS:GetAttributeProperties nil 1 entityName (LIST (CONS 2 (ATS:GetPropertiesValues "NotesAttributeName" *titleBlockList*)))) "")
                                                 (SETQ boundaries (LIST (CAR boundaries) (LIST (CAR (CADR boundaries)) (IF titleBoundaries (CADR (CADR titleBoundaries)) (CADR (CAR boundaries))))))
                                               )
                                               (ATS:ChangeDynamicBlockPropertiesValues nil object (LIST (CONS (ATS:GetPropertiesValues "TitleDistancePropertyName" *titleBlockList*) (ATS:RoundUp (* 12.0 scale) (* 9.0 scale) (- (CADR (CADR boundaries)) (CADR (CAR boundaries)))))))))))

(SETQ *roomBlockList* (LIST
                        (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Ambiente"))
                        (CONS "Layer" (QUOTE *symbolPen3*))
                        (CONS "LevelAttributeName" "AMBIENTE")
                        (CONS "Level2AttributeName" "ÁREA")))

(SETQ *levelBlockList* (LIST
                         (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Nível"))
                         (CONS "Layer" (QUOTE *symbolPen1*))
                         (CONS "LevelAttributeName" "NÍVEL")
                         (CONS "Level2AttributeName" "NÍVEL2")))

(SETQ *viewportBlockList* (LIST (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Viewport"))
                                (CONS "Layer" (QUOTE *viewportLayer*))
                                (CONS "HorizontalDistancePropertyName" "Comprimento Horizontal")
                                (CONS "VerticalDistancePropertyName" "Comprimento Vertical")
                                (CONS "DrawingNameAttributeName" "NOME")
                                (CONS "Insert" (LAMBDA (/ blockName point1 point2 drawingName basePoint object)
                                                 (COND
                                                   ;; Insere o bloco no arquivo
                                                   ((NOT (ATS:InsertBlockFromSupportPaths (SETQ blockName (ATS:GetPropertiesValues "Name" *viewportBlockList*)))) (PROMPT "\nBloco não encontrado.\n"))
                                                   ;; Solicita as extremidades do retângulo
                                                   ((NOT (SETQ point1 (GETPOINT "\nSelecione a primeira extremidade.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
                                                   ((NOT (SETQ point2 (GETCORNER point1 "\nSelecione a segunda extremidade.\n"))) (PROMPT "\nNenhum ponto selecionado.\n"))
                                                   (T
                                                     ;; Solicita o nome do desenho
                                                     (SETQ drawingName (ATS:GetString nil T "PLANTA" "\nInsira o nome do desenho:\n"))
                                                     ;; Obtém o ponto base e escala de inserção
                                                     (SETQ basePoint (ATS:GetPointsMiddle (LIST point1 point2)))
                                                     (SETQ scale (ATS:GetInsertionScale))
                                                     ;; Insere o bloco
                                                     (COMMAND-S "_.-INSERT" blockName basePoint scale "0")
                                                     (SETQ blockName (ENTLAST))
                                                     (SETQ object (ATS:SaveObject blockName))
                                                     ;; Acrescenta a escala anotativa, se necessário
                                                     (IF (EQ (TYPE *scaleFactor*) (READ "STR"))
                                                       (ATS:ApplyScaleFactor (SSADD blockName) *scaleFactor*)
                                                     )
                                                     ;; Ajusta o tamanho do retângulo
                                                     (ATS:ChangeDynamicBlockPropertiesValues nil object (LIST (CONS (ATS:GetPropertiesValues "HorizontalDistancePropertyName" *viewportBlockList*) (ABS (- (CAR point2) (CAR point1))))
                                                                                                              (CONS (ATS:GetPropertiesValues "VerticalDistancePropertyName" *viewportBlockList*) (SETQ point2 (ABS (- (CADR point2) (CADR point1)))))))
                                                     ;; Ajusta o ponto de inserção e layer
                                                     (ATS:ChangePropertiesValues blockName (LIST (CONS 10 basePoint)
                                                                                                 (CONS 8 (ATS:EvaluateStringSymbolList (ATS:GetPropertiesValues "Layer" *viewportBlockList*)))))
                                                     ;; Introduz o nome do desenho
                                                     (ATS:ChangePropertiesValues (ATS:SearchAttribute nil blockName (LIST (CONS 2 (ATS:GetPropertiesValues "DrawingNameAttributeName" *viewportBlockList*)))) (LIST (CONS 1 (STRCASE drawingName))))))))))

;; Lista de carimbos
(SETQ *titleBlockBlockList* (LIST
                              (CONS "Name" (STRCAT *standardPrefix* *affixSeparator* "Carimbo"))
                              (CONS "Layer" (QUOTE *symbolPen5*))
                              (CONS "SizePropertyName" "Tamanho da Folha")
                              (CONS "SheetNotesDistancePropertyName" "Distância das Notas")
                              (CONS "ProjectNameAttributeName" "OBRA")
                              (CONS "AdressAttributeName" "ENDEREÇO")
                              (CONS "ClientAttributeName" "CLIENTE")
                              (CONS "ClientIdentificationAttributeName" "ID_CLIENTE")
                              (CONS "ResponsibleAttributeName" "RESPONSÁVEL")
                              (CONS "ResponsibleIdentificationAttributeName" "ID_RESPONSÁVEL")
                              (CONS "ContactAttributeName" "CONTATO")
                              (CONS "ProjectTypeAttributeName" "TIPO_DE_PROJETO")
                              (CONS "ContentAttributeName" "CONTEÚDO")
                              (CONS "ProjectPhaseAttributeName" "ETAPA")
                              (CONS "RevisionAttributeName" "REVISÃO")
                              (CONS "DateAttributeName" "DATA")
                              (CONS "SheetNumberAttributeName" "PRANCHA")
                              (CONS "ProjectIdentificationAttributeName" "ID_PROJETO")
                              (CONS "SheetNotesAttributeName" "NOTAS")
                              (CONS "NameSheet" (LAMBDA (titleBlockEntityName / projectIdentification projectType shortenedProjetctType projectPhase shortenedProjectPhase sheetNumber revision)
                                                  (SETQ projectIdentification (ATS:GetAttributeProperties nil 1 titleBlockEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectIdentificationAttributeName" *titleBlockBlockList*)))))
                                                  (SETQ projectType (STRCASE (ATS:GetAttributeProperties nil 1 titleBlockEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectTypeAttributeName" *titleBlockBlockList*))))))
                                                  (IF (SETQ shortenedProjetctType (ASSOC projectType *projectTypes*))
                                                    (SETQ shortenedProjetctType (CDR shortenedProjetctType))
                                                    (SETQ shortenedProjetctType projectType))
                                                  (SETQ projectPhase (STRCASE (ATS:GetAttributeProperties nil 1 titleBlockEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "ProjectPhaseAttributeName" *titleBlockBlockList*))))))
                                                  (IF (SETQ shortenedProjectPhase (ASSOC projectPhase *projectPhases*))
                                                    (SETQ shortenedProjectPhase (ATS:GetPropertiesValues "ShortenedProjectPhase" (CDR shortenedProjectPhase)))
                                                    (SETQ shortenedProjectPhase projectPhase))
                                                  (SETQ sheetNumber (ATS:GetAttributeProperties nil 1 titleBlockEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "SheetNumberAttributeName" *titleBlockBlockList*)))))
                                                  (IF *totalSheetNumberSeparator*
                                                    (IF *nameFileTotalSheetNumberSeparator*
                                                      (SETQ sheetNumber (VL-STRING-SUBST *nameFileTotalSheetNumberSeparator* *totalSheetNumberSeparator* sheetNumber))
                                                      (SETQ sheetNumber (ATS:GetSubstring "" *totalSheetNumberSeparator* sheetNumber))))
                                                  (SETQ revision (ATS:GetAttributeProperties nil 1 titleBlockEntityName (LIST (CONS 2 (ATS:GetPropertiesValues "RevisionAttributeName" *titleBlockBlockList*)))))
                                                  (ATS:FixFileName nil (STRCAT projectIdentification *fileSeparator* sheetNumber *fileSeparator* shortenedProjectPhase *fileSeparator* shortenedProjetctType *fileSeparator* "R" revision))))))

(SETQ *titleBlocksList* (LIST
                          (QUOTE *titleBlockBlockList*)))

;; Lista dos blocos que tem prioridade aos layers de desenho, normalmente com wipeout
(SETQ *blocksDrawOrderList* (LIST
                              (QUOTE *doorBlockList*)
                              (QUOTE *windowBlockList*)
                              (QUOTE *laundrySinkBlockList*)))

;; Lista de abreviações de blocos
(SETQ *shortenedBlocksNames* (LIST
                               (CONS "CAR" (QUOTE *titleBlockBlockList*))
                               (CONS "CH" (STRCAT *standardPrefix* *affixSeparator* "Chuveiro"))
                               (CONS "DI" (QUOTE *distanceBlockList*))
                               (CONS "E" (STRCAT *standardPrefix* *affixSeparator* "Estilo"))
                               (CONS "GE" (STRCAT *standardPrefix* *affixSeparator* "Geladeira"))
                               (CONS "ID" (QUOTE *tagBlockList*))
                               (CONS "IA" (STRCAT *standardPrefix* *affixSeparator* "Início Assentamento"))
                               (CONS "J" (QUOTE *windowBlockList*))
                               (CONS "ML" (STRCAT *standardPrefix* *affixSeparator* "Máquina de Lavar Roupa"))
                               (CONS "NI" (QUOTE *levelBlockList*))
                               (CONS "PO" (QUOTE *doorBlockList*))
                               (CONS "TAN" (STRCAT *standardPrefix* *affixSeparator* "Tanque"))
                               (CONS "TIT" (QUOTE *titleBlockList*))
                               (CONS "VV" (QUOTE *viewportBlockList*))))

;;; Rotinas personalizadas
;| Avalia símbolos em seus valores armazenados e concatena recursivamente todas as strings
   @global
   @param stringSymbolList [lst] - Lista de símbolos e/ou strings, sendo os símbolos também listas ou strings
   / Exemplo: (SETQ prefix "Hello" text (LIST (QUOTE prefix) " World"))
              (ATS:EvaluateStringSymbolList (LIST (QUOTE text) "!"))
   @returns [str] - Strings concatenadas
   / Exemplo: "Hello World!"
   |;
(DEFUN ATS:EvaluateStringSymbolList (stringSymbolList)
  ;; Retorna o valor armazenado no(s) símbolo(s)
  (WHILE (EQ (TYPE stringSymbolList) (READ "SYM"))
    (SETQ stringSymbolList (EVAL stringSymbolList))
  )
  ;; Verifica se é uma lista de símbolos/strings
  (IF (AND stringSymbolList (LISTP stringSymbolList))
    ;; Se sim, avalia cada item e aplica a função novamente para verificar se o item avaliado é uma lista, até sobrar apenas strings a serem concatenadas
    (APPLY (FUNCTION STRCAT) (MAPCAR (FUNCTION ATS:EvaluateStringSymbolList) (MAPCAR (FUNCTION (LAMBDA (symbol) (IF (EQ (TYPE symbol) (READ "SYM")) (EVAL symbol) symbol))) stringSymbolList)))
    stringSymbolList
  )
)
