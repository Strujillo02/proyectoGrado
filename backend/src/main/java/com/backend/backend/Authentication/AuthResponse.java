package com.backend.backend.Authentication;


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
