package com.backend.backend.services;

import com.backend.backend.models.Especialidad;
import com.backend.backend.models.Medico;
import com.backend.backend.repositories.EspecialidadRepository;
import com.backend.backend.repositories.MedicoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

@Service
public class MedicoService {
    @Autowired
    MedicoRepository medicoRepository;

    public ArrayList<Medico> obtenerMedicos(){
        return (ArrayList<Medico>) medicoRepository.findAll();
    }
    public Medico guardarMedico(Medico medico) {
        return medicoRepository.save(medico);
    }
    public boolean eliminar(Integer id){
        try {
            medicoRepository.deleteById(id);
            return true;
        }catch (Exception e){
            return false;
        }

    }
    public int consultarValorConsulta(int usuarioId) {
       int valor = Integer.parseInt(medicoRepository.findValorConsultaByUsuarioId(usuarioId));
       return valor;
    }
}
