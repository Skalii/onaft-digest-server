/*
package volkova.restful.digest.controller

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.*
import volkova.restful.digest.entity.Rating
import volkova.restful.digest.service.RatingsService


@RequestMapping(
        value = ["api/ratings"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)
@RestController
class RatingsRestController {

    @Autowired
    private lateinit var ratingsService: RatingsService

    @GetMapping(value = ["one"])
    fun getOne(@RequestParam(value = "id_rating") idRating: Int) = ratingsService.get(idRating)

    @GetMapping(value = ["all"])
    fun getAll() = ratingsService.getAll()

    @PostMapping(value = ["one"])
    fun saveOne(@RequestBody rating: Rating) = ratingsService.save(rating)

}*/
