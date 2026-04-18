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
import com.backend.backend.services.MedicoService;
import com.backend.backend.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
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
    private MedicoService  medicoService;

    @Autowired
    private CitaRepository citaRepository;
    @Autowired
    private NotificacionService notificacionService;
    @Autowired
    private UsuarioRepository usuarioRepository;
    @Autowired
    private MedicoRepository medicoRepository;



    @PostMapping("create")
    public ResponseEntity<?> crearCita(@RequestBody Cita cita) {
        try {
            // Guardar la cita
            Cita citaGuardada = citaRepository.save(cita);

            // Cargar médico y paciente desde BD para evitar null por lazy
            Optional<Medico> medicoOpt = medicoRepository.findById(citaGuardada.getMedico().getId());
            Optional<Usuario> pacienteOpt = usuarioRepository.findById(citaGuardada.getUsuario().getId());

            // La cita ya se guardo; si falla la notificacion no se debe revertir el flujo principal.
            try {
                if (medicoOpt.isPresent()) {
                    Medico medico = medicoOpt.get();
                    String token = (medico.getUsuario() != null) ? medico.getUsuario().getToken_dispositivo() : null;

                    if (token != null && !token.isBlank()) {
                        String pacienteNombre = pacienteOpt.map(Usuario::getNombre).orElse("");

                        Map<String, String> data = new HashMap<>();
                        data.put("citaId", String.valueOf(citaGuardada.getId()));
                        data.put("pacienteNombre", pacienteNombre);
                        data.put("title", "Solicitud de cita");
                        data.put("body", "Tienes una solicitud de cita.");

                        notificacionService.sendDataToToken(token, data);
                    }
                }
            } catch (Exception ignored) {
                // Ignorado intencionalmente para no romper la creacion de la cita.
            }

            return ResponseEntity.ok(citaGuardada);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error: " + e.getMessage());
        }
    }


    @GetMapping("/citasporusuario/{id}")
    public ArrayList<Cita> getCitasPorUsuario(@PathVariable int id) {
        return citaService.obtenerCitaPorId_usuario(id);
    }

    @PutMapping("/citas/{id}/respuesta")
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

            // Actualizar cita
            cita.setRespuesta_medico(respuesta);
            cita.setEstado(respuesta.equalsIgnoreCase("Aceptada") ? "Confirmada" : "Cancelada");
            citaRepository.save(cita);

            // Notificar al paciente sobre la respuesta (DATA-ONLY)
            Optional<Usuario> pacienteOpt = usuarioRepository.findById(cita.getUsuario().getId());
            if (pacienteOpt.isPresent()) {
                String tokenPaciente = pacienteOpt.get().getToken_dispositivo();
                if (tokenPaciente != null && !tokenPaciente.isEmpty()) {
                    Map<String, String> data = new HashMap<>();
                    data.put("title", "Respuesta a tu cita");
                    data.put("body", "El médico ha " + respuesta.toLowerCase() + " tu cita.");
                    data.put("citaId", String.valueOf(cita.getId())); // opcional para manejar en el cliente
                    data.put("estado", cita.getEstado());             // opcional
                    data.put("respuesta", respuesta);                 // opcional

                    notificacionService.sendDataToToken(tokenPaciente, data);
                }
            }

            return ResponseEntity.ok("Respuesta registrada y notificación enviada");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/get/{id}")
    public ArrayList<Cita> getCitas(@PathVariable int id) {
        // Interpretamos primero el parámetro como usuario_id para obtener su médico
        Medico medicoPorUsuario = medicoRepository.findByUsuarioId(id);
        if (medicoPorUsuario != null) {
            return citaService.obtenerCitaPorMedicoId(medicoPorUsuario.getId());
        }
        // Si no existe médico por usuario, interpretamos el id directamente como medico_id
        return medicoRepository.findById(id)
                .map(medico -> citaService.obtenerCitaPorMedicoId(medico.getId()))
                .orElseGet(ArrayList::new);
    }





/**
    @GetMapping("get")
   // @PreAuthorize("hasAnyAuthority('Paciente', 'Medico', 'Administrador')")
    @PreAuthorize("hasAnyRole('Administrador', 'Medico', 'Paciente')")
    public ArrayList<Cita> obtenerCitas() {
        return citaService.obtenerCita();
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("hasAnyRole('Administrador', 'Medico', 'Paciente')")
    public String eliminarCita(@PathVariable int id){
        citaService.eliminar(id);
        return "Cita eliminada correctamente";
    }

    @PutMapping("/update")
    @PreAuthorize("hasAnyRole('Administrador', 'Medico', 'Paciente')")
    public Cita actualizarCita(@RequestBody Cita cita) {
        return citaService.guardarCita(cita);
    }
    */
    }
