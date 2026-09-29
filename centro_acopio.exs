Code.require_file("datos.exs")

defmodule CentroAcopio do
  @moduledoc """
  ## Información del Proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: septiembre del 2026
  - licencia: GNU GPL v3
  Centro de acopio de leche: valida las entregas semanales de los productores,
  calcula la liquidación de cada uno y muestra su comprobante.

  ## Organización

  * Funciones puras (sin E/S): `procesar_entregas/3`, `validar_entrega/3`,
    `calcular_valor_entrega/1` y `liquidar_productor/2`.
  * Funciones impuras (leen o escriben en consola): `main/0`,
    `solicitar_comprobante/2` y `mostrar_comprobante/2`.

  Toda iteración se hace con `Enum` o comprehensions `for`; no se usa
  recursividad manual, `defstruct` ni procesos.


  """
  @tarifa_base 1800
  @meta_diaria_centro 2000
  @dias_recepcion 1..6
  @max_litros_entrega 800
  @litros_bonificacion 450
  @bonificacion_diaria 25000
  @costo_transporte 18000

  def main do
    productores = Datos.productores()
    tanques = Datos.tanques()
    entregas_raw = Datos.entregas()

    {entregas_validas, entregas_rechazadas} =procesar_entregas(entregas_raw, productores, tanques)

    # solicitar entrega adicional (faltante)
    # imprimir reportes R1 al R8 (faltante)

    solicitar_comprobante(productores, entregas_validas)
  end

  @doc """
  Procesa la lista de entregas, validando cada una y separándolas en válidas y rechazadas.
  Retorna una tupla con dos listas: {entregas_validas, entregas_rechazadas}. Uno de los requisitos del parcial
  """
  def procesar_entregas(entregas, productores, tanques) do
    Enum.reduce(entregas, {[], []}, fn entrega, {validas, rechazadas} ->
      case validar_entrega(entrega, productores, tanques) do
        {:ok, entrega_valida} -> {[entrega_valida | validas], rechazadas}
        {:error, motivo} -> {validas, [{motivo, entrega} | rechazadas]}
      end
    end)
  end

  @doc """
  Valida una entrega según las reglas de negocio y retorna un resultado.
  Retorna `{:ok, entrega}` si es válida, o `{:error, motivo}` si es inválida.
  """
  def validar_entrega(entrega, productores, tanques) do
    with :ok <- validar_productor(entrega.productor, productores),
         :ok <- validar_tanque(entrega.tanque, tanques),
         :ok <- validar_dia(entrega.dia),
         :ok <- validar_litros(entrega.litros),
         :ok <- validar_grasa(entrega.grasa) do
      {:ok, entrega}
    else
      {:error, motivo} -> {:error, motivo}
    end
  end

  defp validar_productor(codigo, productores) do
    if Enum.any?(productores, fn p -> p.codigo == codigo end),
      do: :ok,
      else: {:error, :productor_desconocido}
  end

  defp validar_tanque(id, tanques) do
    if Enum.any?(tanques, fn t -> t.id == id end), do: :ok, else: {:error, :tanque_desconocido}
  end

  defp validar_dia(dia) when is_integer(dia) and dia in @dias_recepcion, do: :ok
  defp validar_dia(_), do: {:error, :dia_invalido}

  defp validar_litros(litros)
       when is_number(litros) and litros > 0 and litros <= @max_litros_entrega, do: :ok

  defp validar_litros(_), do: {:error, :litros_fuera_de_rango}

  defp validar_grasa(grasa) when is_number(grasa) and grasa >= 0 and grasa <= 15, do: :ok
  defp validar_grasa(_), do: {:error, :porcentaje_invalido}

  @doc """
  Calcula el valor de una entrega: `litros * tarifa_base`, ajustado según la grasa.

  Ajuste por porcentaje de grasa:

  * grasa >= 3.5 → +6 %
  * grasa >= 3.0 → sin ajuste
  * grasa >= 2.5 → -8 %
  * grasa menor → -20 %
  """
  def calcular_valor_entrega(entrega) do
    valor_base = entrega.litros * @tarifa_base

    ajuste_segun_grasa =
      cond do
        entrega.grasa >= 3.5 -> 0.06
        entrega.grasa >= 3.0 -> 0.0
        entrega.grasa >= 2.5 -> -0.08
        true -> -0.20
      end

    valor_base * (1 + ajuste_segun_grasa)
  end

   @doc """
  Calcula la liquidación semanal de un productor a partir de las entregas válidas.

  Devuelve un mapa con el resumen por día, los totales de litros, valor y
  bonificaciones, el descuento de transporte y el neto a pagar
  (`valor entregas + bonificaciones - descuento de transporte`).
  """
  def liquidar_productor(productor, entregas_validas) do
    resumen_dias =
      entregas_validas
      |> entregas_del_productor(productor)
      |> resumir_por_dia()

    totales = calcular_totales(resumen_dias)

    descuento_transporte =
      calcular_descuento_transporte(
        productor,
        length(resumen_dias)
      )

    %{
      productor: productor,
      resumen_dias: resumen_dias,
      total_litros: totales.litros,
      total_valor_entregas: totales.valor_entregas,
      total_bonificaciones: totales.bonificaciones,
      descuento_transporte: descuento_transporte,
      neto_a_pagar: totales.valor_entregas + totales.bonificaciones - descuento_transporte
    }
  end

  defp entregas_del_productor(entregas, productor) do
    Enum.filter(entregas, fn e -> e.productor == productor.codigo end)
  end

  defp resumir_por_dia(entregas) do
    entregas_por_dia = Enum.group_by(entregas, fn e -> e.dia end)

    for dia <- @dias_recepcion, Map.has_key?(entregas_por_dia, dia) do
      resumen_dia(dia, Map.fetch!(entregas_por_dia, dia))
    end
  end

  defp resumen_dia(dia, entregas) do
    acumulador_inicial = %{litros: 0, valor: 0.0}

    totales_dia =
      Enum.reduce(entregas, acumulador_inicial, fn entrega, acc ->
        %{
          litros: acc.litros + entrega.litros,
          valor: acc.valor + calcular_valor_entrega(entrega)
        }
      end)

    %{
      dia: dia,
      litros: totales_dia.litros,
      valor_entregas: totales_dia.valor,
      bonificacion: calcular_bonificacion(totales_dia.litros)
    }
  end

  defp calcular_bonificacion(litros) when litros >= @litros_bonificacion, do: @bonificacion_diaria
  defp calcular_bonificacion(_litros), do: 0

  defp calcular_totales(resumen_dias) do
    acumulador_inicial = %{litros: 0, valor_entregas: 0.0, bonificaciones: 0}

    Enum.reduce(resumen_dias, acumulador_inicial, fn dia, acc ->
      %{
        litros: acc.litros + dia.litros,
        valor_entregas: acc.valor_entregas + dia.valor_entregas,
        bonificaciones: acc.bonificaciones + dia.bonificacion
      }
    end)
  end

  defp calcular_descuento_transporte(%{transporte: true}, dias) when dias > 0,
    do: dias * @costo_transporte

  defp calcular_descuento_transporte(_productor, _dias), do: 0

  @doc """
  Pide por consola el código de un productor y muestra su comprobante.

  Si el código no existe, muestra un mensaje de error.
  Es una función impura porque lee de teclado y escribe en pantalla.
  """
  def solicitar_comprobante(productores, entregas) do
    "\n=====================================
        COMPROBANTE DEL PRODUCTOR
