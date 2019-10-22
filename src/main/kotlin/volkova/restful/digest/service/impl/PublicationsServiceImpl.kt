package volkova.restful.digest.service.impl


import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service

import volkova.restful.digest.entity.Publication
import volkova.restful.digest.repository.PublicationsRepository
import volkova.restful.digest.service.PublicationsService


@Service
class PublicationsServiceImpl : PublicationsService {

    @Autowired
    private lateinit var publicationsRepository: PublicationsRepository

    override fun getSearch(
            title: String?,
            date: String?,
            keywords: String?,
            authors: String?
    ) =
            publicationsRepository.findSearch(
                    title,
                    date,
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
                        findSearch()[0]
                    }
                }
            }

    override fun delete(idPublication: Int) = publicationsRepository.remove(idPublication)

}