package com.backend.backend.services;

import com.backend.backend.DTO.PushNotificationRequest;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final FirebaseMessaging firebaseMessaging;

    public String sendPushNotificationToToken(PushNotificationRequest request) throws Exception {
        Notification notification = Notification.builder()
                .setTitle(request.getTitle())
                .setBody(request.getBody())
                .build();

        Message message = Message.builder()
                .setToken(request.getToken())
                .setNotification(notification)
                .build();

        // Usa el bean inyectado (no FirebaseMessaging.getInstance())
        String messageId = firebaseMessaging.send(message);
        System.out.println("✅ Notificación enviada. messageId=" + messageId);
        return messageId;
    }
}