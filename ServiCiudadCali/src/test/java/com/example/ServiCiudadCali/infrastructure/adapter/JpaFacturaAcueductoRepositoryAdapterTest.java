package com.example.ServiCiudadCali.infrastructure.adapter;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.ServiCiudadCali.domain.model.FacturaAcueducto;
import com.example.ServiCiudadCali.infrastructure.entity.FacturaAcueductoEntity;
import com.example.ServiCiudadCali.infrastructure.repository.JpaFacturaAcueductoRepository;

@ExtendWith(MockitoExtension.class)
class JpaFacturaAcueductoRepositoryAdapterTest {

    @Mock
    private JpaFacturaAcueductoRepository jpaFacturaAcueductoRepository;

    @InjectMocks
    private JpaFacturaAcueductoRepositoryAdapter adapter;

    private FacturaAcueductoEntity facturaEntity;
    private String clienteId;

    @BeforeEach
    void setUp() {
        clienteId = "1234567890";
        facturaEntity = new FacturaAcueductoEntity();
        facturaEntity.setId(1L);
        facturaEntity.setIdCliente(clienteId);
        facturaEntity.setPeriodo("202311");
        facturaEntity.setConsumo(50);
        facturaEntity.setValorPagar(new BigDecimal("150000.00"));
    }

    @Test
    void obtenerPorCliente_FacturaExiste_RetornaOptionalConFactura() {
        // Arrange
        when(jpaFacturaAcueductoRepository.findFirstByIdClienteOrderByPeriodoDesc(clienteId))
            .thenReturn(Optional.of(facturaEntity));

        // Act
        Optional<FacturaAcueducto> resultado = adapter.obtenerPorCliente(clienteId);

        // Assert
        assertTrue(resultado.isPresent());
        FacturaAcueducto factura = resultado.get();
        assertEquals(1L, factura.getId());
        assertEquals(clienteId, factura.getIdCliente());
        assertEquals("202311", factura.getPeriodo());
        assertEquals(50, factura.getConsumoM3());
        assertEquals(new BigDecimal("150000.00"), factura.getValorPagar());
        
        verify(jpaFacturaAcueductoRepository, times(1)).findFirstByIdClienteOrderByPeriodoDesc(clienteId);
    }

    @Test
    void obtenerPorCliente_FacturaNoExiste_RetornaOptionalVacio() {
        // Arrange
        String clienteIdInexistente = "9999999999";
        when(jpaFacturaAcueductoRepository.findFirstByIdClienteOrderByPeriodoDesc(clienteIdInexistente))
            .thenReturn(Optional.empty());

        // Act
        Optional<FacturaAcueducto> resultado = adapter.obtenerPorCliente(clienteIdInexistente);

        // Assert
        assertFalse(resultado.isPresent());
        assertTrue(resultado.isEmpty());
        
        verify(jpaFacturaAcueductoRepository, times(1)).findFirstByIdClienteOrderByPeriodoDesc(clienteIdInexistente);
    }

    @Test
    void obtenerPorCliente_ConsumoYValorCero_MapeoCorrectamente() {
        // Arrange
        FacturaAcueductoEntity entity = new FacturaAcueductoEntity();
        entity.setId(2L);
        entity.setIdCliente("2222222222");
        entity.setPeriodo("202310");
        entity.setConsumo(0);
        entity.setValorPagar(BigDecimal.ZERO);
        
        when(jpaFacturaAcueductoRepository.findFirstByIdClienteOrderByPeriodoDesc("2222222222"))
            .thenReturn(Optional.of(entity));

        // Act
        Optional<FacturaAcueducto> resultado = adapter.obtenerPorCliente("2222222222");

        // Assert
        assertTrue(resultado.isPresent());
        FacturaAcueducto factura = resultado.get();
        assertEquals(0, factura.getConsumoM3());
        assertEquals(BigDecimal.ZERO, factura.getValorPagar());
        
        verify(jpaFacturaAcueductoRepository, times(1)).findFirstByIdClienteOrderByPeriodoDesc("2222222222");
    }
}

