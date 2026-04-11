;| Retorna uma lista de subpastas de uma pasta
   @global
   @param folderPath [str] - Caminho da pasta
   @param pattern [str] - Padrão do nome das subpastas
   @returns [lst] - Lista de subpastas
   |;
(DEFUN ATS:GetSubfoldersPaths (folderPath pattern / folders)
  (FOREACH folder (MAPCAR (FUNCTION (LAMBDA (folder) (STRCAT folderPath folder "\\")))
                          (VL-REMOVE ".." (VL-REMOVE "." (VL-DIRECTORY-FILES folderPath pattern -1))))
    (SETQ folders (APPEND folders (ATS:GetSubfoldersPaths folder pattern)))
  )
  (SETQ folders (CONS folderPath folders))
)

;| Configura o CAD com as pastas definidas
   @global
   @returns [nil] - Configura o CAD com as pastas definidas
   |;
(DEFUN ATS:SetPaths (sharedFolders automaticConfig / files folder)
  (SETQ *configurationFolder* (GETVAR "LOCALROOTPREFIX"))
  (SETQ *roamingFolder* (GETVAR "ROAMABLEROOTPREFIX"))
  (SETQ files (ATS:SaveObject (VLA-GET-FILES (ATS:SaveObject (VLA-GET-PREFERENCES *acadObject*)))))
  (SETQ folder (VL-REMOVE-IF (FUNCTION (LAMBDA (path) (WCMATCH path (STRCAT *autotsFolder* "*")))) (ATS:StringToList ";" (VLA-GET-SUPPORTPATH files))))
  (IF sharedFolders
    (SETQ folder (APPEND (ATS:GetSubfoldersPaths (ATS:EvaluateStringSymbolList *blocksFolder*) nil)
                         (ATS:GetSubfoldersPaths (ATS:EvaluateStringSymbolList *hatchesFolder*) nil)
                         folder))
    (PROGN
      ;; Pasta de configurações locais do CAD
        (SETQ *templatesFolder* (LIST (QUOTE *configurationFolder*) "Template\\"))
          (SETQ *template* (STRCAT (IF (EQ *CADSoftware* "ZWCAD") "zw" "a") "cadiso.dwt"))
      ;; Pasta de configurações itinerantes do CAD
        (SETQ *scriptsLogFolder* (LIST (QUOTE *roamingFolder*) "Logs\\"))
        (SETQ *plottersFolder* (LIST (QUOTE *roamingFolder*) "Plotters\\"))
          (SETQ *standardPlotter* (STRCAT "DWG To PDF.pc" (IF (EQ *CADSoftware* "ZWCAD") "5" "3")))
            (SETQ *sheetsSizes* (LIST ; Nome do bloco da folha e suas dimensões em centímetros, com relação ao ponto base
                                  (CONS "ISO full bleed A0 (1189.00 x 841.00 mm)" (LIST 118.9 84.1))
                                  (CONS "ISO full bleed A0 (841.00 x 1189.00 mm)" (LIST 84.1 118.9))
                                  (CONS "ISO full bleed A1 (841.00 x 594.00 mm)" (LIST 84.1 59.4))
                                  (CONS "ISO full bleed A1 (594.00 x 841.00 mm)" (LIST 59.4 84.1))
                                  (CONS "ISO full bleed A2 (594.00 x 420.00 mm)" (LIST 59.4 42.0))
                                  (CONS "ISO full bleed A2 (420.00 x 594.00 mm)" (LIST 42.0 59.4))
                                  (CONS "ISO full bleed A3 (420.00 x 297.00 mm)" (LIST 42.0 29.7))
                                  (CONS "ISO full bleed A3 (297.00 x 420.00 mm)" (LIST 29.7 42.0))
                                  (CONS "ISO full bleed A4 (297.00 x 210.00 mm)" (LIST 29.7 21.0))
                                  (CONS "ISO full bleed A4 (210.00 x 297.00 mm)" (LIST 21.0 29.7))
                                  (CONS "ISO full bleed A5 (210.00 x 148.00 mm)" (LIST 21.0 14.8))
                                  (CONS "ISO full bleed A5 (148.00 x 210.00 mm)" (LIST 14.8 21.0))))
            (SETQ *standardPlotStyle* "monochrome.ctb")
            (SETQ *standardPrinterDescription* nil)
      (SETQ *customUserInterfaceFolder* *roamingFolder*)
        (SETQ *parcialCUI* nil)
      (SETQ *blocksFolder* (LIST (QUOTE *roamingFolder*) "Support\\"))
      (SETQ *fontsFolder* (LIST (QUOTE *roamingFolder*) "Support\\"))
      (SETQ *hatchesFolder* (LIST (QUOTE *roamingFolder*) "Support\\"))
      (SETQ *linetypesFolder* (LIST (QUOTE *roamingFolder*) "Support\\"))
        (SETQ *customIconsFolder* (LIST (QUOTE *blocksFolder*) "Icons\\"))
        (SETQ *profilesFolder* (LIST (QUOTE *blocksFolder*) "Profiles\\"))
        (SETQ *toolPaletteFolder* (LIST (QUOTE *blocksFolder*) "ToolPalette\\"))
    )
  )
  (IF automaticConfig
    (PROGN
      (IF (AND *blocksFolder* (SETQ folder (VL-REMOVE-IF-NOT (FUNCTION VL-FILE-DIRECTORY-P) folder)))
        (VLA-PUT-SUPPORTPATH files (ATS:ListToString ";" folder))
      )
      (IF (AND (NOT (EQ *CADSoftware* "ZWCAD")) *customUserInterfaceFolder* (SETQ folder (ATS:EvaluateStringSymbolList *customUserInterfaceFolder*)) (VL-FILE-DIRECTORY-P folder))
        (PROGN
          (IF (AND *enterpriseMenuFile* (FINDFILE (SETQ folder (STRCAT folder *enterpriseMenuFile*))))
            (VLA-PUT-ENTERPRISEMENUFILE files folder)
          )
          (IF (AND *parcialCUI* (FINDFILE (STRCAT folder *parcialCUI*)))
            (COMMAND-S "_.CUILOAD" (STRCAT folder *parcialCUI*))
          )
          (IF (AND *customIconsFolder* (SETQ folder (ATS:EvaluateStringSymbolList *customIconsFolder*)) (VL-FILE-DIRECTORY-P folder))
            (VLA-PUT-CUSTOMICONPATH files folder)
          )
        )
      )
      (IF (AND *plottersFolder* (SETQ folder (ATS:EvaluateStringSymbolList *plottersFolder*)) (VL-FILE-DIRECTORY-P folder))
        (PROGN
          (VLA-PUT-PRINTERCONFIGPATH files folder)
          (IF (AND *plotStylesFolder* (SETQ folder (ATS:EvaluateStringSymbolList *plotStylesFolder*)) (VL-FILE-DIRECTORY-P folder))
            (VLA-PUT-PRINTERSTYLESHEETPATH files folder)
          )
          (IF (AND *printerDescriptionFolder* (SETQ folder (ATS:EvaluateStringSymbolList *printerDescriptionFolder*)) (VL-FILE-DIRECTORY-P folder))
            (VLA-PUT-PRINTERDESCPATH files folder)
          )
        )
      )
      (IF (AND *templatesFolder* (SETQ folder (ATS:EvaluateStringSymbolList *templatesFolder*)) (VL-FILE-DIRECTORY-P folder))
        (PROGN
          (VLA-PUT-TEMPLATEDWGPATH files folder)
          (SETQ folder (STRCAT folder *template*))
          (IF (FINDFILE folder)
            (VLA-PUT-QNEWTEMPLATEFILE files folder)
          )
        )
      )
      (IF (AND *toolPaletteFolder* (SETQ folder (ATS:EvaluateStringSymbolList *toolPaletteFolder*)) (VL-FILE-DIRECTORY-P folder))
        (VLA-PUT-TOOLPALETTEPATH files folder)
      )
    )
  )
)

