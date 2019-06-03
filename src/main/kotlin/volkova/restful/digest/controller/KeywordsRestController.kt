/*
package volkova.restful.digest.controller

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.*
import volkova.restful.digest.entity.Keyword
import volkova.restful.digest.service.KeywordsService

@RequestMapping(
        value = ["api/keywords"],
        produces = [MediaType.APPLICATION_JSON_UTF8_VALUE]
)

@RestController
class KeywordsRestController {

    @Autowired
    private lateinit var keywordsService: KeywordsService

    @GetMapping(value = ["one"])
    fun getOne(@RequestParam(value = "id_keyword") idAuthor: Int) = keywordsService.get(idAuthor)

    @GetMapping(value = ["all"])
    fun getAll() = keywordsService.getAll()

    @PostMapping(value = ["one"])
    fun saveOne(@RequestBody keyword: Keyword) = keywordsService.save(keyword)

}
*/
