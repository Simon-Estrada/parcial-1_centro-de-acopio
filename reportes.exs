# Integrantes: Simon Lopez Estrada, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo

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
  def generar_reportes(validas, rechazadas, _productores, tanques, liquidaciones) do
    rechazadas |> r1() |> imprimir_r1()
    validas |> r2(tanques) |> imprimir_r2()
    validas |> r3() |> imprimir_r3()
    liquidaciones |> r4() |> imprimir_r4()
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

  # ------------------------------------------------------- Auxiliares

  # Redondea a dos decimales; * 1.0 evita error si el valor es entero.
  defp redondear(valor), do: Float.round(valor * 1.0, 2)

  defp si_no(true), do: "sí"
  defp si_no(false), do: "no"
end
