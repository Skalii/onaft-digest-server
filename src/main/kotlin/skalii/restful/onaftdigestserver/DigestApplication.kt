package skalii.restful.onaftdigestserver


import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication


@SpringBootApplication(scanBasePackages = ["skalii.restful.onaftdigestserver"])
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