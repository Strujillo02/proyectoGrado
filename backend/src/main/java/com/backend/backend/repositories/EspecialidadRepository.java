package com.backend.backend.repositories;

import com.backend.backend.models.Especialidad;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EspecialidadRepository extends CrudRepository<Especialidad, Integer> {
}
