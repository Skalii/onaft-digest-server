package skalii.restful.onaftdigestserver.repository


import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as EmptyRepository
import org.springframework.stereotype.Repository
import org.springframework.web.bind.annotation.CrossOrigin

import skalii.restful.onaftdigestserver.entity.Publication


@CrossOrigin
@Repository
interface PublicationsRepository : EmptyRepository<Publication, Int> {

    @Query(value = """select (publication_search(
                          cast_int(:id_publication),
                          cast_text(:title),
                          cast_type(:type),
                          cast_text(:abstract),
                          cast_text(:date),
                          cast_text(:doi),
                          cast_text(:authors),
                          cast_text(:keywords)
                      )).*""",
            nativeQuery = true)
    fun findSome(
            @Param("id_publication") idPublication: Int? = null,
            @Param("title") title: String? = null,
            @Param("type") type: String? = null,
            @Param("abstract") abstract: String? = null,
            @Param("date") date: String? = null,
            @Param("doi") doi: String? = null,
            @Param("keywords") keywords: String? = null,
            @Param("authors") authors: String? = null
    ): MutableList<Publication>

    @Query(value = """select (publication_search(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Publication>

    @Query(value = """select (publication_insert(
                          cast_text(:#{#publication.title}),
                          cast_type(:#{#publication.type.value}),
                          cast_text(:#{#publication.abstract}),
                          cast(:#{#publication.date.toString()} as date),
                          cast_text(:#{#publication.doi}),
                          cast_int(:#{#publication.rating.idRating}),
                          cast_int(:#{#publication.journal.idJournal})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("publication") newPublication: Publication): Publication

    @Query(value = """select (publication_update(
                          cast_text(:#{#publication.title}),
                          cast_type(:#{#publication.type.value}),
                          cast_text(:#{#publication.abstract}),
                          cast(:#{#publication.date.toString()} as date),
                          cast_text(:#{#publication.doi}),
                          cast_int(:#{#publication.idPublication})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("publication") newPublication: Publication): Publication

    @Query(value = """select (publication_delete(cast_int(:id_publication))).*""",
            nativeQuery = true)
    fun remove(@Param("id_publication") idPublication: Int): Publication

}