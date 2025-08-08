package com.backend.backend.controllers;

import com.backend.backend.DTO.PushNotificationRequest;
import com.backend.backend.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/notificaciones")
@RequiredArgsConstructor
public class NotificationController {

    @Autowired
    private NotificacionService notificationService;

    @PostMapping("/enviar")
    public String enviarNotificacion(@RequestBody PushNotificationRequest request) {
        notificationService.sendPushNotificationToToken(request);
        return "Notificación enviada";
    }
}