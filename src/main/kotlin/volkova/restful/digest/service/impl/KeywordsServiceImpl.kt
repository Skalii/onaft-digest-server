/*
package volkova.restful.digest.service.impl

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import volkova.restful.digest.entity.Keyword
import volkova.restful.digest.repository.KeywordsRepository
import volkova.restful.digest.service.KeywordsService

@Service
class KeywordsServiceImpl : KeywordsService {

    @Autowired
    private lateinit var keywordsRepository: KeywordsRepository

    override fun get(idKeyword: Int) = keywordsRepository.getOne(idKeyword)

    override fun getAll(): MutableList<Keyword> = keywordsRepository.findAll()

    override fun save(

httpMethod: HttpMethod,

            newKeyword: Keyword
    ) = keywordsRepository.saveAndFlush(newKeyword)

    override fun delete(idKeyword: Int) = keywordsRepository.deleteById(idKeyword)
}*/
