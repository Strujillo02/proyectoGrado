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

    public ArrayList<Cita> obtenerCitaPorMedicoId(Integer medicoId){
        return citaRepository.findCitaByMedico_Id(medicoId);
    }
    public Cita guardarCita(Cita cita) {
        return citaRepository.save(cita);
    }
    public void eliminar(Integer id){
        citaRepository.deleteById(id);
    }
    
    public ArrayList<Cita> obtenerCitaPorId_usuario(Integer id){
        if(citaRepository.findCitaByUsuario_Id(id).isEmpty()){
            return null;
        }else {
            return citaRepository.findCitaByUsuario_Id(id); 
        }
        
    }
}
