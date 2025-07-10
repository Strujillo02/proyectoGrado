package com.backend.backend.Authentication;

import com.backend.backend.models.Usuario;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getIdentificacion(), request.getContrasena())
        );

        // Obtenemos el usuario desde el repositorio
        Usuario usuario = userRepository.findByIdentificacion(request.getIdentificacion())
                .orElseThrow(() -> new RuntimeException("User not found"));

        String token = jwtService.getToken(usuario);

        return AuthResponse.builder()
                .token(token)
                .user(usuario) // Incluimos el usuario en la respuesta
                .build();
    }

    public AuthResponse register(RegisterRequest request) {
        Usuario usuario = Usuario.builder()
                .identificacion(request.getIdentificacion())
                .nombre(request.getNombre())
                .email(request.getEmail())
                .contrasena(passwordEncoder.encode(request.getContrasena()))
                .tipo_identificacion(request.getTipo_identificacion())
                .tipo_usuario(request.getTipo_usuario())
                .build();

        userRepository.save(usuario);

        String token = jwtService.getToken(usuario);

        return AuthResponse.builder()
                .token(token)
                .user(usuario) // Incluimos el usuario en la respuesta
                .build();
    }
}