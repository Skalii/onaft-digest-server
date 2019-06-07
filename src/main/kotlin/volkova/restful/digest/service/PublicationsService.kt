package volkova.restful.digest.service


import org.springframework.http.HttpMethod

import volkova.restful.digest.entity.Publication


interface PublicationsService {


    fun get(
            title: String? = null,
            date: String? = null,
            keywords: String? = null,
            authors: String? = null
    ): MutableList<Publication>

    fun getAll(): MutableList<Publication>

    fun save(
            httpMethod: HttpMethod,
            newPublication: Publication
    ): Publication

    fun delete(idPublication: Int): Publication

}