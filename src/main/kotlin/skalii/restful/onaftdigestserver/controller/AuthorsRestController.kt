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

import skalii.restful.onaftdigestserver.entity.Author
import skalii.restful.onaftdigestserver.service.AuthorsService


@RequestMapping(
        value = ["digest/api/authors"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)
@RestController
class AuthorsRestController {

    @Autowired
    private lateinit var authorsService: AuthorsService

    @GetMapping(value = ["one"])
    fun getOne(
            @RequestParam(
                    value = "id_author",
                    required = false
            ) idAuthor: Int? = null,
            @RequestParam(
                    value = "full_name",
                    required = false
            ) fullName: String? = null
    ) =
            authorsService.get(
                    idAuthor,
                    fullName
            )

    @GetMapping(value = ["all"])
    fun getAll() = authorsService.getAll()

    @RequestMapping(
            value = ["one"],
            method = [RequestMethod.POST, RequestMethod.PUT])
    fun saveOne(
            httpMethod: HttpMethod,
            @RequestBody author: Author
    ) =
            authorsService.save(
                    httpMethod,
                    author
            )

    @DeleteMapping(value = ["one"])
    fun deleteOne(
            @RequestParam(
                    value = "id_author",
                    required = false) idAuthor: Int? = null,
            @RequestParam(
                    value = "full_name",
                    required = false) fullName: String? = null
    ) =
            authorsService.delete(
                    idAuthor,
                    fullName
            )

}
