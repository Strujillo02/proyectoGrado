package com.backend.backend.services;

import com.backend.backend.models.Cita;
import com.backend.backend.repositories.CitaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

@Service
public class CitaService {
    @Autowired
    CitaRepository citaRepository;

    public ArrayList<Cita> obtenerCita(){
        return (ArrayList<Cita>)citaRepository.findAll();
    }

    public Cita guardarCita(Cita cita) {
        return citaRepository.save(cita);
    }
    public void eliminar(Integer id){
        citaRepository.deleteById(id);
    }
}
