package volkova.restful.digest.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import volkova.restful.digest.entity.Rating
import volkova.restful.digest.repository.RatingsRepository
import volkova.restful.digest.service.RatingsService


@Service
class RatingsServiceImpl : RatingsService {

    @Autowired
    private lateinit var ratingsRepository: RatingsRepository

    override fun get(idRating: Int?) = ratingsRepository.find(idRating)

    override fun getAll() = ratingsRepository.findAll()

    override fun save(
            httpMethod: HttpMethod,
            newRating: Rating
    ) =
            ratingsRepository.run {
                when {
                    httpMethod.matches("POST") -> {
                        add(newRating)
                    }
                    httpMethod.matches("PUT") -> {
                        set(newRating)
                    }
                    else -> {
                        find()
                    }
                }
            }

    override fun delete(idRating: Int) = ratingsRepository.remove(idRating)

}