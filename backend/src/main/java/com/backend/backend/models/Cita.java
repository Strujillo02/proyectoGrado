package com.backend.backend.models;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "citas")
public class Cita {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    Integer id;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "especialidade_id", nullable = false)
    Especialidad especialidad;

    @Column(name = "fecha_registro")
    Instant fecha_registro;

    @Column(name = "motivo_consulta", length = 45)
    String motivo_consulta;

    @Column(name = "precio", length = 45)
    String precio;

    @Column(name = "estado", length = 45)
    String estado;

    @Column(name = "tipo_consulta", length = 45)
    String tipo_consulta;

    @Column(name = "fecha_cita")
    Instant fecha_cita;

    @Column(name = "latitud", precision = 9, scale = 6)
    BigDecimal latitud;

    @Column(name = "longitud", precision = 9, scale = 6)
    BigDecimal longitud;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "medico_id", nullable = false)
    Medico medico;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    Usuario usuario;

    @Column(name = "respuesta_medico", length = 20)
    String respuesta_medico;


}
