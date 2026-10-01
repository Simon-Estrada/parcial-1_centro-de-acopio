defmodule Interaccion do
  @moduledoc """
  Módulo para la gestión de la interacción con el usuario mediante consola (E/S).
  Autores: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo.

  Este módulo permite registrar entregas adicionales desde el teclado cumpliendo
  con las restricciones de no usar `try/rescue`, no usar `defstruct` y evitar
  recursividad manual.
  """
  @doc """
  Solicita al usuario el ingreso de una entrega adicional por consola.

  ## Retornos:
  - `{:ok, mapa_entrega}` si los datos ingresados son válidos.
  - `{:ok, :omitido}` si el usuario presiona Enter sin ingresar datos.
  - `{:error, :formato_invalido}` si los tipos o la cantidad de campos son incorrectos.
  """

  def pedir_entrega_adicional do
    "Ingrese una entrega adicional (productor;tanque;dia;litros;grasa) o Enter para omitir: "
    |> Util.ingresar()
    |> procesar_entrada()
  end

  # Funciones privadas

  # Captura caso de fin de archivo en consola (Ctrl+D)
  defp procesar_entrada(:eof), do: {:ok, :omitido}

  defp procesar_entrada(texto) do
    texto_limpio = String.trim(texto)

    if texto_limpio == "" do
      {:ok, :omitido}
    else
      texto_limpio
      |> String.split(";")
      |> parsear_campos()
    end
  end

  # Caso principal: 5 campos separados por ';' (productor;tanque;dia;litros;grasa)
  defp parsear_campos([prod, tanq, str_dia, str_litros, str_grasa]) do
    with {dia, ""} <- parse_entero(str_dia),
         {litros, ""} <- parse_numero(str_litros),
         {grasa, ""} <- parse_numero(str_grasa) do
      # Mapa plano (sin defstruct)
      entrega = %{
        productor: prod |> String.trim() |> String.upcase(),
        tanque: tanq |> String.trim() |> String.upcase(),
        dia: dia,
        litros: litros,
        grasa: grasa
      }

      {:ok, entrega}
    else
      _ -> {:error, :formato_invalido}
    end
  end

  # Caso por defecto: Número de capos inválido
  defp parsear_campos(_), do: {:error, :formato_invalido}

  # Convierte cadena a entero validando retorno estricto de tupla {valor, ""}
  defp parse_entero(str) do
    str
    |> String.trim()
    |> Integer.parse()
    |> case do
      {num, ""} -> {num, ""}
      _ -> :error
    end
  end

  # Convierte cadena a decimal (Float) validando retorno estricto de tupla {valor, ""}
  defp parse_numero(str) do
    str_limpio = String.trim(str)

    case Float.parse(str_limpio) do
      {num, ""} ->
        {num * 1.0, ""}

      _ ->
        case Integer.parse(str_limpio) do
          {num, ""} -> {num * 1.0, ""}
          _ -> :error
        end
    end
  end
end
