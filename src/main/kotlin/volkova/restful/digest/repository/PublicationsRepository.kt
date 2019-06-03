package volkova.restful.digest.repository

import org.springframework.data.repository.Repository as MyRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import org.springframework.web.bind.annotation.CrossOrigin
import volkova.restful.digest.entity.Publication

@CrossOrigin
@Repository
interface PublicationsRepository : MyRepository<Publication, Int> {

    @Query(value = """select (publication_record(
                          cast_int(:id_publication),
                          cast_type(:type),
                          cast_text(:abstract),
                          cast(:date as date),
                          cast_text(:doi),
                          cast_text(:title)
                      )).*""",
            nativeQuery = true)
    fun findSome(
            @Param("id_publication") idPublication: Int? = null,
            @Param("type") type: String? = null,
            @Param("abstract") abstract: String? = null,
            @Param("date") date: String? = null,
            @Param("doi") doi: String? = null,
            @Param("title") title: String? = null
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
                          cast_dp(:#{#publication.rating.stars}),
                          cast_int(:#{#publication.rating.seen})
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