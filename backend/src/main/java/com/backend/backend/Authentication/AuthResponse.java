package com.backend.backend.authentication;


import com.backend.backend.models.Usuario;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    String token;
    Usuario user;
}
