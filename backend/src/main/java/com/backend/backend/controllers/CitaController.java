package com.backend.backend.controllers;

import com.backend.backend.Authentication.JwtService;
import com.backend.backend.DTO.PushNotificationRequest;
import com.backend.backend.models.Cita;
import com.backend.backend.models.Medico;
import com.backend.backend.models.Usuario;
import com.backend.backend.repositories.CitaRepository;
import com.backend.backend.repositories.MedicoRepository;
import com.backend.backend.repositories.UsuarioRepository;
import com.backend.backend.services.CitaService;
import com.backend.backend.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Optional;

@RestController
@RequestMapping("/cita/v1")
@RequiredArgsConstructor
public class CitaController {
    @Autowired
    CitaService citaService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private CitaRepository citaRepository;
    @Autowired
    private NotificacionService notificacionService;
    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private MedicoRepository medicoRepository;

    @PostMapping("create")
    @PreAuthorize("hasAnyAuthority('ROLE_Administrador', 'ROLE_Medico', 'ROLE_Paciente')")
    public ResponseEntity<?> guardarCita(@RequestBody Cita cita) {
        try {
            cita.setEstado("Pendiente");
            cita.setRespuesta_medico("Pendiente");
            cita.setFecha_registro(Instant.from(LocalDateTime.now()));

            // Guardar la cita
            Cita citaGuardada = citaService.guardarCita(cita);

            // Obtener el token del médico
            // Obtener el médico con su usuario
            Optional<Medico> medico = medicoRepository.findById(cita.getId());
            if (medico.isPresent()) {
                Usuario usuarioMedico = medico.get().getUsuario(); // Aquí sacas el usuario
                String token = usuarioMedico.getToken_dispositivo();

                if (token != null && !token.isEmpty()) {
                    // Enviar notificación al médico
                    PushNotificationRequest noti = new PushNotificationRequest();
                    noti.setToken(token);
                    noti.setTitle("Solicitud de cita");
                    noti.setBody("Tienes una solicitud de cita de un paciente. ¿Deseas aceptarla?");
                    notificacionService.sendPushNotificationToToken(noti);
                }
            }


            return ResponseEntity.ok(citaGuardada);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error: " + e.getMessage());
        }

/**
    @GetMapping("get")
   // @PreAuthorize("hasAnyAuthority('Paciente', 'Medico', 'Administrador')")
    @PreAuthorize("hasAnyAuthority('ROLE_Administrador', 'ROLE_Medico', 'ROLE_Paciente')")
    public ArrayList<Cita> obtenerCitas() {
        return citaService.obtenerCita();
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_Administrador', 'ROLE_Medico', 'ROLE_Paciente')")
    public String eliminarCita(@PathVariable int id){
        citaService.eliminar(id);
        return "Cita eliminada correctamente";
    }

    @PutMapping("/update")
    @PreAuthorize("hasAnyAuthority('ROLE_Administrador', 'ROLE_Medico', 'ROLE_Paciente')")
    public Cita actualizarCita(@RequestBody Cita cita) {
        return citaService.guardarCita(cita);
    }
    */
    }
}
