package com.example.ServiCiudadCali.domain.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ResourceNotFoundExceptionTest {

    @Test
    void constructor_CrearExcepcionConMensaje() {
        // Arrange
        String mensaje = "Recurso no encontrado";

        // Act
        ResourceNotFoundException exception = new ResourceNotFoundException(mensaje);

        // Assert
        assertNotNull(exception);
        assertEquals(mensaje, exception.getMessage());
    }

    @Test
    void esSubclaseDeRuntimeException() {
        // Arrange
        ResourceNotFoundException exception = new ResourceNotFoundException("Test");

        // Act & Assert
        assertTrue(exception instanceof RuntimeException);
    }
}

