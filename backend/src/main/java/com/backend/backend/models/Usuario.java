package com.backend.backend.models;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "usuarios")
public class Usuario  implements UserDetails {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    Integer id;

    @Column(name = "nombre", length = 45)
    String nombre;

    @Lob
    @Column(name = "telefono")
    String telefono;

    @Column(name = "email", length = 45)
    String email;

    @Column(name = "identificacion", length = 45)
    String identificacion;

    @Column(name = "genero", length = 45)
    String genero;

    @Column(name = "estado", length = 45)
    String estado;

    @Column(name = "tipo_identificacion", length = 45)
    String tipo_identificacion;

    @Column(name = "contrasena")
    String contrasena;

    @Column(name = "tipo_usuario", length = 50)
    String tipo_usuario;


    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority(tipo_usuario));
    }

    @Override
    public String getPassword() {
        return this.contrasena;
    }

    @Override
    public String getUsername() {
        return this.identificacion;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
