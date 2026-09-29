Code.require_file("datos.exs")

defmodule CentroAcopio do
  @moduledoc """
  Módulo principal que representa el centro de acopio de leche.
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

    {entregas_validas, entregas_rechazadas} =
      procesar_entregas(entregas_raw, productores, tanques)

    # solicitar entrega adicional (faltante)
    # imprimir reportes R1 al R8 (faltante)

    solicitar_comprobante(productores, entregas_validas)
  end

  def procesar_entregas(entregas, productores, tanques) do
    Enum.reduce(entregas, {[], []}, fn entrega, {validas, rechazadas} ->
      case validar_entrega(entrega, productores, tanques) do
        {:ok, entrega_valida} -> {[entrega_valida | validas], rechazadas}
        {:error, motivo} -> {validas, [{motivo, entrega} | rechazadas]}
      end
    end)
  end

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

  def liquidar_productor(productor, entregas_validas) do
    resumen_dias =
      entregas_validas
      |> entregas_del_productor(productor)
      |> resumir_por_dia

    totales = calcular_totales(resumen_dias)

    descuento_transporte =
      calcular_descuento_transporte(
        productor,
        length(resumen_dias)
      )

    %{
      productor: productor,
      desglose_dias: desglose_dias,
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
    acumulador_inicial = %{litros: 0, valor: 0}

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

  defp calcular_bonificacio(litros) when litros >= @litros_bonificacion, do: @bonificacion_diaria
  defp calcular_bonificacion(_litros), do: 0

  defp calcular_totales(resumen_dias) do
    acumulador_inicial = %{litro: 0, valor_entregas: 0, bonificaciones: 0}

    Enum.reduce(resumen_dias, acumulador_inicial, fn dia, acc ->
      %{
        litros: acc.litros + dia.litros,
        valor_entregas: acc.valor_entregas + dia.valor_entregas,
        bonificaciones: acc.bonificaciones + dia.bonificacion
      }
    end)
  end

  defp calcular_descuento_transporte(%{transporte: true}, dias) when dias > 0, do:
  dias * @costo_transporte
  defp calcular_descuento_transporte(_producto, _dias), do: 0

  def solicitar_comprobante(productores, entregas) do
    IO.puts("\n--- COMPROBANTE DEL PRODUCTOR ---")
    codigo = IO.gets("Ingrese el codigo del productor: ") |> String.trim()

    case Enum.find(productores, fn p -> p.codigo == codigo end) do
      nil ->
        IO.puts("Error: Productor con codigo #{codigo} no existe.")

      productor ->
        mostrar_comprobante(productor, entregas)
    end
  end

  defp mostrar_comprobante(productor, entregas) do
    IO.puts("\n--- COMPROBANTE DEL PRODUCTOR #{productor.nombre} (#{productor.codigo}) ---")
  end
end

CentroAcopio.main()
