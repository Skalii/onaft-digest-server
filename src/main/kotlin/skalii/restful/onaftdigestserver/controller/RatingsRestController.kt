package skalii.restful.onaftdigestserver.controller


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestMethod
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

import skalii.restful.onaftdigestserver.entity.Rating
import skalii.restful.onaftdigestserver.service.RatingsService


@RequestMapping(
        value = ["digest/api/ratings"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)
@RestController
class RatingsRestController {

    @Autowired
    private lateinit var ratingsService: RatingsService

    @GetMapping(value = ["one"])
    fun getOne(
            @RequestParam(
                    value = "id_rating",
                    required = false) idRating: Int
    ) =
            ratingsService.get(idRating)

    @GetMapping(value = ["all"])
    fun getAll() = ratingsService.getAll()

    @RequestMapping(
            value = ["one"],
            method = [RequestMethod.POST, RequestMethod.PUT])
    fun saveOne(
            httpMethod: HttpMethod,
            @RequestBody rating: Rating
    ) =
            ratingsService.save(
                    httpMethod,
                    rating
            )

    @DeleteMapping(value = ["one"])
    fun deleteOne(
            @RequestParam(
                    value = "id_rating",
                    required = false) idRating: Int
    ) =
            ratingsService.delete(idRating)

}
