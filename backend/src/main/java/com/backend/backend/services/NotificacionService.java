package com.backend.backend.services;

import com.backend.backend.DTO.PushNotificationRequest;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final FirebaseMessaging firebaseMessaging;

    // Envía notificación con bloque Notification (útil para pruebas simples)
    public String sendPushNotificationToToken(PushNotificationRequest request) throws Exception {
        Notification notification = Notification.builder()
                .setTitle(request.getTitle())
                .setBody(request.getBody())
                .build();

        Message message = Message.builder()
                .setToken(request.getToken())
                .setNotification(notification)
                .build();

        String messageId = firebaseMessaging.send(message);
        System.out.println("✅ Notificación enviada. messageId=" + messageId);
        return messageId;
    }

    // Envía mensaje SOLO CON DATA (sin Notification) para que el cliente Flutter pinte la notificación con botones
    public String sendDataToToken(String token, Map<String, String> data) throws Exception {
        Message message = Message.builder()
                .setToken(token)
                .putAllData(data)
                .build();

        String messageId = firebaseMessaging.send(message);
        System.out.println("✅ Data-Only enviada. messageId=" + messageId + ", data=" + data);
        return messageId;
    }
}