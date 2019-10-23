package skalii.restful.onaftdigestserver.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import skalii.restful.onaftdigestserver.entity.Author
import skalii.restful.onaftdigestserver.repository.AuthorsRepository
import skalii.restful.onaftdigestserver.service.AuthorsService


@Service
class AuthorsServiceImpl : AuthorsService {

    @Autowired
    private lateinit var authorsRepository: AuthorsRepository

    override fun get(
            idAuthor: Int?,
            fullName: String?
    ) =
            authorsRepository.findSome(
                    idAuthor,
                    fullName
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

    override fun delete(
            idAuthor: Int?,
            fullName: String?
    ) =
            authorsRepository.run {
                remove(idAuthor ?: findSome(fullName = fullName)[0].idAuthor)
            }
}
