package com.backend.backend.controllers;

import com.backend.backend.Authentication.JwtService;
import com.backend.backend.models.Especialidad;
import com.backend.backend.models.Medico;
import com.backend.backend.repositories.EspecialidadRepository;
import com.backend.backend.repositories.MedicoRepository;
import com.backend.backend.services.EspecialidadService;
import com.backend.backend.services.MedicoService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;

@RestController
@RequestMapping("/medico/v1")
@RequiredArgsConstructor
public class MedicoController {
    @Autowired
    MedicoService medicoService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private MedicoRepository medicoRepository;

    @PostMapping("create")
    @PreAuthorize("hasAuthority('Administrador')")
    public Medico guardarMedico(@RequestBody Medico medico) {
        return medicoService.guardarMedico(medico);
    }

    @GetMapping("get")
    public ArrayList<Medico> obtenerMedicos() {
        return medicoService.obtenerMedicos();
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("hasAuthority('Administrador')")
    public String eliminarMedico(@PathVariable int id) {
        medicoService.eliminar(id);
        return "medico eliminado correctamente";
    }

    @PutMapping("/update")
    @PreAuthorize("hasAuthority('Administrador')")
    public Medico actualizarMedico(@RequestBody Medico medico) {
        return medicoService.guardarMedico(medico);
    }

    @GetMapping("/getValorConsulta/{usuarioId}")
    @PreAuthorize("hasAnyAuthority('Administrador','ROLE_Administrador', 'Medico', 'ROLE_Medico', 'Paciente', 'ROLE_Paciente')")
    public int consultarValorConsulta(@PathVariable int usuarioId) {
        return medicoService.consultarValorConsulta(usuarioId);
    }
}
