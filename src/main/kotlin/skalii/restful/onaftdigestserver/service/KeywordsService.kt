package skalii.restful.onaftdigestserver.service


import org.springframework.http.HttpMethod

import skalii.restful.onaftdigestserver.entity.Keyword


interface KeywordsService {

    fun get(
            idKeyword: Int? = null,
            word: String? = null
    ): MutableList<Keyword>

    fun getAll(): MutableList<Keyword>

    fun save(
            httpMethod: HttpMethod,
            newKeyword: Keyword
    ): Keyword

    fun delete(
            idKeyword: Int? = null,
            word: String? = null
    ): Keyword

}