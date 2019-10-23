package skalii.restful.onaftdigestserver.service


import org.springframework.http.HttpMethod

import skalii.restful.onaftdigestserver.entity.Author


interface AuthorsService {

    fun get(
            idAuthor: Int? = null,
            fullName: String? = null
    ): MutableList<Author>

    fun getAll(): MutableList<Author>

    fun save(
            httpMethod: HttpMethod,
            newAuthor: Author
    ): Author

    fun delete(
            idAuthor: Int? = null,
            fullName: String? = null
    ): Author

}