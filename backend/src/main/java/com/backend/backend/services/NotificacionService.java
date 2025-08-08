package com.backend.backend.services;

import com.backend.backend.DTO.PushNotificationRequest;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final FirebaseMessaging firebaseMessaging;

    public void sendPushNotificationToToken(PushNotificationRequest request) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(request.getTitle())
                    .setBody(request.getBody())
                    .build();

            Message message = Message.builder()
                    .setToken(request.getToken())
                    .setNotification(notification)
                    .build();

            FirebaseMessaging.getInstance().send(message);

            System.out.println("✅ Notificación enviada al token: " + request.getToken());
        } catch (Exception e) {
            System.err.println("❌ Error enviando notificación: " + e.getMessage());
        }
    }
}