package volkova.restful.digest.service


import org.springframework.http.HttpMethod

import volkova.restful.digest.entity.Keyword


interface KeywordsService {

    fun get(
            idKeyword: Int? = null,
            word: String? = null
    ): Keyword

    fun getAll(): MutableList<Keyword>

    fun save(
            httpMethod: HttpMethod,
            newKeyword: Keyword
    ): Keyword

    fun delete(idKeyword: Int): Keyword

}
