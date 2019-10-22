package volkova.restful.digest.service


import org.springframework.http.HttpMethod

import volkova.restful.digest.entity.Journal


interface JournalsService {

    fun get(
            idJournal: Int? = null,
            title: String? = null,
            titleEn: String? = null
    ): MutableList<Journal>

    fun getAll(): MutableList<Journal>

    fun save(
            httpMethod: HttpMethod,
            newPublication: Journal
    ): Journal

    fun delete(idJournal: Int): Journal

}