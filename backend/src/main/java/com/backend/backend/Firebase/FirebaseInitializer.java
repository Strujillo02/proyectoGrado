package com.backend.backend.Firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseInitializer {

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        // Intentar obtener credenciales desde variable de entorno o desde el classpath
        InputStream credentialsStream = null;

        // 1) Si está definida GOOGLE_APPLICATION_CREDENTIALS, úsala
        String envPath = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
        if (envPath != null && !envPath.isBlank()) {
            try {
                credentialsStream = new FileInputStream(envPath);
            } catch (FileNotFoundException e) {
                // Continuar y probar con el classpath
            }
        }

        // 2) Fallback: cargar desde el classpath (src/main/resources -> en runtime queda en el classpath)
        if (credentialsStream == null) {
            ClassLoader cl = Thread.currentThread().getContextClassLoader();
            if (cl == null) {
                cl = FirebaseInitializer.class.getClassLoader();
            }
            credentialsStream = cl.getResourceAsStream("firebase-service-account.json");
            if (credentialsStream == null) {
                throw new FileNotFoundException(
                        "No se encontró 'firebase-service-account.json' en el classpath ni una ruta válida en GOOGLE_APPLICATION_CREDENTIALS"
                );
            }
        }

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(credentialsStream))
                .build();

        if (FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.initializeApp(options);
        }
        return FirebaseApp.getInstance();
    }

    @Bean
    public FirebaseMessaging firebaseMessaging(FirebaseApp firebaseApp) {
        // El parámetro asegura que FirebaseApp esté listo antes de crear este bean
        return FirebaseMessaging.getInstance(firebaseApp);
    }
}