/*
package volkova.restful.digest.controller

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.*
import volkova.restful.digest.entity.Author
import volkova.restful.digest.service.AuthorsService


@RequestMapping(
        value = ["api/authors"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)
@RestController
class AuthorsRestController {

    @Autowired
    private lateinit var authorsService: AuthorsService

    @GetMapping(value = ["one"])
    fun getOne(@RequestParam(value = "id_author") idAuthor: Int) = authorsService.get(idAuthor)

    @GetMapping(value = ["all"])
    fun getAll() = authorsService.getAll()

    @PostMapping(value = ["one"])
    fun saveOne(@RequestBody author: Author) = authorsService.save(author)

}*/
