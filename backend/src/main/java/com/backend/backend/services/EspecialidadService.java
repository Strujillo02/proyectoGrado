package com.backend.backend.services;

import com.backend.backend.models.Especialidad;
import com.backend.backend.repositories.EspecialidadRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

@Service
public class EspecialidadService {
    @Autowired
    EspecialidadRepository especialidadRepository;

    public ArrayList<Especialidad> obtenerEspecialidades(){
        return (ArrayList<Especialidad>) especialidadRepository.findAll();
    }
    public Especialidad guardarEspecialidad(Especialidad especialidad) {
        return especialidadRepository.save(especialidad);
    }
    public boolean eliminar(Integer id){
        try {
            especialidadRepository.deleteById(id);
            return true;
        }catch (Exception e){
            return false;
        }

    }
}
