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

import skalii.restful.onaftdigestserver.entity.Keyword
import skalii.restful.onaftdigestserver.service.KeywordsService

@RequestMapping(
        value = ["digest/api/keywords"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)

@RestController
class KeywordsRestController {

    @Autowired
    private lateinit var keywordsService: KeywordsService

    @GetMapping(value = ["one"])
    fun getOne(
            @RequestParam(
                    value = "id_keyword",
                    required = false) idAuthor: Int? = null,
            @RequestParam(
                    value = "word",
                    required = false) word: String? = null
    ) =
            keywordsService.get(
                    idAuthor,
                    word
            )

    @GetMapping(value = ["all"])
    fun getAll() = keywordsService.getAll()

    @RequestMapping(
            value = ["one"],
            method = [RequestMethod.POST, RequestMethod.PUT])
    fun saveOne(
            httpMethod: HttpMethod,
            @RequestBody keyword: Keyword
    ) =
            keywordsService.save(
                    httpMethod,
                    keyword
            )

    @DeleteMapping(value = ["one"])
    fun deleteOne(
            @RequestParam(
                    value = "id_keyword",
                    required = false) idKeyword: Int? = null,
            @RequestParam(
                    value = "word",
                    required = false) word: String? = null
    ) =
            keywordsService.delete(
                    idKeyword,
                    word
            )

}
