package com.fouprix.prixyi.security

import com.fouprix.prixyi.service.JwtService
import com.fouprix.prixyi.service.UserDetailsServiceImpl
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtAuthenticationFilter(
    private val jwtService: JwtService,
    private val userDetailsService: UserDetailsServiceImpl,
) : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        val authHeader = request.getHeader("Authorization")
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response)
            return
        }
        val token = authHeader.substring(7)
        val userId = jwtService.parseUserId(token)
        if (userId != null && SecurityContextHolder.getContext().authentication == null) {
            if (jwtService.validateToken(token)) {
                val userDetails = userDetailsService.loadUserById(userId)
                val auth = UsernamePasswordAuthenticationToken(
                    userDetails,
                    null,
                    userDetails.authorities,
                ).apply {
                    details = WebAuthenticationDetailsSource().buildDetails(request)
                }
                SecurityContextHolder.getContext().authentication = auth
            }
        }
        filterChain.doFilter(request, response)
    }
}
