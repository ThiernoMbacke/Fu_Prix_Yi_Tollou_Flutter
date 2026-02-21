package com.fouprix.prixyi.service

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.stereotype.Service
import org.springframework.web.client.RestTemplate
import java.net.URI

@Service
class SmsService(
    @Value("\${sms.provider:infobip}") private val provider: String,
    @Value("\${sms.infobip.api-key:}") private val infobipApiKey: String,
    @Value("\${sms.infobip.base-url:https://api.infobip.com}") private val infobipBaseUrl: String,
    @Value("\${sms.orange.client-id:}") private val orangeClientId: String,
    @Value("\${sms.orange.client-secret:}") private val orangeClientSecret: String,
    @Value("\${sms.orange.sender-number:}") private val orangeSender: String,
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val rest = RestTemplate()

    fun sendOtp(phoneNumber: String, code: String): Boolean {
        val message = "Votre code Fou Prix: $code. Valide 5 min. Ne partagez pas."
        return when (provider.lowercase()) {
            "infobip" -> sendInfobip(phoneNumber, message)
            "orange" -> sendOrange(phoneNumber, message)
            else -> {
                log.warn("SMS provider '$provider' inconnu; envoi simulé pour $phoneNumber")
                log.info("OTP pour $phoneNumber: $code")
                true
            }
        }
    }

    private fun sendInfobip(to: String, text: String): Boolean {
        if (infobipApiKey.isBlank()) {
            log.warn("INFOBIP_API_KEY non configuré; SMS simulé: $to -> $text")
            return true
        }
        return try {
            val url = "$infobipBaseUrl/sms/2/text/single"
            val headers = HttpHeaders().apply {
                set("Authorization", "App $infobipApiKey")
                contentType = MediaType.APPLICATION_JSON
            }
            val body = mapOf(
                "from" to "FouPrix",
                "to" to to.replace("+", ""),
                "text" to text,
            )
            val entity = HttpEntity(body, headers)
            val resp = rest.postForEntity(URI.create(url), entity, String::class.java)
            resp.statusCode.is2xxSuccessful
        } catch (e: Exception) {
            log.error("Erreur envoi Infobip: ${e.message}")
            false
        }
    }

    private fun sendOrange(to: String, text: String): Boolean {
        if (orangeClientId.isBlank() || orangeClientSecret.isBlank()) {
            log.warn("Orange SMS non configuré; SMS simulé: $to -> $text")
            return true
        }
        // TODO: implémenter OAuth2 Orange + API SMS si besoin
        log.info("Orange SMS (stub): $to -> $text")
        return true
    }
}
