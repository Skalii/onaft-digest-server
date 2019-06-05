package volkova.restful.digest.service


import org.springframework.http.HttpMethod

import volkova.restful.digest.entity.Rating


interface RatingsService {

    fun get(idRating: Int? = null): Rating

    fun getAll(): MutableList<Rating>

    fun save(
            httpMethod: HttpMethod,
            newRating: Rating
    ): Rating

    fun delete(idRating: Int): Rating


}
