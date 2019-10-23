package skalii.restful.onaftdigestserver.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import skalii.restful.onaftdigestserver.entity.Journal
import skalii.restful.onaftdigestserver.repository.JournalsRepository
import skalii.restful.onaftdigestserver.service.JournalsService


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

    override fun delete(
            idJournal: Int?,
            title: String?,
            titleEn: String?
    ) =
            journalsRepository.run {
                remove(
                        idJournal ?: findSome(
                                title = title,
                                titleEn = titleEn
                        )[0].idJournal
                )
            }

}