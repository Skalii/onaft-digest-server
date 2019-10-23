package skalii.restful.onaftdigestserver.service


import org.springframework.http.HttpMethod

import skalii.restful.onaftdigestserver.entity.Publication


interface PublicationsService {


    fun get(
            idPublication: Int? = null,
            type: String? = null,
            title: String? = null,
            abstract: String? = null,
            date: String? = null,
            doi: String? = null,
            keywords: String? = null,
            authors: String? = null
    ): MutableList<Publication>

    fun getAll(): MutableList<Publication>

    fun save(
            httpMethod: HttpMethod,
            newPublication: Publication
    ): Publication

    fun delete(
            idPublication: Int? = null,
            doi: String? = null
    ): Publication

}