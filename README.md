# Centro de acopio de leche: Liquidación de entregas

**Universidad del Quindío · Ingeniería de Sistemas y Computación**
**Programación III, Parcial 1** · Docente: Julián E. Gutiérrez Posada

Integrantes: _(Simon Lopez Estrada, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo)_

## Descripción

Programa en Elixir que procesa las entregas semanales de leche de varios productores a un centro de acopio del Quindío: valida los registros, calcula lo que se le paga a cada productor y genera ocho reportes. Al final, permite consultar el comprobante de un productor.

## Restricciones de alcance

No se permite:

- Recursividad
- `defstruct` o structs propios
- Lectura o escritura de archivos con `File`
- Procesos (`spawn`, `Task`, `Agent`, `GenServer`)
- Proyectos `mix` o librerías externas
- `try/rescue` para validar (los errores se manejan con `{:ok, valor}` y `{:error, motivo}`)

Los recorridos se hacen con `Enum` o `for`.

## Parámetros (atributos de módulo)

| Parámetro | Valor |
|---|---|
| Tarifa base por litro | $1.800 |
| Meta diaria del centro | 2.000 litros |
| Días de recepción | 6 (del 1 al 6) |
| Máximo de litros por entrega | 800 |
| Litros diarios para bonificación | 450 |
| Bonificación diaria | $25.000 |
| Transporte | $18.000 por día con entrega |

