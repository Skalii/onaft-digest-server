package volkova.restful.digest.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import volkova.restful.digest.entity.Keyword
import volkova.restful.digest.repository.KeywordsRepository
import volkova.restful.digest.service.KeywordsService


@Service
class KeywordsServiceImpl : KeywordsService {

    @Autowired
    private lateinit var keywordsRepository: KeywordsRepository

    override fun get(
            idKeyword: Int?,
            word: String?
    ) = keywordsRepository.find(
            idKeyword,
            word
    )

    override fun getAll(): MutableList<Keyword> = keywordsRepository.findAll()

    override fun save(
            httpMethod: HttpMethod,
            newKeyword: Keyword
    ) = keywordsRepository.run {
        when {
            httpMethod.matches("POST") -> {
                add(newKeyword)
            }
            httpMethod.matches("PUT") -> {
                set(newKeyword)
            }
            else -> {
                find()
            }
        }
    }

    override fun delete(idKeyword: Int) = keywordsRepository.remove(idKeyword)
}
