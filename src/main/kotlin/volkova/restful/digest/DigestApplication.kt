package volkova.restful.digest

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.context.annotation.Bean
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource
import java.util.*


@SpringBootApplication(scanBasePackages = ["volkova.restful.digest"])
class DigestApplication

fun main(args: Array<String>) {
	runApplication<DigestApplication>(*args)
}

/*
@Bean
fun corsConfigurationSource(): CorsConfigurationSource {
	val configuration = CorsConfiguration()
	configuration.allowedOrigins = Arrays.asList("*")
	configuration.allowedMethods = Arrays.asList("GET", "POST", "OPTIONS", "DELETE", "PUT", "PATCH")
	configuration.allowedHeaders = Arrays.asList("X-Requested-With", "Origin", "Content-Type", "Accept", "Authorization")
	configuration.allowCredentials = true
	val source = UrlBasedCorsConfigurationSource()
	source.registerCorsConfiguration("/**", configuration)
	return source
}*/