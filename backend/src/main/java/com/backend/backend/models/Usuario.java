package com.backend.backend.models;


import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
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
    @JsonIgnore // Esto evitará que se serialize la contraseña
    String contrasena;

    @JsonProperty("contrasena")
    public void parseContrasena(String contrasena) {
        this.contrasena = contrasena;
    }

    @Column(name = "tipo_usuario", length = 50)
    String tipo_usuario;

    @Column(name = "direccion", length = 100)
    String direccion;

    @Column(name = "token_dispositivo")
    String token_dispositivo;

    @JsonIgnore
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + tipo_usuario));
    }

    @Override
    public String getPassword() {
        return this.contrasena;
    }
    @JsonIgnore
    @Override
    public String getUsername() {
        return this.identificacion;
    }

    @JsonIgnore
    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @JsonIgnore
    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @JsonIgnore
    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @JsonIgnore
    @Override
    public boolean isEnabled() {
        return true;
    }
}

