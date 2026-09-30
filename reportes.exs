# Integrantes: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo

defmodule Reportes do
  @moduledoc """
  Reportes semanales R1 a R8 del centro de acopio de leche.

  ## Información del Proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: septiembre del 2026
  - licencia: GNU GPL v3

  Este módulo recibe datos que **ya fueron validados y liquidados** por
  `CentroAcopio` y los transforma en reportes. No valida ni liquida.

  ## Formato de los datos de entrada

  * `validas`: lista de mapas `%{productor:, tanque:, dia:, litros:, grasa:}`.
  * `rechazadas`: lista de tuplas `{motivo, entrega}`, tal como la devuelve
    `CentroAcopio.procesar_entregas/3`.
  * `productores` y `tanques`: las listas originales de `Datos`.
  * `liquidaciones`: lista de mapas devueltos por
    `CentroAcopio.liquidar_productor/2`.

  ## Organización

  Cada reporte tiene dos funciones:

  * una **función pura** (`r1/1`, `r2/2`, ..., `r8/3`) que recibe datos y
    devuelve datos, sin imprimir nada;
  * una **función impura** (`imprimir_r1/1`, ..., `imprimir_r8/1`) que solo
    escribe en pantalla.

  `generar_reportes/5` ejecuta los ocho reportes en el orden exigido.

  Toda iteración se hace con `Enum` o comprehensions `for`; no se usa
  recursividad manual, `defstruct` ni procesos.
  """

  @meta_diaria_centro 2000
  @dias_recepcion 1..6
  @minimo_entregas_calidad 3
  @motivos_rechazo [
    :productor_desconocido,
    :tanque_desconocido,
    :dia_invalido,
    :litros_fuera_de_rango,
    :porcentaje_invalido
  ]

  @doc """
  Genera e imprime los reportes R1 a R8, en ese orden.

  Es una función impura porque escribe en pantalla.

  ## Parámetros

    - `validas`: entregas válidas.
    - `rechazadas`: entregas rechazadas como `{motivo, entrega}`.
    - `productores`: lista de productores.
    - `tanques`: lista de tanques.
    - `liquidaciones`: una liquidación por cada productor.
  """
  def generar_reportes(validas, rechazadas, productores, tanques, liquidaciones) do
    rechazadas |> r1() |> imprimir_r1()
    validas |> r2(tanques) |> imprimir_r2()
    validas |> r3() |> imprimir_r3()
    liquidaciones |> r4() |> imprimir_r4()
    validas |> r5(productores) |> imprimir_r5()
    validas |> r6(productores) |> imprimir_r6()
    liquidaciones |> r7() |> imprimir_r7()
    validas |> r8(productores, tanques) |> imprimir_r8()
  end

  # ------------------------------------------------------------------ R1

  @doc """
  R1. Agrupa las entregas rechazadas y cuenta los rechazos por motivo.

  El conteo incluye los cinco motivos posibles, con 0 cuando no hubo
  rechazos de ese tipo. Las rechazadas se devuelven en el orden recibido.

  ## Parámetros

    - `rechazadas`: lista de tuplas `{motivo, entrega}`.

  ## Retorno

  Mapa con `:rechazadas` (la lista recibida) y `:conteo`
  (mapa `motivo => cantidad`).

  ## Ejemplos

      iex> rechazadas = [
      ...>   {:dia_invalido, %{productor: "P03", dia: 0}},
      ...>   {:dia_invalido, %{productor: "P04", dia: 7}}
      ...> ]
      iex> resultado = Reportes.r1(rechazadas)
      iex> resultado.conteo.dia_invalido
      2
      iex> resultado.conteo.tanque_desconocido
      0

  """
  def r1(rechazadas) do
    conteo = Enum.frequencies_by(rechazadas, fn {motivo, _entrega} -> motivo end)

    conteo_completo =
      for motivo <- @motivos_rechazo, into: %{}, do: {motivo, Map.get(conteo, motivo, 0)}

    %{rechazadas: rechazadas, conteo: conteo_completo}
  end

  @doc """
  Imprime el reporte R1 a partir del resultado de `r1/1`.
  """
  def imprimir_r1(%{rechazadas: rechazadas, conteo: conteo}) do
    Util.mostrar_mensaje("\n=== R1: ENTREGAS RECHAZADAS ===")

    Enum.each(rechazadas, fn {motivo, e} ->
      # inspect/1 porque en una entrega inválida el dato puede no ser numérico
      Util.mostrar_mensaje(
        "  #{e.productor} | tanque #{e.tanque} | día #{inspect(e.dia)} | " <>
          "litros #{inspect(e.litros)} | grasa #{inspect(e.grasa)} -> #{motivo}"
      )
    end)

    Util.mostrar_mensaje("\nRechazos por motivo:")

    Enum.each(@motivos_rechazo, fn motivo ->
      Util.mostrar_mensaje("  #{motivo}: #{conteo[motivo]}")
    end)
  end

  # ------------------------------------------------------------------ R2

  @doc """
  R2. Calcula los litros almacenados por tanque y su porcentaje de ocupación.

  Recorre la lista de **tanques** (no la de entregas) para que un tanque sin
  entregas válidas aparezca con 0 litros. El resultado queda ordenado de
  mayor a menor ocupación.

  ## Parámetros

    - `validas`: entregas válidas (usa `:tanque` y `:litros`).
    - `tanques`: lista de tanques (usa `:id`, `:nombre` y `:capacidad`).

  ## Ejemplos

      iex> validas = [%{tanque: "T1", litros: 500}]
      iex> tanques = [%{id: "T2", nombre: "Centro", capacidad: 4000},
      ...>            %{id: "T1", nombre: "Norte", capacidad: 5000}]
      iex> filas = Reportes.r2(validas, tanques)
      iex> Enum.map(filas, fn f -> {f.id, f.litros, f.ocupacion} end)
      [{"T1", 500, 10.0}, {"T2", 0, 0.0}]

  """
  def r2(validas, tanques) do
    litros_por_tanque =
      Enum.reduce(validas, %{}, fn e, acc ->
        Map.update(acc, e.tanque, e.litros, fn actual -> actual + e.litros end)
      end)

    filas =
      for t <- tanques do
        litros = Map.get(litros_por_tanque, t.id, 0)
        %{id: t.id, nombre: t.nombre, litros: litros, ocupacion: litros / t.capacidad * 100}
      end

    Enum.sort_by(filas, fn f -> f.ocupacion end, :desc)
  end

  @doc """
  Imprime el reporte R2 a partir del resultado de `r2/2`.
  """
  def imprimir_r2(filas) do
    Util.mostrar_mensaje("\n=== R2: OCUPACIÓN DE TANQUES ===")

    Enum.each(filas, fn f ->
      Util.mostrar_mensaje(
        "  #{f.nombre} (#{f.id}): #{f.litros} L | #{redondear(f.ocupacion)} % de ocupación"
      )
    end)
  end

  # ------------------------------------------------------------------ R3

  @doc """
  R3. Calcula los litros recibidos por día y si se alcanzó la meta diaria.

  Incluye siempre los 6 días de recepción, con 0 litros si no hubo entregas.

  ## Parámetros

    - `validas`: entregas válidas (usa `:dia` y `:litros`).

  ## Retorno

  Mapa con:

    * `:litros`: mapa `dia => litros`. Es el mapa que se usa en la
      investigación de `Map.merge/3`, por eso conserva la forma
      `%{1 => ..., 2 => ...}`.
    * `:cumple`: mapa `dia => true | false`.
    * `:todos`: `true` si la meta se cumplió todos los días.
    * `:alguno`: `true` si la meta se cumplió al menos un día.

  ## Ejemplos

      iex> resultado = Reportes.r3([%{dia: 1, litros: 2500}, %{dia: 2, litros: 100}])
      iex> resultado.litros[1]
      2500
      iex> resultado.litros[6]
      0
      iex> resultado.cumple[1]
      true
      iex> {resultado.todos, resultado.alguno}
      {false, true}

  """
  def r3(validas) do
    por_dia =
      Enum.reduce(validas, %{}, fn e, acc ->
        Map.update(acc, e.dia, e.litros, fn actual -> actual + e.litros end)
      end)

    litros = for dia <- @dias_recepcion, into: %{}, do: {dia, Map.get(por_dia, dia, 0)}
    cumple = for {dia, l} <- litros, into: %{}, do: {dia, l >= @meta_diaria_centro}
    resultados = Map.values(cumple)

    %{
      litros: litros,
      cumple: cumple,
      todos: Enum.all?(resultados),
      alguno: Enum.any?(resultados)
    }
  end

  @doc """
  Imprime el reporte R3 a partir del resultado de `r3/1`.
  """
  def imprimir_r3(%{litros: litros, cumple: cumple, todos: todos, alguno: alguno}) do
    Util.mostrar_mensaje("\n=== R3: LITROS POR DÍA (meta: #{@meta_diaria_centro} L) ===")

    Enum.each(@dias_recepcion, fn dia ->
      estado = if cumple[dia], do: "cumple la meta", else: "no cumple la meta"
      Util.mostrar_mensaje("  Día #{dia}: #{litros[dia]} L -> #{estado}")
    end)

    Util.mostrar_mensaje("\n  ¿Se cumplió la meta todos los días? #{si_no(todos)}")
    Util.mostrar_mensaje("  ¿Se cumplió la meta al menos un día? #{si_no(alguno)}")
  end

  # ------------------------------------------------------------------ R4

  @doc """
  R4. Ordena la liquidación de todos los productores por pago neto, de mayor
  a menor, y les asigna su posición.

  Los productores sin entregas válidas también aparecen (con neto 0).

  ## Parámetros

    - `liquidaciones`: lista de resultados de `CentroAcopio.liquidar_productor/2`.

  ## Retorno

  Lista de tuplas `{liquidacion, posicion}`, con la posición desde 1.

  ## Ejemplos

      iex> liquidaciones = [
      ...>   %{productor: %{nombre: "Ana"}, neto_a_pagar: 100.0},
      ...>   %{productor: %{nombre: "Beto"}, neto_a_pagar: 300.0}
      ...> ]
      iex> [{primero, 1}, {segundo, 2}] = Reportes.r4(liquidaciones)
      iex> {primero.productor.nombre, segundo.productor.nombre}
      {"Beto", "Ana"}

  """
  def r4(liquidaciones) do
    liquidaciones
    |> Enum.sort_by(fn liq -> liq.neto_a_pagar end, :desc)
    |> Enum.with_index(1)
  end

  @doc """
  Imprime el reporte R4 a partir del resultado de `r4/1`.
  """
  def imprimir_r4(liquidaciones_numeradas) do
    Util.mostrar_mensaje("\n=== R4: LIQUIDACIÓN DE PRODUCTORES (por pago neto) ===")

    Enum.each(liquidaciones_numeradas, fn {liq, posicion} ->
      nombre = String.pad_trailing(liq.productor.nombre, 20)

      Util.mostrar_mensaje(
        "  #{posicion}. #{nombre} | #{liq.total_litros} L" <>
          " | Entregas: $#{Util.formatear_moneda(liq.total_valor_entregas)}" <>
          " | Bonif.: $#{Util.formatear_moneda(liq.total_bonificaciones)}" <>
          " | Transp.: -$#{Util.formatear_moneda(liq.descuento_transporte)}" <>
          " | NETO: $#{Util.formatear_moneda(liq.neto_a_pagar)}"
      )
    end)
  end

  # ------------------------------------------------------------------ R5

  @doc """
  R5. Encuentra el productor con más litros entregados en cada día.

  Si hay empate en un día, aparecen todos los empatados. Un día sin entregas
  queda con lista de líderes vacía. Al final determina quién fue líder en
  más días (con empates, aparecen todos).

  ## Parámetros

    - `validas`: entregas válidas.
    - `productores`: lista de productores (para obtener los nombres).

  ## Retorno

  Mapa con:

    * `:por_dia`: mapa `dia => %{litros: maximo, lideres: [{codigo, nombre}]}`.
    * `:mas_dias`: mapa `%{lideres: [{codigo, nombre}], dias: cantidad}`.

  ## Ejemplos

      iex> productores = [%{codigo: "P01", nombre: "Ana"}, %{codigo: "P02", nombre: "Beto"}]
      iex> validas = [
      ...>   %{productor: "P01", dia: 1, litros: 100},
      ...>   %{productor: "P02", dia: 1, litros: 100},
      ...>   %{productor: "P01", dia: 2, litros: 50}
      ...> ]
      iex> resultado = Reportes.r5(validas, productores)
      iex> resultado.por_dia[1].lideres
      [{"P01", "Ana"}, {"P02", "Beto"}]
      iex> resultado.por_dia[3].lideres
      []
      iex> resultado.mas_dias
      %{lideres: [{"P01", "Ana"}], dias: 2}

  """
  def r5(validas, productores) do
    nombres = Map.new(productores, fn p -> {p.codigo, p.nombre} end)

    por_dia =
      for dia <- @dias_recepcion, into: %{} do
        litros_por_productor =
          validas
          |> Enum.filter(fn e -> e.dia == dia end)
          |> Enum.reduce(%{}, fn e, acc ->
            Map.update(acc, e.productor, e.litros, fn actual -> actual + e.litros end)
          end)

        {dia, lideres_del_dia(litros_por_productor, nombres)}
      end

    %{por_dia: por_dia, mas_dias: lideres_de_la_semana(por_dia)}
  end

  # Líderes de un día: los productores cuyo total iguala el máximo del día.
  defp lideres_del_dia(litros_por_productor, _nombres) when map_size(litros_por_productor) == 0,
    do: %{litros: 0, lideres: []}

  defp lideres_del_dia(litros_por_productor, nombres) do
    maximo = litros_por_productor |> Map.values() |> Enum.max()

    lideres =
      for {codigo, litros} <- litros_por_productor, litros == maximo do
        {codigo, Map.get(nombres, codigo, codigo)}
      end

    %{litros: maximo, lideres: Enum.sort(lideres)}
  end

  # Cuenta en cuántos días fue líder cada productor y toma el máximo.
  # Un empate en un día suma un día a cada uno de los empatados.
  defp lideres_de_la_semana(por_dia) do
    dias_como_lider =
      por_dia
      |> Map.values()
      |> Enum.flat_map(fn dia -> dia.lideres end)
      |> Enum.frequencies()

    if map_size(dias_como_lider) == 0 do
      %{lideres: [], dias: 0}
    else
      maximo = dias_como_lider |> Map.values() |> Enum.max()
      lideres = for {lider, dias} <- dias_como_lider, dias == maximo, do: lider
      %{lideres: Enum.sort(lideres), dias: maximo}
    end
  end

  @doc """
  Imprime el reporte R5 a partir del resultado de `r5/2`.
  """
  def imprimir_r5(%{por_dia: por_dia, mas_dias: mas_dias}) do
    Util.mostrar_mensaje("\n=== R5: LÍDER DE LITROS POR DÍA ===")

    Enum.each(@dias_recepcion, fn dia ->
      %{litros: litros, lideres: lideres} = por_dia[dia]

      if lideres == [] do
        Util.mostrar_mensaje("  Día #{dia}: sin entregas válidas")
      else
        Util.mostrar_mensaje("  Día #{dia}: #{texto_lideres(lideres)} con #{litros} L")
      end
    end)

    if mas_dias.lideres == [] do
      Util.mostrar_mensaje("\n  Ningún productor lideró un día.")
    else
      Util.mostrar_mensaje(
        "\n  Primer lugar en más días: #{texto_lideres(mas_dias.lideres)} (#{mas_dias.dias} días)"
      )
    end
  end

  # ------------------------------------------------------------------ R6

  @doc """
  R6. Encuentra el productor con mejor calidad entre quienes tengan al menos
  #{@minimo_entregas_calidad} entregas válidas.

  La calidad es el porcentaje de grasa **ponderado por litros**:

      suma(grasa * litros) / suma(litros)

  También se calcula el promedio simple de los porcentajes, para poder
  compararlos en la explicación del informe.

  ## Parámetros

    - `validas`: entregas válidas.
    - `productores`: lista de productores (para obtener los nombres).

  ## Retorno

  Mapa con `:ganador` (el mejor candidato, o `nil` si nadie califica) y
  `:candidatos` (todos los que califican, de mejor a peor). Cada candidato
  es un mapa con `:codigo`, `:nombre`, `:entregas`, `:litros`,
  `:grasa_ponderada` y `:grasa_simple`.

  ## Ejemplos

      iex> productores = [%{codigo: "P01", nombre: "Ana"}]
      iex> validas = [
      ...>   %{productor: "P01", litros: 10, grasa: 4.0},
      ...>   %{productor: "P01", litros: 500, grasa: 3.0},
      ...>   %{productor: "P01", litros: 10, grasa: 3.0}
      ...> ]
      iex> ganador = Reportes.r6(validas, productores).ganador
      iex> {Float.round(ganador.grasa_ponderada, 2), Float.round(ganador.grasa_simple, 2)}
      {3.02, 3.33}
      iex> Reportes.r6(Enum.take(validas, 2), productores).ganador
      nil

  """
  def r6(validas, productores) do
    nombres = Map.new(productores, fn p -> {p.codigo, p.nombre} end)

    candidatos =
      validas
      |> Enum.group_by(fn e -> e.productor end)
      |> Enum.filter(fn {_codigo, entregas} -> length(entregas) >= @minimo_entregas_calidad end)
      |> Enum.map(fn {codigo, entregas} -> calidad_productor(codigo, nombres, entregas) end)
      |> Enum.sort_by(fn c -> c.grasa_ponderada end, :desc)

    %{ganador: List.first(candidatos), candidatos: candidatos}
  end

  # Calcula la grasa ponderada y la grasa simple de un productor.
  defp calidad_productor(codigo, nombres, entregas) do
    litros = entregas |> Enum.map(fn e -> e.litros end) |> Enum.sum()
    grasa_por_litros = entregas |> Enum.map(fn e -> e.grasa * e.litros end) |> Enum.sum()
    suma_grasas = entregas |> Enum.map(fn e -> e.grasa end) |> Enum.sum()

    %{
      codigo: codigo,
      nombre: Map.get(nombres, codigo, codigo),
      entregas: length(entregas),
      litros: litros,
      grasa_ponderada: grasa_por_litros / litros,
      grasa_simple: suma_grasas / length(entregas)
    }
  end

  @doc """
  Imprime el reporte R6 a partir del resultado de `r6/2`.
  """
  def imprimir_r6(%{ganador: nil}) do
    Util.mostrar_mensaje("\n=== R6: MEJOR CALIDAD DE LECHE ===")

    Util.mostrar_mensaje(
      "  Ningún productor tiene al menos #{@minimo_entregas_calidad} entregas válidas."
    )
  end

  def imprimir_r6(%{ganador: g}) do
    Util.mostrar_mensaje("\n=== R6: MEJOR CALIDAD DE LECHE ===")

    Util.mostrar_mensaje(
      "  #{g.nombre} (#{g.codigo}): #{redondear(g.grasa_ponderada)} % de grasa ponderada " <>
        "(#{g.entregas} entregas, #{g.litros} L)"
    )
  end

  # ------------------------------------------------------------------ R7

  @doc """
  R7. Calcula el total pagado por el centro en la semana y el costo promedio
  pagado por litro.

  El total pagado es la suma del **neto a pagar** de todos los productores.
  El costo por litro es ese total dividido entre los litros válidos recibidos
  (0.0 si no hubo litros).

  ## Parámetros

    - `liquidaciones`: lista de resultados de `CentroAcopio.liquidar_productor/2`.

  ## Ejemplos

      iex> liquidaciones = [
      ...>   %{neto_a_pagar: 1000.0, total_litros: 10},
      ...>   %{neto_a_pagar: 3000.0, total_litros: 30}
      ...> ]
      iex> Reportes.r7(liquidaciones)
      %{total_pagado: 4000.0, total_litros: 40, costo_por_litro: 100.0}

  """
  def r7(liquidaciones) do
    total_pagado = liquidaciones |> Enum.map(fn liq -> liq.neto_a_pagar end) |> Enum.sum()
    total_litros = liquidaciones |> Enum.map(fn liq -> liq.total_litros end) |> Enum.sum()
    costo_por_litro = if total_litros > 0, do: total_pagado / total_litros, else: 0.0

    %{total_pagado: total_pagado, total_litros: total_litros, costo_por_litro: costo_por_litro}
  end

  @doc """
  Imprime el reporte R7 a partir del resultado de `r7/1`.
  """
  def imprimir_r7(%{total_pagado: total, total_litros: litros, costo_por_litro: costo}) do
    Util.mostrar_mensaje("\n=== R7: TOTALES DE LA SEMANA ===")
    Util.mostrar_mensaje("  Total pagado por el centro: $#{Util.formatear_moneda(total)}")
    Util.mostrar_mensaje("  Litros válidos recibidos  : #{litros} L")
    Util.mostrar_mensaje("  Costo promedio por litro  : $#{Util.formatear_moneda(costo * 1.0)}")
  end

  # ------------------------------------------------------------------ R8

  @doc """
  R8. Encuentra los productores que hicieron al menos una entrega válida en
  **todos** los tanques.

  ## Parámetros

    - `validas`: entregas válidas.
    - `productores`: lista de productores.
    - `tanques`: lista de tanques.

  ## Ejemplos

      iex> productores = [%{codigo: "P01", nombre: "Ana"}, %{codigo: "P02", nombre: "Beto"}]
      iex> tanques = [%{id: "T1"}, %{id: "T2"}]
      iex> validas = [
      ...>   %{productor: "P01", tanque: "T1"},
      ...>   %{productor: "P01", tanque: "T2"},
      ...>   %{productor: "P02", tanque: "T1"}
      ...> ]
      iex> Enum.map(Reportes.r8(validas, productores, tanques), fn p -> p.codigo end)
      ["P01"]

  """
  def r8(validas, productores, tanques) do
    Enum.filter(productores, fn p ->
      Enum.all?(tanques, fn t ->
        Enum.any?(validas, fn e -> e.productor == p.codigo and e.tanque == t.id end)
      end)
    end)
  end

  @doc """
  Imprime el reporte R8 a partir del resultado de `r8/3`.
  """
  def imprimir_r8(productores) do
    Util.mostrar_mensaje("\n=== R8: PRODUCTORES PRESENTES EN TODOS LOS TANQUES ===")

    if productores == [] do
      Util.mostrar_mensaje("  Ningún productor entregó en todos los tanques.")
    else
      Enum.each(productores, fn p ->
        Util.mostrar_mensaje("  #{p.nombre} (#{p.codigo})")
      end)
    end
  end

  # ------------------------------------------------------- Auxiliares

  # Redondea a dos decimales; * 1.0 evita error si el valor es entero.
  defp redondear(valor), do: Float.round(valor * 1.0, 2)

  defp si_no(true), do: "sí"
  defp si_no(false), do: "no"

  # Convierte [{"P01", "Ana"}, {"P02", "Beto"}] en "Ana (P01), Beto (P02)".
  defp texto_lideres(lideres) do
    lideres
    |> Enum.map(fn {codigo, nombre} -> "#{nombre} (#{codigo})" end)
    |> Enum.join(", ")
  end
end
