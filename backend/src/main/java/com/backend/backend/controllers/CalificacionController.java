package com.backend.backend.controllers;

import com.backend.backend.Authentication.JwtService;
import com.backend.backend.models.Calificacion;
import com.backend.backend.models.Especialidad;
import com.backend.backend.repositories.CalificacionRepository;
import com.backend.backend.repositories.EspecialidadRepository;
import com.backend.backend.services.CalificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;

@RestController
@RequestMapping("/calificacion/v1")
@RequiredArgsConstructor
public class CalificacionController {

    @Autowired
    CalificacionService calificacionService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private CalificacionRepository calificacionRepository;


    @PostMapping("create")
    public Calificacion guardarCalificacion(@RequestBody Calificacion calificacion) {
        return calificacionService.guardarCalificacion(calificacion);
    }


    @GetMapping("get")
    public ArrayList<Calificacion> obtenerCalificaciones() {
        return calificacionService.obtenerCalificaciones();
    }

    @GetMapping("getcalificacionmedico")
    public ArrayList<Calificacion> obtenerCalificacionPorMedico(@PathVariable int id) {
        return calificacionService.obtenerCalificacionPorMedico(id);
    }


}