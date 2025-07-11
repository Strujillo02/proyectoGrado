package com.backend.backend.controllers;

import com.backend.backend.Authentication.JwtService;
import com.backend.backend.models.Especialidad;
import com.backend.backend.models.Usuario;
import com.backend.backend.repositories.EspecialidadRepository;
import com.backend.backend.repositories.UsuarioRepository;
import com.backend.backend.services.EspecialidadService;
import com.backend.backend.services.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;

@RestController
@RequestMapping("/especialidad/v1")
@RequiredArgsConstructor
public class EspecialidadController {

    @Autowired
    EspecialidadService especialidadService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private EspecialidadRepository especialidadRepository;


    @PostMapping("create")
    @PreAuthorize("hasRole('Administrador')")
    public Especialidad guardarEspecialidad(@RequestBody Especialidad especialidad) {
        return especialidadService.guardarEspecialidad(especialidad);
    }


    @GetMapping("get")
    public ArrayList<Especialidad> obtenerEspecialidades() {
        return especialidadService.obtenerEspecialidades();
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("hasRole('Administrador')")
    public String eliminarEspecialidad(@PathVariable int id){
        especialidadService.eliminar(id);
        return "Especialidad eliminada correctamente";
    }

    @PutMapping("/update")
    @PreAuthorize("hasRole('Administrador')")
    public Especialidad actualizarEspecialidad(@RequestBody Especialidad especialidad) {

        return especialidadService.guardarEspecialidad(especialidad);
    }
}
