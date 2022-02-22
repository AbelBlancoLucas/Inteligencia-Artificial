__includes ["MCTS-LT.nls"]

turtles-own[ valor ]  ; la variable valor dentro de una tortuga hace referencia al "dado" que tendra , es decir si el valor es 2 es que es el dado 2 por ejemplo.
patches-own[tiene-dado? jugador] ;cada patch tendra una variable para seber si tiene un dado y la otra para saber de que jugador es
breed [dados dado]
globals [
  player
  elegir
  tortuga-a-sumar
  modo-juego
  played?
]

to setup
  ca
  set-default-shape dados "die 1"
  set player 1
  set played? false
  set elegir false
  ask patches[set tiene-dado? false set jugador 0]
  ask patches with [(pxcor + pycor) mod 2 = 0] [set pcolor 36]
  ask patches with [(pxcor + pycor) mod 2 = 1] [set pcolor 37]
  set modo-juego vs_IA
  reset-ticks
end

;El go esta puesta de esta forma ya que se pregunta por la variable "modo-juego" para saber si estamos jugando 1vs1 o 1vsIA y si pone asi para que una vez empezada la partida no se pueda cambiar de modo a no ser que se resete el juego.
to go
  ifelse modo-juego [vsIA][vsh]
end


;================================================ Código de humano vs humano ===========================================================
; Esta función funciona como "go" en caso de ser humano vs humano
; Lo primero que hace es mirar si estamos en el estado "elegir"
;sino estamos en ese estado entoces va preguntado si hemos pulsado un patch que no tiene dado y si es asi coloca un dado con valor 1 donde hemos pulsado y se ejecuta la función sumadados que se encarga de sumar
;si tenemos dos vecinos o cambiar a estado elegir si contamos con mas vecinos
;si estamos en el estado elegir se ejecuta la parte encargada para que seleccionemos los dados que deseamos elegir para la suma
;Luego comprueba si se ha acabado la partida y de decir quien es el ganador
to vsh
  ifelse elegir = false[   ;Miramos si estamos en el "estado" elegir que hace referencia si tenemos que elegir dado para saber que dados sumar ( se entra en el estado elegir si tenemos mas de 2 vecinos potenciales (menores que 6)
    if ((mouse-down?) and (false = ([tiene-dado?] of patch round mouse-xcor round mouse-ycor)))[ ; if que se encarga de crear un dado en donde pinches y que solo se pueda crear uno no mas en cada patch
      create-dados 1 [
        set valor 1
        set xcor round mouse-xcor
        set ycor round mouse-ycor
        sumadados
        ifelse player = 1 [set color 96][set color 15]
      ]
      ask patch mouse-xcor round mouse-ycor [ set tiene-dado? true]
      ifelse player = 1 [set player 2][set player 1]
    ]
    ifelse player = 1 [output-print"Turno del jugador Azul"][output-print"Turno del jugador Rojo"]
  ]
  ;empieza el else, esto es lo que corre cuando hay que elegir dados para sumar
  [
    output-print "Elige dados para sumar y pulsa sumar-elegidos"
    sumaselegidos
    wait 0.1
  ]
  convierteDados  ;Función que convierte los dados respecto a su valor
  ;condición de que se ha acabado la partida y salta quien es el ganador
  if (all? patches[tiene-dado?] and elegir = false)[
    let nRojo (count turtles with [color = 15])
    let nAzul (count turtles with [color = 96])
    ifelse nrojo < nazul [user-message (word "El jugador Azul ha ganado con " nAzul "dados")][user-message (word "El jugador Rojo ha ganado con " nRojo " dados" )]
  ]
tick
end

;Una vez colocado un dado en cada turno luego salta esta función, que se encarga de sumar los vecinos potenciales, en caso de tener dos vecinos los suma y los elimina
;en caso de tener 3 o mas vecinos (y se puede sumar (menor que 6)) se cambia al estado elegir a true para que el jugador selecciones los dados que desea sumar
to sumadados
  let x 0
  ask dados-here[ ;dado que se acaba de colocar
    ifelse  ((sum[count turtles-here with [valor < 6 ]] of neighbors4) = 2)[  ; se entra en este if si tengo dos vecinos potenciales (menores que 6 )
      ask neighbors4[
        if ((tiene-dado?) and (sum[valor] of turtles-here) < 6)        ;si el vecino tiene dado y es menor que 6 , sumo en x la suma de los vecinos
        [
          set x (x + sum[valor] of turtles-here)
        ]
      ]
      if (x <= 6)[ ;Miro si x es menor igual que 6 ya que si la suma es mayor quiere decir que eso dos dados no se puede sumar, en caso de que si se pueda sumar cambio el valor del dado que se acaba de poner a la suma y los vecinos los elimino
        ask neighbors4[
          if ((sum[valor] of turtles-here) < 6)[
            ask dados-here [die]
            set tiene-dado? false
            set jugador 0
          ]
        ]
        set valor x ;aqui cambio el valor del dado que se acababa de colocar por la suma de los vecinos potenciales que es x
      ]
    ]
    ;aqui empiza el else, en este else se entra si tengo mas de dos vecinos, vamos a comprobar si con los vecinos potenciales de los que disponemos se puede hacer alguna suma posible (menor igual que 6) en caso de que se pueda hacer cambiamos elegir a true.
    [
      if(sum[count turtles-here with [valor < 6 ]] of neighbors4) >= 3[
        let lista-vecinos(range 0)
        let posiblesumas (range 0)
        ask neighbors4[
          if ((tiene-dado?) and (sum[valor] of turtles-here) < 6)[
            set lista-vecinos lput (sum[valor] of turtles-here) lista-vecinos ;meto en lista-vecinos los vecinos con valor menor que 6 que son los vecinos potenciales
          ]
        ]
        let combinaciones (crea-combinaciones-vecinos lista-vecinos) ;con esos vecinos hago todas las combinaciones posibles
        set combinaciones filter [b -> length b >= 2 ] combinaciones ;Me quedo con aquellas combinaciones que tienes mas de 1 elemento ya que sumar un dado o no sumar ninguno no tendria sentido
        set posiblesumas lista-con-posibles-sumas combinaciones posiblesumas ; guardo en posibles sumas las sumas de todas las combinaciones
        set posiblesumas remove-duplicates posiblesumas ; borro las sumas duplicadas
        if se-puede-sumar posiblesumas = false [ ;miro si algunas de esas sumas sumas es menor igual q 6 es decir si se puede sumar ( se devulve false si se puede sumar)
          set elegir true   ; pasamos a estado elegir
          set tortuga-a-sumar one-of dados-here ;guardamos en tortuga-a-sumar el dado que en la fase elegir ha de ser sumado
        ]
      ]
    ]
  ]
end



;========================================= Código para la Inteligencia Artificial ====================================================

;State -> [content player]
;content -> una lista formada por las posiciones del tablero, las cuales contiene cada una dos elementos , el primero elemento hace referencia a que jugador es el dado (0/1/2) "0->No tiene dado,1->dado del jugador 1,2->dado del jugador 2"
                                                                                                         ;El segundo elemento es el valor del dado que hay posicionado, es una lista ya que "[valor] of turtles-here]" devuelve una lista ( mira en el board-to-state)
;player = 1/2

; Get the content of the state
to-report MCTS:get-content [s]
  report first s
end

; Get the player that generates the state
to-report MCTS:get-playerJustMoved [s]
  report last s
end

; Create a state from the content and player
to-report MCTS:create-state [c p]
  report (list c p)
end

to-report MCTS:get-rules [s]
  let c MCTS:get-content s
  report filter [x -> (item 0(item x c))  = 0] (range 25)
end

; La regla será que no puede colocar un dado donde ya haya uno colocado
to-report MCTS:apply2 [r s]
  let c MCTS:get-content s
  let p MCTS:get-playerJustMoved s
  let y (replace-item 0 (item r c) (3 - p))
  report MCTS:create-state (replace-item r c y) (3 - p)
end

; En aplicar la reglas lo que se tiene en cuenta es como cambia el estado al colocar un dado
; Este esta defino en 4 partes 1.Cuando no tiene o tiene solo un vecino 2.Cuando tiene dos vecinos 3.cuando tiene 3 vecinos 4.Cuando tiene 4 vecinos
to-report MCTS:apply [r s]
  let c MCTS:get-content s
  let p MCTS:get-playerJustMoved s
  let vec vecinos r
  let vec_con_dado []
  foreach vec[ ; miro los vecinos y modifico "vec_con_dados" con aquellos vecinos que tiene dados y ademas los dados tiene un valor menor que 6 , ya que si tiene 6 no se puede sumar y no lo considero un vecino potencial a sumar
    x -> if(empty?(item 1 item x c) = false and (item 0 item 1 item x c) < 6 )[set vec_con_dado lput x vec_con_dado]
  ]
  ifelse length vec_con_dado < 2[  ;si tengo uno o ningun vecino devuelvo el estado con el nuevo dado colocado
    report MCTS:create-state (replace-item r c (list(3 - p) ([1]))) (3 - p) ;Devuelvo el estado modificado poniendo como primer elemento el jugador que lo ha colocado y como segundo el valor del dado
  ]
  [
    ifelse (length vec_con_dado = 2)[ ; si tengo dos vecinos los sumos si la suma es menor que 6 y coloca el nuevo dado con la suma, aprovecho que son siempre 2 elementos para utilizar item 0 item1
      let vc1 item 0 vec_con_dado ;Cojo un vecino( la posicion la poscion en el tablero)
      let vc2 item 1 vec_con_dado ; Cojo el otro vecino ( la posicion en el tablero)
      let valor_vc1 item 0 item 1 (item vc1 c) ;cojo el valor del dado del vecino
      let valor_vc2 item 0 item 1 (item vc2 c) ;cojo el valor del dado del otro vecino
      ifelse (valor_vc1 + valor_vc2) > 6 [report MCTS:create-state (replace-item r c (list(3 - p) ([1]))) (3 - p)] ;Si suma mas de 6 quiere decir que esos vecinos no se pueden sumar entonces devulevo el estado con el nuevo dado colocado
      [  ;si esos vecinos si se pueden sumar ( suman 6 o menos) entonces hago lo siguiente
        set c replace-item vc1 c ((list(0) ([]))) ;limpio el vecino 1
        set c replace-item vc2 c ((list(0) ([]))) ;limpio el vecino 2
        set c replace-item r c ((list(3 - p) (list(valor_vc1 + valor_vc2)))) ;Donde se ha decidido colocar, pongo como primer elemento el jugador y como segundo la suma de los valores de los vecinos
        report MCTS:create-state c (3 - p)
      ]
    ]
    [ ;este else entra si tiene 3 o 4 vecinos con dado
      ifelse length vec_con_dado = 3[ ;utilizo este ifelse para crear las variables dependiendo de si tiene 3 o 4 vecinos potenciales
        let vc1 item 0 vec_con_dado ;Cojo un vecino( la posicion la poscion en el tablero)
        let vc2 item 1 vec_con_dado ; Cojo el otro vecino ( la posicion en el tablero)
        let vc3 item 1 vec_con_dado ; Cojo el otro vecino ( la posicion en el tablero)
        let valor_vc1 item 0 item 1 (item vc1 c) ;cojo el valor del dado del vecino
        let valor_vc2 item 0 item 1 (item vc2 c) ;cojo el valor del dado del otro vecino
        let valor_vc3 item 0 item 1 (item vc3 c) ;cojo el valor del dado del otro vecino
        let lista_valores (list(valor_vc1)(valor_vc2)(valor_vc3)); creo una lista con los valores
        let lista_vecinos_posicion (list(vc1)(vc2)(vc3)); creo una lista con las posiciones de los vecinos en la tabla
        let combinaciones(crea-combinaciones-vecinos lista_valores) ; veo todas las combinaciones posibles de los valores
        set combinaciones filter [b -> length b >= 2 ] combinaciones ;elimino todas aquellas combinaciones con un solo elemento
        let posiblesumas lista-con-posibles-sumas combinaciones []  ;aprovecho la lista "combinaciones" y creo una nueva lista con todas las sumas posibles que pueden dar los diferentes dados ya coja 2 dados o 3.
        set posiblesumas remove-duplicates posiblesumas ;elimino las sumas duplicadas
        ifelse se-puede-sumar posiblesumas = true[ ; Si ninguna de esas sumas es válida ( es decir ninguna suma de las combinaciones es menor a 6)(se devuelve true cuando no se puede sumar)
          report MCTS:create-state (replace-item r c (list(3 - p) ([1]))) (3 - p) ;Devuelvo el estado modificado poniendo como primer elemento el jugador que lo ha colocado y como segundo el valor del dado ( al no sumar el valor del dado es 1)
        ]
        [; si alguna de esas sumas es menor igual que 6 , es decir son válidas entonces hago lo siguiente
          set posiblesumas filter  [? -> ? <= 6] posiblesumas ;Me quedo con aquellas sumas que son menores igual que 6
          set posiblesumas (sort posiblesumas) ; las ordenos de menor a mayor
          let obj last posiblesumas ;cojo la ultima suma( es decir la suma mas grande posible)
          let dados-a-eliminar [0]
          foreach  combinaciones[ ; En este foreach busco cuales de las combinaciones de dados es la que me da la suma obj
            y -> if(suma y = obj)[set dados-a-eliminar y]
          ]
          let i 0
          while [empty? dados-a-eliminar = false] ; mientras la lista dados-a-eliminar no este vacía voy a ir mirando si se ha seleccionado para sumar cada uno de los diferentes valores
          [
            let aux item i lista_valores ; cojo el elemento iesimo de la lista de valores
            if( contiene? aux dados-a-eliminar)[ ;miro si ese valor esta dentro de los que hemos seleccionado para sumar
              set dados-a-eliminar (borra-elemento aux dados-a-eliminar) ; De la lista "dados-a-eliminar" quito un elemento ya que dicho elemento es el valor que se ha seleccionado para la suma
              let vc_eliminar_pos item i lista_vecinos_posicion;aprovecho que los he metido tanto los valores como la posicion en el mismo orden para saber cual eliminar
              set c replace-item vc_eliminar_pos c ((list(0) ([]))) ;limpio el vecino seleccionado para la suma
            ]
            set i ( i + 1)
          ]
          set c replace-item r c ((list(3 - p) (list(obj)))) ;Donde se ha decidido colocar, pongo como primer elemento el jugador y como segundo la suma de los valores de los vecinos
          report MCTS:create-state c (3 - p)
        ]
      ]
      [;aqui entra cuando son 4 los vecinos potenciales
        let vc1 item 0 vec_con_dado ;Cojo un vecino( la posicion la poscion en el tablero)
        let vc2 item 1 vec_con_dado ; Cojo el otro vecino ( la posicion en el tablero)
        let vc3 item 1 vec_con_dado ; Cojo el otro vecino ( la posicion en el tablero)
        let vc4 item 1 vec_con_dado ; Cojo el otro vecino ( la posicion en el tablero)
        let valor_vc1 item 0 item 1 (item vc1 c) ;cojo el valor del dado del vecino
        let valor_vc2 item 0 item 1 (item vc2 c) ;cojo el valor del dado del otro vecino
        let valor_vc3 item 0 item 1 (item vc3 c) ;cojo el valor del dado del otro vecino
        let valor_vc4 item 0 item 1 (item vc4 c) ;cojo el valor del dado del otro vecino
        let lista_valores (list(valor_vc1)(valor_vc2)(valor_vc3)(valor_vc4)); creo una lista con los valores
        let lista_vecinos_posicion (list(vc1)(vc2)(vc3)(vc4)); creo una lista con las posiciones de los vecinos en la tabla
        let combinaciones(crea-combinaciones-vecinos lista_valores) ; veo todas las combinaciones posibles de los valores
        set combinaciones filter [b -> length b >= 2 ] combinaciones ;elimino todas aquellas combinaciones con un solo elemento
        let posiblesumas lista-con-posibles-sumas combinaciones []  ;aprovecho la lista "combinaciones" y creo una nueva lista con todas las sumas posibles que pueden dar los diferentes dados ya coja 2 dados o 3.
        set posiblesumas remove-duplicates posiblesumas ;elimino las sumas duplicadas
        ifelse se-puede-sumar posiblesumas = true[ ; Si ninguna de esas sumas es válida ( es decir ninguna suma de las combinaciones es menor a 6)(se devuelve true cuando no se puede sumar)
          report MCTS:create-state (replace-item r c (list(3 - p) ([1]))) (3 - p) ;Devuelvo el estado modificado poniendo como primer elemento el jugador que lo ha colocado y como segundo el valor del dado ( al no sumar el valor del dado es 1)
        ]
        [; si alguna de esas sumas es menor igual que 6 , es decir son válidas entonces hago lo siguiente
          set posiblesumas filter  [? -> ? <= 6] posiblesumas ;Me quedo con aquellas sumas que son menores igual que 6
          set posiblesumas (sort posiblesumas) ; las ordenos de menor a mayor
          let obj last posiblesumas ;cojo la ultima suma( es decir la suma mas grande posible)
          let dados-a-eliminar [0]
          foreach  combinaciones[ ; En este foreach busco cuales de las combinaciones de dados es la que me da la suma obj
            y -> if(suma y = obj)[set dados-a-eliminar y]
          ]
          let i 0
          while [empty? dados-a-eliminar = false] ; mientras la lista dados-a-eliminar no este vacía voy a ir mirando si se ha seleccionado para sumar cada uno de los diferentes valores
          [
            let aux item i lista_valores ; cojo el elemento iesimo de la lista_valores
            if( contiene? aux dados-a-eliminar)[ ;miro si ese valor esta dentro de los que hemos seleccionado para sumar
              set dados-a-eliminar (borra-elemento aux dados-a-eliminar) ; De la lista "dados-a-eliminar" quito un elemento ya que dicho elemento es el valor que se ha seleccionado para la suma
              let vc_eliminar_pos item i lista_vecinos_posicion;aprovecho que los he metido tanto los valores como la posicion en el mismo orden para saber cual eliminar
              set c replace-item vc_eliminar_pos c ((list(0) ([]))) ;limpio el vecino seleccionado para la suma
            ]
            set i ( i + 1)
          ]
          set c replace-item r c ((list(3 - p) (list(obj)))) ;Donde se ha decidido colocar, pongo como primer elemento el jugador y como segundo la suma de los valores de los vecinos
          report MCTS:create-state c (3 - p)
        ]
      ]
    ]
  ]
end

;Para saber el resultado que se mirará cuando todas las casillas esten ocupadas
;Contamos las casillas que tienen jugador 1 y las comparamos con las casillas que tiene el jugador 2 el que tengas mas es el que gana
;Al haber un numero impar de casillas no puede haber empate
to-report MCTS:get-result [s p]
  let pl MCTS:get-playerJustMoved s
  let c MCTS:get-content s
  let puntos1 0
  let puntos2 0
  if empty? MCTS:get-rules s[
  foreach c[
    x -> ifelse( (item 0 x) = 1 )[set puntos1 (puntos1 + 1) ][if ((item 0 x) = 2) [set puntos2 (puntos2 + 1) ]]
  ]
  ifelse(p = 1)[ifelse puntos1 > puntos2[report 1][report 0]][if (p = 2)[ifelse puntos1 > puntos2[report 0][report 1]]]
  ]
  report [false]
end

; esta función funciona como go cuando es humano vs IA , igual que la función vsh pero implementada para algoritmo montecarlo
to vsIA
  ifelse elegir = false[
    ifelse played? = false[
      output-print "su turno"
      if ((mouse-down?) and (false = ([tiene-dado?] of patch round mouse-xcor round mouse-ycor)))[
        create-dados 1 [
          set valor 1
          set xcor round mouse-xcor
          set ycor round mouse-ycor
          sumadados
          set color 96
        ]
        ask patch round mouse-xcor round mouse-ycor [
          set tiene-dado? true
          set jugador 1
          set played? true
        ]
        let result_for_1 MCTS:get-result (list (board-to-state) 1) 1
        if elegir = false[
          if result_for_1 = 1 [
            user-message "You win!!!"
            stop
          ]
        ]
      ]
    ][
      output-print "Turno IA"
      let m 0
      ;he implementado este ifelse por que a veces ( no siempre ) saltaba un error cuando quedaba una casilla libre y le tocaba a la IA colocar el dado
      ; un error el el MCTS-LT de que "untriedRules-of [N]" no puede ser una table con 0. Mi forma de solucionarlo ha sido que cuando solo quede una casilla libre
      ;la ia no tenga que pensar donde colocar el dado sino que direcmente se colocque en el unico hueco libre que queda
      ifelse(  length solucionar-error = 1)[set m item 0 solucionar-error]
      [set m MCTS:UCT (list (board-to-state) 1) Max_iterations]

      ask (item m (sort patches)) [
        set jugador 2
        set tiene-dado? true
        sprout-dados 1 [set valor 1 set color 15]
        sumadadosIA
      ]
      set played? false
    ]
    let result_for_2 MCTS:get-result (list (board-to-state) 2) 2
    if elegir = false[
      if result_for_2 = 1 [
        user-message "I win!!!"
        stop
      ]
    ]
  ]
  ;empieza el else
  [
    output-print "Elige dados para sumar y pulsa sumar-elegidos"
    sumaselegidos
    wait 0.1
  ]
  convierteDados
  tick
end

;Este sumadados es muy parecido al sumadados normal pero con una pecularidad ya que es el sumas dado para la IA
;para el caso de no tener vecinos y dos vecinos es igual al otro sumadados
;pero para el caso que tiene 3 o 4 vecinos que la ia debería elegir que dados sumar he decicido implentar
; que para la ia automaticamente sume el mayor numero posible que puedas con los vecinos ( explicaré esta decisión mas profundamente el documento )
to sumadadosIA
  let x 0
  ask dados-here[
    ifelse  ((sum[count turtles-here with [valor < 6 ]] of neighbors4) = 2)[
      ask neighbors4[
        if ((tiene-dado?) and (sum[valor] of turtles-here) < 6)
        [
          set x (x + sum[valor] of turtles-here)
        ]
      ]
      if (x <= 6)[
        ask neighbors4[
          if ((sum[valor] of turtles-here) < 6)[
            ask dados-here [die]
            set tiene-dado? false
            set jugador 0
          ]
        ]
        set valor x
      ]
    ]
    ;aqui empiza el else
    [
      if(sum[count turtles-here with [valor < 6 ]] of neighbors4) >= 3[ ;Para el caso de 3 o mas dados adyacentes con valores menores de 6
        let lista-vecinos(range 0)
        let posiblesumas (range 0)
        ;Meto en listas-vecinos los valores de los vecinos menores a 6
        ask neighbors4[
          if ((tiene-dado?) and (sum[valor] of turtles-here) < 6)[
            set lista-vecinos lput (sum[valor] of turtles-here) lista-vecinos
          ]
        ]
        let dados-a-eliminar [0]
        let combinaciones(crea-combinaciones-vecinos lista-vecinos)
        set combinaciones filter [b -> length b >= 2 ] combinaciones ;Meto en "combinaciones" todas las combinaciones de los valores de los vecinos y elimino aquellas que tenga un solo elemento
        set posiblesumas lista-con-posibles-sumas combinaciones posiblesumas ;aprovecho la lista "combinaciones" y creo una nueva lista con todas las sumas posibles que pueden dar los diferentes dados ya coja 2 dados, 3 o 4.
        set posiblesumas remove-duplicates posiblesumas ;elimino las sumas duplicadas
        if se-puede-sumar posiblesumas = false[ ; si algunas de esas sumas es menor o igual que 6 ( es decir algunas de las combinaciones es valida)
          set posiblesumas filter  [? -> ? <= 6] posiblesumas ;Me quedo con aquellas sumas que son menores iguales que 6
          set posiblesumas (sort posiblesumas) ; las ordenos de menor a mayor
          let obj last posiblesumas ;cojo la ultima suma( es decir la suma mas grande posible)
          set valor obj ; cambio el valor del dado que se acaba de colocar al obj
          foreach  combinaciones[ ; En este foreach busco cuales de las combinaciones de dados es la que me da la suma obj
            y ->
            if(suma y = obj)[set dados-a-eliminar y]
          ]
          ;Ahora preguntare a las 4 vecinos para ir borrando aquellos que han sido seleccionados
          ;(Se aprovecha que la llamada a los vecinos es una detrás de otra , es decir primero se llama a uno hace lo que tiene dentro una vez terminado ese vecino se pasa al siguiente)
          ask neighbors4[
            if ((tiene-dado?) and (sum[valor] of turtles-here) < 6)[ ; miro si el vecino que estoy preguntando tiene dado y si el dado es menor que 6
              ask dados-here[ ;pregunto al dado que hay en ese vecino
                if( contiene? valor dados-a-eliminar)[ ; Miro si ese vecino tiene uno de lo valores de los dados que se han seleccionado para sumar
                  set dados-a-eliminar (borra-elemento valor dados-a-eliminar) ; De la lista "dados-a-eliminar" quito un elemento ya que dicho elemento es el valor que se ha seleccionado para la suma( se quita para que no elimine por ejemplo dos 1 cuando se ha seleccionado solo uno)
                  ask patch-here[ ;cambio tambien los valores del pacth donde esta el dado
                    set jugador 0
                    set tiene-dado? false
                  ]
                  die ;elimino el dado
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end


;================================== Funciones para el caso de tener que elegir dados ( más de dos vecinos potenciales) ==============================================

; Estas funciones se usan cuando hay más de dos vecinos por lo tanto el jugador tiene que elegir cuales de esos dados vecinos potenciales ( menores que 6) quiere elegir para sumarlos
; una vez el jugador haya seleccionado que dados elegir (función sumaselegidos) debe pulsar el botón en la interfaz "sumar-elegidos" para sumar los dados seleccionados.


; Cuando se entra en el estado "elegir = true" esta será la función que ira corriendo continuamente.
;Esta función lo de que se encarga es de que eligas los dados vecinos potenciales (menores que 6) que quieres sumar, para ello lo que hacemos es cambiar el color de los dados seleccionados asi aprovechamos que visualmente se sabe
;que dados hemos seleccionados y además cuando el programa vaya a sumar los dados aprovecho y le digo que sume los dados con dicho color que representa que están seleccionados.
;(Cambiar el color tienes dos funciones tanto visual para el humano y como estado para netlogo para saber que dados sumar)
to sumaselegidos
  if ((mouse-down?) and (true = ([tiene-dado?] of patch  mouse-xcor mouse-ycor)) and (sum[[valor] of turtles-here] of patch  mouse-xcor  mouse-ycor) < 6
    and [distance (patch mouse-xcor mouse-ycor)] of tortuga-a-sumar  = 1 )[
    ask patch round mouse-xcor round mouse-ycor[
      ask dados-here [
        ifelse color = 96 [set color 93]
        [ifelse color = 93 [set color 96]
          [ifelse color = 15 [set color 12]
            [if color = 12 [set color 15]
            ]
          ]
        ]
      ]
    ]
  ]
end

;Sumar-elegidos es un botón
;Está función se encarga primero de comprobar que los dados seleccionados su suma sea menor que 6 y que se hayan seleccionado tambien almenos dos dados
;luego sumará dichos dados y eliminara los vecinos seleccinados cambiando tambien el estado de los patches
;elegir pasará a false y seguira corriendo normal
to sumar-elegidos
  if ( (sum [valor] of dados with [color = 93 or color = 12] <= 6) and (sum [valor] of dados with [color = 93 or color = 12] > 0) and (count dados with [color = 93 or color = 12] >= 2) )[
    ask tortuga-a-sumar [set valor (sum [valor] of dados with [color = 93 or color = 12]) ]
    ask patches with [any? turtles-here with [color = 93 or color = 12]][set tiene-dado? false set jugador 0]
    ask dados with [color = 93 or color = 12] [die]
    set elegir false
    convierteDados
  ]
end

;=====================================================Funciones Auxiliares=====================================================================

;ponemos a cada dado su figura correspondiente a su valor
to convierteDados
  ask dados [
    ifelse valor = 2 [ set shape "die 2"]
    [ifelse valor = 3 [ set shape "die 3"]
      [ifelse valor = 4 [ set shape "die 4"]
        [ifelse valor = 5 [ set shape "die 5"]
        [if valor = 6[ set shape "die 6"]]
        ]
      ]
    ]
  ]
end

;Función que suma todos los elemento de una lista
to-report suma [L]
  if empty? L[report 0]
  report (first L) + suma (bf L)
end

;Función que crea todas las combinaciones posibles con los elementos de una lista
;ejemplo crea-combinaciones-vecinos [1 2] --> [[] [2] [1] [2 1]]
to-report crea-combinaciones-vecinos [ L ]
  if empty? L [report [[]]]
  let x first L
  let L' bf L
  let PL' crea-combinaciones-vecinos L'
  report sentence PL'(map [B -> lput x B] PL')
end

;Función que escribe en Lres la suma de cada elemento de L(cada elemento de L sera las combinaciones vistas en la función de arriba)
to-report lista-con-posibles-sumas [L Lres]
  if empty? L[ report Lres ]
  Let x suma(first L)
  let yLres lput x Lres
  report lista-con-posibles-sumas (bf L) yLres
end

;Función que devuelve false si en la lista hay algún elemento menor o igual a 6 ( que en nuestro tipo de juego 6 es la suma mas alta posible, es decir si todas las sumas son mayores de 6 quiere decir que no se pueden sumar esos dados)
to-report se-puede-sumar [L]
  if empty? L [ report true ]
  let x first L
  let L' bf L
  if x <= 6 [report false]
  report se-puede-sumar L'
end

;Función que devuelve true si el elemento "el" esta en la lista "L"
to-report contiene? [el L]
  if empty? L [report false]
  let x first L
  let L' bf L
  if el = x [report true]
  report contiene? el L'
end

;esta función se usa siempre existiendo el elemento en la lista (con la funcion de arriba)
;y sirve para borrar un elemento pero no sus duplicados
to-report borra-elemento [el L]
  let x first L
  let L' bf L
  if el = x [report L']
  set L' lput x L'
  report borra-elemento el L'
end

;Función que construye el estado dependiendo del tablero actual
;Forma del estado ejemplo --> [ [0,[]] [1,[1]] [2,[4]] ....]
to-report board-to-state
  let b map [x -> (list([jugador] of x)(
    [[valor] of turtles-here] of x)
    )
  ] (sort patches)
  report b
end

;Devuelve los vecinos respecto a la lista de estados de la posicion x
to-report vecinos [x]
  ifelse x = 0 [report [1 5]]
  [ifelse (x >= 1 and x <= 3)[report (list(x - 1) (x + 5 ) (x + 1))]
    [ifelse x = 4 [report [3 9]]
      [ifelse (x mod 5 = 0 and x != 20)[report (list(x + 1) (x - 5) (x + 5))]
        [ifelse (x = 9 or x = 14 or x = 19)[report (list(x - 1) (x - 5) (x + 5))]
          [ifelse x = 20[report [15 21]]
            [ifelse (x >= 21 and x <= 23)[report (list(x - 1) (x - 5) (x + 1))]
              [ifelse x = 24 [report [19 23]]
                [report (list(x - 5) (x - 1) (x + 1) (x + 5))
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end

;función que devuelve los huecos libres del tablero, se explica en donde se usa por que se usa para solucionar un error
to-report solucionar-error
  let c board-to-state
  report filter [x -> (item 0(item x c))  = 0] (range 25)
end

@#$#@#$#@
GRAPHICS-WINDOW
28
32
736
741
-1
-1
140.0
1
10
1
1
1
0
0
0
1
0
4
0
4
1
1
1
ticks
30.0

BUTTON
760
35
871
86
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
760
99
881
163
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
745
673
878
741
NIL
sumar-elegidos
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
760
303
945
336
Max_iterations
Max_iterations
0
10000
100.0
100
1
NIL
HORIZONTAL

SWITCH
761
258
905
291
vs_IA
vs_IA
1
1
-1000

OUTPUT
759
184
1246
216
18

TEXTBOX
978
247
1128
327
Si desea cambiar entre modo IA (on) o modo jugador vs jugador (off) , cambie el switch y luego pulse el botón setup
13
0.0
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

die 1
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 129 129 42

die 2
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 189 189 42

die 3
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 189 189 42

die 4
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 5
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 6
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 84 69 42
Circle -16777216 true false 84 129 42
Circle -16777216 true false 84 189 42
Circle -16777216 true false 174 69 42
Circle -16777216 true false 174 129 42
Circle -16777216 true false 174 189 42

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
