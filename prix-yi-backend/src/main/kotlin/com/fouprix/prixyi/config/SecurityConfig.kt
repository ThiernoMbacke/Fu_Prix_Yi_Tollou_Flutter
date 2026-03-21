package com.fouprix.prixyi.config

import com.fouprix.prixyi.security.JwtAuthenticationFilter
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.HttpMethod
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource

@Configuration
@EnableWebSecurity
class SecurityConfig(
    private val jwtAuthFilter: JwtAuthenticationFilter,
) {

    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .csrf { it.disable() }
            .cors { it.configurationSource(corsConfigurationSource()) }
            .sessionManagement {
                it.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            }
            .authorizeHttpRequests { auth ->
                auth
                    // Preflight navigateur (Flutter web, etc.) — doit répondre 200 avec en-têtes CORS
                    .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                    // Racine : page JSON utile si ouverture dans Chrome (évite confusion avec 403 Whitelabel)
                    .requestMatchers(HttpMethod.GET, "/", "/api").permitAll()
                    .requestMatchers("/api/auth/**").permitAll()
                    .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                    .requestMatchers("/api/**").authenticated()
                    .anyRequest().permitAll()
            }
            .exceptionHandling { ex ->
                // Sans cela, un navigateur sur /api/users/me sans JWT reçoit souvent 403 + page HTML « Whitelabel ».
                ex.authenticationEntryPoint { _, response, _ ->
                    response.status = HttpServletResponse.SC_UNAUTHORIZED
                    response.characterEncoding = "UTF-8"
                    response.contentType = "application/json;charset=UTF-8"
                    response.writer.write(
                        """{"message":"Authentification requise : en-tête Authorization: Bearer <token>","status":401}""",
                    )
                }
                ex.accessDeniedHandler { _, response, _ ->
                    response.status = HttpServletResponse.SC_FORBIDDEN
                    response.characterEncoding = "UTF-8"
                    response.contentType = "application/json;charset=UTF-8"
                    response.writer.write("""{"message":"Accès refusé","status":403}""")
                }
            }
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter::class.java)
        return http.build()
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val config = CorsConfiguration().apply {
            // Avec `true`, le navigateur refuse `Allow-Origin: *` → preflight sans ACAO (erreur CORS).
            // L’app mobile/web envoie le JWT en header Authorization, pas en cookie : pas besoin de credentials CORS.
            allowCredentials = false
            addAllowedOriginPattern("*")
            addAllowedHeader("*")
            addAllowedMethod("*")
            maxAge = 3600
        }
        return UrlBasedCorsConfigurationSource().apply {
            registerCorsConfiguration("/**", config)
        }
    }
}
