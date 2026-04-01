;| Desloca o item no valor padrão de 20
   @returns nil
   |;
(DEFUN C:020 ()
  (ATS:WriteLog "020" nil)
  (COMMAND-S "_.OFFSET" (* *unitsFactor* 20))
)

;| Desloca o item no valor padrão de 15
   @returns nil
   |;
(DEFUN C:015 ()
  (ATS:WriteLog "015" nil)
  (COMMAND-S "_.OFFSET" (* *unitsFactor* 15))
)

;| Desloca o item no valor padrão de 12.5
   @returns nil
   |;
(DEFUN C:0125 ()
  (ATS:WriteLog "0125" nil)
  (COMMAND-S "_.OFFSET" (* *unitsFactor* 12.5))
)

;| Desloca o item no valor padrão de 10
   @returns nil
   |;
(DEFUN C:010 ()
  (ATS:WriteLog "010" nil)
  (COMMAND-S "_.OFFSET" (* *unitsFactor* 10))
)

;| Desloca o item no valor padrão de 7.5
   @returns nil
   |;
(DEFUN C:075 ()
  (ATS:WriteLog "075" nil)
  (COMMAND-S "_.OFFSET" (* *unitsFactor* 7.5))
)

;| Desloca o item no valor padrão de 5
   @returns nil
   |;
(DEFUN C:05 ()
  (ATS:WriteLog "05" nil)
  (COMMAND-S "_.OFFSET" (* *unitsFactor* 5))
)
