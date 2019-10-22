package volkova.restful.digest.service


import org.springframework.http.HttpMethod

import volkova.restful.digest.entity.Author


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

    fun delete(idAuthor: Int): Author

}