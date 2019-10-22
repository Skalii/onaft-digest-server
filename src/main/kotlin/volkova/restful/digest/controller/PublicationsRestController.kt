package volkova.restful.digest.controller


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

import volkova.restful.digest.entity.Publication
import volkova.restful.digest.service.AuthorsService
import volkova.restful.digest.service.JournalsService
import volkova.restful.digest.service.KeywordsService
import volkova.restful.digest.service.PublicationsService


@RequestMapping(
        value = ["digest/api/publications"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE])
@RestController
//@CrossOrigin(origins = ["192.168.0.101:63342/digest/"])
class PublicationsRestController {

    @Autowired
    private lateinit var publicationsService: PublicationsService

    @Autowired
    private lateinit var journalsService: JournalsService

    @Autowired
    private lateinit var authorsService: AuthorsService

    @Autowired
    private lateinit var keywordsService: KeywordsService


    @GetMapping(value = ["search"])
    fun getSearch(
            @RequestParam(
                    value = "title",
                    required = false) title: String? = null,
            @RequestParam(
                    value = "date",
                    required = false) date: String? = null,
            @RequestParam(
                    value = "authors",
                    required = false) authors: String? = null,
            @RequestParam(
                    value = "keywords",
                    required = false) keywords: String? = null
    ) =
            publicationsService.getSearch(
                    title,
                    date,
                    keywords,
                    authors
            )


    @GetMapping(value = ["all"])
    fun getAll(
            @RequestParam(
                    value = "value",
                    required = false) value: String? = null
    ) =
            if (!value.isNullOrEmpty()) {
                when (value) {
                    "journals" -> journalsService.getAll()
                    "authors" -> authorsService.getAll()
                    "keywords" -> keywordsService.getAll()
                    else -> publicationsService.getAll()
                }
            } else {
                publicationsService.getAll()
            }

    @RequestMapping(
            value = ["one"],
            method = [RequestMethod.POST, RequestMethod.PUT])
    fun saveOne(
            httpMethod: HttpMethod,
            @RequestBody publication: Publication
    ) = publicationsService.save(
            httpMethod,
            publication
    )

    @DeleteMapping(value = ["one"])
    fun deleteOne(
            @RequestParam(
                    value = "id_publication",
                    required = false) idPublication: Int
    ) = publicationsService.delete(idPublication)

}
