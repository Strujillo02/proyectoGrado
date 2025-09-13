package com.backend.backend.repositories;

import com.backend.backend.models.Medico;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MedicoRepository extends CrudRepository<Medico, Integer> {
    @Query(value = "SELECT m.valor_consulta FROM medicos m WHERE m.usuario_id = :usuarioId LIMIT 1", nativeQuery = true)
    String findValorConsultaByUsuarioId(@Param("usuarioId") int usuarioId);
}
