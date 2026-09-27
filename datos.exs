defmodule Datos do
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

  def tanques do
    [
      %{id: "T1", nombre: "Tanque Norte", capacidad: 5000},
      %{id: "T2", nombre: "Tanque Central", capacidad: 4000},
      %{id: "T3", nombre: "Tanque Sur", capacidad: 3000},
      %{id: "T4", nombre: "Tanque Este", capacidad: 4000}
    ]
  end

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

      # Entrega invalida para Litro Fuera de Rango (Teniendo en cuanta que
      # que debe ser >0 y <= 800)
      %{productor: "P05", tanque: "T2", dia: 2, litros: 0, grasa: 3.0},
      %{productor: "P06", tanque: "T4", dia: 4, litros: 850, grasa: 3.6},

      # Entrega Invalida para porcentaje de grasa invalido
      # (En base a que el % debe ser entre 0 y 15)
      %{productor: "P07", tanque: "T1", dia: 5, litros: 250, grasa: -1.0},
      %{productor: "P08", tanque: "T3", dia: 6, litros: 310, grasa: 16.5},

      # Entregas Validas
    ]
  end
end
