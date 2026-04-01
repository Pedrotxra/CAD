;| Obtém o ponto médio de uma lista de pontos
   @global
   @param pointsList [lst] - Lista de pontos
   @returns [lst] - Ponto médio
   |;
(DEFUN ATS:GetPointsMiddle (pointsList / listLength)
  (SETQ listLength (LENGTH pointsList))
  (LIST
     (/ (APPLY (FUNCTION +) (MAPCAR (FUNCTION CAR) pointsList)) listLength)
     (/ (APPLY (FUNCTION +) (MAPCAR (FUNCTION CADR) pointsList)) listLength)
  )
)

;| Translada um ponto
   @global
   @param point [lst] - Coordenadas do ponto
   @param deslocation [lst] - Acréscimo às coordenadas do ponto
   @returns [lst] - Coordenadas do ponto transladado
   |;
(DEFUN ATS:TranslatePoint (point deslocation)
  (MAPCAR (FUNCTION +) point deslocation)
)

;| Obtém a menor distância de um ponto a uma reta
   @global
   @param linePoint1 [lst] - Primeira linha que define a reta
   @param linePoint2 [lst] - Segunda linha que define a reta
   @param point [lst] - Ponto
   @returns [real] - Distância perpendicular do ponto à reta, incluindo sinal
   |;
(DEFUN ATS:GetDistanceFromPointToLine (linePoint1 linePoint2 point / line pointDistance)
  (SETQ line (MAPCAR (FUNCTION -) linePoint2 linePoint1))
  (SETQ pointDistance (MAPCAR (FUNCTION -) point linePoint1))
  (/ (- (* (CAR line) (CADR pointDistance)) (* (CADR line) (CAR pointDistance))) (DISTANCE linePoint1 linePoint2))
)