;| Pesquisa por arquivos nos arquivos de suporte
   @global
   @param pattern [str] - Padrão do nome dos arquivos
   @returns [lst] - Lista de arquivos encontrados
   |;
(DEFUN ATS:FindFilesInLibrary (pattern / path result)
  (FOREACH code (REVERSE (VL-STRING->LIST (GETVAR "ACADPREFIX")))
    (IF (EQ code 59)
      (IF path
        (PROGN
          (SETQ result (CONS path result))
          (SETQ path nil)
        )
      )
      (SETQ path (CONS code path))
    )
  )
  (VL-REMOVE nil
    (MAPCAR
      (FUNCTION
        (LAMBDA (path / result)
          (IF (SETQ result (VL-DIRECTORY-FILES path pattern 1))
            (CONS path result)
          )
        )
      )
      (MAPCAR (FUNCTION VL-LIST->STRING) (IF path (CONS path result) result))
    )
  )
)

;| Adequa o nome do arquivo para o padrão do Windows
   @global
   @param extension [bool] - 'T' se o nome contém a extensão
   @param fileName [str] - Nome do arquivo
   @returns [str] - Nome do arquivo adequado
   |;
(DEFUN ATS:FixFileName (extension fileName)
  (FOREACH character (LIST "\\" "/" ":" "*" "?" "\"" "<" ">" "|")
    (SETQ fileName (ATS:ReplaceAllInString *secondaryFileSeparator* character fileName))
  )
  (IF extension
    (STRCAT (ATS:ReplaceAllInString *secondaryFileSeparator* "." (VL-FILENAME-BASE fileName)) (VL-FILENAME-EXTENSION fileName))
    (ATS:ReplaceAllInString *secondaryFileSeparator* "." fileName)
  )
)

