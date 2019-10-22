package volkova.restful.digest.repository


import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as EmptyRepository
import org.springframework.stereotype.Repository
import org.springframework.web.bind.annotation.CrossOrigin

import volkova.restful.digest.entity.Publication


@CrossOrigin
@Repository
interface PublicationsRepository : EmptyRepository<Publication, Int> {

    @Query(value = """select (publication_search(
                          cast_text(:title),
                          cast_text(:date),
                          cast_text(:authors),
                          cast_text(:keywords)
                      )).*""",
            nativeQuery = true)
    fun findSearch(
            @Param("title") title: String? = null,
            @Param("date") date: String? = null,
            @Param("keywords") keywords: String? = null,
            @Param("authors") authors: String? = null
    ): MutableList<Publication>

    @Query(value = """select (publication_record(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Publication>

    @Query(value = """select (publication_insert(
                          cast_type(:#{#publication.type.value}),
                          cast_text(:#{#publication.abstract}),
                          cast(:#{#publication.date.toString()} as date),
                          cast_text(:#{#publication.doi}),
                          cast_text(:#{#publication.title}),
                          cast_int(:#{#publication.rating.idRating}),
                          cast_int(:#{#publication.journal.idJournal})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("publication") newPublication: Publication): Publication

    @Query(value = """select (publication_update(
                          cast_type(:#{#publication.type.value}),
                          cast_text(:#{#publication.abstract}),
                          cast(:#{#publication.date.toString()} as date),
                          cast_text(:#{#publication.doi}),
                          cast_text(:#{#publication.title}),
                          cast_int(:#{#publication.idPublication})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("publication") newPublication: Publication): Publication

    @Query(value = """select (publication_delete(cast_int(:id_publication))).*""",
            nativeQuery = true)
    fun remove(@Param("id_publication") idPublication: Int): Publication

}