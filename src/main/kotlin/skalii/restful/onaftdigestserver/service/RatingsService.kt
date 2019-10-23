package skalii.restful.onaftdigestserver.service


import org.springframework.http.HttpMethod

import skalii.restful.onaftdigestserver.entity.Rating


interface RatingsService {

    fun get(idRating: Int? = null): Rating

    fun getAll(): MutableList<Rating>

    fun save(
            httpMethod: HttpMethod,
            newRating: Rating
    ): Rating

    fun delete(idRating: Int): Rating


}
