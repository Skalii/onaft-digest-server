package skalii.restful.onaftdigestserver.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import skalii.restful.onaftdigestserver.entity.Publication
import skalii.restful.onaftdigestserver.repository.PublicationsRepository
import skalii.restful.onaftdigestserver.service.PublicationsService


@Service
class PublicationsServiceImpl : PublicationsService {

    @Autowired
    private lateinit var publicationsRepository: PublicationsRepository

    override fun get(
            idPublication: Int?,
            type: String?,
            title: String?,
            abstract: String?,
            date: String?,
            doi: String?,
            keywords: String?,
            authors: String?
    ) =
            publicationsRepository.findSome(
                    idPublication,
                    title,
                    type,
                    abstract,
                    date,
                    doi,
                    keywords,
                    authors
            )

    override fun getAll(): MutableList<Publication> = publicationsRepository.findAll()

    override fun save(
            httpMethod: HttpMethod,
            newPublication: Publication
    ) =
            publicationsRepository.run {
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
            idPublication: Int?,
            doi: String?
    ) =
            publicationsRepository.run {
                remove(idPublication ?: findSome(doi = doi)[0].idPublication)
            }

}