====================================="
    |> Util.mostrar_mensaje()

    codigo = Util.ingresar("Ingrese el codigo del productor: ")

    case Enum.find(productores, fn p -> p.codigo == codigo end) do
      nil ->
        "\nError: El productor con codigo '#{codigo}' no existe en el sistema."
        |> Util.mostrar_mensaje()

      productor ->
        mostrar_comprobante(productor, entregas)
    end
  end

  defp mostrar_comprobante(productor, entregas_validas) do
    liq = liquidar_productor(productor, entregas_validas)

    "\n--------------------------------
    NOMBRE: #{productor.nombre}
    CODIGO: #{productor.codigo}
    SERVICIO TRANSPORTE: #{if productor.transporte, do: "si", else: "no"}
--------------------------------"
    |> Util.mostrar_mensaje()

    "\n--------------------------------
    DETALLE DIARIO DE ENTREGAS VALIDAS:"
    |> Util.mostrar_mensaje()

    if Enum.empty?(liq.resumen_dias) do
      "  (El productor no registró entregas válidas en la semana)"
      |> Util.mostrar_mensaje()
    else
      Enum.each(liq.resumen_dias, fn d ->
        "* Día #{d.dia}: #{d.litros} L | Valor entregas: $#{Util.formatear_moneda(d.valor_entregas)} | Bonificación: $#{d.bonificacion}"
        |> Util.mostrar_mensaje()
      end)
    end

    "\n--------------------------------
    RESUMEN DE LIQUIDACION:
     - Total litros entregados: #{liq.total_litros} L
     - Total valor de entregas : $#{Util.formatear_moneda(liq.total_valor_entregas)}
     - Total bonificaciones    : $#{liq.total_bonificaciones}
     - Descuento por transporte: -$#{liq.descuento_transporte}
--------------------------------
    NETO A PAGAR            : $#{Util.formatear_moneda(liq.neto_a_pagar)}
    ==========================================\n"
    |> Util.mostrar_mensaje()
  end
end

CentroAcopio.main()
