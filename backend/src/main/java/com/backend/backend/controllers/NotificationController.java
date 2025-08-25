package com.backend.backend.controllers;

import com.backend.backend.DTO.PushNotificationRequest;
import com.backend.backend.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/notification/v1")
@CrossOrigin // opcional
public class NotificationController {


    private final NotificacionService notificacionService;

    @PostMapping("/test")
    @PreAuthorize("hasAnyAuthority('ROLE_Administrador','ROLE_Medico','ROLE_Paciente')") // o quítalo si quieres público
    public ResponseEntity<?> sendTest(@RequestBody PushNotificationRequest req) {
        try {
            if (req.getToken() == null || req.getToken().isBlank())
                return ResponseEntity.badRequest().body("Token requerido");

            String id = notificacionService.sendPushNotificationToToken(req);
            return ResponseEntity.ok().body("{\"messageId\":\"" + id + "\"}");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}