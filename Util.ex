defmodule Util do
  @moduledoc """
  Módulo con funciones que se reutilizan
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: septiembre del 2026
  - licencia: GNU GPL v3
  """
  @doc """
  Función que muestra un mensaje en pantalla
  ## Parametro
  - mensaje: string que se mostrará en pantalla
  ## Ejemplo
      iex> Util.mostrar_mensaje("Hola mundo")

      o puede usar

      "Hola mundo"
      |> Util.mostrar_mensaje()
  """
  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end

  @doc """
  Solicita un dato por consola y retorna el string limpio.
  """
  def ingresar(mensaje) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def formatear_moneda(valor) when is_float(valor) do
    :erlang.float_to_binary(valor, decimals: 2)
  end

  def formatear_moneda(valor) when is_integer(valor) do
    Integer.to_string(valor)
  end
end
