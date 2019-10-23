package skalii.restful.onaftdigestserver.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import skalii.restful.onaftdigestserver.entity.Rating
import skalii.restful.onaftdigestserver.repository.RatingsRepository
import skalii.restful.onaftdigestserver.service.RatingsService


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