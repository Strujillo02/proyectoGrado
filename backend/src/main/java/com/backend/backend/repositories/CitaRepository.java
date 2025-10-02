package com.backend.backend.repositories;

import com.backend.backend.models.Cita;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;

@Repository
public interface CitaRepository extends CrudRepository<Cita, Integer> {
    ArrayList<Cita> findCitaByMedico_Id(Integer medicoId);

    ArrayList<Cita> findCitaByUsuario_Id(Integer usuarioId);

}
