package com.backend.backend.services;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

import com.backend.backend.models.Medico;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.backend.backend.models.Calificacion;
import com.backend.backend.repositories.CalificacionRepository;
import com.backend.backend.repositories.MedicoRepository;

@Service
public class CalificacionService {
    @Autowired
    CalificacionRepository calificacionRepository;

    @Autowired
    MedicoRepository medicoRepository;

    public ArrayList<Calificacion> obtenerCalificaciones(){
        return (ArrayList<Calificacion>) calificacionRepository.findAll();
    }
    @Transactional
    public Calificacion guardarCalificacion(Calificacion calificacion) {
        Calificacion calificacionGuardada = calificacionRepository.save(calificacion);

        if (calificacionGuardada.getMedico() == null || calificacionGuardada.getMedico().getId() == null) {
            return calificacionGuardada;
        }

        Integer medicoId = calificacionGuardada.getMedico().getId();
        List<Calificacion> calificacionesMedico = calificacionRepository.findByMedico_Id(medicoId);

        double promedio = calificacionesMedico.stream()
                .map(Calificacion::getCalificacion)
                .filter(java.util.Objects::nonNull)
                .mapToDouble(Integer::doubleValue)
                .average()
                .orElse(0.0);

        Medico medico = medicoRepository.findById(medicoId).orElse(null);
        if (medico != null) {
            medico.setCalificacion(BigDecimal.valueOf(promedio).setScale(2, RoundingMode.HALF_UP));
            medicoRepository.save(medico);
        }

        return calificacionGuardada;
    }

    public ArrayList<Calificacion> obtenerCalificacionPorMedico(int idMedico) {
        return calificacionRepository.findByMedico_Id(idMedico);
    }
   
}
