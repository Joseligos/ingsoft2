package com.example.ServiCiudadCali.infrastructure.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.example.ServiCiudadCali.domain.exception.ResourceNotFoundException;

class GlobalExceptionTest {

    private GlobalException globalException;

    @BeforeEach
    void setUp() {
        globalException = new GlobalException();
    }

    @Test
    void handleResourceNotFoundException_RetornaHttpStatus404() {
        // Arrange
        String mensajeError = "El id: 1234567890 no corresponde a ningun cliente";
        ResourceNotFoundException exception = new ResourceNotFoundException(mensajeError);

        // Act
        ResponseEntity<String> response = globalException.handleResourceNotFoundException(exception);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertEquals(mensajeError, response.getBody());
    }

    @Test
    void handleGeneralException_RetornaHttpStatus500() {
        // Arrange
        Exception exception = new Exception("Error inesperado en la aplicación");

        // Act
        ResponseEntity<String> response = globalException.handleGeneralException(exception);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals("Error interno del servidor", response.getBody());
    }

    @Test
    void handleGeneralException_RetornaMensajeGenerico() {
        // Arrange
        RuntimeException exception = new RuntimeException("Cualquier error no controlado");

        // Act
        ResponseEntity<String> response = globalException.handleGeneralException(exception);

        // Assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals("Error interno del servidor", response.getBody());
        // No debe exponer detalles del error interno
        assertFalse(response.getBody().contains("Cualquier error no controlado"));
    }

    @Test
    void handleGeneralException_NullPointerException_RetornaErrorGenerico() {
        // Arrange
        NullPointerException exception = new NullPointerException("NPE interno");

        // Act
        ResponseEntity<String> response = globalException.handleGeneralException(exception);

        // Assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals("Error interno del servidor", response.getBody());
    }

    @Test
    void handleGeneralException_IllegalArgumentException_RetornaErrorGenerico() {
        // Arrange
        IllegalArgumentException exception = new IllegalArgumentException("Argumento inválido");

        // Act
        ResponseEntity<String> response = globalException.handleGeneralException(exception);

        // Assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals("Error interno del servidor", response.getBody());
    }
}

