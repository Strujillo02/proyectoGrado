package com.backend.backend.DTO;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
public class PushNotificationRequest {
    private String title;
    private String body;
    private String token;
}
