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
    public ResponseEntity<?> crearCita(@RequestBody Cita cita) {
        try {
            // Guardar la cita
            Cita citaGuardada = citaRepository.save(cita);

            // Obtener el médico relacionado
            Optional<Medico> medicoOpt = medicoRepository.findById(citaGuardada.getMedico().getId());
            if (medicoOpt.isPresent()) {
                Medico medico = medicoOpt.get();

                // El token está en el usuario asociado al médico
                String token = medico.getUsuario().getToken_dispositivo();

                if (token != null && !token.isEmpty()) {
                    PushNotificationRequest noti = new PushNotificationRequest();
                    noti.setToken(token);
                    noti.setTitle("Solicitud de cita");
                    noti.setBody("Tienes una solicitud de cita del paciente: "
                            + citaGuardada.getUsuario().getNombre() +
                            ". ¿Deseas aceptarla?");
                    notificacionService.sendPushNotificationToToken(noti);
                }
            }

            return ResponseEntity.ok(citaGuardada);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error: " + e.getMessage());
        }
    }

    @PutMapping("/citas/{id}/respuesta")
    @PreAuthorize("hasAuthority('ROLE_Medico')")
    public ResponseEntity<?> responderCita(
            @PathVariable Integer id,
            @RequestParam String respuesta) {
        try {
            Optional<Cita> citaOpt = citaRepository.findById(id);
            if (!citaOpt.isPresent()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Cita no encontrada");
            }

            Cita cita = citaOpt.get();

            // Validar respuesta
            if (!respuesta.equalsIgnoreCase("Aceptada") &&
                    !respuesta.equalsIgnoreCase("Rechazada")) {
                return ResponseEntity.badRequest().body("Respuesta inválida");
            }

            cita.setRespuesta_medico(respuesta);
            cita.setEstado(respuesta.equalsIgnoreCase("Aceptada") ? "Confirmada" : "Cancelada");
            citaRepository.save(cita);

            // Notificar al paciente sobre la respuesta
            Optional<Usuario> pacienteOpt = usuarioRepository.findById(cita.getUsuario().getId());
            if (pacienteOpt.isPresent()) {
                String tokenPaciente = pacienteOpt.get().getToken_dispositivo();
                if (tokenPaciente != null && !tokenPaciente.isEmpty()) {
                    PushNotificationRequest noti = new PushNotificationRequest();
                    noti.setToken(tokenPaciente);
                    noti.setTitle("Respuesta a tu cita");
                    noti.setBody("El médico ha " + respuesta.toLowerCase() + " tu cita.");
                    notificacionService.sendPushNotificationToToken(noti);
                }
            }

            return ResponseEntity.ok("Respuesta registrada y notificación enviada");

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error: " + e.getMessage());
        }
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

