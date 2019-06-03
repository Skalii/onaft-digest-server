/*
package volkova.restful.digest.service.impl

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import volkova.restful.digest.entity.Author
import volkova.restful.digest.repository.AuthorsRepository
import volkova.restful.digest.service.AuthorsService

@Service
class AuthorsServiceImpl : AuthorsService {

    @Autowired
    private lateinit var authorsRepository: AuthorsRepository

    override fun get(idAuthor: Int) = authorsRepository.getOne(idAuthor)

    override fun getAll(): MutableList<Author> = authorsRepository.findAll()

    override fun save(
            */
/*httpMethod: HttpMethod, *//*

            newAuthor: Author
    ) = authorsRepository.saveAndFlush(newAuthor)

    override fun delete(idAuthor: Int) = authorsRepository.deleteById(idAuthor)
}*/
