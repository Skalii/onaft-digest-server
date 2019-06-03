package volkova.restful.digest.service

import org.springframework.http.HttpMethod
import volkova.restful.digest.entity.Publication

interface PublicationsService {


    fun get(
            idPublication: Int? = null,
            type: String? = null,
            abstract: String? = null,
            date: String? = null,
            doi: String? = null,
            title: String? = null
    ): MutableList<Publication>

    fun getAll(): MutableList<Publication>

    fun save(
            httpMethod: HttpMethod,
            newPublication: Publication
    ): Publication

    fun delete(idPublication: Int): Publication

}