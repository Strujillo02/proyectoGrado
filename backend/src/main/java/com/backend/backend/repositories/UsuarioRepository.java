package com.backend.backend.repositories;

import com.backend.backend.models.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.CrudRepository;

import java.util.Optional;

public interface UsuarioRepository extends CrudRepository<Usuario, Integer> {
    public abstract Usuario findByIdentificacion(String identificacion);

}