package volkova.restful.digest.controller

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.*
import volkova.restful.digest.entity.Publication
import volkova.restful.digest.service.PublicationsService


@RequestMapping(
        value = ["api/publications"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)
@RestController
//@CrossOrigin(origins = ["192.168.0.101:63342/digest/"])
class PublicationsRestController {

    @Autowired
    private lateinit var publicationsService: PublicationsService

    @GetMapping(value = ["some"])
    fun getSome(
            @RequestParam(
                    value = "id_publication",
                    required = false) idPublication: Int? = null,
            @RequestParam(
                    value = "type",
                    required = false) type: String? = null,
            @RequestParam(
                    value = "abstract",
                    required = false) abstract: String? = null,
            @RequestParam(
                    value = "date",
                    required = false) date: String? = null,
            @RequestParam(
                    value = "doi",
                    required = false) doi: String? = null,
            @RequestParam(
                    value = "title",
                    required = false) title: String? = null
    ) = publicationsService.get(
            idPublication,
            type,
            abstract,
            date,
            doi,
            title
    )

    @GetMapping(value = ["all"])
    fun getAll() = publicationsService.getAll()

    @RequestMapping(
            value = ["one"],
            method = [RequestMethod.POST, RequestMethod.PUT])
    fun saveOne(
            httpMethod: HttpMethod,
            @RequestBody author: Publication
    ) = publicationsService.save(
            httpMethod,
            author
    )

    @DeleteMapping(value = ["one"])
    fun deleteOne(
            @RequestParam(
                    value = "id_publication",
                    required = false) idPublication: Int
    ) = publicationsService.delete(idPublication)

}
