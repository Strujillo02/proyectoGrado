package com.backend.backend.services;

import com.backend.backend.models.Usuario;
import com.backend.backend.repositories.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

@Service
public class UsuarioService {
    @Autowired
    UsuarioRepository usuarioRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;

    public ArrayList<Usuario> obtenerUsuarios(){

        return  (ArrayList<Usuario>) usuarioRepository.findAll();
    }

    public Usuario guardarUsuario(Usuario usuario) {
        // Solo encripta si la contraseña no es null ni vacía
        if (usuario.getContrasena() != null && !usuario.getContrasena().trim().isEmpty()) {
            usuario.setContrasena(passwordEncoder.encode(usuario.getContrasena()));
        } else {
            // Si no se proporciona nueva contraseña, mantener la existente
            Usuario existingUser = usuarioRepository.findById(usuario.getId())
                    .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
            usuario.setContrasena(existingUser.getContrasena());
        }

        return usuarioRepository.save(usuario);
    }

    public void eliminarUsuario(int id) {
        usuarioRepository.deleteById(id);
    }

    public Usuario consultarIdentificacion(String id) {
        return usuarioRepository.findByIdentificacion(id);
    }

}