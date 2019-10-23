package skalii.restful.onaftdigestserver.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import skalii.restful.onaftdigestserver.entity.Keyword
import skalii.restful.onaftdigestserver.repository.KeywordsRepository
import skalii.restful.onaftdigestserver.service.KeywordsService


@Service
class KeywordsServiceImpl : KeywordsService {

    @Autowired
    private lateinit var keywordsRepository: KeywordsRepository

    override fun get(
            idKeyword: Int?,
            word: String?
    ) = keywordsRepository.findSome(
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
                findSome()[0]
            }
        }
    }

    override fun delete(
            idKeyword: Int?,
            word: String?
    ) =
            keywordsRepository.run {
                remove(idKeyword ?: findSome(word = word)[0].idKeyword)
            }
}