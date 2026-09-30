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
  def generar_reportes(validas, rechazadas, _productores, tanques, _liquidaciones) do
    rechazadas |> r1() |> imprimir_r1()
    validas |> r2(tanques) |> imprimir_r2()
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

  # ------------------------------------------------------- Auxiliares

  # Redondea a dos decimales; * 1.0 evita error si el valor es entero.
  defp redondear(valor), do: Float.round(valor * 1.0, 2)
end
