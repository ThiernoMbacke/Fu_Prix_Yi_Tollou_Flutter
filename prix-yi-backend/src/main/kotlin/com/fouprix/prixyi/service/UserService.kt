package com.fouprix.prixyi.service

import com.fouprix.prixyi.exception.UnauthorizedException
import com.fouprix.prixyi.model.dto.UserDto
import com.fouprix.prixyi.repository.UserRepository
import org.springframework.stereotype.Service
import java.util.*

@Service
class UserService(private val userRepository: UserRepository) {

    fun getById(userId: UUID): UserDto {
        val user = userRepository.findById(userId).orElseThrow { UnauthorizedException() }
        return UserDto.from(user)
    }

    fun updateProfile(userId: UUID, nom: String?) {
        val user = userRepository.findById(userId).orElseThrow { UnauthorizedException() }
        if (nom != null) user.nom = nom
        userRepository.save(user)
    }

    fun incrementContributions(userId: UUID) {
        userRepository.findById(userId).ifPresent { user ->
            user.contributionsCount = user.contributionsCount + 1
            userRepository.save(user)
        }
    }

    fun getStats(userId: UUID): Map<String, Any> {
        val user = userRepository.findById(userId).orElseThrow { UnauthorizedException() }
        return mapOf(
            "contributionsCount" to user.contributionsCount,
            "createdAt" to user.createdAt.toString(),
        )
    }
}
