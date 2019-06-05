package volkova.restful.digest.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import volkova.restful.digest.entity.Author
import volkova.restful.digest.repository.AuthorsRepository
import volkova.restful.digest.service.AuthorsService


@Service
class AuthorsServiceImpl : AuthorsService {

    @Autowired
    private lateinit var authorsRepository: AuthorsRepository

    override fun get(
            idAuthor: Int?,
            firstName: String?,
            middleName: String?,
            surname: String?
    ) =
            authorsRepository.findSome(
                    idAuthor,
                    firstName,
                    middleName,
                    surname
            )

    override fun getAll(): MutableList<Author> = authorsRepository.findAll()

    override fun save(
            httpMethod: HttpMethod,
            newAuthor: Author
    ) =
            authorsRepository.run {
                when {
                    httpMethod.matches("POST") -> {
                        add(newAuthor)
                    }
                    httpMethod.matches("PUT") -> {
                        set(newAuthor)
                    }
                    else -> {
                        findSome()[0]
                    }
                }
            }

    override fun delete(idAuthor: Int) = authorsRepository.remove(idAuthor)
}
