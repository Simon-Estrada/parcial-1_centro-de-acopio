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
    productores= Datos.productores()
    tanques= Datos.tanques()
    entregas_raw= Datos.entregas()

    {entregas_validas, entregas_rechazadas} = procesar_entregas(entregas_raw, productores, tanques)
    #solicitar entrega adicional (faltante)
    #imprimir reportes R1 al R8 (faltante)

    solicitar_comprobante(productores, entregas_validas)
  end

  def procesar_entregas(entregas, productores, tanques) do
    Enum.reduce(entregas, {[], []}, fn entrega,{validas, rechazadas} ->
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
    if Enum.any?(productores, fn p -> p.codigo == codigo end), do: :ok, else: {:error, :productor_desconocido}
  end

  defp validar_tanque(id, tanques) do
    if Enum.any?(tanques, fn t -> t.id == id end), do: :ok, else: {:error, :tanque_desconocido}
  end

  defp validar_dia(dia) when is_integer(dia) and dia in @dias_recepcion, do: :ok
  defp validar_dia(_), do: {:error, :dia_invalido}

  defp validar_litros(litros) when is_number(litros) and litros >0 and litros <= @max_litros_entrega, do: :ok
  defp validar_litros(_), do: {:error, :litro_fuera_de_rango}

  defp validar_grasa(grasa) when is_number(grasa) and grasa >= 0 and grasa <= 100, do: :ok
  defp validar_grasa(_), do: {:error, :porcentaje_invalido}

  def solicitar_comprobante(productores, entregas) do
    IO.puts("\n--- COMPROBANTE DEL PRODUCTOR ---")
    codigo = IO.gets("Ingrese el codigo del productor: ") |> String.trim()

    case Enum.find(productores, fn p -> p.codigo == codigo end ) do
      nil -> IO.puts("Error: Productor con codigo #{codigo} no existe.")

      productor ->
        mostrar_comprobante(productor, entregas)
    end
  end

  defp mostrar_comprobante(productor, entregas) do
    IO.puts("\n--- COMPROBANTE DEL PRODUCTOR #{productor.nombre} (#{productor.codigo}) ---")
  end
end
CentroAcopio.main()