;| Nomeia o arquivo de forma única
   @global
   @param affixPosition [bool] - 'T' para prefixo, ou 'nil' para sufixo
   @param affix [str/int] - Afixo a ser adicionado. Caso seja um número, o novo nome será ele +1
   @param fileDirectory [str] - Caminho do diretório do arquivo
   @returns [str] - Nome do arquivo com o afixo adicionado, se necessário
   |;
(DEFUN ATS:NameFileUniquely (affixPosition affix fileDirectory)
  (IF (FINDFILE fileDirectory)
    (ATS:NameFileUniquely affixPosition affix (STRCAT
                                               (VL-FILENAME-DIRECTORY fileDirectory)
                                               (ATS:AffixName *fileSeparator* affixPosition affix (VL-FILENAME-BASE fileDirectory))
                                               (VL-FILENAME-EXTENSION fileDirectory)))
    fileDirectory
  )
)

;| Cria uma pasta
   @global
   @param folderName [str] - Nome da pasta
   @param folderPath [str] - Caminho da pasta
   @returns [nil] - Cria a nova pasta
   |;
(DEFUN ATS:CreateFolder (folderName folderPath / fullPath)
  (SETQ fullPath (STRCAT folderPath folderName))
  (IF (NOT (VL-FILE-DIRECTORY-P fullPath))
    (VL-MKDIR fullPath)
  )
)

;| Abre o diálogo de seleção de pasta
   @global
   @param promptMessage [str] - Mensagem a ser exibida na caixa de diálogo
   @param browseFlags [int] - Flags de comportamento da caixa de diálogo:
   @param initialDirectory [str] - Caminho inicial da caixa de diálogo
   @returns [str] - Caminho da pasta selecionada
   |;
