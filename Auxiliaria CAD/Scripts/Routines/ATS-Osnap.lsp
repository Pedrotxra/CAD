;| Ativa os pontos de referência padrões
   @returns nil
   |;
(DEFUN C:AO (/ objectSnap)
  (ATS:WriteLog "AO" nil)
  (SETQ objectSnap (COND ((CADR (ASSOC "OSMODE" *systemVariables*))) ((GETVAR "OSMODE"))))
  (IF (NOT (ZEROP (LOGAND objectSnap 512)))
    (SETQ objectSnap (- objectSnap 512))
  )
  (SETVAR "OSMODE" objectSnap)
)

;| Ativa os pontos de referência padrões, acrescidos de 'Mais próximo'
   @returns nil
   |;
(DEFUN C:AON ()
  (ATS:WriteLog "AON" nil)
  (SETVAR "OSMODE" (LOGIOR (CADR (ASSOC "OSMODE" *systemVariables*)) 512))
)
