package com.backend.backend.Authentication;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;



//@EnableMethodSecurity
@EnableMethodSecurity(prePostEnabled = true)

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final AuthenticationProvider authProvider;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/auth/**").permitAll()

                        // Usuarios
                        .requestMatchers("/user/v1/delete/**").hasAuthority("Administrador")
                        .requestMatchers("/user/v1/update").authenticated()

                        // Especialidad
                        .requestMatchers("/especialidad/v1/create").hasAuthority("Administrador")
                        .requestMatchers("/especialidad/v1/delete/**").hasAuthority("Administrador")
                        .requestMatchers("/especialidad/v1/update").hasAuthority("Administrador")

                        // Médico
                        .requestMatchers("/medico/v1/create").hasAuthority("Administrador")
                        .requestMatchers("/medico/v1/update").hasAuthority("Administrador")
                        .requestMatchers("/medico/v1/delete/**").hasAuthority("Administrador")
                        .requestMatchers("/medico/v1/getValorConsulta/**")
                        .hasAnyAuthority("Administrador","ROLE_Administrador", "Medico", "ROLE_Medico", "Paciente", "ROLE_Paciente")

                        // Citas y notificaciones
                        .requestMatchers("/cita/**").hasAnyAuthority("Administrador","ROLE_Administrador", "Medico", "ROLE_Medico", "Paciente", "ROLE_Paciente")
                        .requestMatchers("/notificaciones/**").hasAnyAuthority("Administrador","Paciente","Medico")

                        .anyRequest().authenticated()
                )
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authenticationProvider(authProvider)
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }
}