(DEFUN ATS:BrowseForFolder (promptMessage browseFlags initialDirectory / folder)
  ; 0	Standard behaviour (Default)
  ; 1	Only file system folders can be selected.
  ; If this bit is set, the OK button is disabled if the user selects a folder that doesn't belong to the file system.
  ; 2	The user is prohibited from browsing below the domain within a network
  ; 4	Room for status text is provided under the dialog box
  ; 8	Returns file system ancestors only. An ancestor is a subfolder that is beneath the root folder.
  ; If the user selects an ancestor of the root folder that is not part of the file system, the OK button is greyed.
  ; 16	Shows an edit box in the dialog box for the user to type the name of an item.
  ; 32	Validate the name typed in the edit box.
  ; 64	Enable drag-and-drop capability within the dialog box, reordering, shortcut menus, new folders, delete, and other shortcut menu commands.
  ; 128	The browse dialog box can display URLs.
  ; 256	When combined with flag 64, adds a usage hint to the dialog box, in place of the edit box.
  ; 512	Suppresses display of the New Folder button
  ; 1024	When the selected item is a shortcut, return the PIDL of the shortcut itself rather than its target.
  ; 4096	Enables the user to browse the network branch for computer names.
  ; If the user selects anything other than a computer, the OK button is greyed.
  ; 8192	Enables the user to browse the network branch for printer names.
  ; If the user selects anything other than a printer, the OK button is greyed.
  ; 16384	Allows browsing for everything: the browse dialog box displays files as well as folders.
  ; 32768	If combined with flag 64, the browse dialog box can display shareable resources on remote systems.
  ; 65536	Windows 7 & later: Allow folder junctions such as a library or a compressed file with a .zip file name extension to be browsed.
  (SETQ folder (ATS:SaveObject (VLAX-INVOKE-METHOD (ATS:SaveObject (VLA-GETINTERFACEOBJECT *acadObject* "SHELL.APPLICATION")) "BROWSEFORFOLDER" (VLA-GET-HWND *acadObject*) promptMessage browseFlags initialDirectory)))
  (IF folder
    (STRCAT (VLAX-GET-PROPERTY (ATS:SaveObject (VLAX-GET-PROPERTY folder "SELF")) "PATH") "\\")
  )
)

;| Obtém o tamanho de um arquivo
   @global
   @param unit [bool] - 'T' para megabytes, ou 'nil' para kilobytes
   @param filePath [str] - Caminho do arquivo, ou 'nil' para arquivo atual
   @returns [real] - Tamanho do arquivo
   |;
(DEFUN ATS:GetFileSize (unit filePath)
  (IF (NOT filePath)
    (SETQ filePath (VLA-GET-FullName *activeDocument*))
  )
  (SETQ fileSize (/ (FLOAT (VL-FILE-SIZE filePath)) (EXPT 1024 (IF unit 2 1))))
)

;| Abre a pasta de temporários
   @returns nil
   |;
(DEFUN C:TEMP ()
  (ATS:WriteLog "TEMP" nil)
  (STARTAPP "EXPLORER" (GETVAR "SAVEFILEPATH"))
)

;| Abre o log de comandos
   @returns nil
   |;
(DEFUN C:LOG ()
  (ATS:WriteLog "LOG" nil)
  (STARTAPP "NOTEPAD" (STRCAT (ATS:EvaluateStringSymbolList *scriptsLogFolder*) *scriptsLog*))
)

;| Abre a pasta de logs de comandos
   @returns nil
   |;
(DEFUN C:LOGF ()
  (ATS:WriteLog "LOGF" nil)
  (STARTAPP "EXPLORER" (ATS:EvaluateStringSymbolList *scriptsLogFolder*))
)

;| Abre a pasta de configurações locais do CAD
  @returns nil
  |;
(DEFUN C:CFG ()
  (ATS:WriteLog "CFG" nil)
  (STARTAPP "EXPLORER" *configurationFolder*)
)

;| Abre a pasta de configurações itinerantes do CAD
  @returns nil
  |;
(DEFUN C:CFGR ()
  (ATS:WriteLog "CFGR" nil)
  (STARTAPP "EXPLORER" *roamingFolder*)
)
