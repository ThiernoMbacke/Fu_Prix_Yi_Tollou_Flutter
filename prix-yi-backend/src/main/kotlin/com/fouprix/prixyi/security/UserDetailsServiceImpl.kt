package com.fouprix.prixyi.service

import com.fouprix.prixyi.model.entity.User
import com.fouprix.prixyi.repository.UserRepository
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.stereotype.Service
import java.util.*

@Service
class UserDetailsServiceImpl(private val userRepository: UserRepository) : UserDetailsService {

    fun loadUserById(id: UUID): UserDetails = userRepository.findById(id)
        .map { toUserDetails(it) }
        .orElseThrow { UsernameNotFoundException("User not found: $id") }

    override fun loadUserByUsername(username: String?): UserDetails {
        if (username == null) throw UsernameNotFoundException("Username null")
        return userRepository.findByPhone(username)
            .map { toUserDetails(it) }
            .orElseThrow { UsernameNotFoundException("User not found: $username") }
    }

    private fun toUserDetails(user: User): UserDetails =
        org.springframework.security.core.userdetails.User(
            user.id.toString(),
            "",
            user.isActive,
            true,
            true,
            true,
            listOf(SimpleGrantedAuthority("ROLE_${user.role.name}")),
        )
}
