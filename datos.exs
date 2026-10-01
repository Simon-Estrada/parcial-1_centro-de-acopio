defmodule Datos do
  @moduledoc """
  Módulo con los datos requeridos para el funcionamiento del centro de acopio de leche.

  Este módulo actúa como la fuente de datos estática para pruebas del sistema de acopio,
  proporcionando registros de productores, tanques disponibles y el historial de entregas.

  ## Información del Proyecto
    - **Autores:** Simon Lopez E, Luna Sofia Oviedo R, David Alejandro Henao J.
    - **Fecha:** Septiembre del 2026
    - **Licencia:** GNU GPL v3
  """

  @doc """
  Devuelve el listado de productores registrados en el sistema.

  ## Ejemplos

      iex> lista = Datos.productores()
      iex> Enum.any?(lista, fn p -> p.nombre == "Danielle Marsh" end)
      true

  """
  def productores do
    [
      %{codigo: "P01", nombre: "Danielle Marsh", transporte: true},
      %{codigo: "P02", nombre: "Mateo Silvestre", transporte: false},
      %{codigo: "P03", nombre: "Mina Myoi", transporte: false},
      %{codigo: "P04", nombre: "Julian Casablancas", transporte: true},
      %{codigo: "P05", nombre: "Valeria Sotomayor", transporte: false},
      %{codigo: "P06", nombre: "Hunter Schafer", transporte: true},
      %{codigo: "P07", nombre: "Maria Kamila", transporte: true},
      %{codigo: "P08", nombre: "Juan Salazar", transporte: true},
      %{codigo: "P09", nombre: "Dante Beltran", transporte: false},
      %{codigo: "P10", nombre: "Camilo Martinez", transporte: false}
    ]
  end

  @doc """
  Devuelve el listado de tanques disponibles en el centro de acopio.

  ## Ejemplos

      iex> lista = Datos.tanques()
      iex> length(lista)
      4

  """
  def tanques do
    [
      %{id: "T1", nombre: "Tanque Norte", capacidad: 8000},
      %{id: "T2", nombre: "Tanque Central", capacidad: 9000},
      %{id: "T3", nombre: "Tanque Sur", capacidad: 8500},
      %{id: "T4", nombre: "Tanque Este", capacidad: 9900}
    ]
  end

  @doc """
  Muestra o devuelve el historial de entregas de leche realizadas en el centro de acopio.

  Contiene tanto registros válidos como simulaciones de registros inválidos que se pidieron en
  los requisitos del parcial para
  pruebas de validación (IDs inexistentes, días fuera de rango, litros o grasa inválidos).

  ## Reglas de Validación asociadas a los datos:
    - **Días válidos:** Del 1 al 6.
    - **Litros permitidos:** Mayor a 0 y menor o igual a 800.
    - **Porcentaje de grasa:** Entre 0.0% y 15.0%.

  ## Ejemplos

      iex> lista = Datos.entregas()
      iex> hd(lista).productor
      "P99"

  """
  def entregas do
    [
      # Entrega invalida para productor desconocido
      %{productor: "P99", tanque: "T1", dia: 1, litros: 200, grasa: 3.5},
      %{productor: "P70", tanque: "T2", dia: 2, litros: 150, grasa: 3.2},

      # Entrega invalida para tanque desconocido
      %{productor: "P01", tanque: "T9", dia: 1, litros: 200, grasa: 3.5},
      %{productor: "P02", tanque: "T10", dia: 4, litros: 300, grasa: 5.0},

      # Entrega invalida para Dia invalido (Recordando que es de 1 a 6)
      %{productor: "P03", tanque: "T2", dia: 0, litros: 180, grasa: 3.1},
      %{productor: "P04", tanque: "T4", dia: 7, litros: 220, grasa: 3.4},
      %{productor: "P06", tanque: "T2", dia: 2.5, litros: 200, grasa: 3.0},

      # Entrega invalida para Litro Fuera de Rango (Teniendo en cuanta que
      # que debe ser >0 y <= 800)
      %{productor: "P05", tanque: "T2", dia: 2, litros: 0, grasa: 3.0},
      %{productor: "P06", tanque: "T4", dia: 4, litros: 850, grasa: 3.6},
      %{productor: "P10", tanque: "T1", dia: 3, litros: "abc", grasa: 3.2},

      # Entrega Invalida para porcentaje de grasa invalido
      # (En base a que el % debe ser entre 0 y 15)
      %{productor: "P07", tanque: "T1", dia: 5, litros: 250, grasa: -1.0},
      %{productor: "P08", tanque: "T3", dia: 6, litros: 310, grasa: 16.5},

      # Entregas con VARIOS errores a la vez: solo se reporta el primer motivo según el orden de validación
      %{productor: "P98", tanque: "T9", dia: 9, litros: 0, grasa: -5.0},
      %{productor: "P05", tanque: "T7", dia: 0, litros: 900, grasa: 20.0},

      # Entregas Validas

      # DÍA 1
      %{productor: "P01", tanque: "T1", dia: 1, litros: 180, grasa: 3.8},
      %{productor: "P01", tanque: "T4", dia: 1, litros: 120, grasa: 3.7},
      %{productor: "P01", tanque: "T3", dia: 1, litros: 120, grasa: 3.9},
      %{productor: "P02", tanque: "T2", dia: 1, litros: 225, grasa: 3.2},
      %{productor: "P02", tanque: "T1", dia: 1, litros: 225, grasa: 3.4},
      %{productor: "P03", tanque: "T3", dia: 1, litros: 200, grasa: 2.7},
      %{productor: "P03", tanque: "T4", dia: 1, litros: 150, grasa: 3.1},
      %{productor: "P04", tanque: "T4", dia: 1, litros: 220, grasa: 2.1},
      %{productor: "P04", tanque: "T2", dia: 1, litros: 229, grasa: 3.1},
      %{productor: "P05", tanque: "T1", dia: 1, litros: 250, grasa: 4.2},
      %{productor: "P05", tanque: "T2", dia: 1, litros: 260, grasa: 3.9},
      %{productor: "P07", tanque: "T3", dia: 1, litros: 110, grasa: 3.6},
      %{productor: "P07", tanque: "T2", dia: 1, litros: 100, grasa: 3.5},
      %{productor: "P07", tanque: "T4", dia: 1, litros: 160, grasa: 2.6},
      %{productor: "P09", tanque: "T1", dia: 1, litros: 270, grasa: 5.5},
      %{productor: "P10", tanque: "T2", dia: 1, litros: 100, grasa: 5.0},

      # DÍA 2
      %{productor: "P01", tanque: "T2", dia: 2, litros: 130, grasa: 2.6},
      %{productor: "P01", tanque: "T3", dia: 2, litros: 100, grasa: 2.8},
      %{productor: "P01", tanque: "T1", dia: 2, litros: 180, grasa: 3.9},
      %{productor: "P02", tanque: "T1", dia: 2, litros: 320, grasa: 3.7},
      %{productor: "P02", tanque: "T2", dia: 2, litros: 90, grasa: 3.0},
      %{productor: "P03", tanque: "T2", dia: 2, litros: 270, grasa: 3.3},
      %{productor: "P03", tanque: "T3", dia: 2, litros: 120, grasa: 2.9},
      %{productor: "P04", tanque: "T3", dia: 2, litros: 290, grasa: 2.9},
      %{productor: "P04", tanque: "T4", dia: 2, litros: 110, grasa: 3.2},
      %{productor: "P05", tanque: "T4", dia: 2, litros: 250, grasa: 2.3},
      %{productor: "P05", tanque: "T3", dia: 2, litros: 210, grasa: 3.4},
      %{productor: "P06", tanque: "T1", dia: 2, litros: 200, grasa: 4.1},
      %{productor: "P06", tanque: "T2", dia: 2, litros: 160, grasa: 4.0},
      %{productor: "P06", tanque: "T4", dia: 2, litros: 80, grasa: 3.6},
      %{productor: "P07", tanque: "T2", dia: 2, litros: 200, grasa: 3.0},
      %{productor: "P07", tanque: "T1", dia: 2, litros: 150, grasa: 4.0},

      # DÍA 3
      %{productor: "P01", tanque: "T4", dia: 3, litros: 180, grasa: 4.0},
      %{productor: "P01", tanque: "T3", dia: 3, litros: 100, grasa: 3.8},
      %{productor: "P01", tanque: "T2", dia: 3, litros: 100, grasa: 3.5},
      %{productor: "P02", tanque: "T3", dia: 3, litros: 250, grasa: 3.1},
      %{productor: "P02", tanque: "T1", dia: 3, litros: 170, grasa: 2.4},
      %{productor: "P03", tanque: "T1", dia: 3, litros: 250, grasa: 2.8},
      %{productor: "P03", tanque: "T4", dia: 3, litros: 200, grasa: 3.0},
      %{productor: "P05", tanque: "T3", dia: 3, litros: 200, grasa: 3.6},
      %{productor: "P05", tanque: "T4", dia: 3, litros: 100, grasa: 3.7},
      %{productor: "P05", tanque: "T2", dia: 3, litros: 90, grasa: 3.3},
      %{productor: "P06", tanque: "T4", dia: 3, litros: 270, grasa: 3.3},
      %{productor: "P06", tanque: "T3", dia: 3, litros: 120, grasa: 3.9},
      %{productor: "P07", tanque: "T1", dia: 3, litros: 450, grasa: 4.3},
      %{productor: "P10", tanque: "T3", dia: 3, litros: 100, grasa: 5.0},

      # DÍA 4
      %{productor: "P01", tanque: "T4", dia: 4, litros: 150, grasa: 3.5},
      %{productor: "P01", tanque: "T3", dia: 4, litros: 100, grasa: 3.6},
      %{productor: "P02", tanque: "T1", dia: 4, litros: 110, grasa: 2.6},
      %{productor: "P02", tanque: "T3", dia: 4, litros: 100, grasa: 3.2},
      %{productor: "P03", tanque: "T4", dia: 4, litros: 200, grasa: 3.9},
      %{productor: "P03", tanque: "T1", dia: 4, litros: 100, grasa: 3.4},
      %{productor: "P04", tanque: "T1", dia: 4, litros: 150, grasa: 3.0},
      %{productor: "P04", tanque: "T4", dia: 4, litros: 110, grasa: 2.9},
      %{productor: "P05", tanque: "T2", dia: 4, litros: 200, grasa: 2.7},
      %{productor: "P05", tanque: "T3", dia: 4, litros: 140, grasa: 3.0},
      %{productor: "P07", tanque: "T4", dia: 4, litros: 230, grasa: 4.2},
      %{productor: "P07", tanque: "T2", dia: 4, litros: 170, grasa: 3.9},
      %{productor: "P09", tanque: "T2", dia: 4, litros: 240, grasa: 5.8},

      # DÍA 5
      %{productor: "P01", tanque: "T2", dia: 5, litros: 160, grasa: 3.7},
      %{productor: "P01", tanque: "T3", dia: 5, litros: 150, grasa: 3.8},
      %{productor: "P03", tanque: "T1", dia: 5, litros: 120, grasa: 3.6},
      %{productor: "P03", tanque: "T3", dia: 5, litros: 90, grasa: 2.9},
      %{productor: "P06", tanque: "T2", dia: 5, litros: 260, grasa: 3.0},
      %{productor: "P06", tanque: "T3", dia: 5, litros: 230, grasa: 2.8},
      %{productor: "P07", tanque: "T3", dia: 5, litros: 180, grasa: 3.8},
      %{productor: "P07", tanque: "T4", dia: 5, litros: 120, grasa: 4.0},
      %{productor: "P10", tanque: "T4", dia: 5, litros: 650, grasa: 2.4},

      # DÍA 6
      %{productor: "P01", tanque: "T2", dia: 6, litros: 180, grasa: 2.5},
      %{productor: "P01", tanque: "T4", dia: 6, litros: 150, grasa: 3.0},
      %{productor: "P02", tanque: "T3", dia: 6, litros: 300.5, grasa: 4},
      %{productor: "P02", tanque: "T1", dia: 6, litros: 100, grasa: 3.6},
      %{productor: "P03", tanque: "T4", dia: 6, litros: 270, grasa: 3.4},
      %{productor: "P03", tanque: "T2", dia: 6, litros: 100, grasa: 3.2},
      %{productor: "P05", tanque: "T1", dia: 6, litros: 200, grasa: 3.9},
      %{productor: "P05", tanque: "T2", dia: 6, litros: 120, grasa: 3.8},
      %{productor: "P05", tanque: "T4", dia: 6, litros: 120, grasa: 3.1},
      %{productor: "P06", tanque: "T4", dia: 6, litros: 110, grasa: 2.1},
      %{productor: "P06", tanque: "T3", dia: 6, litros: 100, grasa: 2.2},
      %{productor: "P06", tanque: "T1", dia: 6, litros: 150, grasa: 3.2},
      %{productor: "P07", tanque: "T2", dia: 6, litros: 340, grasa: 4.2},
      %{productor: "P07", tanque: "T1", dia: 6, litros: 259.5, grasa: 3.0}
    ]
  end
end
