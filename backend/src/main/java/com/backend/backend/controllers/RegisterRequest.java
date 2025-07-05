package com.backend.backend.controllers;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {

    String nombre;
    String email;
    String identificacion;
    String tipo_identificacion;
    String contrasena;
    String tipo_usuario;


}
