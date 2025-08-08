package com.backend.backend.controllers;

import com.backend.backend.Authentication.JwtService;
import com.backend.backend.models.Usuario;
import com.backend.backend.repositories.UsuarioRepository;
import com.backend.backend.services.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.Collections;

@RestController
@RequestMapping("/user/v1")
@RequiredArgsConstructor
@Slf4j
public class UsuarioController {

    @Autowired
    UsuarioService usuarioService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @PostMapping("create")
    public Usuario guardarUsuario(@RequestBody Usuario usuario) {
        return usuarioService.guardarUsuario(usuario);
    }


    @GetMapping("get")
    public ArrayList<Usuario> obtenerUsuarios() {
        return usuarioService.obtenerUsuarios();
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("hasRole('Administrador')")
    public String eliminarUsuario(@PathVariable int id){
        usuarioService.eliminarUsuario(id);
        return "Usuario eliminado correctamente";
    }

    @PutMapping("/update")
    public Usuario actualizarUsuario(@RequestBody Usuario usuario) {
        log.info("Actualizando usuario con ID: {}", usuario.getId());
        return usuarioService.guardarUsuario(usuario);
    }

    @GetMapping("/getIdentificacion/{id}")
    @PreAuthorize("hasRole('Administrador')")
    public ResponseEntity<?> consultarIdentificacion(@PathVariable String id) {
        try {
            Usuario usuario = usuarioRepository.findByIdentificacion(id);
            if (usuario == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Collections.singletonMap("mensaje", "Usuario no encontrado"));
            }
            return ResponseEntity.ok(usuario);
        } catch (Exception e) {

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Collections.singletonMap("mensaje", "Error al consultar el usuario"));
        }
    }
}
