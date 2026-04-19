package com.backend.backend.repositories;

import com.backend.backend.models.Calificacion;


import java.util.ArrayList;

import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CalificacionRepository extends CrudRepository<Calificacion, Integer> {
    ArrayList<Calificacion> findByMedico_Id(Integer medicoId);
}