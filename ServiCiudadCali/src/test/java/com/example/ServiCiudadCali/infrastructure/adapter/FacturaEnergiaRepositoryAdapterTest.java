package com.example.ServiCiudadCali.infrastructure.adapter;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.example.ServiCiudadCali.domain.model.FacturaEnergia;

class FacturaEnergiaRepositoryAdapterTest {

    private FacturaEnergiaRepositoryAdapter adapter;

    @BeforeEach
    void setUp() {
        adapter = new FacturaEnergiaRepositoryAdapter();
    }

    @Test
    void obtenerPorCliente_ClienteExisteEnArchivo_RetornaOptionalConFactura() {
        // Arrange - Cliente que existe en el archivo consumos_energia.txt
        String clienteId = "0001234567";

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteId);

        // Assert
        assertTrue(resultado.isPresent());
        FacturaEnergia factura = resultado.get();
        assertEquals(clienteId, factura.getIdCliente());
        assertNotNull(factura.getPeriodo());
        assertTrue(factura.getConsumokwh() >= 0);
        assertNotNull(factura.getValorPagar());
        assertTrue(factura.getValorPagar().compareTo(BigDecimal.ZERO) >= 0);
    }

    @Test
    void obtenerPorCliente_ClienteNoExisteEnArchivo_RetornaOptionalVacio() {
        // Arrange - Cliente que no existe en el archivo
        String clienteIdInexistente = "9999999999";

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteIdInexistente);

        // Assert
        assertFalse(resultado.isPresent());
        assertTrue(resultado.isEmpty());
    }

    @Test
    void obtenerPorCliente_ClienteConVariasFacturas_RetornaUltimaFactura() {
        // Arrange - Cliente con múltiples registros en el archivo
        String clienteId = "0001234567";

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteId);

        // Assert
        assertTrue(resultado.isPresent());
        // El adaptador devuelve la última factura encontrada
        FacturaEnergia factura = resultado.get();
        assertEquals(clienteId, factura.getIdCliente());
        // Verificar valores de la segunda línea (última factura del cliente 0001234567)
        assertEquals("202510", factura.getPeriodo());
        assertEquals(950, factura.getConsumokwh());
        assertEquals(new BigDecimal("65000.25"), factura.getValorPagar());
    }

    @Test
    void obtenerPorCliente_ValidarDatosEspecificosDeCliente() {
        // Arrange - Probar con cliente específico del archivo
        String clienteId = "0009876543";

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteId);

        // Assert
        assertTrue(resultado.isPresent());
        FacturaEnergia factura = resultado.get();
        assertEquals("0009876543", factura.getIdCliente());
        assertEquals("202510", factura.getPeriodo());
        assertEquals(1200, factura.getConsumokwh());
        assertEquals(new BigDecimal("82500.50"), factura.getValorPagar());
    }

    @Test
    void obtenerPorCliente_ConsumoYValorPositivos() {
        // Arrange
        String clienteId = "1106514392";

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteId);

        // Assert
        assertTrue(resultado.isPresent());
        FacturaEnergia factura = resultado.get();
        assertTrue(factura.getConsumokwh() > 0);
        assertTrue(factura.getValorPagar().compareTo(BigDecimal.ZERO) > 0);
        assertEquals(1000, factura.getConsumokwh());
        assertEquals(new BigDecimal("70000.75"), factura.getValorPagar());
    }

    @Test
    void obtenerPorCliente_ClienteIdVacio_RetornaOptionalVacio() {
        // Arrange
        String clienteIdVacio = "";

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteIdVacio);

        // Assert
        assertFalse(resultado.isPresent());
    }

    @Test
    void obtenerPorCliente_ClienteIdNull_RetornaOptionalVacio() {
        // Arrange
        String clienteIdNull = null;

        // Act
        Optional<FacturaEnergia> resultado = adapter.obtenerPorCliente(clienteIdNull);

        // Assert
        // Aunque puede lanzar NullPointerException, el método actual maneja excepciones
        // y retorna Optional.empty() en caso de error
        assertFalse(resultado.isPresent());
    }
}

