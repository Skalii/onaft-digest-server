package volkova.restful.digest.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import volkova.restful.digest.entity.Journal
import volkova.restful.digest.repository.JournalsRepository
import volkova.restful.digest.service.JournalsService


@Service
class JournalsServiceImpl : JournalsService {

    @Autowired
    private lateinit var journalsRepository: JournalsRepository

    override fun get(
            idJournal: Int?,
            title: String?,
            titleEn: String?
    ) =
            journalsRepository.findSome(
                    idJournal,
                    title,
                    titleEn
            )

    override fun getAll() = journalsRepository.findAll()

    override fun save(
            httpMethod: HttpMethod,
            newPublication: Journal
    ) =
            journalsRepository.run {
                when {
                    httpMethod.matches("POST") -> {
                        add(newPublication)
                    }
                    httpMethod.matches("PUT") -> {
                        set(newPublication)
                    }
                    else -> {
                        findSome()[0]
                    }
                }
            }

    override fun delete(idJournal: Int) = journalsRepository.remove(idJournal)

}